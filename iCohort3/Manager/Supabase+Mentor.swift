//
//  Supabase+Mentor.swift
//  iCohort3
//
//  Created by user@51 on 23/01/26.
//

//
//  SupabaseManager+Mentor.swift
//  iCohort3
//
//  Mentor-specific functionality
//

import Foundation
import UIKit
import Supabase

// MARK: - Mentor Announcements Extension
extension SupabaseManager {
    
    struct MentorAnnouncement: Encodable {
        let title: String
        let description: String?
        let category: String?
        let color_hex: String?
    }
    
    struct MentorAnnouncementUpdate: Encodable {
        let title: String?
        let description: String?
        let category: String?
        let color_hex: String?
    }
    
    struct MentorAnnouncementRow: Decodable {
        let id: Int
        let title: String
        let description: String?
        let category: String?
        let color_hex: String?
        let created_at: String?
        let author: String?
    }
    
    // MARK: - CREATE Announcement
    
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
    
    // MARK: - READ Announcements
    
    func fetchMentorAnnouncements() async throws -> [MentorAnnouncementRow] {
        let rows: [MentorAnnouncementRow] = try await client
            .from("mentor_announcements")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return rows
    }
    
    // MARK: - UPDATE Announcement
    
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
    
    // MARK: - DELETE Announcement
    
    func deleteAnnouncement(id: Int) async throws {
        _ = try await client
            .from("mentor_announcements")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Mentor Activities Extension
extension SupabaseManager {
    
    struct MentorActivityInsert: Encodable {
        let title: String
        let note: String?
        let start_date: String
        let end_date: String
        let is_all_day: Bool
        let alert_option: String?
        let send_to: String?
        let mentor_id: String?
    }
    
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
    
    struct MentorActivityUpdate: Encodable {
        let title: String?
        let note: String?
        let start_date: String?
        let end_date: String?
        let is_all_day: Bool?
        let alert_option: String?
        let send_to: String?
    }
    
    // MARK: - CREATE Activity
    
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
    
    func fetchAllMentorActivities() async throws -> [MentorActivityRow] {
        let rows: [MentorActivityRow] = try await client
            .from("mentor_activities")
            .select()
            .order("start_date", ascending: true)
            .execute()
            .value
        
        return rows
    }
    
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
    
    func fetchMentorActivities(forDate date: Date) async throws -> [MentorActivityRow] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await fetchMentorActivities(from: startOfDay, to: endOfDay)
    }
    
    // MARK: - UPDATE Activity
    
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
    
    func deleteMentorActivity(id: Int) async throws {
        _ = try await client
            .from("mentor_activities")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

// MARK: - Mentor Team Management Extension
extension SupabaseManager {
    
    struct TeamRow: Decodable, Sendable {
        let id: String
        let team_no: Int
        let mentor_id: String
    }
    
    struct TeamTaskRow: Decodable, Sendable {
        let team_id: String
        let total_task: Int?
        let ongoing_task: Int?
        let assigned_task: Int?
        let for_review_task: Int?
        let completed_task: Int?
        let rejected_task: Int?
        let prepared_task: Int?
        let approved_task: Int?
    }
    
    struct TeamStudentNameRow: Decodable, Sendable {
        let team_id: String
        let full_name: String
    }
    
    // MARK: - Fetch Teams
    
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
            .select("team_id, total_task, ongoing_task, assigned_task, for_review_task, prepared_task, approved_task, completed_task, rejected_task")
            .in("team_id", values: teamIds)
            .execute()
            .value
        
        return rows
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
