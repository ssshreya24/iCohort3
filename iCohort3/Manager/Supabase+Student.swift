//
//  Supabase+Student.swift
//  iCohort3
//
//  Created by user@51 on 23/01/26.
//

//
//  SupabaseManager+Student.swift
//  iCohort3
//
//  Student-specific functionality
//

import Foundation
internal import PostgREST
import Supabase

// MARK: - Student Profile Extension
extension SupabaseManager {
    
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
    
    // MARK: - Fetch Student Profile
    
    func fetchStudentProfile(personId: String) async throws -> StudentProfileComplete? {
        let response: [StudentProfileComplete] = try await client
            .from("student_profile_complete")
            .select()
            .eq("person_id", value: personId)
            .execute()
            .value
        
        return response.first
    }
    
    func fetchBasicStudentProfile(personId: String) async throws -> StudentProfile? {
        let response: [StudentProfile] = try await client
            .from("student_profiles")
            .select()
            .eq("person_id", value: personId)
            .execute()
            .value
        
        return response.first
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
        let isComplete = firstName != nil && !firstName!.isEmpty &&
                        lastName != nil && !lastName!.isEmpty &&
                        department != nil && !department!.isEmpty &&
                        srmMail != nil && !srmMail!.isEmpty &&
                        regNo != nil && !regNo!.isEmpty
        
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
        
        struct UpsertResponse: Codable {
            let id: String
        }
        
        let response: [UpsertResponse] = try await client
            .from("student_profiles")
            .upsert(payload, onConflict: "person_id")
            .select("id")
            .execute()
            .value
        
        guard let profileId = response.first?.id else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to upsert profile"])
        }
        
        return profileId
    }
    
    // MARK: - Get Student Greeting
    
    func getStudentGreeting(personId: String) async throws -> String {
        let params: [String: String] = ["p_person_id": personId]
        
        let result: String = try await client
            .rpc("get_student_greeting", params: params)
            .execute()
            .value
        
        return result
    }
    
    // MARK: - Assign Student to Team
    
    func assignStudentToTeam9(studentPersonId: String) async throws {
        struct TeamRow: Codable {
            let id: String
        }
        
        let teams: [TeamRow] = try await client
            .from("teams")
            .select("id")
            .eq("team_no", value: 9)
            .execute()
            .value
        
        guard let teamId = teams.first?.id else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Team 9 not found"])
        }
        
        struct MemberCheck: Codable {
            let team_id: String
            let member_id: String
        }
        
        let existing: [MemberCheck] = try await client
            .from("team_members")
            .select()
            .eq("team_id", value: teamId)
            .eq("member_id", value: studentPersonId)
            .execute()
            .value
        
        if existing.isEmpty {
            let member: [String: String] = [
                "team_id": teamId,
                "member_id": studentPersonId
            ]
            
            _ = try await client
                .from("team_members")
                .insert(member)
                .execute()
        }
    }
    
    // MARK: - Check Profile Completion
    
    func isStudentProfileComplete(personId: String) async throws -> Bool {
        let profile = try await fetchBasicStudentProfile(personId: personId)
        return profile?.is_profile_complete ?? false
    }
    
    // MARK: - Fetch Student ID
    
    func fetchStudentId(srmMail: String) async throws -> String? {
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
        let profiles: [StudentProfile] = try await client
            .from("student_profiles")
            .select()
            .eq("reg_no", value: regNo)
            .limit(1)
            .execute()
            .value
        
        return profiles.first?.person_id
    }
    
    func fetchStudentId(teamId: String, studentName: String) async throws -> String? {
        struct MemberWithProfile: Codable {
            let member_id: String
            let people: PersonInfo?
            
            struct PersonInfo: Codable {
                let full_name: String
            }
        }
        
        let members: [MemberWithProfile] = try await client
            .from("team_members")
            .select("member_id, people!inner(full_name)")
            .eq("team_id", value: teamId)
            .execute()
            .value
        
        for member in members {
            if member.people?.full_name == studentName {
                return member.member_id
            }
        }
        
        return nil
    }
    
    func getCurrentStudentId() -> String? {
        return UserDefaults.standard.string(forKey: "current_person_id")
    }
    
    func fetchPerson(personId: String) async throws -> PersonDetailRow? {
        let persons: [PersonDetailRow] = try await client
            .from("people")
            .select()
            .eq("id", value: personId)
            .limit(1)
            .execute()
            .value
        
        return persons.first
    }
}
