//
//  Supabase+ApprovedStudents.swift
//  iCohort3
//
//  ✅ FIXED: fetchActiveTeamForUser  → fetchAdminTeamRowForUser  (admin context)
//  ✅ FIXED: adminFetchTeamsWithApprovedStudents uses TeamWithDetails + AdminTeamRow
//  ✅ FIXED: adminAssignMentorToTeam delegates to assignMentorToTeam (new_teams)
//  ✅ REMOVED: private fetchAllTeams() — superseded by fetchAllTeamsWithDetails()
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

        var displayName: String { approved_student.displayName }

        var statusText: String {
            if has_team {
                return is_team_creator
                    ? "Team Admin (Team \(team_number ?? 0))"
                    : "Team Member (Team \(team_number ?? 0))"
            }
            return "Available"
        }
    }

    // MARK: - Fetch Approved Students

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

    /// Fetch all approved students with their team status.
    func fetchAvailableStudents(excludingPersonId: String? = nil) async throws -> [StudentWithTeamStatus] {
        print("🔍 Fetching available students...")
        let approvedStudents = try await fetchApprovedStudents()
        var results: [StudentWithTeamStatus] = []

        for student in approvedStudents {
            let personId = try await findPersonIdForApprovedStudent(email: student.email ?? "")

            if let exclude = excludingPersonId, personId == exclude { continue }

            var hasTeam    = false
            var teamId:     String?
            var teamNumber: Int?
            var isCreator  = false

            if let personId = personId {
                // ✅ fetchAdminTeamRowForUser → AdminTeamRow? (SupabaseManager+Admin.swift)
                //    NOT fetchActiveTeamForUser → that returns NewTeamRow? and is
                //    reserved for student-facing code (TeamViewController, etc.)
                if let team = try await fetchAdminTeamRowForUser(userId: personId) {
                    hasTeam    = true
                    teamId     = team.id                    // String (UUID string)
                    teamNumber = team.team_number           // Int
                    isCreator  = team.created_by_id == personId
                }
            }

            results.append(StudentWithTeamStatus(
                approved_student: student,
                has_team:         hasTeam,
                team_id:          teamId,
                team_number:      teamNumber,
                is_team_creator:  isCreator,
                person_id:        personId
            ))
        }

        print("✅ Found \(results.count) students with team status")
        return results
    }

    func fetchStudentsWithoutTeams(excludingPersonId: String? = nil) async throws -> [StudentWithTeamStatus] {
        let all     = try await fetchAvailableStudents(excludingPersonId: excludingPersonId)
        let without = all.filter { !$0.has_team }
        print("✅ Found \(without.count) students without teams")
        return without
    }

    /// Resolve person_id for an approved student by matching email against student_profiles.
    func findPersonIdForApprovedStudent(email: String) async throws -> String? {
        guard !email.isEmpty else { return nil }

        struct ProfileWithPerson: Codable {
            let person_id: String
            let srm_mail:  String?
            let personal_mail: String?
        }

        let profiles: [ProfileWithPerson] = try await client
            .from("student_profiles")
            .select("person_id, srm_mail, personal_mail")
            .execute()
            .value

        for profile in profiles {
            if profile.srm_mail?.lowercased()     == email.lowercased() ||
               profile.personal_mail?.lowercased() == email.lowercased() {
                return profile.person_id
            }
        }
        return nil
    }

    // MARK: - Team Creation with Approved Students

    func createTeamForApprovedStudent(
        approvedStudentEmail: String,
        personId: String,
        teamName: String? = nil
    ) async throws -> NewTeamRow {
        print("🔄 Creating team for approved student:", approvedStudentEmail)

        let approved = try await fetchApprovedStudents()
        guard approved.contains(where: { $0.email?.lowercased() == approvedStudentEmail.lowercased() }) else {
            throw NSError(domain: "SupabaseManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Student is not in approved list"])
        }

        // ✅ Admin context check — use fetchAdminTeamRowForUser
        if let _ = try await fetchAdminTeamRowForUser(userId: personId) {
            throw NSError(domain: "SupabaseManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Student already has a team"])
        }

        let team = try await createTeamIfNone(
            personIdString: personId,
            fallbackUserName: teamName ?? "Team"
        )
        print("✅ Team created for approved student")
        return team
    }

    // MARK: - Send Join Request (validated)

    func sendTeamJoinRequestValidated(
        fromPersonId: String,
        fromEmail:    String,
        toPersonId:   String,
        toEmail:      String
    ) async throws {
        print("🔄 Sending validated team join request...")

        let approved       = try await fetchApprovedStudents()
        let approvedEmails = approved.compactMap { $0.email?.lowercased() }

        guard approvedEmails.contains(fromEmail.lowercased()) else {
            throw NSError(domain: "SupabaseManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Sender is not in approved list"])
        }
        guard approvedEmails.contains(toEmail.lowercased()) else {
            throw NSError(domain: "SupabaseManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Recipient is not in approved list"])
        }

        let fromName = try await fetchStudentFullName(personIdString: fromPersonId)
        let toName   = try await fetchStudentFullName(personIdString: toPersonId)

        try await sendTeamMemberRequest(
            fromId:   fromPersonId,
            fromName: fromName,
            toId:     toPersonId,
            toName:   toName
        )
        print("✅ Validated team join request sent")
    }

    // MARK: - Admin: Teams with Approved Student Members

    /// Returns all active teams paired with their approved-student member info.
    func adminFetchTeamsWithApprovedStudents() async throws -> [(team: TeamWithDetails, members: [StudentWithTeamStatus])] {
        print("🔍 Admin: Fetching teams with approved students...")

        // fetchAllTeamsWithDetails() and fetchAdminTeamRows() are both in
        // SupabaseManager+Admin.swift and query new_teams.
        let teams     = try await fetchAllTeamsWithDetails()
        let adminRows = try await fetchAdminTeamRows()

        var results: [(team: TeamWithDetails, members: [StudentWithTeamStatus])] = []

        for team in teams {
            // Match the admin row so we have raw member IDs
            guard let adminRow = adminRows.first(where: { $0.id == team.id }) else { continue }

            let memberIds = [adminRow.created_by_id,
                             adminRow.member2_id,
                             adminRow.member3_id].compactMap { $0 }

            var members: [StudentWithTeamStatus] = []

            for memberId in memberIds {
                if let profile = try? await fetchStudentProfile(personId: memberId) {
                    let email = profile.srm_mail ?? profile.personal_mail ?? ""
                    if let approvedStudent = try? await findApprovedStudent(byEmail: email) {
                        members.append(StudentWithTeamStatus(
                            approved_student: approvedStudent,
                            has_team:         true,
                            team_id:          team.id,
                            team_number:      team.teamNo,
                            is_team_creator:  adminRow.created_by_id == memberId,
                            person_id:        memberId
                        ))
                    }
                }
            }

            results.append((team: team, members: members))
        }

        print("✅ Admin: Found \(results.count) teams with members")
        return results
    }

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

    /// Admin: validate mentor role then delegate to the unified assignMentorToTeam.
    func adminAssignMentorToTeam(teamId: String, mentorPersonId: String) async throws {
        print("🔄 Admin: Assigning mentor to team...")

        guard let person = try await fetchPerson(personId: mentorPersonId) else {
            throw NSError(domain: "SupabaseManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Mentor not found"])
        }
        guard person.role == "mentor" else {
            throw NSError(domain: "SupabaseManager", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Person is not a mentor"])
        }

        // ✅ Delegates to assignMentorToTeam(teamId:mentorId:) in SupabaseManager+Admin.swift
        //    which updates both mentor_id AND mentor_name on new_teams.
        try await assignMentorToTeam(teamId: teamId, mentorId: mentorPersonId)
        print("✅ Admin: Mentor assigned to team successfully")
    }
}
