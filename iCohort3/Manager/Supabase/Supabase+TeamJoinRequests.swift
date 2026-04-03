import Foundation
import Supabase

// MARK: - Team Join Requests Extension
// Add this as a separate file: Supabase+TeamJoinRequests.swift

extension SupabaseManager {
    
    // MARK: - Team Join Request Types
    
    struct TeamJoinRequestRow: Codable, Sendable {
        let id: UUID
        let from_person_id: String
        let from_name: String
        let from_reg_no: String?
        let from_department: String?
        let from_srm_mail: String?
        let to_team_id: UUID
        let to_team_number: String?
        let to_created_by_id: String?
        let status: String
        let created_at: String?
    }
    
    // MARK: - Send Team Join Request
    
    func sendTeamJoinRequest(
        fromPersonId: String,
        fromName: String,
        fromRegNo: String?,
        fromDepartment: String?,
        fromSrmMail: String?,
        toTeamId: UUID,
        toTeamNumber: Int,
        toCreatedById: String
    ) async throws {
        print("📨 [sendTeamJoinRequest] START")
        print("   from:", fromName, "(\(fromPersonId))")
        print("   to team:", toTeamNumber, "id:", toTeamId.uuidString)
        
        struct JoinRequestInsert: Encodable {
            let from_person_id: String
            let from_name: String
            let from_reg_no: String?
            let from_department: String?
            let from_srm_mail: String?
            let to_team_id: String
            let to_team_number: String
            let to_created_by_id: String
            let status: String
        }
        
        let insert = JoinRequestInsert(
            from_person_id: fromPersonId,
            from_name: fromName,
            from_reg_no: fromRegNo,
            from_department: fromDepartment,
            from_srm_mail: fromSrmMail,
            to_team_id: toTeamId.uuidString,
            to_team_number: String(toTeamNumber),
            to_created_by_id: toCreatedById,
            status: "pending"
        )
        
        try await client
            .from("team_join_requests")
            .insert(insert)
            .execute()
        
        print("✅ [sendTeamJoinRequest] SUCCESS")
    }
    
    // MARK: - Fetch Join Requests
    
    func fetchSentJoinRequests(fromPersonId: String) async throws -> [TeamJoinRequestRow] {
        print("🟦 [fetchSentJoinRequests] fromPersonId:", fromPersonId)
        
        let rows: [TeamJoinRequestRow] = try await client
            .from("team_join_requests")
            .select()
            .eq("from_person_id", value: fromPersonId)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ [fetchSentJoinRequests] COUNT =", rows.count)
        return rows
    }
    
    func fetchReceivedJoinRequests(toPersonId: String) async throws -> [TeamJoinRequestRow] {
        print("🟦 [fetchReceivedJoinRequests] toPersonId:", toPersonId)
        
        let rows: [TeamJoinRequestRow] = try await client
            .from("team_join_requests")
            .select()
            .eq("to_created_by_id", value: toPersonId)
            .eq("status", value: "pending")
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("✅ [fetchReceivedJoinRequests] COUNT =", rows.count)
        return rows
    }
    
    // MARK: - Accept Team Join Request (WITH TEAM SWITCHING)
    
