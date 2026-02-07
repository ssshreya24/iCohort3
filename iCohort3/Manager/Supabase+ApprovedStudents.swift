//
//  Supabase+ApprovedStudents.swift
//  iCohort3
//
//  Approved students and team management functionality
//

import Foundation
import Supabase

// MARK: - Approved Students Extension
extension SupabaseManager {
    
    // MARK: - Approved Student Types
    
    struct ApprovedStudent: Codable, Sendable, Identifiable {
        let id: String
        let firebase_doc_id: String?
        let full_name: String?
        let email: String?
        let reg_number: String?
        let institute_domain: String?
        let approval_status: String?
        let approved_at: String?
        let approved_by: String?
        let created_at: String?
        let updated_at: String?
        let profile_picture: String?
        let department: String?
        let personal_mail: String?
        let contact_number: String?
        
        var displayName: String {
            full_name ?? email?.components(separatedBy: "@").first ?? "Unknown"
        }
        
        var isApproved: Bool {
            approval_status?.lowercased() == "approved"
        }
    }
    
    struct StudentWithTeamStatus: Codable, Sendable {
        let approved_student: ApprovedStudent
        let has_team: Bool
        let team_id: String?
        let team_number: Int?
        let is_team_creator: Bool
        let person_id: String?
        
        var displayName: String {
            approved_student.displayName
        }
        
        var statusText: String {
            if has_team {
                if is_team_creator {
                    return "Team Admin (Team \(team_number ?? 0))"
                } else {
                    return "Team Member (Team \(team_number ?? 0))"
                }
            }
            return "Available"
        }
    }
    
    // MARK: - Fetch Approved Students
    
    /// Fetch all approved students
    func fetchApprovedStudents() async throws -> [ApprovedStudent] {
        print("🔍 Fetching all approved students...")
        
        let students: [ApprovedStudent] = try await client
            .from("approved_students")
            .select()
            .eq("approval_status", value: "approved")
            .order("full_name")
            .execute()
            .value
        
        print("✅ Found \(students.count) approved students")
        return students
    }
    
    /// Fetch approved students without teams (available for team creation/joining)
    func fetchAvailableStudents(excludingPersonId: String? = nil) async throws -> [StudentWithTeamStatus] {
        print("🔍 Fetching available students...")
        
        // Get all approved students
        let approvedStudents = try await fetchApprovedStudents()
        
        var results: [StudentWithTeamStatus] = []
        
        for student in approvedStudents {
            // Find if student has a person_id (is registered in the system)
            let personId = try await findPersonIdForApprovedStudent(email: student.email ?? "")
            
            // Skip if this is the excluding person
            if let exclude = excludingPersonId, personId == exclude {
                continue
            }
            
            // Check team status
            var hasTeam = false
            var teamId: String?
            var teamNumber: Int?
            var isCreator = false
            
            if let personId = personId {
                if let team = try await fetchActiveTeamForUser(userId: personId) {
                    hasTeam = true
                    teamId = team.id.uuidString
                    teamNumber = team.teamNumber
                    isCreator = team.createdById == personId
                }
            }
            
            let status = StudentWithTeamStatus(
                approved_student: student,
                has_team: hasTeam,
                team_id: teamId,
                team_number: teamNumber,
                is_team_creator: isCreator,
                person_id: personId
            )
            
            results.append(status)
        }
        
        print("✅ Found \(results.count) students with team status")
        return results
    }
    
    /// Fetch only students without teams
    func fetchStudentsWithoutTeams(excludingPersonId: String? = nil) async throws -> [StudentWithTeamStatus] {
        let allStudents = try await fetchAvailableStudents(excludingPersonId: excludingPersonId)
        let withoutTeams = allStudents.filter { !$0.has_team }
        
        print("✅ Found \(withoutTeams.count) students without teams")
        return withoutTeams
    }
    
    /// Find person_id for an approved student by email
    func findPersonIdForApprovedStudent(email: String) async throws -> String? {
        guard !email.isEmpty else { return nil }
        
        // Try to find in people table by matching with student_profiles
        struct ProfileWithPerson: Codable {
            let person_id: String
            let srm_mail: String?
            let personal_mail: String?
        }
        
        let profiles: [ProfileWithPerson] = try await client
            .from("student_profiles")
            .select("person_id, srm_mail, personal_mail")
            .execute()
            .value
        
        // Try to match by SRM email or personal email
        for profile in profiles {
            if profile.srm_mail?.lowercased() == email.lowercased() ||
               profile.personal_mail?.lowercased() == email.lowercased() {
                return profile.person_id
            }
        }
        
        return nil
    }
    
    // MARK: - Team Creation with Approved Students
    
    /// Create team and link to approved student
    func createTeamForApprovedStudent(
        approvedStudentEmail: String,
        personId: String,
        teamName: String? = nil
    ) async throws -> NewTeamRow {
        print("🔄 Creating team for approved student: \(approvedStudentEmail)")
        
        // Verify student is approved
        let approved = try await fetchApprovedStudents()
        guard approved.contains(where: { $0.email?.lowercased() == approvedStudentEmail.lowercased() }) else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Student is not in approved list"])
        }
        
