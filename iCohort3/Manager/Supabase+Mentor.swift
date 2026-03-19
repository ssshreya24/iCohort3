// COMPLETE FIXED VERSION - Replace entire file content

import Foundation
import Supabase

// MARK: - Mentor Profile Models
extension SupabaseManager {
    
    struct MentorProfile: Codable {
        let id: String
        let person_id: String
        let first_name: String?
        let last_name: String?
        let email: String?
        let employee_id: String?
        let designation: String?
        let department: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool?
        let created_at: String?
        let updated_at: String?
    }
    
    struct MentorProfileComplete: Codable {
        let id: String
        let person_id: String
        let full_name: String
        let first_name: String?
        let last_name: String?
        let email: String?
        let employee_id: String?
        let designation: String?
        let department: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool?
        let created_at: String?
        let updated_at: String?
    }
}

// MARK: - Mentor Profile Query Functions (FIXED)
extension SupabaseManager {
    
    /// Fetch mentor person_id by email - FIXED SELECT QUERY
    func fetchMentorId(email: String) async throws -> String? {
        print("🔍 Fetching mentor ID for email:", email)
        
        do {
            // ✅ FIXED: Select ALL fields explicitly
            let response: [MentorProfile] = try await client
                .from("mentor_profiles")
                .select("*")  // Select all fields
                .eq("email", value: email)
                .limit(1)
                .execute()
                .value
            
            let personId = response.first?.person_id
            
            if let personId = personId {
                print("✅ Found mentor person_id:", personId)
            } else {
                print("⚠️ No mentor found for email:", email)
            }
            
            return personId
            
        } catch {
            print("❌ Error fetching mentor ID:", error)
            print("   Error details: \(error.localizedDescription)")
            
            if error.localizedDescription.contains("missing") ||
               error.localizedDescription.contains("not found") {
                print("⚠️ No mentor profile exists for email:", email)
                return nil
            }
            
            throw error
        }
    }
    
    /// Fetch basic mentor profile by person_id - FIXED SELECT QUERY
    func fetchBasicMentorProfile(personId: String) async throws -> MentorProfile? {
        print("🔍 Fetching mentor profile for person_id:", personId)
        
        do {
            // ✅ FIXED: Select ALL fields explicitly
            let response: [MentorProfile] = try await client
                .from("mentor_profiles")
                .select("*")  // Select all fields
                .eq("person_id", value: personId)
                .limit(1)
                .execute()
                .value
            
            let profile = response.first
            
            if profile != nil {
                print("✅ Found mentor profile for person_id:", personId)
            } else {
                print("⚠️ No mentor profile found for person_id:", personId)
            }
            
            return profile
            
        } catch {
            print("❌ Error fetching mentor profile:", error)
            
            if error.localizedDescription.contains("missing") ||
               error.localizedDescription.contains("not found") {
                print("⚠️ No mentor profile exists for person_id:", personId)
                return nil
            }
            
            throw error
        }
    }
    
    /// Fetch complete mentor profile - FIXED SELECT QUERY
    func fetchCompleteMentorProfile(personId: String) async throws -> MentorProfileComplete? {
        print("🔍 Fetching complete mentor profile for person_id:", personId)
        
        do {
            // ✅ FIXED: Select ALL fields explicitly
            let response: [MentorProfileComplete] = try await client
                .from("mentor_profile_complete")
                .select("*")  // Select all fields
                .eq("person_id", value: personId)
                .limit(1)
                .execute()
                .value
            
            let profile = response.first
            
            if profile != nil {
                print("✅ Found complete mentor profile")
            } else {
                print("⚠️ No complete mentor profile found")
            }
            
            return profile
            
        } catch {
            print("❌ Error fetching complete mentor profile:", error)
            
            if error.localizedDescription.contains("missing") ||
               error.localizedDescription.contains("not found") {
                print("⚠️ No complete mentor profile exists for person_id:", personId)
                return nil
            }
            
            throw error
        }
    }
    
