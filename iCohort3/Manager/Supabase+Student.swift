//
//  Supabase+Student.swift
//  iCohort3
//
//  UNIFIED VERSION - All student-related types and functions
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
        
        if profile != nil {
            print("✅ Found complete student profile")
        } else {
            print("⚠️ No complete student profile found")
        }
        
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
        
        if profile != nil {
            print("✅ Found basic student profile")
        } else {
            print("⚠️ No basic student profile found")
        }
        
        return profile
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
                         userInfo: [NSLocalizedDescriptionKey: "Failed to upsert student profile"])
        }
        
        print("✅ Student profile upserted with id:", profileId)
        return profileId
    }
    
    // MARK: - Get Student Greeting
    
    func getStudentGreeting(personId: String) async throws -> String {
        print("🔍 Fetching student greeting for person_id:", personId)
        
        do {
            let params: [String: String] = ["p_person_id": personId]
            
            let result: String = try await client
                .rpc("get_student_greeting", params: params)
                .execute()
                .value
            
            print("✅ Student greeting retrieved:", result)
            return result
            
        } catch {
            print("❌ Error fetching student greeting from RPC:", error)
            print("   Error details: \(error.localizedDescription)")
            
            // Fallback 1: Try to get first name from student profile
            do {
                if let profile = try await fetchBasicStudentProfile(personId: personId),
                   let firstName = profile.first_name,
                   !firstName.isEmpty {
                    print("✅ Using first name from profile:", firstName)
                    return "Hi \(firstName)"
                }
            } catch {
                print("⚠️ Could not fetch student profile for fallback:", error)
            }
            
            // Fallback 2: Try to get first name from people table
            do {
                if let person = try await fetchPerson(personId: personId) {
                    let firstName = person.full_name.components(separatedBy: " ").first ?? "Student"
                    print("✅ Using first name from people table:", firstName)
                    return "Hi \(firstName)"
                }
            } catch {
                print("⚠️ Could not fetch person for fallback:", error)
            }
            
            // Final fallback
            print("✅ Using default greeting")
            return "Hi Student"
        }
    }
    
    // MARK: - Assign Student to Team
    
    func assignStudentToTeam9(studentPersonId: String) async throws {
        print("🔄 Assigning student to Team 9...")
        
        struct TeamRow: Codable {
            let id: String
            let team_no: Int
        }
        
        // 1. Get Team 9's ID
        let teams: [TeamRow] = try await client
            .from("teams")
            .select("id, team_no")
            .eq("team_no", value: 9)
            .limit(1)
            .execute()
            .value
        
        guard let team = teams.first else {
            print("⚠️ Team 9 not found in database - skipping team assignment")
            print("⚠️ Please create Team 9 in Supabase or update assignment logic")
            return
        }
        
        let teamId = team.id
        print("✅ Found Team 9 with ID:", teamId)
        
        // 2. Check if student is already assigned
        struct MemberCheck: Codable {
            let team_id: String
            let member_id: String
        }
        
        let existing: [MemberCheck] = try await client
            .from("team_members")
            .select("team_id, member_id")
            .eq("team_id", value: teamId)
            .eq("member_id", value: studentPersonId)
            .execute()
            .value
        
        if !existing.isEmpty {
            print("✅ Student already assigned to Team 9")
            return
        }
        
        // 3. Insert team member assignment
        let member: [String: String] = [
            "team_id": teamId,
            "member_id": studentPersonId
        ]
        
        struct TeamMemberResponse: Codable {
            let team_id: String
            let member_id: String
        }
        
        let _: [TeamMemberResponse] = try await client
            .from("team_members")
            .insert(member)
            .select("team_id, member_id")
            .execute()
            .value
        
        print("✅ Student successfully assigned to Team 9")
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
        
        let personId = profiles.first?.person_id
        
        if let personId = personId {
            print("✅ Found student person_id:", personId)
        } else {
            print("⚠️ No student found for SRM email:", srmMail)
        }
        
        return personId
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
    
    func fetchStudentId(teamId: String, studentName: String) async throws -> String? {
        print("🔍 Fetching student ID for team:", teamId, "name:", studentName)
        
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
                print("✅ Found student ID:", member.member_id)
                return member.member_id
            }
        }
        
        print("⚠️ Student not found in team")
        return nil
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
        } else {
            print("⚠️ Person not found")
            return nil
        }
    }
}