        // Check if student already has a team
        if let existingTeam = try await fetchActiveTeamForUser(userId: personId) {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Student already has a team"])
        }
        
        // Create the team
        let team = try await createTeamIfNone(
            personIdString: personId,
            fallbackUserName: teamName ?? "Team"
        )
        
        print("✅ Team created successfully for approved student")
        return team
    }
    
    // MARK: - Send Join Request (with approved student validation)
    
    func sendTeamJoinRequestValidated(
        fromPersonId: String,
        fromEmail: String,
        toPersonId: String,
        toEmail: String
    ) async throws {
        print("🔄 Sending validated team join request...")
        
        // Verify both students are approved
        let approved = try await fetchApprovedStudents()
        let approvedEmails = approved.compactMap { $0.email?.lowercased() }
        
        guard approvedEmails.contains(fromEmail.lowercased()) else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Sender is not in approved list"])
        }
        
        guard approvedEmails.contains(toEmail.lowercased()) else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Recipient is not in approved list"])
        }
        
        // Get names
        let fromName = try await fetchStudentFullName(personIdString: fromPersonId)
        let toName = try await fetchStudentFullName(personIdString: toPersonId)
        
        // Send the request
        try await sendTeamMemberRequest(
            fromId: fromPersonId,
            fromName: fromName,
            toId: toPersonId,
            toName: toName
        )
        
        print("✅ Validated team join request sent")
    }
    
    // MARK: - Admin Functions for Approved Students
    
    /// Admin: Fetch all teams with their approved student members
    func adminFetchTeamsWithApprovedStudents() async throws -> [(team: NewTeamRow, members: [StudentWithTeamStatus])] {
        print("🔍 Admin: Fetching teams with approved students...")
        
        // Get all teams
        let teams = try await fetchAllTeams()
        
        var results: [(team: NewTeamRow, members: [StudentWithTeamStatus])] = []
        
        for team in teams {
            // Get member person IDs
            let memberIds = [team.createdById, team.member2Id, team.member3Id].compactMap { $0 }
            
            var members: [StudentWithTeamStatus] = []
            
            for memberId in memberIds {
                // Get student profile
                if let profile = try? await fetchStudentProfile(personId: memberId) {
                    // Find corresponding approved student
                    let email = profile.srm_mail ?? profile.personal_mail ?? ""
                    if let approvedStudent = try? await findApprovedStudent(byEmail: email) {
                        let status = StudentWithTeamStatus(
                            approved_student: approvedStudent,
                            has_team: true,
                            team_id: team.id.uuidString,
                            team_number: team.teamNumber,
                            is_team_creator: team.createdById == memberId,
                            person_id: memberId
                        )
                        members.append(status)
                    }
                }
            }
            
            results.append((team: team, members: members))
        }
        
        print("✅ Admin: Found \(results.count) teams with members")
        return results
    }
    
    /// Find approved student by email
    func findApprovedStudent(byEmail email: String) async throws -> ApprovedStudent? {
        let students: [ApprovedStudent] = try await client
            .from("approved_students")
            .select()
            .eq("email", value: email.lowercased())
            .limit(1)
            .execute()
            .value
        
        return students.first
    }
    
    /// Admin: Assign mentor to team
    func adminAssignMentorToTeam(teamId: String, mentorPersonId: String) async throws {
        print("🔄 Admin: Assigning mentor to team...")
        
        // Verify mentor role
        guard let person = try await fetchPerson(personId: mentorPersonId) else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Mentor not found"])
        }
        
        guard person.role == "mentor" else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Person is not a mentor"])
        }
        
        // Update team with mentor
        struct TeamMentorUpdate: Encodable {
            let mentor_id: String
        }
        
        let update = TeamMentorUpdate(mentor_id: mentorPersonId)
        
        try await client
            .from("teams")
            .update(update)
            .eq("id", value: teamId)
            .execute()
        
        print("✅ Admin: Mentor assigned to team successfully")
    }
    
    /// Fetch all teams (admin function)
    private func fetchAllTeams() async throws -> [NewTeamRow] {
        struct TeamWithMembers: Codable {
            let id: String
            let team_number: Int
            let created_by_id: String
            let member_2_id: String?
            let member_3_id: String?
            let created_at: String?
        }
        
        let teams: [TeamWithMembers] = try await client
            .from("new_teams")
            .select()
            .order("team_number")
            .execute()
            .value
        
        return teams.map { t in
            NewTeamRow(
                id: UUID(uuidString: t.id) ?? UUID(),
                teamNumber: t.team_number,
                createdById: t.created_by_id,
                createdByName: "",
                member2Id: t.member_2_id,
                member2Name: "",
                member3Id: t.member_3_id,
                member3Name: "",
                mentorId: "",
                mentorName: "",
                status: "",
                createdAt: t.created_at
            )
        }
    }
}

