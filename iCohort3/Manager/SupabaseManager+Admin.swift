//
//  SupabaseManager+Admin.swift
//  iCohort3
//
//  Admin-specific team management functionality with team count
//


import Foundation
import Supabase

extension SupabaseManager {
    
    // MARK: - DB Models (new_teams)
    
    struct AdminTeamRow: Decodable, Sendable {
        let id: String
        let teamNo: Int
        let mentorId: String?
        let mentorName: String?
        let createdByName: String
        let member2Name: String?
        let member3Name: String?
        let status: String
        let createdAt: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case teamNo = "team_number"
            case mentorId = "mentor_id"
            case mentorName = "mentor_name"
            case createdByName = "created_by_name"
            case member2Name = "member2_name"
            case member3Name = "member3_name"
            case status
            case createdAt = "created_at"
        }
    }
    
    // MARK: - Mentor list model (mentor_profile_complete)
    
    struct MentorProfileCompleteRow: Decodable, Sendable {
        let personId: String
        let fullName: String?
        let firstName: String?
        let lastName: String?
        
        enum CodingKeys: String, CodingKey {
            case personId = "person_id"
            case fullName = "full_name"
            case firstName = "first_name"
            case lastName  = "last_name"
        }
    }
    
    // MARK: - App DTO for Admin teams screen
    
    struct TeamWithDetails: Sendable {
        let id: String
        let teamNo: Int
        let mentorId: String?
        let mentorName: String?
        let memberNames: [String]
        let memberCount: Int
        let status: String
    }
    
    // MARK: - Helpers
    
    private func buildMemberNames(from team: AdminTeamRow) -> [String] {
        var names: [String] = []
        
        let n1 = team.createdByName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !n1.isEmpty { names.append(n1) }
        
        if let m2 = team.member2Name?.trimmingCharacters(in: .whitespacesAndNewlines), !m2.isEmpty {
            names.append(m2)
        }
        
        if let m3 = team.member3Name?.trimmingCharacters(in: .whitespacesAndNewlines), !m3.isEmpty {
            names.append(m3)
        }
        
        return names
    }
    
    // MARK: - Count Teams (new_teams)
    
    /// ✅ Fetch total teams count from public.new_teams
    func fetchTeamsCount() async throws -> Int {
        do {
            let response = try await client
                .from("new_teams")
                .select("id", head: false, count: .exact)
                .execute()
            
            if let count = response.count {
                return count
            }
            
            // Fallback
            let rows: [[String: String]] = try await client
                .from("new_teams")
                .select("id")
                .execute()
                .value
            
            return rows.count
        } catch {
            // Do NOT crash admin screen
            return 0
        }
    }
    
    // MARK: - Fetch Teams
    
    /// ✅ Fetch all teams from public.new_teams
    /// If you only want active teams, set `onlyActive = true`
    func fetchAllTeams(onlyActive: Bool = false) async throws -> [AdminTeamRow] {

        let rows: [AdminTeamRow] = try await client
            .from("new_teams")
            .select("""
                id,
                team_number,
                mentor_id,
                mentor_name,
                created_by_name,
                member2_name,
                member3_name,
                status,
                created_at
            """)
            .order("team_number", ascending: true)
            .execute()
            .value

        if onlyActive {
            return rows.filter { $0.status.lowercased() == "active" }
        } else {
            return rows
        }
    }

    /// ✅ Returns teams with member names + memberCount (computed from new_teams columns)
    func fetchAllTeamsWithDetails(onlyActive: Bool = false) async throws -> [TeamWithDetails] {
        let teams = try await fetchAllTeams(onlyActive: onlyActive)
        
        return teams.map { team in
            let memberNames = buildMemberNames(from: team)
            return TeamWithDetails(
                id: team.id,
                teamNo: team.teamNo,
                mentorId: team.mentorId,
                mentorName: team.mentorName,
                memberNames: memberNames,
                memberCount: memberNames.count,
                status: team.status
            )
        }
    }
    
    // MARK: - Fetch Mentors (mentor_profile_complete)
    
    /// ✅ Mentors list for assignment sheet (from mentor_profile_complete)
    func fetchMentorsForAssignment() async throws -> [MentorProfileCompleteRow] {
        let rows: [MentorProfileCompleteRow] = try await client
            .from("mentor_profile_complete")
            .select("person_id, full_name, first_name, last_name")
            .order("first_name", ascending: true)
            .execute()
            .value
        
        return rows
    }
    
    // MARK: - Assign / Remove Mentor (new_teams)
    
    /// ✅ IMPORTANT: Must update BOTH mentor_id + mentor_name because of new_teams_mentor_pair constraint
    // MARK: - Assign / Remove Mentor (new_teams)
    
    func assignMentorToTeam(teamId: String, mentorId: String, mentorName: String) async throws {
        struct MentorAssignPayload: Encodable {
            let mentor_id: String
            let mentor_name: String
        }
        
        let payload = MentorAssignPayload(mentor_id: mentorId, mentor_name: mentorName)
        
        try await client
            .database
            .from("new_teams")
            .update(payload)
            .eq("id", value: teamId)
            .execute()
    }
    
    func removeMentorFromTeam(teamId: String) async throws {
        struct MentorRemovePayload: Encodable {
            let mentor_id: String?
            let mentor_name: String?
        }
        
        let payload = MentorRemovePayload(mentor_id: nil, mentor_name: nil)
        
        try await client
            .database
            .from("new_teams")
            .update(payload)
            .eq("id", value: teamId)
            .execute()
    }
}
