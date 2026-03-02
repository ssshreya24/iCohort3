//
//  SupabaseManager+Admin.swift
//  iCohort3
//
//  ✅ FIXED: Renamed fetchActiveTeamForUser → fetchAdminTeamRowForUser
//            to avoid "Ambiguous use of 'fetchActiveTeamForUser(userId:)'" error.
//
//  Naming contract:
//    fetchActiveTeamForUser(userId:)    → NewTeamRow?   (Supabase+Teams.swift)
//    fetchAdminTeamRowForUser(userId:)  → AdminTeamRow? (this file — admin only)
//

import Foundation
import Supabase

extension SupabaseManager {

    // MARK: - TeamWithDetails (local shim)
    // If a canonical definition exists elsewhere, consider moving it to a shared file
    // and removing this local copy. This matches the usage in fetchAllTeamsWithDetails().
    struct TeamWithDetails: Sendable {
        let id: String
        let teamNo: Int
        let mentorId: String?
        let mentorName: String?
        let memberNames: [String]
        let memberCount: Int
    }

    // MARK: - AdminTeamRow
    //
    // Mirrors new_teams schema exactly.
    // Kept separate from NewTeamRow so admin code doesn't
    // depend on the student-facing model.

    struct AdminTeamRow: Decodable, Sendable {
        let id: String
        let team_number: Int
        let created_by_id: String
        let created_by_name: String
        let member2_id: String?
        let member2_name: String?
        let member3_id: String?
        let member3_name: String?
        let mentor_id: String?
        let mentor_name: String?
        let status: String
        let created_at: String?
    }

    // MARK: - fetchTeamsCount
    //
    // ✅ Queries new_teams WHERE status = 'active' via PostgREST exact count.
    //    Single definition — NOT redeclared anywhere else.

    func fetchTeamsCount() async throws -> Int {
        print("🔍 Fetching active teams count from new_teams...")
        do {
            let response = try await client
                .from("new_teams")
                .select("id", head: true, count: .exact)
                .eq("status", value: "active")
                .execute()
            let count = response.count ?? 0
            print("✅ Active teams count: \(count)")
            return count
        } catch {
            print("⚠️ fetchTeamsCount error: \(error.localizedDescription)")
            return 0
        }
    }

    // MARK: - fetchAdminTeamRows

    func fetchAdminTeamRows() async throws -> [AdminTeamRow] {
        print("🔍 Fetching all active teams from new_teams...")
        let rows: [AdminTeamRow] = try await client
            .from("new_teams")
            .select("id, team_number, created_by_id, created_by_name, member2_id, member2_name, member3_id, member3_name, mentor_id, mentor_name, status, created_at")
            .eq("status", value: "active")
            .order("team_number", ascending: true)
            .execute()
            .value
        print("✅ Fetched \(rows.count) admin team rows")
        return rows
    }

    // MARK: - fetchAllTeamsWithDetails
    //
    // ✅ Single definition — builds TeamWithDetails (declared in Supabase+Student.swift).
    //    Used by AdminTeamsViewController.

    func fetchAllTeamsWithDetails() async throws -> [TeamWithDetails] {
        print("🔍 fetchAllTeamsWithDetails from new_teams...")
        let rows = try await fetchAdminTeamRows()

        return rows.map { row in
            var memberNames: [String] = [row.created_by_name]
            if let m2 = row.member2_name, !m2.isEmpty { memberNames.append(m2) }
            if let m3 = row.member3_name, !m3.isEmpty { memberNames.append(m3) }

            return TeamWithDetails(
                id: row.id,
                teamNo: row.team_number,
                mentorId: row.mentor_id,
                mentorName: row.mentor_name,
                memberNames: memberNames,
                memberCount: memberNames.count
            )
        }
    }

    // MARK: - assignMentorToTeam / removeMentorFromTeam
    //
    // ✅ Single definitions here — new_teams stores BOTH mentor_id and mentor_name.

    func assignMentorToTeam(teamId: String, mentorId: String) async throws {
        print("🔄 Assigning mentor \(mentorId) to team \(teamId)...")

        struct MentorNameRow: Codable {
            let first_name: String?
            let last_name: String?
        }

        let profiles: [MentorNameRow] = (try? await client
            .from("mentor_profiles")
            .select("first_name, last_name")
            .eq("person_id", value: mentorId)
            .limit(1)
            .execute()
            .value) ?? []

        let mentorName: String = {
            guard let p = profiles.first else { return "Mentor" }
            let name = [p.first_name, p.last_name]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespaces)
            return name.isEmpty ? "Mentor" : name
        }()

        struct MentorAssign: Encodable {
            let mentor_id: String
            let mentor_name: String
        }

        try await client
            .from("new_teams")
            .update(MentorAssign(mentor_id: mentorId, mentor_name: mentorName))
            .eq("id", value: teamId)
            .execute()

        print("✅ Mentor '\(mentorName)' assigned to team \(teamId)")
    }

    func removeMentorFromTeam(teamId: String) async throws {
        print("🔄 Removing mentor from team \(teamId)...")

        struct MentorRemove: Encodable {
            let mentor_id: String?
            let mentor_name: String?
        }

        try await client
            .from("new_teams")
            .update(MentorRemove(mentor_id: nil, mentor_name: nil))
            .eq("id", value: teamId)
            .execute()

        print("✅ Mentor removed from team \(teamId)")
    }

    // MARK: - fetchAdminTeamRowForUser
    //
    // ✅ RENAMED from fetchActiveTeamForUser(userId:) to avoid compiler error:
    //    "Ambiguous use of 'fetchActiveTeamForUser(userId:)'"
    //
    //    The student-facing fetchActiveTeamForUser(userId:) → NewTeamRow? lives
    //    in Supabase+Teams.swift and is used by TeamViewController,
    //    JoinTeamsViewController, and leaveTeam / deleteTeam flows.
    //
    //    This admin variant returns AdminTeamRow? and should only be called
    //    from admin-specific code (e.g. Supabase+ApprovedStudents.swift).
    //    Update any call sites that previously used fetchActiveTeamForUser
    //    in admin context to use fetchAdminTeamRowForUser instead.

    func fetchAdminTeamRowForUser(userId: String) async throws -> AdminTeamRow? {
        let cols = "id, team_number, created_by_id, created_by_name, member2_id, member2_name, member3_id, member3_name, mentor_id, mentor_name, status, created_at"

        // Slot 1 — creator
        var rows: [AdminTeamRow] = try await client
            .from("new_teams")
            .select(cols)
            .eq("created_by_id", value: userId)
            .eq("status", value: "active")
            .limit(1)
            .execute()
            .value

        // Slot 2 — member2
        if rows.isEmpty {
            rows = try await client
                .from("new_teams")
                .select(cols)
                .eq("member2_id", value: userId)
                .eq("status", value: "active")
                .limit(1)
                .execute()
                .value
        }

        // Slot 3 — member3
        if rows.isEmpty {
            rows = try await client
                .from("new_teams")
                .select(cols)
                .eq("member3_id", value: userId)
                .eq("status", value: "active")
                .limit(1)
                .execute()
                .value
        }

        return rows.first
    }
}

