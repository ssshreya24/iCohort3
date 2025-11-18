//
//  SupabaseManager.swift
//  iCohort3
//
//  Created by user@0 on 18/11/25.
//
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
        // 1. Put YOUR Supabase project URL & anon public key here
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
    ///
    /// - Parameters:
    ///   - title: Announcement title (required)
    ///   - description: Body / details text
    ///   - category: Tag / label (e.g., "Meeting", "Event")
    ///   - colorHex: Color string like "#FFCC00" for your tag background
    ///   - author: Name of mentor or program (e.g., "Program Lead")
    /// - Returns: The inserted row from Supabase
    @discardableResult
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
    
    // MARK: - DELETE: Delete an announcement by id (optional helper)
    
    /// Deletes an announcement from Supabase by its numeric `id`.
    func deleteAnnouncement(id: Int) async throws {
        _ = try await client
            .from("mentor_announcements")
            .delete()
            .eq("id", value: id)
            .execute()
    }
}