    /// Get mentor greeting - IMPROVED with better fallbacks
    func getMentorGreeting(personId: String) async throws -> String {
        print("🔍 Fetching mentor greeting for person_id:", personId)
        
        // Try RPC function first
        do {
            let greeting: String = try await client
                .rpc("get_mentor_greeting", params: ["p_person_id": personId])
                .execute()
                .value
            
            print("✅ Mentor greeting retrieved from RPC:", greeting)
            return greeting
            
        } catch {
            print("⚠️ RPC function failed, trying fallback methods:", error.localizedDescription)
        }
        
        // Fallback 1: Try complete profile
        do {
            if let profile = try await fetchCompleteMentorProfile(personId: personId) {
                let firstName = profile.full_name.components(separatedBy: " ").first ?? "Mentor"
                print("✅ Using first name from complete profile:", firstName)
                return "Hi \(firstName)"
            }
        } catch {
            print("⚠️ Could not fetch complete mentor profile:", error)
        }
        
        // Fallback 2: Try basic profile
        do {
            if let profile = try await fetchBasicMentorProfile(personId: personId),
               let firstName = profile.first_name,
               !firstName.isEmpty {
                print("✅ Using first name from basic profile:", firstName)
                return "Hi \(firstName)"
            }
        } catch {
            print("⚠️ Could not fetch basic mentor profile:", error)
        }
        
        // Fallback 3: Try people table
        do {
            if let person = try await fetchPerson(personId: personId) {
                let firstName = person.full_name.components(separatedBy: " ").first ?? "Mentor"
                print("✅ Using first name from people table:", firstName)
                return "Hi \(firstName)"
            }
        } catch {
            print("⚠️ Could not fetch person:", error)
        }
        
        // Final fallback
        print("✅ Using default greeting")
        return "Hi Mentor"
    }
}

// MARK: - Mentor Profile Mutation Functions
extension SupabaseManager {
    
    /// Upsert mentor profile - IMPROVED error handling
    func upsertMentorProfile(
        personId: String,
        firstName: String?,
        lastName: String?,
        email: String?,
        employeeId: String?,
        designation: String?,
        department: String?,
        personalMail: String?,
        contactNumber: String?
    ) async throws -> String {
        print("🔄 Upserting mentor profile for person_id:", personId)
        
        struct MentorProfileUpsert: Encodable {
            let person_id: String
            let first_name: String?
            let last_name: String?
            let email: String?
            let employee_id: String?
            let designation: String?
            let department: String?
            let personal_mail: String?
            let contact_number: String?
            let is_profile_complete: Bool
        }
        
        let isComplete = (firstName?.isEmpty == false) &&
                        (lastName?.isEmpty == false) &&
                        (email?.isEmpty == false) &&
                        (employeeId?.isEmpty == false) &&
                        (designation?.isEmpty == false) &&
                        (department?.isEmpty == false)
        
        let profile = MentorProfileUpsert(
            person_id: personId,
            first_name: firstName,
            last_name: lastName,
            email: email,
            employee_id: employeeId,
            designation: designation,
            department: department,
            personal_mail: personalMail,
            contact_number: contactNumber,
            is_profile_complete: isComplete
        )
        
        struct ProfileResponse: Codable {
            let id: String
        }
        
        do {
            let response: [ProfileResponse] = try await client
                .from("mentor_profiles")
                .upsert(profile, onConflict: "person_id")
                .select("id")
                .execute()
                .value
            
            guard let profileId = response.first?.id else {
                throw NSError(domain: "SupabaseManager", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to upsert mentor profile"
                ])
            }
            
            print("✅ Mentor profile upserted with id:", profileId)
            return profileId
            
        } catch {
            // ✅ IMPROVED: Handle duplicate key errors
            if error.localizedDescription.contains("duplicate key") &&
               error.localizedDescription.contains("email") {
                print("⚠️ Duplicate email detected, trying to update by email...")
                
                // Try update by email
                do {
                    let updateResponse: [ProfileResponse] = try await client
                        .from("mentor_profiles")
                        .update(profile)
                        .eq("email", value: email ?? "")
                        .select("id")
                        .execute()
                        .value
                    
                    guard let profileId = updateResponse.first?.id else {
                        throw NSError(domain: "SupabaseManager", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Failed to update existing mentor profile"
                        ])
                    }
                    
                    print("✅ Updated existing mentor profile with id:", profileId)
                    return profileId
                    
                } catch {
                    print("❌ Could not update existing profile:", error)
                    throw error
                }
            }
            
            throw error
        }
    }
}

// MARK: - Mentor Profile Helper Functions
extension SupabaseManager {
    
    func mentorProfileExists(personId: String) async throws -> Bool {
        let profile = try await fetchBasicMentorProfile(personId: personId)
        return profile != nil
    }
    
