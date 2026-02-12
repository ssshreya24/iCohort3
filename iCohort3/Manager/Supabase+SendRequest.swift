//
//  Supabase+SendRequest.swift
//  iCohort3
//
//  Created by admin100 on 13/02/26.
//

import Foundation
import Supabase

extension SupabaseManager {

    // MARK: - Student list row (from student_profile_complete)

    struct StudentPickerRow: Decodable, Hashable, Sendable {
        let person_id: String
        let srm_mail: String?
        let department: String?
        let reg_no: String?
        let first_name: String?
        let last_name: String?

        var displayName: String {
            let fn = (first_name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let ln = (last_name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let full = "\(fn) \(ln)".trimmingCharacters(in: .whitespacesAndNewlines)
            return full.isEmpty ? "Student" : full
        }
    }

    /// ✅ Fetch students where is_profile_complete = true
    func fetchProfileCompleteStudents() async throws -> [StudentPickerRow] {

        print("🟦 [fetchProfileCompleteStudents] START")

        let rows: [StudentPickerRow] = try await client
            .from("student_profile_complete")
            .select("person_id, srm_mail, department, reg_no, first_name, last_name")
            .eq("is_profile_complete", value: true)
            .order("first_name", ascending: true)
            .execute()
            .value

        print("✅ [fetchProfileCompleteStudents] COUNT =", rows.count)

        if let first = rows.first {
            print("✅ [fetchProfileCompleteStudents] FIRST ROW =>",
                  "person_id:", first.person_id,
                  "| name:", first.displayName,
                  "| mail:", first.srm_mail ?? "nil",
                  "| reg:", first.reg_no ?? "nil",
                  "| dept:", first.department ?? "nil")
        } else {
            print("⚠️ [fetchProfileCompleteStudents] NO ROWS RETURNED")
        }

        return rows
    }

    // MARK: - INVITES (Leader -> Student) using team_member_invites

    struct TeamInviteInsert: Encodable {
        let team_id: String
        let team_number: Int

        let from_person_id: String
        let from_name: String

        let to_person_id: String
        let to_name: String

        let status: String // pending / accepted / rejected / cancelled
    }

    struct TeamInviteRow: Decodable, Hashable, Sendable {
        let id: String

        let team_id: String
        let team_number: Int

        let from_person_id: String
        let from_name: String

        let to_person_id: String
        let to_name: String

        let status: String
        let created_at: String?
    }

    struct InviteStatusUpdate: Encodable {
        let status: String
    }

    /// ✅ Send invite to a student (Leader -> Student)
    func sendInviteToStudent(
        teamId: UUID,
        teamNumber: Int,
        fromPersonId: String,
        fromName: String,
        toPersonId: String,
        toName: String
    ) async throws {

        print("🟦 [sendInviteToStudent] START")
        print("team:", teamId.uuidString, "teamNumber:", teamNumber)
        print("from:", fromName, fromPersonId)
        print("to:", toName, toPersonId)

        let payload = TeamInviteInsert(
            team_id: teamId.uuidString,
            team_number: teamNumber,
            from_person_id: fromPersonId,
            from_name: fromName,
            to_person_id: toPersonId,
            to_name: toName,
            status: "pending"
        )

        try await client
            .from("team_member_invites")
            .insert(payload)
            .execute()

        print("✅ [sendInviteToStudent] INSERTED")
    }

    /// ✅ Fetch SENT invites (Leader side) for a team
    func fetchSentInvites(fromPersonId: String, teamId: UUID) async throws -> [TeamInviteRow] {

        print("🟦 [fetchSentInvites] fromPersonId:", fromPersonId, "teamId:", teamId.uuidString)

        let rows: [TeamInviteRow] = try await client
            .from("team_member_invites")
            .select("id, team_id, team_number, from_person_id, from_name, to_person_id, to_name, status, created_at")
            .eq("from_person_id", value: fromPersonId)
            .eq("team_id", value: teamId.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ [fetchSentInvites] COUNT =", rows.count)
        return rows
    }

    /// ✅ Fetch RECEIVED invites (Student side)
    func fetchReceivedInvites(toPersonId: String) async throws -> [TeamInviteRow] {

        print("🟦 [fetchReceivedInvites] toPersonId:", toPersonId)

        let rows: [TeamInviteRow] = try await client
            .from("team_member_invites")
            .select("id, team_id, team_number, from_person_id, from_name, to_person_id, to_name, status, created_at")
            .eq("to_person_id", value: toPersonId)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value

        print("✅ [fetchReceivedInvites] COUNT =", rows.count)
        return rows
    }

    /// ✅ Accept invite (Receiver side)
    func acceptInvite(inviteId: String) async throws {
        print("🟦 [acceptInvite] inviteId:", inviteId)

        try await client
            .from("team_member_invites")
            .update(InviteStatusUpdate(status: "accepted"))
            .eq("id", value: inviteId)
            .execute()

        print("✅ [acceptInvite] UPDATED")
    }

    /// ✅ Reject invite (Receiver side)
    func rejectInvite(inviteId: String) async throws {
        print("🟦 [rejectInvite] inviteId:", inviteId)

        try await client
            .from("team_member_invites")
            .update(InviteStatusUpdate(status: "rejected"))
            .eq("id", value: inviteId)
            .execute()

        print("✅ [rejectInvite] UPDATED")
    }

    /// ✅ Cancel invite (Sender side)
    func cancelInvite(inviteId: String) async throws {
        print("🟦 [cancelInvite] inviteId:", inviteId)

        try await client
            .from("team_member_invites")
            .update(InviteStatusUpdate(status: "cancelled"))
            .eq("id", value: inviteId)
            .execute()

        print("✅ [cancelInvite] UPDATED")
    }

    // MARK: - Helper: Max 2 pending invites rule

    /// ✅ returns how many pending invites you have already sent for this team
    func pendingInviteCount(fromPersonId: String, teamId: UUID) async throws -> Int {
        let rows = try await fetchSentInvites(fromPersonId: fromPersonId, teamId: teamId)
        return rows.count
    }
}
