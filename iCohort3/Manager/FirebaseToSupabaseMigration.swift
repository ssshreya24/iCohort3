//  FirebaseToSupabaseMigration.swift
//  iCohort3
//
//  COMPLETELY FIXED - No re-fetch after migration, just return the stored ID
//

import Foundation
import FirebaseFirestore
import Supabase

class FirebaseToSupabaseMigration {
    static let shared = FirebaseToSupabaseMigration()
    
    private let firebaseDB = Firestore.firestore()
    private let supabase = SupabaseManager.shared
    
    private init() {}
    
    // MARK: - Local Type (no external dependencies)
    
    private struct PersonRow: Codable {
        let id: String
        let full_name: String
        let role: String
    }
    
    // MARK: - Student Migration
    
    func migrateApprovedStudent(email: String) async throws {
        print("🔄 Starting student migration for:", email)
        
        let approvedStudentsRef = firebaseDB.collection("approved_students")
        let document = try await approvedStudentsRef.document(email).getDocument()
        
        guard document.exists, let data = document.data() else {
            print("❌ Student document not found in Firebase")
            throw MigrationError.studentNotFound
        }
        
        let fullName = data["fullName"] as? String ?? ""
        let regNumber = data["regNumber"] as? String ?? ""
        
        guard !fullName.isEmpty else {
            print("❌ Student fullName is empty")
            throw MigrationError.studentNotFound
        }
        
        print("✅ Found Firebase student - Name:", fullName, "Reg:", regNumber)
        
        let personId = try await getOrCreatePerson(
            fullName: fullName,
            email: email,
            role: "student"
        )
        
        print("✅ Person ID:", personId)
        
        let nameParts = fullName.components(separatedBy: " ")
        let firstName = nameParts.first ?? fullName
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        let profileId = try await supabase.upsertStudentProfile(
            personId: personId,
            firstName: firstName,
            lastName: lastName,
            department: nil,
            srmMail: email,
            regNo: regNumber.isEmpty ? nil : regNumber,
            personalMail: nil,
            contactNumber: nil
        )
        
        print("✅ Student profile ID:", profileId)
        
        do {
            try await supabase.assignStudentToTeam9(studentPersonId: personId)
            print("✅ Assigned to Team 9")
        } catch {
            print("⚠️ Could not assign to Team 9:", error)
        }
        
        UserDefaults.standard.set(personId, forKey: "current_person_id")
        UserDefaults.standard.set(fullName, forKey: "current_user_name")
        
        print("✅ Student migration completed successfully")
    }
    
    // MARK: - Mentor Migration
    
    func migrateApprovedMentor(email: String) async throws {
        print("🔄 Starting mentor migration for:", email)
        
        let approvedMentorsRef = firebaseDB.collection("approved_mentors")
        let document = try await approvedMentorsRef.document(email).getDocument()
        
        guard document.exists, let data = document.data() else {
            print("❌ Mentor document not found in Firebase")
            throw MigrationError.mentorNotFound
        }
        
        let fullName = data["fullName"] as? String ?? ""
        let employeeId = data["employeeId"] as? String ?? ""
        let designation = data["designation"] as? String ?? ""
        let department = data["department"] as? String ?? ""
        
        guard !fullName.isEmpty else {
            print("❌ Mentor fullName is empty")
            throw MigrationError.mentorNotFound
        }
        
        print("✅ Found Firebase mentor - Name:", fullName)
        print("   Employee ID:", employeeId, "Designation:", designation)
        
        let personId = try await getOrCreatePerson(
            fullName: fullName,
            email: email,
            role: "mentor"
        )
        
        print("✅ Person ID:", personId)
        
        let nameParts = fullName.components(separatedBy: " ")
        let firstName = nameParts.first ?? fullName
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        try await createOrUpdateMentorProfile(
            personId: personId,
            firstName: firstName,
            lastName: lastName,
            email: email,
            employeeId: employeeId.isEmpty ? nil : employeeId,
            designation: designation.isEmpty ? nil : designation,
            department: department.isEmpty ? nil : department
        )
        
        print("✅ Mentor profile created/updated")
        
        UserDefaults.standard.set(personId, forKey: "current_person_id")
        UserDefaults.standard.set(fullName, forKey: "current_user_name")
        
        print("✅ Mentor migration completed - Person ID stored:", personId)
    }
    
    // MARK: - Helper Methods
    
    private func getOrCreatePerson(
        fullName: String,
        email: String,
        role: String
    ) async throws -> String {
        
        print("🔍 Checking if person exists...")
        
        do {
            if role == "student" {
                if let existingPersonId = try await supabase.fetchStudentId(srmMail: email) {
                    print("✅ Found existing student person:", existingPersonId)
                    return existingPersonId
                }
            } else {
                if let existingPersonId = try await supabase.fetchMentorId(email: email) {
                    print("✅ Found existing mentor person:", existingPersonId)
                    return existingPersonId
                }
            }
        } catch {
            print("⚠️ Error checking existing person:", error)
        }
        
        print("📝 Creating new person in Supabase...")
        
        struct PersonInsert: Encodable {
            let full_name: String
            let role: String
        }
        
        struct PersonResponse: Codable {
            let id: String
        }
        
        let newPerson = PersonInsert(full_name: fullName, role: role)
        
        do {
            let response: [PersonResponse] = try await supabase.client
                .from("people")
                .insert(newPerson)
                .select("id")
                .execute()
                .value
            
            guard let personId = response.first?.id else {
                print("❌ No person ID in response")
                throw MigrationError.personCreationFailed
            }
            
            print("✅ Created new person:", personId)
            return personId
            
        } catch {
            print("❌ Error creating person:", error)
            throw MigrationError.personCreationFailed
        }
    }
    
