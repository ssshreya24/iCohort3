//
//  SupabaseManager.swift
//  iCohort3
//

import Foundation
import Supabase
import UIKit

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
    
    // MARK: - Announcements Models
    
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
    
    // MARK: - Announcements CRUD
    
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
    
    func fetchMentorAnnouncements() async throws -> [MentorAnnouncementRow] {
        let rows: [MentorAnnouncementRow] = try await client
            .from("mentor_announcements")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return rows
    }
    
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
    
    func deleteAnnouncement(id: Int) async throws {
        _ = try await client
            .from("mentor_announcements")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Calendar Activity Models
    
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
    
    // MARK: - Calendar Activities CRUD
    
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
    
    func deleteMentorActivity(id: Int) async throws {
        _ = try await client
            .from("mentor_activities")
            .delete()
            .eq("id", value: id)
            .execute()
    }
    
    // MARK: - Teams Models
    
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
    
    struct TeamStudentNameRow: Decodable {
        let team_id: String
        let full_name: String
    }
    
    struct TeamMemberRow: Decodable {
        let team_id: String
        let member_id: String
        let people: PersonInfo?
    }
    
    struct PersonInfo: Decodable {
        let full_name: String
    }
    
    // MARK: - Teams Queries
    
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
    
    func fetchStudentNamesForTeam(teamId: String) async throws -> [String] {
        let rows: [TeamStudentNameRow] = try await client
            .from("team_student_names")
            .select("team_id, full_name")
            .eq("team_id", value: teamId)
            .execute()
            .value
        
        return rows.map { $0.full_name }
    }
    
    // MARK: - Fetch Student ID by Name
    
    func fetchStudentId(teamId: String, studentName: String) async throws -> String? {
        let rows: [TeamMemberRow] = try await client
            .from("team_members")
            .select("team_id, member_id, people(full_name)")
            .eq("team_id", value: teamId)
            .execute()
            .value
        
        return rows.first(where: { $0.people?.full_name == studentName })?.member_id
    }
    
    // MARK: - Tasks Models
    
    struct TaskInsert: Encodable {
        let team_id: String
        let mentor_id: String
        let title: String
        let description: String?
        let status: String
        let assigned_date: String
        let remark: String?
        let remark_description: String?
    }
    
    struct TaskRow: Decodable {
        let id: String
        let team_id: String
        let mentor_id: String
        let title: String
        let description: String?
        let status: String
        let assigned_date: String
        let remark: String?
        let remark_description: String?
        let created_at: String?
        let updated_at: String?
        let task_assignees: [TaskAssigneeRow]?
    }
    
    struct TaskAssigneeRow: Decodable {
        let student_id: String
        let people: PersonInfo?
    }
    
    struct TaskUpdate: Encodable {
        let title: String?
        let description: String?
        let status: String?
        let assigned_date: String?
        let remark: String?
        let remark_description: String?
    }
    
    struct TaskAssigneeInsert: Encodable {
        let task_id: String
        let student_id: String
    }
    
    struct TaskAttachmentInsert: Encodable {
        let task_id: String
        let filename: String
        let file_url: String?
        let file_type: String?
    }
    
    struct TaskAttachmentRow: Decodable {
        let id: String
        let task_id: String
        let filename: String
        let file_url: String?
        let file_type: String?
        let created_at: String?
    }
    
    // MARK: - Tasks CRUD
    
    /// Create a new task with attachments and return the created task ID
    func createTask(
        teamId: String,
        mentorId: String,
        title: String,
        description: String?,
        assignedDate: Date,
        assignToAll: Bool,
        specificStudentId: String?,
        attachments: [UIImage] = []
    ) async throws -> String {
        let formatter = ISO8601DateFormatter()
        
        let taskInsert = TaskInsert(
            team_id: teamId,
            mentor_id: mentorId,
            title: title,
            description: description,
            status: "assigned",
            assigned_date: formatter.string(from: assignedDate),
            remark: nil,
            remark_description: nil
        )
        
        // 1. Insert task and get the ID
        let taskRow: TaskRow = try await client
            .from("tasks")
            .insert(taskInsert)
            .select()
            .single()
            .execute()
            .value
        
        let taskId = taskRow.id
        
        // 2. Assign to students
        if assignToAll {
            // Call RPC to assign to all team members
            try await client
                .rpc("assign_task_to_all_members", params: [
                    "p_task_id": taskId,
                    "p_team_id": teamId
                ])
                .execute()
        } else if let studentId = specificStudentId {
            // Assign to specific student
            let assignee = TaskAssigneeInsert(task_id: taskId, student_id: studentId)
            _ = try await client
                .from("task_assignees")
                .insert(assignee)
                .execute()
        }
        
        // 3. Upload attachments if any
        if !attachments.isEmpty {
            try await uploadAttachments(attachments, for: taskId)
        }
        
        return taskId
    }
    
    /// Fetch all tasks for a team with assignees
    func fetchTasksForTeam(teamId: String) async throws -> [TaskRow] {
        let rows: [TaskRow] = try await client
            .from("tasks")
            .select("*, task_assignees(student_id, people(full_name))")
            .eq("team_id", value: teamId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return rows
    }
    
    /// Fetch tasks by status
    func fetchTasksForTeam(teamId: String, status: String) async throws -> [TaskRow] {
        let rows: [TaskRow] = try await client
            .from("tasks")
            .select("*, task_assignees(student_id, people(full_name))")
            .eq("team_id", value: teamId)
            .eq("status", value: status)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return rows
    }
    
    /// Update task with assignees and attachments (FIXED VERSION)
    func updateTask(
        taskId: String,
        title: String?,
        description: String?,
        assignedDate: Date?,
        status: String? = nil,
        remark: String? = nil,
        remarkDescription: String? = nil,
        attachments: [UIImage] = [],
        updateAssignees: Bool = false,
        assignToAll: Bool = false,
        teamId: String? = nil,
        specificStudentId: String? = nil
    ) async throws {
        let formatter = ISO8601DateFormatter()
        
        let update = TaskUpdate(
            title: title,
            description: description,
            status: status,
            assigned_date: assignedDate.map { formatter.string(from: $0) },
            remark: remark,
            remark_description: remarkDescription
        )
        
        // 1. Update task details
        _ = try await client
            .from("tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()
        
        // 2. Update assignees if requested
        if updateAssignees {
            print("🔄 Updating assignees for task: \(taskId)")
            
            // First, delete existing assignees
            _ = try await client
                .from("task_assignees")
                .delete()
                .eq("task_id", value: taskId)
                .execute()
            
            print("✅ Deleted old assignees")
            
            // Then, add new assignees
            if assignToAll, let teamId = teamId {
                print("🔄 Assigning to all team members")
                
                // Use RPC to assign to all team members
                try await client
                    .rpc("assign_task_to_all_members", params: [
                        "p_task_id": taskId,
                        "p_team_id": teamId
                    ])
                    .execute()
                
                print("✅ Assigned to all team members")
            } else if let studentId = specificStudentId {
                print("🔄 Assigning to specific student: \(studentId)")
                
                // Assign to specific student
                let assignee = TaskAssigneeInsert(task_id: taskId, student_id: studentId)
                _ = try await client
                    .from("task_assignees")
                    .insert(assignee)
                    .execute()
                
                print("✅ Assigned to specific student")
            }
        }
        
        // 3. Handle attachments if provided
        if !attachments.isEmpty {
            print("🔄 Updating attachments for task: \(taskId)")
            
            // Delete old attachments
            try await deleteAttachments(for: taskId)
            
            // Upload new attachments
            try await uploadAttachments(attachments, for: taskId)
            
            print("✅ Attachments updated")
        }
    }
    
    /// Delete task and its attachments
    func deleteTask(taskId: String) async throws {
        // 1. Delete attachments from storage
        try await deleteAttachments(for: taskId)
        
        // 2. Delete task (cascade will handle task_assignees and task_attachments records)
        _ = try await client
            .from("tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()
    }
    
    // MARK: - Attachment Management
    
    /// Upload multiple images as attachments for a task
    private func uploadAttachments(_ images: [UIImage], for taskId: String) async throws {
        for (index, image) in images.enumerated() {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("⚠️ Failed to convert image \(index) to JPEG data")
                continue
            }
            
            let filename = "\(taskId)_\(index)_\(UUID().uuidString).jpg"
            let path = "tasks/\(taskId)/\(filename)"
            
            do {
                // Upload to Supabase Storage
                _ = try await client.storage
                    .from("task-attachments")
                    .upload(
                        path: path,
                        file: imageData,
                        options: FileOptions(contentType: "image/jpeg")
                    )
                
                // Save metadata to task_attachments table
                let attachmentData = TaskAttachmentInsert(
                    task_id: taskId,
                    filename: filename,
                    file_url: path,
                    file_type: "image/jpeg"
                )
                
                _ = try await client
                    .from("task_attachments")
                    .insert(attachmentData)
                    .execute()
                
                print("✅ Uploaded attachment: \(filename)")
            } catch {
                print("❌ Failed to upload attachment \(index): \(error)")
                // Continue with other attachments even if one fails
            }
        }
    }
    
    /// Delete all attachments for a task
    private func deleteAttachments(for taskId: String) async throws {
        // 1. Get all attachment records
        let attachments: [TaskAttachmentRow] = try await client
            .from("task_attachments")
            .select()
            .eq("task_id", value: taskId)
            .execute()
            .value
        
        // 2. Delete files from storage
        let paths = attachments.compactMap { $0.file_url }
        if !paths.isEmpty {
            do {
                _ = try await client.storage
                    .from("task-attachments")
                    .remove(paths: paths)
                print("✅ Deleted \(paths.count) attachment files from storage")
            } catch {
                print("⚠️ Failed to delete some attachment files: \(error)")
                // Continue even if storage deletion fails
            }
        }
        
        // 3. Delete records from database
        _ = try await client
            .from("task_attachments")
            .delete()
            .eq("task_id", value: taskId)
            .execute()
    }
    
    /// Download all attachments for a task
    func downloadAttachments(for taskId: String) async throws -> [UIImage] {
        // Get attachment records
        let attachments: [TaskAttachmentRow] = try await client
            .from("task_attachments")
            .select()
            .eq("task_id", value: taskId)
            .execute()
            .value
        
        var images: [UIImage] = []
        
        for attachment in attachments {
            guard let path = attachment.file_url else {
                print("⚠️ Attachment has no file URL")
                continue
            }
            
            do {
                // Download from storage
                let data = try await client.storage
                    .from("task-attachments")
                    .download(path: path)
                
                if let image = UIImage(data: data) {
                    images.append(image)
                    print("✅ Downloaded attachment: \(attachment.filename)")
                } else {
                    print("⚠️ Failed to create image from data: \(attachment.filename)")
                }
            } catch {
                print("❌ Failed to download attachment \(attachment.filename): \(error)")
                // Continue with other attachments
            }
        }
        
        return images
    }
    
    /// Fetch attachments metadata for a task
    func fetchAttachmentsForTask(taskId: String) async throws -> [TaskAttachmentRow] {
        let rows: [TaskAttachmentRow] = try await client
            .from("task_attachments")
            .select()
            .eq("task_id", value: taskId)
            .execute()
            .value
        
        return rows
    }
}

// MARK: - TaskModel Extension

extension TaskModel {
    /// Convert TaskRow from Supabase to TaskModel with downloaded attachments
    static func from(taskRow: SupabaseManager.TaskRow) async -> TaskModel {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        
        let assignedDate: Date
        if let date = ISO8601DateFormatter().date(from: taskRow.assigned_date) {
            assignedDate = date
        } else {
            assignedDate = Date()
        }
        
        let dateString = dateFormatter.string(from: assignedDate)
        
        // Get assignee names
        let assigneeNames = taskRow.task_assignees?.compactMap { $0.people?.full_name } ?? []
        let name = assigneeNames.isEmpty ? "Unassigned" : assigneeNames.joined(separator: ", ")
        
        // Download attachments
        var attachments: [UIImage] = []
        do {
            attachments = try await SupabaseManager.shared.downloadAttachments(for: taskRow.id)
        } catch {
            print("❌ Failed to download attachments for task \(taskRow.id): \(error)")
        }
        
        return TaskModel(
            id: taskRow.id,
            name: name,
            desc: taskRow.description ?? "",
            date: dateString,
            remark: taskRow.remark,
            remarkDesc: taskRow.remark_description,
            title: taskRow.title,
            attachments: attachments,
            assignedDate: assignedDate,
            status: taskRow.status
        )
    }
}
