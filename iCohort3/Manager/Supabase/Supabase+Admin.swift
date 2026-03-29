//
//  Supabase+Admin.swift
//  iCohort3
//
//  ✅ FIXED: fetchTeamsCount uses new_teams table with status = 'active'
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
    
    // MARK: - Institute ID Management
    
    func getInstituteIdForAdmin(adminEmail: String) async throws -> String {
        print("🔍 Fetching institute ID for admin:", adminEmail)
        
        let institutes: [Institute] = try await client
            .from("institutes")
            .select()
            .eq("admin_email", value: adminEmail)
            .limit(1)
            .execute()
            .value
        
        guard let institute = institutes.first else {
            throw SupabaseError.instituteNotFound
        }
        
        print("✅ Institute ID found:", institute.id)
        return institute.id
    }
    
    func getInstituteById(instituteId: String) async throws -> Institute {
        let institutes: [Institute] = try await client
            .from("institutes")
            .select()
            .eq("id", value: instituteId)
            .limit(1)
            .execute()
            .value
        
        guard let institute = institutes.first else {
            throw SupabaseError.instituteNotFound
        }
        
        return institute
    }
    
    // MARK: - Domain-Based Filtering
    
    func getPendingStudentsForAdmin(adminEmail: String) async throws -> [StudentRegistration] {
        print("🔍 Fetching pending students for admin:", adminEmail)
        
        guard let institute = try await getInstitute(byAdminEmail: adminEmail) else {
            throw SupabaseError.instituteNotFound
        }
        
        print("📍 Admin's institute domain:", institute.domain)
        
        let students: [StudentRegistration] = try await client
            .from("student_registrations")
            .select()
            .eq("institute_domain", value: institute.domain)
            .eq("approval_status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ Found \(students.count) pending students for domain:", institute.domain)
        return students
    }

    func getPendingMentorsForAdmin(adminEmail: String) async throws -> [MentorRegistration] {
        print("🔍 Fetching pending mentors for admin:", adminEmail)
        
        guard let institute = try await getInstitute(byAdminEmail: adminEmail) else {
            throw SupabaseError.instituteNotFound
        }
        
        print("📍 Admin's institute domain:", institute.domain)
        
        let mentors = try await getPendingMentorsByDomain(instituteDomain: institute.domain)
        
        print("✅ Found \(mentors.count) pending mentors for domain:", institute.domain)
        return mentors
    }

    func countApprovedMentorsForAdmin(adminEmail: String) async throws -> Int {
        guard let institute = try await getInstitute(byAdminEmail: adminEmail) else {
            return 0
        }
        return try await countApprovedMentorsByDomain(instituteDomain: institute.domain)
    }
    
    func countApprovedStudentsForAdmin(adminEmail: String) async throws -> Int {
        guard let institute = try await getInstitute(byAdminEmail: adminEmail) else {
            return 0
        }
        return try await countApprovedStudents(forDomain: institute.domain)
    }
    
    // MARK: - Institute-Aware Statistics
    
    struct InstituteStatistics: Sendable {
        let instituteId: String
        let instituteName: String
        let instituteDomain: String
        let pendingStudents: Int
        let pendingMentors: Int
        let approvedStudents: Int
        let approvedMentors: Int
        let totalTeams: Int
    }
    
    /// Get complete statistics for admin's institute
    /// ✅ totalTeams is fetched from new_teams (status = 'active')
    func getInstituteStatistics(adminEmail: String) async throws -> InstituteStatistics {
        print("📊 Fetching statistics for admin:", adminEmail)
        
        guard let institute = try await getInstitute(byAdminEmail: adminEmail) else {
            throw SupabaseError.instituteNotFound
        }
        
        print("✅ Institute found: \(institute.name) | Domain: \(institute.domain)")
        
        // Run all queries concurrently
        async let pendingStudentsTask = getPendingStudents(forDomain: institute.domain)
        async let pendingMentorsTask = getPendingMentorsByDomain(instituteDomain: institute.domain)
        async let approvedStudentsCountTask = countApprovedStudents(forDomain: institute.domain)
        async let approvedMentorsCountTask = countApprovedMentorsByDomain(instituteDomain: institute.domain)
        async let teamsCountTask = fetchTeamsCount(forInstituteDomain: institute.domain)
        
        let (pending_students, pending_mentors, approved_students, approved_mentors, teams) =
            try await (pendingStudentsTask, pendingMentorsTask, approvedStudentsCountTask, approvedMentorsCountTask, teamsCountTask)
        
        let stats = InstituteStatistics(
            instituteId: institute.id,
            instituteName: institute.name,
            instituteDomain: institute.domain,
            pendingStudents: pending_students.count,
            pendingMentors: pending_mentors.count,
            approvedStudents: approved_students,
            approvedMentors: approved_mentors,
            totalTeams: teams
        )
        
        print("✅ Statistics loaded for institute: \(institute.name)")
        print("   Pending Students: \(stats.pendingStudents)")
        print("   Pending Mentors:  \(stats.pendingMentors)")
        print("   Approved Students:\(stats.approvedStudents)")
        print("   Approved Mentors: \(stats.approvedMentors)")
        print("   Total Teams:      \(stats.totalTeams)")
        
        return stats
    }
    
    // MARK: - Fetch All Students (Institute-Filtered)
    
    func fetchAllStudentsForAdmin(adminEmail: String) async throws -> [AdminStudentOverview] {
        guard let institute = try await getInstitute(byAdminEmail: adminEmail) else {
            throw SupabaseError.instituteNotFound
        }
        
        let students: [AdminStudentOverview] = try await client
            .from("admin_student_overview")
            .select()
            .execute()
            .value
        
        return students.filter { student in
            student.srm_mail?.hasSuffix("@\(institute.domain)") ?? false
        }
    }
    
    // MARK: - Admin Profile Updates
    
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
    
    // MARK: - Validation Helpers
    
    func validateStudentBelongsToInstitute(
        studentEmail: String,
        adminEmail: String
    ) async throws -> Bool {
        guard let institute = try await getInstitute(byAdminEmail: adminEmail) else {
            return false
        }
        return studentEmail.hasSuffix("@\(institute.domain)")
    }
    
    func validateMentorBelongsToInstitute(
        mentorInstituteName: String,
        adminEmail: String
    ) async throws -> Bool {
        guard let institute = try await getInstitute(byAdminEmail: adminEmail) else {
            return false
        }
        return mentorInstituteName.lowercased() == institute.name.lowercased()
    }
}
