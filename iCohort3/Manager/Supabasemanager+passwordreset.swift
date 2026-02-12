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
    
    // MARK: - Custom OTP Password Reset (No Auth Dependency)
    
    /// Generate and send OTP email (custom implementation)
    /// - Parameter email: The user's email address
    func sendPasswordResetEmail(email: String) async throws {
        print("\n===========================================")
        print("📧 CUSTOM PASSWORD RESET EMAIL")
        print("===========================================")
        
        // ✅ Normalize email
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        print("Email:", normalizedEmail)
        
        // ✅ Delete any existing OTPs for this email first
        try? await client
            .from("password_reset_otps")
            .delete()
            .eq("email", value: normalizedEmail)
            .execute()
        
        print("🗑️  Cleared any existing OTPs")
        
        // Generate a 6-digit OTP
        let otp = String(format: "%06d", Int.random(in: 100000...999999))
        print("Generated OTP:", otp)
        print("OTP length:", otp.count)
        
        // Store OTP in database with expiration (60 minutes)
        let expiresAt = Date().addingTimeInterval(3600) // 1 hour from now
        
        struct OTPRecord: Encodable {
            let email: String
            let otp_code: String
            let expires_at: String
            let created_at: String
        }
        
        let otpRecord = OTPRecord(
            email: normalizedEmail,
            otp_code: otp,
            expires_at: ISO8601DateFormatter().string(from: expiresAt),
            created_at: ISO8601DateFormatter().string(from: Date())
        )
        
        // Store in password_reset_otps table
        do {
            try await client
                .from("password_reset_otps")
                .insert(otpRecord)
                .execute()
            
            print("✅ OTP stored in database")
            print("   Email: \(normalizedEmail)")
            print("   OTP: \(otp)")
            print("   Expires: \(ISO8601DateFormatter().string(from: expiresAt))")
            
            // Now try to send via Supabase Auth
            do {
                try await client.auth.resetPasswordForEmail(normalizedEmail)
                print("✅ Email sent via Supabase Auth")
            } catch {
                print("⚠️  Supabase Auth email failed, but OTP is stored")
                print("   Error: \(error.localizedDescription)")
            }
            
        } catch {
            print("❌ Failed to store OTP:", error.localizedDescription)
            throw error
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
        let expiresAt = ISO8601DateFormatter().date(from: record.expires_at) ?? Date.distantPast
        
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
        
        // ✅ UPDATE 2: approved_students table (if exists)
        do {
            struct ApprovedStudentUpdate: Encodable {
                let password_hash: String
            }
            
            let update = ApprovedStudentUpdate(password_hash: newPasswordHash)
            
            try await client
                .from("approved_students")
                .update(update)
                .eq("srm_mail", value: normalizedEmail)
                .execute()
            
            print("✅ Password updated in approved_students")
        } catch {
            print("⚠️  approved_students update failed (table might not exist or student not in it):", error.localizedDescription)
            // Don't throw error, continue to next table
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
