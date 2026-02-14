import Foundation
import Supabase

// MARK: - Team Member Invites Extension

extension SupabaseManager {
    
    // MARK: - Team Invite Types
    
    struct TeamInviteRow: Codable, Sendable {
        let id: UUID
        let team_id: UUID
        let team_number: Int
        let from_person_id: String
        let from_name: String
        let to_person_id: String
        let to_name: String
        let status: String
        let created_at: String?
    }
    
    // MARK: - Send Invite
    
    func sendInviteToStudent(
        teamId: UUID,
        teamNumber: Int,
        fromPersonId: String,
        fromName: String,
        toPersonId: String,
        toName: String
    ) async throws {
        print("📨 [sendInviteToStudent] START")
        print("   from:", fromName, "(\(fromPersonId))")
        print("   to:", toName, "(\(toPersonId))")
        print("   team:", teamNumber, "id:", teamId.uuidString)
        
        struct InviteInsert: Encodable {
            let team_id: String
            let team_number: Int
            let from_person_id: String
            let from_name: String
            let to_person_id: String
            let to_name: String
            let status: String
        }
        
        let insert = InviteInsert(
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
            .insert(insert)
            .execute()
        
        print("✅ [sendInviteToStudent] SUCCESS")
    }
    
    // MARK: - Fetch Invites
    
    func fetchSentInvites(fromPersonId: String, teamId: UUID) async throws -> [TeamInviteRow] {
        print("🟦 [fetchSentInvites] fromPersonId:", fromPersonId, "teamId:", teamId.uuidString)
        
        let rows: [TeamInviteRow] = try await client
            .from("team_member_invites")
            .select()
            .eq("from_person_id", value: fromPersonId)
            .eq("team_id", value: teamId.uuidString)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ [fetchSentInvites] COUNT =", rows.count)
        return rows
    }
    
    func fetchReceivedInvites(toPersonId: String) async throws -> [TeamInviteRow] {
        print("🟦 [fetchReceivedInvites] toPersonId:", toPersonId)
        
        let rows: [TeamInviteRow] = try await client
            .from("team_member_invites")
            .select()
            .eq("to_person_id", value: toPersonId)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ [fetchReceivedInvites] COUNT =", rows.count)
        return rows
    }
    
    // MARK: - Accept Invite (WITH TEAM SWITCHING)
    
    func acceptInvite(inviteId: UUID, receiverId: String) async throws {
        print("🟢 [acceptInvite] START")
        print("   inviteId:", inviteId.uuidString)
        print("   receiverId:", receiverId)
        
        // 1. Get the invite details
        guard let invite = try await fetchInviteById(inviteId) else {
            throw NSError(domain: "TeamInvite", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Invite not found"])
        }
        
        print("   inviter:", invite.from_name, "(\(invite.from_person_id))")
        print("   target team:", invite.team_number)
        
        // 2. Verify receiver is the invitee
        guard invite.to_person_id == receiverId else {
            throw NSError(domain: "TeamInvite", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Only the invitee can accept this invite"])
        }
        
        // 3. Get inviter's team (the team receiver wants to join)
        guard let inviterTeam = try await fetchTeamById(invite.team_id) else {
            throw NSError(domain: "TeamInvite", code: -3,
                         userInfo: [NSLocalizedDescriptionKey: "Team not found"])
        }
        
        print("   inviter team #\(inviterTeam.teamNumber)")
        
        // 4. Check if team has space
        let memberCount = [inviterTeam.createdById, inviterTeam.member2Id, inviterTeam.member3Id]
            .compactMap { $0 }
            .count
        
        if memberCount >= 3 {
            throw NSError(domain: "TeamInvite", code: -4,
                         userInfo: [NSLocalizedDescriptionKey: "Team is full (maximum 3 members)"])
        }
        
        // 5. ✅ CRITICAL: Check if receiver has an existing team
        let receiverHasTeam = try await fetchActiveTeamForUser(userId: receiverId)
        
        if let receiverOldTeam = receiverHasTeam {
            print("⚠️  Receiver has existing team #\(receiverOldTeam.teamNumber)")
            
            // ✅ Remove receiver from their old team
            if receiverOldTeam.createdById == receiverId {
                // If they're the creator, check if team will be empty
                let hasOtherMembers = receiverOldTeam.member2Id != nil || receiverOldTeam.member3Id != nil
                
                if hasOtherMembers {
                    // Promote member2 to creator before leaving
                    try await promoteCreatorAndLeave(
                        team: receiverOldTeam,
                        leavingCreatorId: receiverId
                    )
                }
                // If no other members, we'll delete the team after moving
            } else {
                // Regular member leaving
                try await leaveTeam(team: receiverOldTeam, userId: receiverId)
                print("✅ Removed receiver from team #\(receiverOldTeam.teamNumber)")
            }
        }
        
        // 6. Add receiver to inviter's team
        try await addMemberToTeam(
            team: inviterTeam,
            memberId: receiverId,
            memberName: invite.to_name
        )
        
        print("✅ Added receiver to team #\(inviterTeam.teamNumber)")
        
        // 7. If receiver was a solo creator, delete their old team now
        if let oldTeam = receiverHasTeam,
           oldTeam.createdById == receiverId,
           oldTeam.member2Id == nil,
           oldTeam.member3Id == nil {
            do {
                try await deleteTeam(teamId: oldTeam.id, creatorId: receiverId)
                print("✅ Deleted empty team #\(oldTeam.teamNumber)")
            } catch {
                print("⚠️  Could not delete old team:", error.localizedDescription)
            }
        }
        
        // 8. Update invite status to accepted
        try await updateInviteStatus(inviteId: inviteId, status: "accepted")
        
        print("✅ [acceptInvite] COMPLETE")
    }
    
    // MARK: - Reject Invite
    
    func rejectInvite(inviteId: UUID) async throws {
        print("❌ [rejectInvite] inviteId:", inviteId.uuidString)
        
        try await updateInviteStatus(inviteId: inviteId, status: "rejected")
        
        print("✅ Invite rejected")
    }
    
    // MARK: - Helper Functions
    
    private func fetchInviteById(_ inviteId: UUID) async throws -> TeamInviteRow? {
        let rows: [TeamInviteRow] = try await client
            .from("team_member_invites")
            .select()
            .eq("id", value: inviteId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return rows.first
    }
    
    private func updateInviteStatus(inviteId: UUID, status: String) async throws {
        struct StatusUpdate: Encodable {
            let status: String
        }
        
        try await client
            .from("team_member_invites")
            .update(StatusUpdate(status: status))
            .eq("id", value: inviteId.uuidString)
            .execute()
    }
    
    private func fetchTeamById(_ teamId: UUID) async throws -> NewTeamRow? {
        let teams: [NewTeamRow] = try await client
            .from("new_teams")
            .select("id,team_number,created_by_id,created_by_name,member2_id,member2_name,member3_id,member3_name,mentor_id,mentor_name,status,created_at")
            .eq("id", value: teamId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return teams.first
    }
    
    /// ✅ Promote member2 to creator when creator leaves
    private func promoteCreatorAndLeave(team: NewTeamRow, leavingCreatorId: String) async throws {
        print("🔄 [promoteCreatorAndLeave] Promoting member2 to creator")
        
        guard let newCreatorId = team.member2Id,
              let newCreatorName = team.member2Name else {
            throw NSError(domain: "TeamManagement", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "No member2 to promote"])
        }
        
        struct PromotionUpdate: Encodable {
            let created_by_id: String
            let created_by_name: String
            let member2_id: String?
            let member2_name: String?
            let member3_id: String?
            let member3_name: String?
        }
        
        let update = PromotionUpdate(
            created_by_id: newCreatorId,
            created_by_name: newCreatorName,
            member2_id: team.member3Id,
            member2_name: team.member3Name,
            member3_id: nil,
            member3_name: nil
        )
        
        try await client
            .from("new_teams")
            .update(update)
            .eq("id", value: team.id.uuidString)
            .execute()
        
        print("✅ Promoted \(newCreatorName) to creator")
    }
}
