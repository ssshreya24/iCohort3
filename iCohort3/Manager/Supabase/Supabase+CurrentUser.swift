import Foundation
import Supabase

extension SupabaseManager {

    // ✅ SIMPLIFIED: Remove all auth_id references
    
    private struct PeopleRow: Decodable {
        let id: String          // people.id (person_id)

        enum CodingKeys: String, CodingKey {
            case id
        }
    }

    /// Supabase Auth user UUID string
    func currentAuthId() async throws -> String {
        let session = try await client.auth.session
        return session.user.id.uuidString
    }

    /// ✅ SIMPLIFIED: Just return cached person_id or throw error
    /// No auth_id lookup needed - your app already knows the person_id
    func currentPersonId() async throws -> String {
        
        // Check if we have a cached person_id from login
        if let cachedPersonId = UserDefaults.standard.string(forKey: "current_person_id"),
           !cachedPersonId.isEmpty {
            return cachedPersonId
        }
        
        // ✅ If no cached value, user needs to login properly
        throw NSError(
            domain: "SupabaseManager",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: "Session expired. Please login again."
            ]
        )
    }
    
    /// ✅ SIMPLIFIED: Create people record without auth_id
    /// Call this during signup and save the returned person_id
    func createPersonRecord(fullName: String, role: String) async throws -> String {
        
        struct PersonInsert: Encodable {
            let fullName: String
            let role: String
            
            enum CodingKeys: String, CodingKey {
                case fullName = "full_name"
                case role
            }
        }
        
        struct PersonResponse: Decodable {
            let id: String
        }
        
        let insert = PersonInsert(fullName: fullName, role: role)
        
        let created: [PersonResponse] = try await client
            .from("people")
            .insert(insert)
            .select("id")
            .execute()
            .value
        
        guard let personId = created.first?.id else {
            throw NSError(domain: "SupabaseManager", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create person record"])
        }
        
        // ✅ IMPORTANT: Save this person_id - it's your user identifier
        UserDefaults.standard.set(personId, forKey: "current_person_id")
        print("✅ Created people record with id:", personId)
        
        return personId
    }
    
    /// ✅ NEW: Call this after login to set the current person_id
    /// You need to get this from your login/signup flow
    func setCurrentPersonId(_ personId: String) {
        UserDefaults.standard.set(personId, forKey: "current_person_id")
        print("✅ Set current person_id:", personId)
    }

    func deleteAccount(role: String, personId: String, email: String?) async throws {
        let normalizedRole = role.lowercased()
        let normalizedEmail = email?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if normalizedRole == "student" {
            try await cleanupStudentTeamState(personId: personId)
            _ = try? await client.from("team_member_invites").delete().eq("from_person_id", value: personId).execute()
            _ = try? await client.from("team_member_invites").delete().eq("to_person_id", value: personId).execute()
            _ = try? await client.from("team_join_requests").delete().eq("from_person_id", value: personId).execute()
            _ = try? await client.from("team_join_requests").delete().eq("to_created_by_id", value: personId).execute()

            try await client
                .from("student_profiles")
                .delete()
                .eq("person_id", value: personId)
                .execute()

            if let normalizedEmail, !normalizedEmail.isEmpty {
                _ = try? await client
                    .from("student_registrations")
                    .delete()
                    .eq("email", value: normalizedEmail)
                    .execute()
            }
        } else if normalizedRole == "mentor" {
            try await client
                .from("mentor_profiles")
                .delete()
                .eq("person_id", value: personId)
                .execute()

            if let normalizedEmail, !normalizedEmail.isEmpty {
                _ = try? await client
                    .from("mentor_registrations")
                    .delete()
                    .eq("email", value: normalizedEmail)
                    .execute()
            }
        } else {
            throw NSError(
                domain: "SupabaseManager",
                code: -11,
                userInfo: [NSLocalizedDescriptionKey: "Unsupported role for deletion."]
            )
        }

        _ = try? await client
            .from("people")
            .delete()
            .eq("id", value: personId)
            .execute()

        try? await client.auth.signOut()
    }

    private func cleanupStudentTeamState(personId: String) async throws {
        guard let team = try await fetchActiveTeamForUser(userId: personId) else { return }

        let hasOtherMembers = [team.member2Id, team.member3Id].compactMap { $0 }.isEmpty == false

        if team.createdById == personId, !hasOtherMembers {
            try await deleteTeam(teamId: team.id, creatorId: personId)
        } else {
            try await leaveTeam(team: team, userId: personId)
        }
    }
}

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/*
// SCENARIO 1: NEW USER SIGNUP
// ============================

Task {
    do {
        // 1. Create Supabase Auth account
        try await SupabaseManager.shared.client.auth.signUp(
            email: "student@srmist.edu.in",
            password: "password123"
        )
        
        // 2. Create people record (returns person_id)
        let personId = try await SupabaseManager.shared.createPersonRecord(
            fullName: "Lakshy Pandey",
            role: "student"
        )
        // personId is automatically saved to UserDefaults
        
        // 3. Create student profile using this person_id
        try await SupabaseManager.shared.upsertStudentProfile(
            personId: personId,
            firstName: "Lakshy",
            lastName: "Pandey",
            department: "CSE",
            srmMail: "student@srmist.edu.in",
            regNo: "RA2011003010XXX"
        )
        
        // 4. Navigate to home
        navigateToHome()
        
    } catch {
        showAlert(title: "Signup Failed", message: error.localizedDescription)
    }
}

// SCENARIO 2: EXISTING USER LOGIN
// ================================

Task {
    do {
        // 1. Login with Supabase Auth
        try await SupabaseManager.shared.client.auth.signIn(
            email: "lp9013@srmist.edu.in",
            password: "password123"
        )
        
        // 2. Get person_id from student_profiles using email
        // (You need to fetch this from your database)
        let authUser = try await SupabaseManager.shared.client.auth.session.user
        let email = authUser.email ?? ""
        
        struct StudentRow: Decodable {
            let person_id: String
        }
        
        let students: [StudentRow] = try await SupabaseManager.shared.client
            .from("student_profiles")
            .select("person_id")
            .eq("srm_mail", value: email)
            .limit(1)
            .execute()
            .value
        
        guard let personId = students.first?.person_id else {
            throw NSError(domain: "Login", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Profile not found"])
        }
        
        // 3. ✅ Set the current person_id
        SupabaseManager.shared.setCurrentPersonId(personId)
        
        // 4. Navigate to home
        navigateToHome()
        
    } catch {
        showAlert(title: "Login Failed", message: error.localizedDescription)
    }
}

// SCENARIO 3: CHECK IF USER IS LOGGED IN (App Launch)
// ====================================================

Task {
    do {
        // Check if Supabase Auth session exists
        let session = try await SupabaseManager.shared.client.auth.session
        
        // Check if we have person_id saved
        if let personId = UserDefaults.standard.string(forKey: "current_person_id"),
           !personId.isEmpty {
            // User is logged in
            print("✅ Logged in as person_id:", personId)
            navigateToHome()
        } else {
            // Has auth session but no person_id - need to fetch it
            let email = session.user.email ?? ""
            
            struct StudentRow: Decodable { let person_id: String }
            
            let students: [StudentRow] = try await SupabaseManager.shared.client
                .from("student_profiles")
                .select("person_id")
                .eq("srm_mail", value: email)
                .limit(1)
                .execute()
                .value
            
            if let personId = students.first?.person_id {
                SupabaseManager.shared.setCurrentPersonId(personId)
                navigateToHome()
            } else {
                navigateToSignup()
            }
        }
        
    } catch {
        // No valid session - need to login
        navigateToLogin()
    }
}
*/
