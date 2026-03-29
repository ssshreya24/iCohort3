//
//  SupabaseManager+TeamTaskSync.swift
//  iCohort3
//
//  Created by admin100 on 20/02/26.
//

import Foundation
import Supabase

extension SupabaseManager {

    // MARK: - Team lookup (new_teams)

    struct NewTeamRowForLookup: Decodable {
        let id: String
        let team_number: Int
        let created_by_id: String
        let member2_id: String?
        let member3_id: String?
        let status: String?
    }

    struct TeamLookupResult {
        let id: String
        let teamNo: Int
    }

    func fetchCurrentUsersTeamFromNewTeams(personId: String) async throws -> TeamLookupResult? {
        let rows: [NewTeamRowForLookup] = try await client
            .from("new_teams")
            .select("id, team_number, created_by_id, member2_id, member3_id, status")
            .or("created_by_id.eq.\(personId),member2_id.eq.\(personId),member3_id.eq.\(personId)")
            .eq("status", value: "active")
            .limit(1)
            .execute()
            .value

        guard let team = rows.first else { return nil }
        return TeamLookupResult(id: team.id, teamNo: team.team_number)
    }

    // MARK: - Ensure team_task row exists

    struct TeamTaskUpsert: Encodable {
        let team_id: String
        let team_no: Int
        let updated_at: String?
    }

    private struct TeamNumberRow: Decodable {
        let team_number: Int
    }

    private struct TeamTaskCountersUpsert: Encodable {
        let team_id: String
        let team_no: Int
        let total_task: Int
        let ongoing_task: Int
        let assigned_task: Int
        let for_review_task: Int
        let prepared_task: Int
        let approved_task: Int
        let completed_task: Int
        let rejected_task: Int
        let updated_at: String?
    }

    func ensureTeamTaskRow(teamId: String, teamNo: Int) async throws {
        let payload = TeamTaskUpsert(team_id: teamId, team_no: teamNo, updated_at: nil)

        _ = try await client
            .from("team_task")
            .upsert(payload, onConflict: "team_id")
            .execute()
    }

    private func fetchTeamNumberFromNewTeams(teamId: String) async throws -> Int? {
        let rows: [TeamNumberRow] = try await client
            .from("new_teams")
            .select("team_number")
            .eq("id", value: teamId)
            .limit(1)
            .execute()
            .value

        return rows.first?.team_number
    }

    // MARK: - Recalculate counters WITHOUT fetch-all (uses ONLY fetchTasksForTeam(teamId,status))

    struct TeamTaskCountersUpdate: Encodable {
        let total_task: Int
        let ongoing_task: Int
        let assigned_task: Int
        let for_review_task: Int
        let prepared_task: Int
        let approved_task: Int
        let completed_task: Int
        let rejected_task: Int
        let updated_at: String?
    }

    func recalculateAndSyncTeamTaskCounters(teamId: String, teamNo: Int? = nil) async throws {
        let resolvedTeamNo: Int? = try await {
            if let teamNo { return teamNo }
            return try await fetchTeamNumberFromNewTeams(teamId: teamId)
        }()

        async let assignedRows  = fetchTasksForTeam(teamId: teamId, status: "assigned")
        async let ongoingRows   = fetchTasksForTeam(teamId: teamId, status: "ongoing")
        async let reviewRows    = fetchTasksForTeam(teamId: teamId, status: "for_review")
        async let preparedRows  = fetchTasksForTeam(teamId: teamId, status: "prepared")
        async let approvedRows  = fetchTasksForTeam(teamId: teamId, status: "approved")
        async let rejectedRows  = fetchTasksForTeam(teamId: teamId, status: "rejected")
        async let completedRows = fetchTasksForTeam(teamId: teamId, status: "completed")

        let (assigned, ongoing, review, prepared, approved, rejected, completed) = try await (
            assignedRows, ongoingRows, reviewRows, preparedRows, approvedRows, rejectedRows, completedRows
        )

        let total = assigned.count + ongoing.count + review.count + prepared.count + approved.count + rejected.count + completed.count

        let update = TeamTaskCountersUpdate(
            total_task: total,
            ongoing_task: ongoing.count,
            assigned_task: assigned.count,
            for_review_task: review.count,
            prepared_task: prepared.count,
            approved_task: approved.count,
            completed_task: completed.count,
            rejected_task: rejected.count,
            updated_at: nil
        )

        if let resolvedTeamNo {
            let upsertPayload = TeamTaskCountersUpsert(
                team_id: teamId,
                team_no: resolvedTeamNo,
                total_task: total,
                ongoing_task: ongoing.count,
                assigned_task: assigned.count,
                for_review_task: review.count,
                prepared_task: prepared.count,
                approved_task: approved.count,
                completed_task: completed.count,
                rejected_task: rejected.count,
                updated_at: nil
            )

            _ = try await client
                .from("team_task")
                .upsert(upsertPayload, onConflict: "team_id")
                .execute()
        } else {
            _ = try await client
                .from("team_task")
                .update(update)
                .eq("team_id", value: teamId)
                .execute()
        }
    }
}