    func getMentorProfileCompletionStatus(personId: String) async throws -> Bool {
        let profile = try await fetchBasicMentorProfile(personId: personId)
        return profile?.is_profile_complete ?? false
    }
    
    func fetchMentorProfileByEmail(email: String) async throws -> MentorProfile? {
        print("🔍 Fetching mentor profile by email:", email)
        
        do {
            let response: [MentorProfile] = try await client
                .from("mentor_profiles")
                .select("*")
                .eq("email", value: email)
                .limit(1)
                .execute()
                .value
            
            return response.first
        } catch {
            print("❌ Error fetching mentor profile by email:", error)
            
            if error.localizedDescription.contains("missing") ||
               error.localizedDescription.contains("not found") {
                return nil
            }
            
            throw error
        }
    }
    
    func fetchMentorProfileByEmployeeId(employeeId: String) async throws -> MentorProfile? {
        print("🔍 Fetching mentor profile by employee ID:", employeeId)
        
        do {
            let response: [MentorProfile] = try await client
                .from("mentor_profiles")
                .select("*")
                .eq("employee_id", value: employeeId)
                .limit(1)
                .execute()
                .value
            
            return response.first
        } catch {
            print("❌ Error fetching mentor profile by employee ID:", error)
            
            if error.localizedDescription.contains("missing") ||
               error.localizedDescription.contains("not found") {
                return nil
            }
            
            throw error
        }
    }
}

// MARK: - Mentor Announcements Extension
extension SupabaseManager {
    
    struct MentorAnnouncement: Encodable {
        let title: String
        let description: String?
        let category: String?
        let color_hex: String?
    }
    
    struct MentorAnnouncementUpdate: Encodable {
        let title: String?
        let description: String?
        let category: String?
        let color_hex: String?
    }
    
    struct MentorAnnouncementRow: Decodable {
        let id: Int
        let title: String
        let description: String?
        let category: String?
        let color_hex: String?
        let created_at: String?
        let author: String?
    }
    
    func saveAnnouncementToSupabase(
        title: String,
        description: String?,
        category: String?,
        colorHex: String?
    ) async throws {
        let announcement = MentorAnnouncement(
            title: title,
            description: description,
            category: category,
            color_hex: colorHex
        )

        _ = try await client
            .from("mentor_announcements")
            .insert(announcement)
            .execute()
    }
    
    func fetchMentorAnnouncements() async throws -> [MentorAnnouncementRow] {
        let rows: [MentorAnnouncementRow] = try await client
            .from("mentor_announcements")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return rows
    }
    
    func updateMentorAnnouncement(
        id: Int,
        title: String?,
        description: String?,
        category: String?,
        colorHex: String?
    ) async throws {
        let update = MentorAnnouncementUpdate(
            title: title,
            description: description,
            category: category,
            color_hex: colorHex
        )
        
        _ = try await client
            .from("mentor_announcements")
            .update(update)
            .eq("id", value: id)
            .execute()
    }
    
