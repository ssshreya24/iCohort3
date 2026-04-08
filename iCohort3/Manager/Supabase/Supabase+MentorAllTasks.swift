//
//  Supabse+MentorAllTasks.swift
//  iCohort3
//
//  Created by admin100 on 20/02/26.
//
import Supabase
import Foundation

extension SupabaseManager {

    struct NewTeamMembersRow: Decodable {
        let id: String
        let createdById: String
        let createdByName: String
        let member2Id: String?
        let member2Name: String?
        let member3Id: String?
        let member3Name: String?

        enum CodingKeys: String, CodingKey {
            case id
            case createdById = "created_by_id"
            case createdByName = "created_by_name"
            case member2Id = "member2_id"
            case member2Name = "member2_name"
            case member3Id = "member3_id"
            case member3Name = "member3_name"
        }
    }
    func fetchMemberDetailsFromNewTeams(teamId: String) async throws -> [(id: String, name: String)] {

            let rows: [NewTeamMembersRow] = try await client
                .from("new_teams")
                .select("id, created_by_id, created_by_name, member2_id, member2_name, member3_id, member3_name")
                .execute()
                .value

            guard let team = rows.first(where: { $0.id == teamId }) else { return [] }

            var members: [(id: String, name: String)] = []
            
            let id1 = team.createdById.trimmingCharacters(in: .whitespacesAndNewlines)
            let n1 = team.createdByName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !n1.isEmpty { members.append((id: id1, name: n1)) }

            if let n2 = team.member2Name?.trimmingCharacters(in: .whitespacesAndNewlines), !n2.isEmpty, let id2 = team.member2Id?.trimmingCharacters(in: .whitespacesAndNewlines) {
                members.append((id: id2, name: n2))
            }

            if let n3 = team.member3Name?.trimmingCharacters(in: .whitespacesAndNewlines), !n3.isEmpty, let id3 = team.member3Id?.trimmingCharacters(in: .whitespacesAndNewlines) {
                members.append((id: id3, name: n3))
            }

            return members
        }
}
