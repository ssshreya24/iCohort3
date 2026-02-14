//
//  Supabase+Team Invites.swift
//  iCohort3
//
//  Created by admin100 on 13/02/26.
//
//
//import Foundation
//import Supabase
//
//extension SupabaseManager {
//
//    // MARK: - Models
//
//    struct TeamInviteInsert: Encodable {
//        let team_id: String
//        let team_number: Int
//
//        let from_person_id: String
//        let from_name: String
//
//        let to_person_id: String
//        let to_name: String
//
//        let status: String // "pending"
//    }
//
//    struct TeamInviteRow: Decodable, Hashable {
//        let id: String
//
//        let team_id: String
//        let team_number: Int
//
//        let from_person_id: String
//        let from_name: String
//
//        let to_person_id: String
//        let to_name: String
//
//        let status: String
//        let created_at: String?
//    }
//
//    struct InviteStatusUpdate: Encodable {
//        let status: String
//    }
//
//    // MARK: - Send Invite (Leader -> Student)
//
//    func sendInviteToStudent(
//        teamId: UUID,
//        teamNumber: Int,
//        fromPersonId: String,
//        fromName: String,
//        toPersonId: String,
//        toName: String
//    ) async throws {
//
//        let payload = TeamInviteInsert(
//            team_id: teamId.uuidString,
//            team_number: teamNumber,
//            from_person_id: fromPersonId,
//            from_name: fromName,
//            to_person_id: toPersonId,
//            to_name: toName,
//            status: "pending"
//        )
//
//        try await client
//            .from("team_member_invites")
//            .insert(payload)
//            .execute()
//    }
//
//    // MARK: - Fetch Sent Invites (Leader side)
//
//    func fetchSentInvites(fromPersonId: String, teamId: UUID) async throws -> [TeamInviteRow] {
//        let rows: [TeamInviteRow] = try await client
//            .from("team_member_invites")
//            .select("id, team_id, team_number, from_person_id, from_name, to_person_id, to_name, status, created_at")
//            .eq("from_person_id", value: fromPersonId)
//            .eq("team_id", value: teamId.uuidString)
//            .eq("status", value: "pending")
//            .order("created_at", ascending: false)
//            .execute()
//            .value
//
//        return rows
//    }
//
//    // MARK: - Fetch Received Invites (Student side)
//
//    func fetchReceivedInvites(toPersonId: String) async throws -> [TeamInviteRow] {
//        let rows: [TeamInviteRow] = try await client
//            .from("team_member_invites")
//            .select("id, team_id, team_number, from_person_id, from_name, to_person_id, to_name, status, created_at")
//            .eq("to_person_id", value: toPersonId)
//            .eq("status", value: "pending")
//            .order("created_at", ascending: false)
//            .execute()
//            .value
//
//        return rows
//    }
//
//    // MARK: - Accept / Reject Invite (Receiver side)
//
//    func acceptInvite(inviteId: String) async throws {
//        try await client
//            .from("team_member_invites")
//            .update(InviteStatusUpdate(status: "accepted"))
//            .eq("id", value: inviteId)
//            .execute()
//    }
//
//    func rejectInvite(inviteId: String) async throws {
//        try await client
//            .from("team_member_invites")
//            .update(InviteStatusUpdate(status: "rejected"))
//            .eq("id", value: inviteId)
//            .execute()
//    }
//
//    // OPTIONAL: Cancel invite (Sender side)
//    func cancelInvite(inviteId: String) async throws {
//        try await client
//            .from("team_member_invites")
//            .update(InviteStatusUpdate(status: "cancelled"))
//            .eq("id", value: inviteId)
//            .execute()
//    }
//}