    func deleteAnnouncement(id: Int) async throws {
        _ = try await client
            .from("mentor_announcements")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Mentor Activities Extension
extension SupabaseManager {
    
    struct MentorActivityInsert: Encodable {
        let title: String
        let note: String?
        let start_date: String
        let end_date: String
        let is_all_day: Bool
        let alert_option: String?
        let send_to: String?
        let mentor_id: String?
    }
    
    struct MentorActivityRow: Decodable {
        let id: Int
        let title: String
        let note: String?
        let start_date: String
        let end_date: String
        let is_all_day: Bool
        let alert_option: String?
        let send_to: String?
        let mentor_id: String?
        let created_at: String?
    }
    
    struct MentorActivityUpdate: Encodable {
        let title: String?
        let note: String?
        let start_date: String?
        let end_date: String?
        let is_all_day: Bool?
        let alert_option: String?
        let send_to: String?
    }
    
    func saveMentorActivity(
        title: String,
        note: String?,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        alertOption: String?,
        sendTo: String?,
        mentorId: String?
    ) async throws -> MentorActivityRow {
        let formatter = ISO8601DateFormatter()
        
        let activity = MentorActivityInsert(
            title: title,
            note: note,
            start_date: formatter.string(from: startDate),
            end_date: formatter.string(from: endDate),
            is_all_day: isAllDay,
            alert_option: alertOption,
            send_to: sendTo,
            mentor_id: mentorId
        )
        
        let response: MentorActivityRow = try await client
            .from("mentor_activities")
            .insert(activity)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func fetchAllMentorActivities() async throws -> [MentorActivityRow] {
        let rows: [MentorActivityRow] = try await client
            .from("mentor_activities")
            .select()
            .order("start_date", ascending: true)
            .execute()
            .value
        
        return rows
    }
    
    func fetchMentorActivities(from startDate: Date, to endDate: Date) async throws -> [MentorActivityRow] {
        let formatter = ISO8601DateFormatter()
        
        let rows: [MentorActivityRow] = try await client
            .from("mentor_activities")
            .select()
            .gte("start_date", value: formatter.string(from: startDate))
            .lte("start_date", value: formatter.string(from: endDate))
            .order("start_date", ascending: true)
            .execute()
            .value
        
        return rows
    }
    
    func fetchMentorActivities(forDate date: Date) async throws -> [MentorActivityRow] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await fetchMentorActivities(from: startOfDay, to: endOfDay)
    }
    
    func updateMentorActivity(
        id: Int,
        title: String?,
        note: String?,
        startDate: Date?,
        endDate: Date?,
        isAllDay: Bool?,
        alertOption: String?,
        sendTo: String?
    ) async throws {
        let formatter = ISO8601DateFormatter()
        
        let update = MentorActivityUpdate(
            title: title,
            note: note,
            start_date: startDate.map { formatter.string(from: $0) },
            end_date: endDate.map { formatter.string(from: $0) },
            is_all_day: isAllDay,
            alert_option: alertOption,
            send_to: sendTo
        )
        
        _ = try await client
            .from("mentor_activities")
            .update(update)
            .eq("id", value: id)
            .execute()
    }
    
    func deleteMentorActivity(id: Int) async throws {
        _ = try await client
            .from("mentor_activities")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Mentor Team Management Extension
extension SupabaseManager {
    
    struct TeamRow: Decodable {
        let id: String
        let teamNo: Int
        let mentorId: String?
        let mentorName: String?

        let createdByName: String
        let member2Name: String?
        let member3Name: String?
        let status: String

        enum CodingKeys: String, CodingKey {
            case id
            case teamNo = "team_number"
            case mentorId = "mentor_id"
            case mentorName = "mentor_name"
            case createdByName = "created_by_name"
            case member2Name = "member2_name"
            case member3Name = "member3_name"
            case status
        }
    }

    
    struct TeamTaskRow: Decodable, Sendable {
        let team_id: String
        let total_task: Int?
        let ongoing_task: Int?
        let assigned_task: Int?
        let for_review_task: Int?
        let completed_task: Int?
        let rejected_task: Int?
        let prepared_task: Int?
        let approved_task: Int?
    }
    
    struct TeamStudentNameRow: Decodable, Sendable {
        let team_id: String
        let full_name: String
    }
    
    func fetchTeamsForMentor(mentorId: String) async throws -> [TeamRow] {
        let rows: [TeamRow] = try await client
            .from("new_teams")
            .select("""
                id,
                team_number,
                mentor_id,
                mentor_name,
                created_by_name,
                member2_name,
                member3_name,
                status
            """)
            .eq("mentor_id", value: mentorId)
            .eq("status", value: "active")
            .order("team_number", ascending: true)
            .execute()
            .value

        return rows
    }

    
    func fetchTeamTasks(teamIds: [String]) async throws -> [TeamTaskRow] {
        guard !teamIds.isEmpty else { return [] }

        let rows: [TeamTaskRow] = try await client
            .from("team_task")
            .select("team_id, total_task, ongoing_task, assigned_task, for_review_task, prepared_task, approved_task, completed_task, rejected_task")
            .in("team_id", values: teamIds)
            .execute()
            .value

        let fetchedIds = Set(rows.map(\.team_id))
        let missingIds = teamIds.filter { !fetchedIds.contains($0) }
        guard !missingIds.isEmpty else { return rows }

        struct TaskStatusRow: Decodable {
            let team_id: String
            let status: String
        }

        let liveTaskRows: [TaskStatusRow] = try await client
            .from("tasks")
            .select("team_id, status")
            .in("team_id", values: missingIds)
            .execute()
            .value

        var grouped: [String: [TaskStatusRow]] = [:]
        for row in liveTaskRows {
            grouped[row.team_id, default: []].append(row)
        }

        let fallbackRows: [TeamTaskRow] = missingIds.map { teamId in
            let statuses = grouped[teamId] ?? []
            let assigned = statuses.filter { $0.status == "assigned" }.count
            let ongoing = statuses.filter { $0.status == "ongoing" }.count
            let review = statuses.filter { $0.status == "for_review" }.count
            let prepared = statuses.filter { $0.status == "prepared" }.count
            let approved = statuses.filter { $0.status == "approved" }.count
            let completed = statuses.filter { $0.status == "completed" }.count
            let rejected = statuses.filter { $0.status == "rejected" }.count

            return TeamTaskRow(
                team_id: teamId,
                total_task: statuses.count,
                ongoing_task: ongoing,
                assigned_task: assigned,
                for_review_task: review,
                completed_task: completed,
                rejected_task: rejected,
                prepared_task: prepared,
                approved_task: approved
            )
        }

        return rows + fallbackRows
    }
    
    func fetchStudentNamesForTeam(teamId: String) async throws -> [String] {
        let rows: [TeamStudentNameRow] = try await client
            .from("team_student_names")
            .select("team_id, full_name")
            .eq("team_id", value: teamId)
            .execute()
            .value
        
        return rows.map { $0.full_name }
    }
}


extension SupabaseManager {
    
    /// Fetch mentor's full name by person_id
    func fetchMentorFullName(personId: String) async throws -> String {
        print("🔍 Fetching mentor full name for person_id:", personId)
        
        // Try mentor_profiles first
        if let profile = try await fetchBasicMentorProfile(personId: personId) {
            // Build full name from first_name and last_name
            if let firstName = profile.first_name, let lastName = profile.last_name {
                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                if !fullName.isEmpty {
                    print("✅ Found name from mentor profile:", fullName)
                    return fullName
                }
            }
        }
        
        // Fallback to people table
        if let person = try await fetchPerson(personId: personId) {
            print("✅ Found name from people table:", person.full_name)
            return person.full_name
        }
        
        // Fallback to approved_mentors table
        do {
            struct ApprovedMentor: Codable {
                let full_name: String?
            }
            
            // Get mentor email from mentor_profiles
            if let profile = try await fetchBasicMentorProfile(personId: personId),
               let email = profile.email {
                
                let approved: [ApprovedMentor] = try await client
                    .from("approved_mentors")
                    .select("full_name")
                    .eq("email", value: email)
                    .limit(1)
                    .execute()
                    .value
                
                if let mentor = approved.first, let name = mentor.full_name {
                    print("✅ Found name from approved_mentors:", name)
                    return name
                }
            }
        } catch {
            print("⚠️ Could not fetch from approved_mentors:", error)
        }
        
        // Final fallback
        print("⚠️ Could not find mentor name, using default")
        return "Mentor"
    }
    
    /// Fetch mentor's full name by email
    func fetchMentorFullNameByEmail(email: String) async throws -> String {
        print("🔍 Fetching mentor full name for email:", email)
        
        // Try mentor_profiles first
        if let profile = try await fetchMentorProfileByEmail(email: email) {
            if let firstName = profile.first_name, let lastName = profile.last_name {
                let fullName = "\(firstName) \(lastName)".trimmingCharacters(in: .whitespaces)
                if !fullName.isEmpty {
                    print("✅ Found name from mentor profile:", fullName)
                    return fullName
                }
            }
        }
        
        // Try approved_mentors table
        do {
            struct ApprovedMentor: Codable {
                let full_name: String?
            }
            
            let approved: [ApprovedMentor] = try await client
                .from("approved_mentors")
                .select("full_name")
                .eq("email", value: email)
                .limit(1)
                .execute()
                .value
            
            if let mentor = approved.first, let name = mentor.full_name {
                print("✅ Found name from approved_mentors:", name)
                return name
            }
        } catch {
            print("⚠️ Could not fetch from approved_mentors:", error)
        }
        
        // Try mentor_registrations table
        do {
            struct MentorReg: Codable {
                let full_name: String
            }
            
            let registrations: [MentorReg] = try await client
                .from("mentor_registrations")
                .select("full_name")
                .eq("email", value: email)
                .limit(1)
                .execute()
                .value
            
            if let registration = registrations.first {
                print("✅ Found name from mentor_registrations:", registration.full_name)
                return registration.full_name
            }
        } catch {
            print("⚠️ Could not fetch from mentor_registrations:", error)
        }
        
        print("⚠️ Could not find mentor name, using default")
        return "Mentor"
    }
    
    /// Check if mentor exists in any table
    func mentorExists(email: String) async throws -> Bool {
        // Check mentor_profiles
        if let _ = try await fetchMentorProfileByEmail(email: email) {
            return true
        }
        
        // Check approved_mentors
        do {
            struct Count: Codable {
                let count: Int?
            }
            
            let result: [Count] = try await client
                .from("approved_mentors")
                .select("email", count: .exact)
                .eq("email", value: email)
                .execute()
                .value
            
            if let count = result.first?.count, count > 0 {
                return true
            }
        } catch {}
        
        // Check mentor_registrations
        do {
            struct Count: Codable {
                let count: Int?
            }
            
            let result: [Count] = try await client
                .from("mentor_registrations")
                .select("email", count: .exact)
                .eq("email", value: email)
                .execute()
                .value
            
            if let count = result.first?.count, count > 0 {
                return true
            }
        } catch {}
        
        return false
    }
    
    /// Get mentor's institute name
    func fetchMentorInstituteName(personId: String) async throws -> String? {
        // Try mentor_profiles first
        if let profile = try await fetchBasicMentorProfile(personId: personId) {
            if let email = profile.email {
                // Try approved_mentors
                do {
                    struct ApprovedMentor: Codable {
                        let institute_name: String?
                    }
                    
                    let approved: [ApprovedMentor] = try await client
                        .from("approved_mentors")
                        .select("institute_name")
                        .eq("email", value: email)
                        .limit(1)
                        .execute()
                        .value
                    
                    if let instituteName = approved.first?.institute_name {
                        return instituteName
                    }
                } catch {}
                
                // Try mentor_registrations
                do {
                    struct MentorReg: Codable {
                        let institute_name: String
                    }
                    
                    let registrations: [MentorReg] = try await client
                        .from("mentor_registrations")
                        .select("institute_name")
                        .eq("email", value: email)
                        .limit(1)
                        .execute()
                        .value
                    
                    if let instituteName = registrations.first?.institute_name {
                        return instituteName
                    }
                } catch {}
            }
        }
        
        return nil
    }
    
    /// Sync mentor data from approved_mentors to mentor_profiles
    func syncMentorFromApprovedMentors(email: String) async throws {
        print("🔄 Syncing mentor from approved_mentors to mentor_profiles...")
        
        struct ApprovedMentor: Codable {
            let email: String
            let full_name: String?
            let employee_id: String?
            let designation: String?
            let department: String?
            let institute_name: String?
        }
        
        // Fetch from approved_mentors
        let approved: [ApprovedMentor] = try await client
            .from("approved_mentors")
            .select("email, full_name, employee_id, designation, department, institute_name")
            .eq("email", value: email)
            .limit(1)
            .execute()
            .value
        
        guard let mentor = approved.first else {
            print("❌ Mentor not found in approved_mentors")
            return
        }
        
        // Get or create person_id
        let personId: String
        if let existingPersonId = try await fetchMentorId(email: email) {
            personId = existingPersonId
            print("✅ Found existing person_id:", personId)
        } else {
            // Create person record
            struct PersonInsert: Encodable {
                let full_name: String
                let role: String
            }
            
            struct PersonResponse: Codable {
                let id: String
            }
            
            let insert = PersonInsert(
                full_name: mentor.full_name ?? "Unknown Mentor",
                role: "mentor"
            )
            
            let response: [PersonResponse] = try await client
                .from("people")
                .insert(insert)
                .select("id")
                .execute()
                .value
            
            guard let newPersonId = response.first?.id else {
                throw NSError(domain: "SupabaseManager", code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Failed to create person record"])
            }
            
            personId = newPersonId
            print("✅ Created new person_id:", personId)
        }
        
        // Parse name
        let nameParts = (mentor.full_name ?? "").components(separatedBy: " ")
        let firstName = nameParts.first ?? ""
        let lastName = nameParts.count > 1 ? nameParts.dropFirst().joined(separator: " ") : ""
        
        // Upsert mentor profile
        _ = try await upsertMentorProfile(
            personId: personId,
            firstName: firstName,
            lastName: lastName,
            email: mentor.email,
            employeeId: mentor.employee_id,
            designation: mentor.designation,
            department: mentor.department,
            personalMail: nil,
            contactNumber: nil
        )
        
        print("✅ Mentor profile synced successfully")
    }
}
