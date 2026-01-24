//
//  Supabase+Admin.swift
//  iCohort3
//
//  Created by user@51 on 23/01/26.
//

//
//  SupabaseManager+Admin.swift
//  iCohort3
//
//  Admin-specific functionality
//

import Foundation
import Supabase

// MARK: - Admin Functions Extension
extension SupabaseManager {
    
    struct AdminStudentOverview: Codable, Sendable {
        let person_id: String
        let full_name: String?
        let role: String
        let profile_id: String?
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let is_profile_complete: Bool?
        let team_no: Int?
        let last_profile_update: String?
        let registration_date: String?
    }
    
    // MARK: - Fetch All Students
    
    func fetchAllStudentsForAdmin() async throws -> [AdminStudentOverview] {
        let students: [AdminStudentOverview] = try await client
            .from("admin_student_overview")
            .select()
            .execute()
            .value
        
        return students
    }
    
    // MARK: - Admin Update Student Profile
    
    func adminUpdateStudentProfile(
        profileId: String,
        adminId: String,
        update: StudentProfileUpdate
    ) async throws {
        _ = try await client
            .from("student_profiles")
            .update(update)
            .eq("id", value: profileId)
            .execute()
        
        struct AdminLog: Encodable {
            let student_profile_id: String
            let admin_id: String
            let action: String
            let changes: [String: String?]
        }
        
        let changes: [String: String?] = [
            "first_name": update.first_name,
            "last_name": update.last_name,
            "department": update.department,
            "srm_mail": update.srm_mail,
            "reg_no": update.reg_no,
            "personal_mail": update.personal_mail,
            "contact_number": update.contact_number
        ]
        
        let log = AdminLog(
            student_profile_id: profileId,
            admin_id: adminId,
            action: "updated",
            changes: changes
        )
        
        _ = try await client
            .from("profile_admin_logs")
            .insert(log)
            .execute()
    }
    
    // MARK: - Admin Delete Student Profile
    
    func adminDeleteStudentProfile(profileId: String, adminId: String) async throws {
        struct AdminLog: Encodable {
            let student_profile_id: String
            let admin_id: String
            let action: String
        }
        
        let log = AdminLog(
            student_profile_id: profileId,
            admin_id: adminId,
            action: "deleted"
        )
        
        _ = try await client
            .from("profile_admin_logs")
            .insert(log)
            .execute()
        
        _ = try await client
            .from("student_profiles")
            .delete()
            .eq("id", value: profileId)
            .execute()
    }
}
