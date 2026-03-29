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
        let createdByName: String
        let member2Name: String?
        let member3Name: String?

        enum CodingKeys: String, CodingKey {
            case id
            case createdByName = "created_by_name"
            case member2Name = "member2_name"
            case member3Name = "member3_name"
        }
    }
    func fetchMemberNamesFromNewTeams(teamId: String) async throws -> [String] {

            let rows: [NewTeamMembersRow] = try await client
                .from("new_teams")
                .select("id, created_by_name, member2_name, member3_name")
                .execute()
                .value

            guard let team = rows.first(where: { $0.id == teamId }) else { return [] }

            var names: [String] = []
            let n1 = team.createdByName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !n1.isEmpty { names.append(n1) }

            if let n2 = team.member2Name?.trimmingCharacters(in: .whitespacesAndNewlines), !n2.isEmpty {
                names.append(n2)
            }

            if let n3 = team.member3Name?.trimmingCharacters(in: .whitespacesAndNewlines), !n3.isEmpty {
                names.append(n3)
            }

            return names
        }
}
