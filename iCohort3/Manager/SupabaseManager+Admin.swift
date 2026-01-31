//
//  SupabaseManager+Admin.swift
//  iCohort3
//
//  Admin-specific team management functionality with team count
//

import Foundation
import Supabase

extension SupabaseManager {
    
    // MARK: - Team Models
    
    struct AdminTeamRow: Decodable, Sendable {
        let id: String
        let team_no: Int
        let mentor_id: String?
        let created_at: String?
    }
    
    struct TeamMemberRow: Decodable, Sendable {
        let member_id: String
        let team_id: String
    }
    
    struct TeamWithDetails: Sendable {
        let id: String
        let teamNo: Int
        let mentorId: String?
        let mentorName: String?
        let memberNames: [String]
        let memberCount: Int
    }
    
    // MARK: - Get Teams Count
    
    /// ✅ NEW: Fetch total teams count
    func fetchTeamsCount() async throws -> Int {
        let rows: [AdminTeamRow] = try await client
            .from("teams")
            .select("id")
            .execute()
            .value
        
        return rows.count
    }
    
    // MARK: - Fetch Teams for Institute
    
    /// Fetch all teams - since there's no institute filter in teams table, fetch all
    func fetchTeamsForInstitute(instituteName: String) async throws -> [AdminTeamRow] {
        // Note: The teams table doesn't have institute_name column
        // So we fetch all teams for now
        let rows: [AdminTeamRow] = try await client
            .from("teams")
            .select("id, team_no, mentor_id, created_at")
            .order("team_no", ascending: true)
            .execute()
            .value
        
        return rows
    }
    
    /// Fetch team details with members
    func fetchTeamDetails(teamId: String) async throws -> (members: [String], mentorId: String?) {
        // Fetch team info
        let teamRows: [AdminTeamRow] = try await client
            .from("teams")
            .select("id, team_no, mentor_id")
            .eq("id", value: teamId)
            .execute()
            .value
        
        guard let team = teamRows.first else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Team not found"])
        }
        
        // Fetch member names from team_student_names view
        let memberNames = try await fetchStudentNamesForTeam(teamId: teamId)
        
        return (memberNames, team.mentor_id)
    }
    
    /// Fetch all team details with member counts
    func fetchAllTeamsWithDetails() async throws -> [TeamWithDetails] {
        let teams = try await fetchTeamsForInstitute(instituteName: "")
        
        var teamsWithDetails: [TeamWithDetails] = []
        
        for team in teams {
            let (memberNames, mentorId) = try await fetchTeamDetails(teamId: team.id)
            
            // Mentor name will be fetched from Firebase by the ViewController
            let teamDetail = TeamWithDetails(
                id: team.id,
                teamNo: team.team_no,
                mentorId: mentorId,
                mentorName: nil, // Will be populated from Firebase
                memberNames: memberNames,
                memberCount: memberNames.count
            )
            
            teamsWithDetails.append(teamDetail)
        }
        
        return teamsWithDetails
    }
    
    // MARK: - Assign Mentor to Team
    
    /// Assign a mentor to a team
    func assignMentorToTeam(teamId: String, mentorId: String) async throws {
        struct MentorUpdate: Encodable {
            let mentor_id: String
        }
        
        let update = MentorUpdate(mentor_id: mentorId)
        
        _ = try await client
            .from("teams")
            .update(update)
            .eq("id", value: teamId)
            .execute()
        
        print("✅ Mentor \(mentorId) assigned to team \(teamId)")
    }
    
    /// Remove mentor from team
    func removeMentorFromTeam(teamId: String) async throws {
        struct MentorRemove: Encodable {
            let mentor_id: String?
        }
        
        let update = MentorRemove(mentor_id: nil)
        
        _ = try await client
            .from("teams")
            .update(update)
            .eq("id", value: teamId)
            .execute()
        
        print("✅ Mentor removed from team \(teamId)")
    }
}
