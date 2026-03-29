//
//  Supabase+Student.swift
//  iCohort3
//
//  ✅ CLEAN: Student profile + team info for the student-facing profile screen.
//  ✅ NOTE:  fetchTeamsCount, fetchAllTeamsWithDetails, assignMentorToTeam,
//            removeMentorFromTeam are all defined in SupabaseManager+Admin.swift.
//            TeamWithDetails struct is defined HERE (used by both files).
//

import Foundation
import PostgREST
import Supabase

// MARK: - Student Profile Extension
extension SupabaseManager {
    
    // MARK: - Student Types
    
    struct StudentProfile: Codable, Sendable {
        let id: String?
        let person_id: String
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool?
        let created_at: String?
        let updated_at: String?
    }
    
    struct StudentProfileComplete: Codable, Sendable {
        let id: String
        let person_id: String
        let full_name: String?
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool
        let team_no: Int?
        let team_id: String?
        let mentor_name: String?
        let created_at: String?
        let updated_at: String?
    }
    
    struct StudentProfileUpdate: Encodable, Sendable {
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let personal_mail: String?
        let contact_number: String?
    }
    
    struct StudentProfileUpsert: Encodable, Sendable {
        let person_id: String
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool
    }
    
    struct PersonDetailRow: Codable, Sendable {
        let id: String
        let full_name: String
        let role: String
        let created_at: String?
    }
    
    // MARK: - TeamWithDetails
    //
    // Declared HERE (single definition).
    // Used by:
    //   • SupabaseManager+Admin.swift  → fetchAllTeamsWithDetails()
    //   • AdminTeamsViewController      → TeamDisplayModel mapping
    
    
    // MARK: - StudentTeamInfo
    //
    // Lightweight model for the student-facing profile screen.
    // Shows team number, fullness, mentor, and the student's role.
    
    struct StudentTeamInfo: Sendable {
        let teamNumber: Int
        let teamId: String
        let mentorName: String?
        let problemStatement: String?
        let memberCount: Int    // 1, 2, or 3
        let isFull: Bool        // true when memberCount == 3
        let isCreator: Bool
    }
    
    // MARK: - Fetch Student Profile
    
    func fetchStudentProfile(personId: String) async throws -> StudentProfileComplete? {
        print("🔍 Fetching complete student profile for person_id:", personId)
        
        let response: [StudentProfileComplete] = try await client
            .from("student_profile_complete")
            .select()
            .eq("person_id", value: personId)
            .limit(1)
            .execute()
            .value
        
        let profile = response.first
        print(profile != nil ? "✅ Found complete student profile" : "⚠️ No complete student profile found")
        return profile
    }
    
    func fetchBasicStudentProfile(personId: String) async throws -> StudentProfile? {
        print("🔍 Fetching basic student profile for person_id:", personId)
        
        let response: [StudentProfile] = try await client
            .from("student_profiles")
            .select()
            .eq("person_id", value: personId)
            .limit(1)
            .execute()
            .value
        
        let profile = response.first
        print(profile != nil ? "✅ Found basic student profile" : "⚠️ No basic student profile found")
        return profile
    }
    
    // MARK: - Fetch Team Info for Student (from new_teams)
    
    /// Fetches team info for the student profile screen.
    /// Checks all three member slots in new_teams.
    /// Returns nil if the student has no active team.
    func fetchTeamInfoForStudent(personId: String) async throws -> StudentTeamInfo? {
        print("🔍 Fetching team info for person_id:", personId)
        
        // Minimal projection — only what we need
        struct TeamSlim: Codable {
            let id: String
            let team_number: Int
            let created_by_id: String
            let member2_id: String?
            let member3_id: String?
            let mentor_name: String?
            let problem_statement: String?
        }
        
        let selectCols = "id, team_number, created_by_id, member2_id, member3_id, mentor_name, problem_statement"
        
        // 1 — creator slot
        var rows: [TeamSlim] = try await client
            .from("new_teams")
            .select(selectCols)
            .eq("created_by_id", value: personId)
            .eq("status", value: "active")
            .limit(1)
            .execute()
            .value
        
        var isCreator = true
        
        // 2 — member2 slot
        if rows.isEmpty {
            isCreator = false
            rows = try await client
                .from("new_teams")
                .select(selectCols)
                .eq("member2_id", value: personId)
                .eq("status", value: "active")
                .limit(1)
                .execute()
                .value
        }
        
        // 3 — member3 slot
        if rows.isEmpty {
            rows = try await client
                .from("new_teams")
                .select(selectCols)
                .eq("member3_id", value: personId)
                .eq("status", value: "active")
                .limit(1)
                .execute()
                .value
        }
        
        guard let team = rows.first else {
            print("⚠️ No active team found for person_id:", personId)
            return nil
        }
        
        // Count filled slots
        var memberCount = 1                              // creator always present
        if team.member2_id != nil { memberCount += 1 }
        if team.member3_id != nil { memberCount += 1 }
        
        let info = StudentTeamInfo(
            teamNumber: team.team_number,
            teamId: team.id,
            mentorName: team.mentor_name,
            problemStatement: team.problem_statement,
            memberCount: memberCount,
            isFull: memberCount == 3,
            isCreator: isCreator
        )
        
        print("✅ Team \(team.team_number) | members: \(memberCount)/3 | full: \(info.isFull) | creator: \(isCreator)")
        return info
    }
    
