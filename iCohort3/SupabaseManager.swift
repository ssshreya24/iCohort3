//
//  SupabaseManager.swift
//  iCohort3
//

import Foundation
import Supabase

final class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        let url = URL(string: "https://jcengntlnilevfbsnswh.supabase.co")!
        let key = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpjZW5nbnRsbmlsZXZmYnNuc3doIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjM0Mzc5OTcsImV4cCI6MjA3OTAxMzk5N30.XOHB4ld2o__8JBFb6Z2W0bUf4nHDl5Q7b3nNDA2Kml8"
        
        client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: key
        )
    }
    
    // MARK: - Table Models
    
    /// Payload used when inserting a new row into `mentor_announcements`
    struct MentorAnnouncement: Encodable {
        let title: String
        let description: String?
        let category: String?
        let color_hex: String?
    }
    
    /// Payload for updating an announcement
    struct MentorAnnouncementUpdate: Encodable {
        let title: String?
        let description: String?
        let category: String?
        let color_hex: String?
    }
    
    /// Row model as it exists in Supabase `mentor_announcements`
    struct MentorAnnouncementRow: Decodable {
        let id: Int
        let title: String
        let description: String?
        let category: String?
        let color_hex: String?
        let created_at: String?
        let author: String?
    }
    
    // MARK: - CREATE: Save new mentor announcement
    
    /// Saves a new mentor announcement into the `mentor_announcements` table.
    func saveAnnouncementToSupabase(
        title: String,
        description: String?,
        category: String?,
        colorHex: String?
    ) async throws {
        let announcement = MentorAnnouncement(
            title: title,
            description: description,
            category: category,
            color_hex: colorHex
        )

        _ = try await client
            .from("mentor_announcements")
            .insert(announcement)
            .execute()
    }
    
    // MARK: - READ: Fetch all mentor announcements
    
    /// Fetches all mentor announcements ordered by `created_at` (latest first).
    func fetchMentorAnnouncements() async throws -> [MentorAnnouncementRow] {
        let rows: [MentorAnnouncementRow] = try await client
            .from("mentor_announcements")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return rows
    }
    
    // MARK: - UPDATE: Update an existing announcement
    
    /// Updates an existing announcement in the database
    func updateMentorAnnouncement(
        id: Int,
        title: String?,
        description: String?,
        category: String?,
        colorHex: String?
    ) async throws {
        let update = MentorAnnouncementUpdate(
            title: title,
            description: description,
            category: category,
            color_hex: colorHex
        )
        
        _ = try await client
            .from("mentor_announcements")
            .update(update)
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - DELETE: Delete an announcement by id
    
    /// Deletes an announcement from Supabase by its numeric `id`.
    func deleteAnnouncement(id: Int) async throws {
        _ = try await client
            .from("mentor_announcements")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Calendar Activity Models
    
    /// Payload for inserting a new activity
    struct MentorActivityInsert: Encodable {
        let title: String
        let note: String?
        let start_date: String  // ISO8601 format
        let end_date: String    // ISO8601 format
        let is_all_day: Bool
        let alert_option: String?
        let send_to: String?
        let mentor_id: String?  // Optional: track which mentor created it
    }
    
    /// Row model as returned from Supabase
    struct MentorActivityRow: Decodable {
        let id: Int
        let title: String
        let note: String?
        let start_date: String
        let end_date: String
        let is_all_day: Bool
        let alert_option: String?
        let send_to: String?
        let mentor_id: String?
        let created_at: String?
    }
    
    // MARK: - CREATE Activity
    
    /// Saves a new mentor activity to Supabase
    func saveMentorActivity(
        title: String,
        note: String?,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        alertOption: String?,
        sendTo: String?,
        mentorId: String?
    ) async throws -> MentorActivityRow {
        let formatter = ISO8601DateFormatter()
        
        let activity = MentorActivityInsert(
            title: title,
            note: note,
            start_date: formatter.string(from: startDate),
            end_date: formatter.string(from: endDate),
            is_all_day: isAllDay,
            alert_option: alertOption,
            send_to: sendTo,
            mentor_id: mentorId
        )
        
        let response: MentorActivityRow = try await client
            .from("mentor_activities")
            .insert(activity)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - READ Activities
    
    /// Fetch all mentor activities
    func fetchAllMentorActivities() async throws -> [MentorActivityRow] {
        let rows: [MentorActivityRow] = try await client
            .from("mentor_activities")
            .select()
            .order("start_date", ascending: true)
            .execute()
            .value
        
        return rows
    }
    
    /// Fetch activities for a specific date range
    func fetchMentorActivities(from startDate: Date, to endDate: Date) async throws -> [MentorActivityRow] {
        let formatter = ISO8601DateFormatter()
        
        let rows: [MentorActivityRow] = try await client
            .from("mentor_activities")
            .select()
            .gte("start_date", value: formatter.string(from: startDate))
            .lte("start_date", value: formatter.string(from: endDate))
            .order("start_date", ascending: true)
            .execute()
            .value
        
        return rows
    }
    
    /// Fetch activities for a specific date (matches any activity that starts on this day)
    func fetchMentorActivities(forDate date: Date) async throws -> [MentorActivityRow] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await fetchMentorActivities(from: startOfDay, to: endOfDay)
    }
    
    // MARK: - UPDATE Activity
    
    /// Payload for updating an activity
    struct MentorActivityUpdate: Encodable {
        let title: String?
        let note: String?
        let start_date: String?
        let end_date: String?
        let is_all_day: Bool?
        let alert_option: String?
        let send_to: String?
    }
    
    /// Updates an existing activity
    func updateMentorActivity(
        id: Int,
        title: String?,
        note: String?,
        startDate: Date?,
        endDate: Date?,
        isAllDay: Bool?,
        alertOption: String?,
        sendTo: String?
    ) async throws {
        let formatter = ISO8601DateFormatter()
        
        let update = MentorActivityUpdate(
            title: title,
            note: note,
            start_date: startDate.map { formatter.string(from: $0) },
            end_date: endDate.map { formatter.string(from: $0) },
            is_all_day: isAllDay,
            alert_option: alertOption,
            send_to: sendTo
        )
        
        _ = try await client
            .from("mentor_activities")
            .update(update)
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - DELETE Activity
    
    /// Deletes an activity by id
    func deleteMentorActivity(id: Int) async throws {
        _ = try await client
            .from("mentor_activities")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}
extension SupabaseManager {

    struct TeamRow: Decodable {
        let id: String
        let team_no: Int
        let mentor_id: String
    }

    struct TeamTaskRow: Decodable {
        let team_id: String
        let total_task: Int?
        let ongoing_task: Int?
        let assigned_task: Int?
        let for_review_task: Int?
        let completed_task: Int?
        let rejected_task: Int?
    }

    func fetchTeamsForMentor(mentorId: String) async throws -> [TeamRow] {
        let rows: [TeamRow] = try await client
            .from("teams")
            .select("id, team_no, mentor_id")
            .eq("mentor_id", value: mentorId)
            .order("team_no", ascending: true)
            .execute()
            .value

        return rows
    }

    func fetchTeamTasks(teamIds: [String]) async throws -> [TeamTaskRow] {
        guard !teamIds.isEmpty else { return [] }

        let rows: [TeamTaskRow] = try await client
            .from("team_task")
            .select("team_id, total_task, ongoing_task, assigned_task, for_review_task, completed_task, rejected_task")
            .in("team_id", values: teamIds)
            .execute()
            .value

        return rows
    }
}
extension SupabaseManager {
    struct TeamStudentNameRow: Decodable {
        let team_id: String
        let full_name: String
    }

    func fetchStudentNamesForTeam(teamId: String) async throws -> [String] {
        let rows: [TeamStudentNameRow] = try await client
            .from("team_student_names")
            .select("team_id, full_name")
            .eq("team_id", value: teamId)
            .execute()
            .value

        return rows.map { $0.full_name }
    }
}