    private func createOrUpdateMentorProfile(
        personId: String,
        firstName: String,
        lastName: String,
        email: String,
        employeeId: String?,
        designation: String?,
        department: String?
    ) async throws {
        
        print("📝 Upserting mentor profile...")
        
        struct MentorProfileUpsert: Encodable {
            let person_id: String
            let first_name: String
            let last_name: String
            let email: String
            let employee_id: String?
            let designation: String?
            let department: String?
            let personal_mail: String?
            let contact_number: String?
            let is_profile_complete: Bool
        }
        
        struct ProfileResponse: Codable {
            let id: String
        }
        
        let isComplete = !firstName.isEmpty && !lastName.isEmpty
        
        let profile = MentorProfileUpsert(
            person_id: personId,
            first_name: firstName,
            last_name: lastName,
            email: email,
            employee_id: employeeId,
            designation: designation,
            department: department,
            personal_mail: nil,
            contact_number: nil,
            is_profile_complete: isComplete
        )
        
        let _: [ProfileResponse] = try await supabase.client
            .from("mentor_profiles")
            .upsert(profile, onConflict: "person_id")
            .select("id")
            .execute()
            .value
        
        print("✅ Mentor profile upserted")
    }
    
    // MARK: - Sync at Login (FIXED - no re-fetch)
    
    func syncStudentAtLogin(email: String) async throws -> String {
        print("🔄 Syncing student at login:", email)
        
        // Check if already in Supabase
        if let personId = try await supabase.fetchStudentId(srmMail: email) {
            print("✅ Student already in Supabase, person_id:", personId)
            
            // ✅ FIX: Try to get full name, but don't fail if we can't
            do {
                let persons: [PersonRow] = try await supabase.client
                    .from("people")
                    .select("id, full_name, role")
                    .eq("id", value: personId)
                    .limit(1)
                    .execute()
                    .value
                
                if let person = persons.first {
                    UserDefaults.standard.set(personId, forKey: "current_person_id")
                    UserDefaults.standard.set(person.full_name, forKey: "current_user_name")
                    print("✅ Session updated - Name:", person.full_name)
                    return person.full_name
                }
            } catch {
                print("⚠️ Could not fetch full name, using default")
                UserDefaults.standard.set(personId, forKey: "current_person_id")
                return "Student"
            }
        }
        
        // ✅ FIX: Migrate and return the name from Firebase data
        print("⚠️ Student not in Supabase, migrating from Firebase...")
        
        // Get Firebase data first
        let approvedStudentsRef = firebaseDB.collection("approved_students")
        let document = try await approvedStudentsRef.document(email).getDocument()
        
        guard document.exists, let data = document.data() else {
            throw MigrationError.studentNotFound
        }
        
        let fullName = data["fullName"] as? String ?? "Student"
        
        // Do the migration
        try await migrateApprovedStudent(email: email)
        
        // ✅ FIX: Return the name we got from Firebase, don't re-fetch
        print("✅ Migration complete - Name:", fullName)
        return fullName
    }
    
    func syncMentorAtLogin(email: String) async throws -> String {
        print("🔄 Syncing mentor at login:", email)
        
        // Check if already in Supabase
        if let personId = try await supabase.fetchMentorId(email: email) {
            print("✅ Mentor already in Supabase, person_id:", personId)
            
            // ✅ FIX: Try to get full name, but don't fail if we can't
            do {
                let persons: [PersonRow] = try await supabase.client
                    .from("people")
                    .select("id, full_name, role")
                    .eq("id", value: personId)
                    .limit(1)
                    .execute()
                    .value
                
                if let person = persons.first {
                    UserDefaults.standard.set(personId, forKey: "current_person_id")
                    UserDefaults.standard.set(person.full_name, forKey: "current_user_name")
                    print("✅ Session updated - Name:", person.full_name)
                    return person.full_name
                }
            } catch {
                print("⚠️ Could not fetch full name, using default")
                UserDefaults.standard.set(personId, forKey: "current_person_id")
                return "Mentor"
            }
        }
        
        // ✅ FIX: Migrate and return the name from Firebase data
        print("⚠️ Mentor not in Supabase, migrating from Firebase...")
        
        // Get Firebase data first
        let approvedMentorsRef = firebaseDB.collection("approved_mentors")
        let document = try await approvedMentorsRef.document(email).getDocument()
        
        guard document.exists, let data = document.data() else {
            throw MigrationError.mentorNotFound
        }
        
        let fullName = data["fullName"] as? String ?? "Mentor"
        
        // Do the migration
        try await migrateApprovedMentor(email: email)
        
        // ✅ FIX: Return the name we got from Firebase, don't re-fetch
        print("✅ Migration complete - Name:", fullName)
        return fullName
    }
}

// MARK: - Errors

enum MigrationError: Error, LocalizedError {
    case studentNotFound
    case mentorNotFound
    case personCreationFailed
    case syncFailed
    
    var errorDescription: String? {
        switch self {
        case .studentNotFound:
            return "Student data not found in Firebase"
        case .mentorNotFound:
            return "Mentor data not found in Firebase"
        case .personCreationFailed:
            return "Failed to create person in Supabase"
        case .syncFailed:
            return "Failed to sync user data"
        }
    }
}
