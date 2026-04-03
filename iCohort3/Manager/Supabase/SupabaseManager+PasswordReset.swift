//
//  SupabaseManager+PasswordReset.swift
//  iCohort3
//
//  ✅ SIMPLIFIED: Direct OTP generation without Auth dependency
//  ✅ Works even if user is not in auth.users table
//  ✅ Updates password in ALL relevant tables
//

import Foundation
import Supabase

extension SupabaseManager {
    enum PasswordResetUserRole: String {
        case student
        case mentor
        case admin
    }

    enum EmailOTPPurpose: String {
        case verification
        case password_reset
    }

    private struct EmailOTPFunctionRequest: Encodable {
        let email: String
        let purpose: String
    }

    private struct EmailOTPFunctionResponse: Decodable {
        let success: Bool?
        let message: String?
        let error: String?
    }
    
    // MARK: - Custom OTP Password Reset (No Auth Dependency)

    private func parseISODate(_ value: String) -> Date? {
        let formatterWithFractionalSeconds = ISO8601DateFormatter()
        formatterWithFractionalSeconds.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatterWithFractionalSeconds.date(from: value) {
            return date
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
    
    /// Generate and send OTP email (custom implementation)
    /// - Parameter email: The user's email address
    func sendPasswordResetEmail(
        email: String,
        purpose: EmailOTPPurpose = .verification
    ) async throws {
        print("\n===========================================")
        print("📧 CUSTOM PASSWORD RESET EMAIL")
        print("===========================================")
        
        // ✅ Normalize email
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("Email:", normalizedEmail)

        let endpoint = supabaseURL
            .appendingPathComponent("functions")
            .appendingPathComponent("v1")
            .appendingPathComponent("email-otp")

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(
            EmailOTPFunctionRequest(email: normalizedEmail, purpose: purpose.rawValue)
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        let httpResponse = response as? HTTPURLResponse

        guard (200..<300).contains(httpResponse?.statusCode ?? 0) else {
            let rawBody = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            throw NSError(
                domain: "EmailOTPFunction",
                code: httpResponse?.statusCode ?? -1,
                userInfo: [NSLocalizedDescriptionKey: rawBody?.isEmpty == false ? rawBody! : "Failed to send OTP email."]
            )
        }

        let payload = try JSONDecoder().decode(EmailOTPFunctionResponse.self, from: data)
        if payload.success != true {
            throw NSError(
                domain: "EmailOTPFunction",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: payload.error ?? payload.message ?? "Failed to send OTP email."]
            )
        }
        
        print("===========================================\n")
    }
    
    /// Verify OTP from database
    func verifyOTPForPasswordReset(email: String, otp: String) async throws {
        print("\n===========================================")
        print("📝 CUSTOM OTP VERIFICATION")
        print("===========================================")
        
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedOTP = otp.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Email:", normalizedEmail)
        print("OTP entered:", normalizedOTP)
        
        struct OTPRecord: Codable {
            let email: String
            let otp_code: String
            let expires_at: String
        }
        
        let records: [OTPRecord] = try await client
            .from("password_reset_otps")
            .select()
            .eq("email", value: normalizedEmail)
            .eq("otp_code", value: normalizedOTP)
            .execute()
            .value
        
        guard let record = records.first else {
            print("❌ Invalid OTP")
            throw NSError(
                domain: "PasswordReset",
                code: 1002,
                userInfo: [NSLocalizedDescriptionKey: "Invalid OTP code. Please check and try again."]
            )
        }
        
        // Check if OTP has expired
        let expiresAt = parseISODate(record.expires_at) ?? Date.distantPast
        
        guard Date() < expiresAt else {
            print("❌ OTP expired")
            try? await deleteOTP(email: normalizedEmail)
            throw NSError(
                domain: "PasswordReset",
                code: 1003,
                userInfo: [NSLocalizedDescriptionKey: "OTP has expired. Please request a new one."]
            )
        }
        
        print("✅ OTP verified successfully")
        print("===========================================\n")
    }
    
    /// Delete OTP after successful verification or reset
    func deleteOTP(email: String) async throws {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        try await client
            .from("password_reset_otps")
            .delete()
            .eq("email", value: normalizedEmail)
            .execute()
        
        print("✅ OTP deleted from database for email: \(normalizedEmail)")
    }
    
    // MARK: - Database Password Reset (ALL TABLES)
    
    /// Update student password in ALL relevant tables
    func updateStudentPassword(email: String, newPassword: String) async throws {
        print("\n===========================================")
        print("📝 DATABASE PASSWORD UPDATE (ALL TABLES)")
        print("===========================================")
        
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("Email:", normalizedEmail)
        
        // Hash the new password
        let newPasswordHash = hashPassword(newPassword)
        print("New password hash:", newPasswordHash)
        
        // ✅ UPDATE 1: student_profiles table
        do {
            struct PasswordUpdate: Encodable {
                let password_hash: String
                let updated_at: String
            }
            
            let update = PasswordUpdate(
                password_hash: newPasswordHash,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await client
                .from("student_profiles")
                .update(update)
                .eq("srm_mail", value: normalizedEmail)
                .execute()
            
            print("✅ Password updated in student_profiles")
        } catch {
            print("❌ Failed to update student_profiles:", error.localizedDescription)
            throw error
        }
        
        // ✅ UPDATE 2: student_registrations table
        do {
            struct StudentRegistrationUpdate: Encodable {
                let password_hash: String
                let updated_at: String
            }
            
            let update = StudentRegistrationUpdate(
                password_hash: newPasswordHash,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await client
                .from("student_registrations")
                .update(update)
                .eq("email", value: normalizedEmail)
                .execute()
            
            print("✅ Password updated in student_registrations")
        } catch {
            print("⚠️  student_registrations update failed:", error.localizedDescription)
        }
        
        // ✅ UPDATE 3: Check for any other tables with email reference
        // Add more tables here if needed in the future
        
        print("✅ Password update completed across all tables")
        print("===========================================\n")
    }
    
    /// Verify student exists by email
    func verifyStudentExists(email: String) async throws -> Bool {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("🔍 Checking if student exists:", normalizedEmail)
        
        let students: [StudentProfile] = try await client
            .from("student_profiles")
            .select("person_id")
            .eq("srm_mail", value: normalizedEmail)
            .limit(1)
            .execute()
            .value
        
        let exists = !students.isEmpty
        print(exists ? "✅ Student exists" : "❌ Student not found")
        return exists
    }

    func verifyMentorExists(email: String) async throws -> Bool {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        struct MentorProfileRow: Decodable { let person_id: String }
        let mentors: [MentorProfileRow] = try await client
            .from("mentor_profiles")
            .select("person_id")
            .eq("email", value: normalizedEmail)
            .limit(1)
            .execute()
            .value

        return !mentors.isEmpty
    }

    func verifyAdminExists(email: String) async throws -> Bool {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        struct AdminRow: Decodable { let id: String }
        let admins: [AdminRow] = try await client
            .from("admin_accounts")
            .select("id")
            .eq("email", value: normalizedEmail)
            .limit(1)
            .execute()
            .value

        return !admins.isEmpty
    }

    func verifyAccountExists(email: String, role: PasswordResetUserRole) async throws -> Bool {
        switch role {
        case .student:
            return try await verifyStudentExists(email: email)
        case .mentor:
            return try await verifyMentorExists(email: email)
        case .admin:
            return try await verifyAdminExists(email: email)
        }
    }

    func updateMentorPassword(email: String, newPassword: String) async throws {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let newPasswordHash = hashPassword(newPassword)
        let updatedAt = ISO8601DateFormatter().string(from: Date())

        struct MentorPasswordUpdate: Encodable {
            let password_hash: String
            let updated_at: String
        }

        let update = MentorPasswordUpdate(password_hash: newPasswordHash, updated_at: updatedAt)

        try await client
            .from("mentor_profiles")
            .update(update)
            .eq("email", value: normalizedEmail)
            .execute()

        _ = try? await client
            .from("mentor_registrations")
            .update(update)
            .eq("email", value: normalizedEmail)
            .execute()
    }

    func updateAdminPassword(email: String, newPassword: String) async throws {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let newPasswordHash = hashPassword(newPassword)
        let updatedAt = ISO8601DateFormatter().string(from: Date())

        struct AdminPasswordUpdate: Encodable {
            let password_hash: String
            let updated_at: String
        }

        try await client
            .from("admin_accounts")
            .update(AdminPasswordUpdate(password_hash: newPasswordHash, updated_at: updatedAt))
            .eq("email", value: normalizedEmail)
            .execute()
    }

    func updatePassword(email: String, newPassword: String, role: PasswordResetUserRole) async throws {
        switch role {
        case .student:
            try await updateStudentPassword(email: email, newPassword: newPassword)
        case .mentor:
            try await updateMentorPassword(email: email, newPassword: newPassword)
        case .admin:
            try await updateAdminPassword(email: email, newPassword: newPassword)
        }
    }
}

// MARK: - Student Profile Structure
struct StudentProfile: Codable, Sendable {
    let person_id: String
    let first_name: String?
    let last_name: String?
    let srm_mail: String
    let reg_no: String?
    let department: String?
    let password_hash: String?
    let contact_number: String?
    let personal_mail: String?
    let created_at: String?
    let updated_at: String?
}