    func acceptTeamJoinRequest(requestId: UUID, receiverId: String) async throws {
        print("🟢 [acceptTeamJoinRequest] START")
        print("   requestId:", requestId.uuidString)
        print("   receiverId:", receiverId)
        
        // 1. Get the request details
        guard let request = try await fetchJoinRequestById(requestId) else {
            throw NSError(domain: "TeamJoinRequest", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Request not found"])
        }
        
        print("   requester:", request.from_name, "(\(request.from_person_id))")
        print("   target team:", request.to_team_number ?? "?")
        
        // 2. Verify receiver is the team creator
        guard request.to_created_by_id == receiverId else {
            throw NSError(domain: "TeamJoinRequest", code: -2,
                         userInfo: [NSLocalizedDescriptionKey: "Only team creator can accept requests"])
        }
        
        // 3. Get receiver's team (the team requestor wants to join)
        guard let receiverTeam = try await fetchActiveTeamForUser(userId: receiverId) else {
            throw NSError(domain: "TeamJoinRequest", code: -3,
                         userInfo: [NSLocalizedDescriptionKey: "Receiver has no active team"])
        }
        
        print("   receiver team #\(receiverTeam.teamNumber)")
        
        // 4. Check if team has space
        let memberCount = [receiverTeam.createdById, receiverTeam.member2Id, receiverTeam.member3Id]
            .compactMap { $0 }
            .count
        
        if memberCount >= 3 {
            throw NSError(domain: "TeamJoinRequest", code: -4,
                         userInfo: [NSLocalizedDescriptionKey: "Team is full (maximum 3 members)"])
        }
        
        // 5. ✅ CRITICAL: Check if requester has an existing team
        let requesterHasTeam = try await fetchActiveTeamForUser(userId: request.from_person_id)
        
        if let requesterOldTeam = requesterHasTeam {
            print("⚠️  Requester has existing team #\(requesterOldTeam.teamNumber)")
            
            // ✅ Remove requester from their old team
            if requesterOldTeam.createdById == request.from_person_id {
                // If they're the creator, check if team will be empty
                let hasOtherMembers = requesterOldTeam.member2Id != nil || requesterOldTeam.member3Id != nil
                
                if hasOtherMembers {
                    // Promote member2 to creator before leaving
                    try await promoteCreatorAndLeave(
                        team: requesterOldTeam,
                        leavingCreatorId: request.from_person_id
                    )
                }
                // If no other members, we'll delete the team after moving
            } else {
                // Regular member leaving
                try await leaveTeam(team: requesterOldTeam, userId: request.from_person_id)
                print("✅ Removed \(request.from_name) from team #\(requesterOldTeam.teamNumber)")
            }
        }
        
        // 6. Add requester to receiver's team
        try await addMemberToTeam(
            team: receiverTeam,
            memberId: request.from_person_id,
            memberName: request.from_name
        )
        
        print("✅ Added \(request.from_name) to team #\(receiverTeam.teamNumber)")
        
        // 7. If requester was a solo creator, delete their old team now
        if let oldTeam = requesterHasTeam,
           oldTeam.createdById == request.from_person_id,
           oldTeam.member2Id == nil,
           oldTeam.member3Id == nil {
            do {
                try await deleteTeam(teamId: oldTeam.id, creatorId: request.from_person_id)
                print("✅ Deleted empty team #\(oldTeam.teamNumber)")
            } catch {
                print("⚠️  Could not delete old team:", error.localizedDescription)
            }
        }
        
        // 8. Update request status to accepted
        try await updateJoinRequestStatus(requestId: requestId, status: "accepted")
        
        print("✅ [acceptTeamJoinRequest] COMPLETE")
    }
    
    // MARK: - Reject Team Join Request
    
    func rejectTeamJoinRequest(requestId: UUID) async throws {
        print("❌ [rejectTeamJoinRequest] requestId:", requestId.uuidString)
        
        try await updateJoinRequestStatus(requestId: requestId, status: "rejected")
        
        print("✅ Request rejected")
    }
    
    // MARK: - Helper Functions
    
    private func fetchJoinRequestById(_ requestId: UUID) async throws -> TeamJoinRequestRow? {
        let rows: [TeamJoinRequestRow] = try await client
            .from("team_join_requests")
            .select()
            .eq("id", value: requestId.uuidString)
            .limit(1)
            .execute()
            .value
        
        return rows.first
    }
    
    private func updateJoinRequestStatus(requestId: UUID, status: String) async throws {
        struct StatusUpdate: Encodable {
            let status: String
        }
        
        try await client
            .from("team_join_requests")
            .update(StatusUpdate(status: status))
            .eq("id", value: requestId.uuidString)
            .execute()
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
    
    // MARK: - Additional Helper Functions
    
    /// Fetch all active teams (for join requests UI)
    func fetchAllActiveTeams() async throws -> [NewTeamRow] {
        print("🔍 [fetchAllActiveTeams] START")
        
        let teams: [NewTeamRow] = try await client
            .from("new_teams")
            .select("id,team_number,created_by_id,created_by_name,member2_id,member2_name,member3_id,member3_name,mentor_id,mentor_name,status,created_at")
            .eq("status", value: "active")
            .order("team_number", ascending: true)
            .execute()
            .value
        
        print("✅ [fetchAllActiveTeams] Found \(teams.count) active teams")
        return teams
    }
    

        
        /// Fetch student info for displaying member details
        func fetchStudentPickerInfo(personId: String) async throws -> StudentPickerRow {
            print("🔍 [fetchStudentPickerInfo] personId:", personId)
            
            let rows: [StudentPickerRow] = try await client
                .from("student_profile_complete")
                .select("person_id,full_name,first_name,last_name,department,reg_no,srm_mail")
                .eq("person_id", value: personId)
                .limit(1)
                .execute()
                .value
            
            guard let row = rows.first else {
                throw NSError(
                    domain: "SupabaseManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Student not found: \(personId)"]
                )
            }
            
            print("✅ [fetchStudentPickerInfo] Found:", row.displayName)
            return row
        }
}
