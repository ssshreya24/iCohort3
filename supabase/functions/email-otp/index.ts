import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const corsHeaders = {
  "Content-Type": "application/json",
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

type Purpose = "verification" | "password_reset";

interface EmailOTPRequest {
  email: string;
  purpose?: Purpose;
}

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
);

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), { status, headers: corsHeaders });
}

function normalizeEmail(email: string) {
  return email.trim().toLowerCase();
}

function generateOtp() {
  return String(Math.floor(100000 + Math.random() * 900000));
}

function base64UrlEncode(input: string) {
  const bytes = new TextEncoder().encode(input);
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function getGoogleAccessToken() {
  const clientId = Deno.env.get("GOOGLE_CLIENT_ID");
  const clientSecret = Deno.env.get("GOOGLE_CLIENT_SECRET");
  const refreshToken = Deno.env.get("GOOGLE_REFRESH_TOKEN");

  if (!clientId || !clientSecret || !refreshToken) {
    throw new Error("Missing Google OAuth secrets");
  }

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      client_id: clientId,
      client_secret: clientSecret,
      refresh_token: refreshToken,
      grant_type: "refresh_token",
    }),
  });

  const data = await response.json();
  if (!response.ok || !data.access_token) {
    throw new Error(`Failed to get Google access token: ${JSON.stringify(data)}`);
  }

  return data.access_token as string;
}

async function sendOtpEmail(toEmail: string, otp: string, purpose: Purpose) {
  const sender = Deno.env.get("GMAIL_SENDER_EMAIL");
  if (!sender) throw new Error("Missing GMAIL_SENDER_EMAIL secret");

  const accessToken = await getGoogleAccessToken();
  const subject =
    purpose === "password_reset"
      ? "Your iCohort password reset code"
      : "Your iCohort verification code";
  const actionText =
    purpose === "password_reset"
      ? "reset your password"
      : "verify your email";

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 520px; margin: 0 auto; padding: 24px;">
      <h2 style="color: #2f4b66; margin-bottom: 8px;">iCohort Verification Code</h2>
      <p style="color: #4b5f73; font-size: 15px;">
        Use the code below to ${actionText}.
      </p>
      <div style="margin: 28px 0; text-align: center;">
        <div style="
          display: inline-block;
          padding: 16px 28px;
          border-radius: 14px;
          background: #779cb3;
          color: white;
          font-size: 30px;
          font-weight: 700;
          letter-spacing: 8px;">
          ${otp}
        </div>
      </div>
      <p style="color: #4b5f73; font-size: 14px;">This code expires in 60 minutes.</p>
    </div>
  `;

  const mime = [
    `From: iCohort <${sender}>`,
    `To: ${toEmail}`,
    `Subject: ${subject}`,
    "MIME-Version: 1.0",
    'Content-Type: text/html; charset="UTF-8"',
    "",
    html,
  ].join("\r\n");

  const raw = base64UrlEncode(mime);

  const response = await fetch("https://gmail.googleapis.com/gmail/v1/users/me/messages/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ raw }),
  });

  const data = await response.json();
  if (!response.ok) {
    throw new Error(`Failed to send Gmail message: ${JSON.stringify(data)}`);
  }
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = (await req.json().catch(() => ({}))) as EmailOTPRequest;
    const email = normalizeEmail(body.email ?? "");
    const purpose: Purpose = body.purpose === "password_reset" ? "password_reset" : "verification";

    if (!email) {
      return json({ success: false, error: "email is required" }, 400);
    }

    await supabase
      .from("password_reset_otps")
      .delete()
      .eq("email", email);

    const otp = generateOtp();
    const expiresAt = new Date(Date.now() + 60 * 60 * 1000).toISOString();
    const createdAt = new Date().toISOString();

    const { error: insertError } = await supabase
      .from("password_reset_otps")
      .insert({
        email,
        otp_code: otp,
        expires_at: expiresAt,
        created_at: createdAt,
      });

    if (insertError) {
      throw insertError;
    }

    await sendOtpEmail(email, otp, purpose);

    return json({
      success: true,
      message: "OTP email sent successfully",
    });
  } catch (error) {
    return json(
      { success: false, error: error instanceof Error ? error.message : "Unknown error" },
      500
    );
  }
});
