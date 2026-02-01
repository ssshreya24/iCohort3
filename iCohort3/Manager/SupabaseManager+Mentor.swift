//
//  SupabaseManager+Mentor.swift
//  iCohort3
//
//  Mentor-specific functionality for Supabase
//

import Foundation
import Supabase

extension SupabaseManager {
    
    // MARK: - Mentor Profile Models
    
    struct MentorProfile: Codable, Sendable {
        let id: String?
        let person_id: String
        let first_name: String?
        let last_name: String?
        let department: String?
        let email: String?
        let employee_id: String?
        let designation: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool?
        let created_at: String?
        let updated_at: String?
    }
    
    struct MentorProfileComplete: Codable, Sendable {
        let id: String
        let person_id: String
        let full_name: String?
        let first_name: String?
        let last_name: String?
        let department: String?
        let email: String?
        let employee_id: String?
        let designation: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool
        let assigned_teams_count: Int?
        let created_at: String?
        let updated_at: String?
    }
    
    struct MentorProfileUpdate: Encodable, Sendable {
        let first_name: String?
        let last_name: String?
        let department: String?
        let email: String?
        let employee_id: String?
        let designation: String?
        let personal_mail: String?
        let contact_number: String?
    }
    
    struct MentorProfileUpsert: Encodable, Sendable {
        let person_id: String
        let first_name: String?
        let last_name: String?
        let department: String?
        let email: String?
        let employee_id: String?
        let designation: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool
    }
    
    // MARK: - Fetch Mentor Profile
    
    func fetchMentorProfile(personId: String) async throws -> MentorProfileComplete? {
        let response: [MentorProfileComplete] = try await client
            .from("mentor_profile_complete")
            .select()
            .eq("person_id", value: personId)
            .execute()
            .value
        
        return response.first
    }
    
    func fetchBasicMentorProfile(personId: String) async throws -> MentorProfile? {
        let response: [MentorProfile] = try await client
            .from("mentor_profiles")
            .select()
            .eq("person_id", value: personId)
            .execute()
            .value
        
        return response.first
    }
    
    // MARK: - Create/Update Mentor Profile
    
    func upsertMentorProfile(
        personId: String,
        firstName: String? = nil,
        lastName: String? = nil,
        department: String? = nil,
        email: String? = nil,
        employeeId: String? = nil,
        designation: String? = nil,
        personalMail: String? = nil,
        contactNumber: String? = nil
    ) async throws -> String {
        let isComplete = firstName != nil && !firstName!.isEmpty &&
                        lastName != nil && !lastName!.isEmpty &&
                        department != nil && !department!.isEmpty &&
                        email != nil && !email!.isEmpty &&
                        employeeId != nil && !employeeId!.isEmpty &&
                        designation != nil && !designation!.isEmpty
        
        let payload = MentorProfileUpsert(
            person_id: personId,
            first_name: firstName,
            last_name: lastName,
            department: department,
            email: email,
            employee_id: employeeId,
            designation: designation,
            personal_mail: personalMail,
            contact_number: contactNumber,
            is_profile_complete: isComplete
        )
        
        struct UpsertResponse: Codable {
            let id: String
        }
        
        let response: [UpsertResponse] = try await client
            .from("mentor_profiles")
            .upsert(payload, onConflict: "person_id")
            .select("id")
            .execute()
            .value
        
        guard let profileId = response.first?.id else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to upsert mentor profile"])
        }
        
        return profileId
    }
    
    // MARK: - Get Mentor Greeting
    
    func getMentorGreeting(personId: String) async throws -> String {
        let params: [String: String] = ["p_person_id": personId]
        
        let result: String = try await client
            .rpc("get_mentor_greeting", params: params)
            .execute()
            .value
        
        return result
    }
    
    // MARK: - Check Profile Completion
    
    func isMentorProfileComplete(personId: String) async throws -> Bool {
        let profile = try await fetchBasicMentorProfile(personId: personId)
        return profile?.is_profile_complete ?? false
    }
    
    // MARK: - Fetch Mentor ID
    
    func fetchMentorId(email: String) async throws -> String? {
        let profiles: [MentorProfile] = try await client
            .from("mentor_profiles")
            .select()
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        return profiles.first?.person_id
    }
    
    func fetchMentorId(employeeId: String) async throws -> String? {
        let profiles: [MentorProfile] = try await client
            .from("mentor_profiles")
            .select()
            .eq("employee_id", value: employeeId)
            .limit(1)
            .execute()
            .value
        
        return profiles.first?.person_id
    }
    
    func getCurrentMentorId() -> String? {
        return UserDefaults.standard.string(forKey: "current_person_id")
    }
    
    // MARK: - Fetch Assigned Teams Count
    
    func fetchMentorAssignedTeamsCount(personId: String) async throws -> Int {
        struct TeamRow: Codable {
            let id: String
        }
        
        let teams: [TeamRow] = try await client
            .from("teams")
            .select("id")
            .eq("mentor_id", value: personId)
            .execute()
            .value
        
        return teams.count
    }
}