    // MARK: - Create/Update Student Profile
    
    func upsertStudentProfile(
        personId: String,
        firstName: String? = nil,
        lastName: String? = nil,
        department: String? = nil,
        srmMail: String? = nil,
        regNo: String? = nil,
        personalMail: String? = nil,
        contactNumber: String? = nil
    ) async throws -> String {
        print("🔄 Upserting student profile for person_id:", personId)
        
        let isComplete = firstName != nil && !firstName!.isEmpty &&
                         lastName  != nil && !lastName!.isEmpty  &&
                         department != nil && !department!.isEmpty &&
                         srmMail   != nil && !srmMail!.isEmpty   &&
                         regNo     != nil && !regNo!.isEmpty
        
        let payload = StudentProfileUpsert(
            person_id: personId,
            first_name: firstName,
            last_name: lastName,
            department: department,
            srm_mail: srmMail,
            reg_no: regNo,
            personal_mail: personalMail,
            contact_number: contactNumber,
            is_profile_complete: isComplete
        )
        
        struct UpsertResponse: Codable { let id: String }
        
        let response: [UpsertResponse] = try await client
            .from("student_profiles")
            .upsert(payload, onConflict: "person_id")
            .select("id")
            .execute()
            .value
        
        guard let profileId = response.first?.id else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to upsert student profile"])
        }
        
        print("✅ Student profile upserted with id:", profileId)
        return profileId
    }
    
    // MARK: - Get Student Greeting
    
    func getStudentGreeting(personId: String) async throws -> String {
        print("🔍 Fetching student greeting for person_id:", personId)
        
        // 1. Use the profile first name only when the student has filled it in.
        if let profile = try? await fetchBasicStudentProfile(personId: personId),
           let firstName = profile.first_name?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !firstName.isEmpty {
            return "Hi \(firstName)"
        }

        // 2. Fall back to the complete profile/view if basic profile fields are empty.
        if let profile = try? await fetchStudentProfile(personId: personId) {
            if let firstName = profile.first_name?.trimmingCharacters(in: .whitespacesAndNewlines),
               !firstName.isEmpty {
                return "Hi \(firstName)"
            }

            if let fullName = profile.full_name?.trimmingCharacters(in: .whitespacesAndNewlines),
               !fullName.isEmpty {
                let firstName = fullName.components(separatedBy: .whitespaces).first ?? fullName
                return "Hi \(firstName)"
            }
        }

        // 3. Use the shared student_profile_complete name lookup as another profile-backed source.
        if let fullName = try? await fetchStudentFullName(personIdString: personId) {
            let cleaned = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !cleaned.isEmpty {
                let firstName = cleaned.components(separatedBy: .whitespaces).first ?? cleaned
                return "Hi \(firstName)"
            }
        }

        // 4. Safe cached fallback from login/session if present.
        if let cachedName = UserDefaults.standard.string(forKey: "current_user_name")?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !cachedName.isEmpty {
            let firstName = cachedName.components(separatedBy: .whitespaces).first ?? cachedName
            return "Hi \(firstName)"
        }

        // 5. If profile is not updated, keep the greeting generic.
        return "Hi user"
    }
    
    // MARK: - Check Profile Completion
    
    func isStudentProfileComplete(personId: String) async throws -> Bool {
        let profile = try await fetchBasicStudentProfile(personId: personId)
        return profile?.is_profile_complete ?? false
    }
    
    // MARK: - Fetch Student ID
    
    func fetchStudentId(srmMail: String) async throws -> String? {
        print("🔍 Fetching student ID for SRM email:", srmMail)
        let profiles: [StudentProfile] = try await client
            .from("student_profiles")
            .select()
            .eq("srm_mail", value: srmMail)
            .limit(1)
            .execute()
            .value
        return profiles.first?.person_id
    }
    
    func fetchStudentId(regNo: String) async throws -> String? {
        print("🔍 Fetching student ID for reg no:", regNo)
        let profiles: [StudentProfile] = try await client
            .from("student_profiles")
            .select()
            .eq("reg_no", value: regNo)
            .limit(1)
            .execute()
            .value
        return profiles.first?.person_id
    }
    
    func getCurrentStudentId() -> String? {
        return UserDefaults.standard.string(forKey: "current_person_id")
    }
    
    // MARK: - Fetch Person
    
    func fetchPerson(personId: String) async throws -> PersonDetailRow? {
        print("🔍 Fetching person:", personId)
        let persons: [PersonDetailRow] = try await client
            .from("people")
            .select("id, full_name, role, created_at")
            .eq("id", value: personId)
            .limit(1)
            .execute()
            .value
        
        if let person = persons.first {
            print("✅ Found person:", person.full_name)
            return person
        }
        print("⚠️ Person not found")
        return nil
    }
}
