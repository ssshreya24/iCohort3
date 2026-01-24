//
//  Supabase+Tasks.swift
//  iCohort3
//
//  Created by user@51 on 23/01/26.

import Foundation
import UIKit
import Supabase

// MARK: - Task Management Extension
extension SupabaseManager {
    
    // MARK: - Task Models
    
    struct TaskRow: Codable, Sendable {
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
    }
    
    struct TaskInsert: Encodable, Sendable {
        let team_id: String
        let mentor_id: String
        let title: String
        let description: String?
        let status: String
        let assigned_date: String
    }
    
    struct TaskUpdate: Encodable, Sendable {
        let title: String?
        let description: String?
        let status: String?
        let remark: String?
        let remark_description: String?
        let assigned_date: String?
    }
    
    struct TaskAssigneeRow: Codable, Sendable {
        let task_id: String
        let student_id: String
        let assigned_at: String?
    }
    
    struct TaskAttachmentRow: Codable, Sendable {
        let id: String
        let task_id: String
        let filename: String
        let file_type: String
        let file_data: String?
        let mentor_id: String?
        let team_id: String?
        let student_id: String?
        let mentor_attachment: Bool?
        let created_at: String?
    }
    
    struct TaskAttachmentInsert: Encodable, Sendable {
        let task_id: String
        let filename: String
        let file_type: String
        let file_data: String?
        let mentor_id: String?
        let team_id: String?
        let student_id: String?
        let mentor_attachment: Bool
    }
    
    struct TeamTaskCounterUpdate: Encodable {
        let ongoing_task: Int?
        let for_review_task: Int?
        let assigned_task: Int?
        let prepared_task: Int?
        let approved_task: Int?
        let completed_task: Int?
        let rejected_task: Int?
    }
    
    // MARK: - Create Task (with Base64 attachments)
    
    func createTask(
        teamId: String,
        mentorId: String,
        title: String,
        description: String?,
        status: String = "assigned",
        assignedDate: Date = Date(),
        assignToAll: Bool = true,
        specificStudentId: String? = nil,
        attachments: [UIImage] = [],
        attachmentFilenames: [String] = []
    ) async throws -> String {
        print("🔄 Creating task: '\(title)'")
        print("   Team ID: \(teamId)")
        print("   Mentor ID: \(mentorId)")
        print("   Status: \(status)")
        print("   Assign to all: \(assignToAll)")
        print("   Attachments: \(attachments.count)")
        
        let formatter = ISO8601DateFormatter()
        
        let task = TaskInsert(
            team_id: teamId,
            mentor_id: mentorId,
            title: title,
            description: description,
            status: status,
            assigned_date: formatter.string(from: assignedDate)
        )
        
        let response: TaskRow = try await client
            .from("tasks")
            .insert(task)
            .select()
            .single()
            .execute()
            .value
        
        let taskId = response.id
        print("✅ Task created with ID: \(taskId)")
        
        // Assign to students
        if assignToAll {
            struct TeamMember: Codable {
                let member_id: String
            }
            
            let members: [TeamMember] = try await client
                .from("team_members")
                .select("member_id")
                .eq("team_id", value: teamId)
                .execute()
                .value
            
            let studentIds = members.map { $0.member_id }
            print("📋 Found \(studentIds.count) team members")
            
            if !studentIds.isEmpty {
                try await assignTaskToStudents(taskId: taskId, studentIds: studentIds)
                print("✅ Assigned to \(studentIds.count) students")
            }
        } else if let studentId = specificStudentId {
            try await assignTaskToStudents(taskId: taskId, studentIds: [studentId])
            print("✅ Assigned to specific student: \(studentId)")
        }
        
        // Upload attachments as base64
        if !attachments.isEmpty {
            print("📎 Uploading \(attachments.count) attachments...")
            try await uploadTaskAttachments(
                taskId: taskId,
                teamId: teamId,
                mentorId: mentorId,
                studentId: nil,
                isMentorAttachment: true,
                images: attachments,
                filenames: attachmentFilenames
            )
            print("✅ Uploaded \(attachments.count) attachments")
        }
        
        return taskId
    }
    
    // MARK: - Upload Attachments (Base64)
    
    private func uploadTaskAttachments(
        taskId: String,
        teamId: String,
        mentorId: String?,
        studentId: String?,
        isMentorAttachment: Bool,
        images: [UIImage],
        filenames: [String]
    ) async throws {
        for (index, image) in images.enumerated() {
            let filename = index < filenames.count ? filenames[index] : "Image_\(index).jpg"
            
            // Check if it's a link (URL)
            if filename.hasPrefix("http://") || filename.hasPrefix("https://") {
                _ = try await addTaskAttachment(
                    taskId: taskId,
                    filename: filename,
                    fileType: "link",
                    fileData: filename,
                    mentorId: mentorId,
                    teamId: teamId,
                    studentId: studentId,
                    isMentorAttachment: isMentorAttachment
                )
                print("✅ Saved link: \(filename)")
                continue
            }
            
            // Convert image to base64
            guard let base64String = convertImageToBase64(image: image, maxSizeKB: 500) else {
                print("⚠️ Failed to convert image to base64: \(filename)")
                continue
            }
            
            let fileType = detectTaskFileType(filename: filename)
            
            _ = try await addTaskAttachment(
                taskId: taskId,
                filename: filename,
                fileType: fileType,
                fileData: base64String,
                mentorId: mentorId,
                teamId: teamId,
                studentId: studentId,
                isMentorAttachment: isMentorAttachment
            )
            
            print("✅ Saved attachment: \(filename) (\(base64String.count) chars, ~\(base64String.count / 1024)KB)")
        }
    }
    
    // MARK: - Download Attachments (Convert Base64 to Images)
    
    func downloadTaskAttachmentImages(taskId: String) async throws -> [UIImage] {
        let attachments = try await fetchTaskAttachments(taskId: taskId)
        var images: [UIImage] = []
        
        for attachment in attachments {
            // Handle links
            if attachment.file_type == "link" {
                let linkImage = createTaskLinkPlaceholder()
                images.append(linkImage)
                print("✅ Loaded link placeholder: \(attachment.filename)")
                continue
            }
            
            // Handle base64 images
            guard let base64Data = attachment.file_data else {
                print("⚠️ No data for attachment: \(attachment.filename)")
                continue
            }
            
            guard let image = convertBase64ToImage(base64String: base64Data) else {
                print("⚠️ Failed to decode base64 for: \(attachment.filename)")
                continue
            }
            
            images.append(image)
            print("✅ Downloaded attachment: \(attachment.filename)")
        }
        
        return images
    }
    
    // MARK: - Add Attachment Metadata
    
    func addTaskAttachment(
        taskId: String,
        filename: String,
        fileType: String,
        fileData: String?,
        mentorId: String?,
        teamId: String?,
        studentId: String?,
        isMentorAttachment: Bool
    ) async throws -> TaskAttachmentRow {
        let attachment = TaskAttachmentInsert(
            task_id: taskId,
            filename: filename,
            file_type: fileType,
            file_data: fileData,
            mentor_id: mentorId,
            team_id: teamId,
            student_id: studentId,
            mentor_attachment: isMentorAttachment
        )
        
        let response: TaskAttachmentRow = try await client
            .from("task_attachments")
            .insert(attachment)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Fetch Tasks
    
    func fetchTasksForTeam(teamId: String) async throws -> [TaskRow] {
        print("🔍 Fetching tasks for team: \(teamId)")
        
        let tasks: [TaskRow] = try await client
            .from("tasks")
            .select()
            .eq("team_id", value: teamId)
            .order("assigned_date", ascending: false)
            .execute()
            .value
        
        print("✅ Fetched \(tasks.count) tasks")
        return tasks
    }
    
    func fetchTasksForTeam(teamId: String, status: String) async throws -> [TaskRow] {
        let tasks: [TaskRow] = try await client
            .from("tasks")
            .select()
            .eq("team_id", value: teamId)
            .eq("status", value: status)
            .order("assigned_date", ascending: false)
            .execute()
            .value
        
        return tasks
    }
    
    func fetchTask(taskId: String) async throws -> TaskRow? {
        let tasks: [TaskRow] = try await client
            .from("tasks")
            .select()
            .eq("id", value: taskId)
            .execute()
            .value
        
        return tasks.first
    }
    
    func fetchTasksForStudent(studentId: String) async throws -> [TaskRow] {
        struct TaskWithAssignee: Codable {
            let task_id: String
            let tasks: TaskRow?
        }
        
        let result: [TaskWithAssignee] = try await client
            .from("task_assignees")
            .select("task_id, tasks!inner(*)")
            .eq("student_id", value: studentId)
            .execute()
            .value
        
        return result.compactMap { $0.tasks }
    }
    
    func fetchTasksForStudent(studentId: String, status: String) async throws -> [TaskRow] {
        struct TaskWithAssignee: Codable {
            let task_id: String
            let tasks: TaskRow?
        }
        
        let result: [TaskWithAssignee] = try await client
            .from("task_assignees")
            .select("task_id, tasks!inner(*)")
            .eq("student_id", value: studentId)
            .execute()
            .value
        
        return result.compactMap { $0.tasks }.filter { $0.status == status }
    }
    
    // MARK: - Update Task (with Base64 attachments)
    
    func updateTask(
        taskId: String,
        title: String? = nil,
        description: String? = nil,
        status: String? = nil,
        remark: String? = nil,
        remarkDescription: String? = nil,
        assignedDate: Date? = nil,
        attachments: [UIImage]? = nil,
        attachmentFilenames: [String]? = nil,
        updateAssignees: Bool = false,
        assignToAll: Bool = false,
        teamId: String? = nil,
        mentorId: String? = nil,
        specificStudentId: String? = nil
    ) async throws {
        print("🔄 Updating task: \(taskId)")
        
        let formatter = ISO8601DateFormatter()
        
        let update = TaskUpdate(
            title: title,
            description: description,
            status: status,
            remark: remark,
            remark_description: remarkDescription,
            assigned_date: assignedDate.map { formatter.string(from: $0) }
        )
        
        _ = try await client
            .from("tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()
        
        print("✅ Task updated: \(taskId)")
        
        // Update assignees if requested
        if updateAssignees {
            print("🔄 Updating assignees...")
            
            // Delete existing assignees
            _ = try await client
                .from("task_assignees")
                .delete()
                .eq("task_id", value: taskId)
                .execute()
            
            if assignToAll, let teamId = teamId {
                struct TeamMember: Codable {
                    let member_id: String
                }
                
                let members: [TeamMember] = try await client
                    .from("team_members")
                    .select("member_id")
                    .eq("team_id", value: teamId)
                    .execute()
                    .value
                
                let studentIds = members.map { $0.member_id }
                if !studentIds.isEmpty {
                    try await assignTaskToStudents(taskId: taskId, studentIds: studentIds)
                    print("✅ Assigned to \(studentIds.count) students")
                }
            } else if let studentId = specificStudentId {
                try await assignTaskToStudents(taskId: taskId, studentIds: [studentId])
                print("✅ Assigned to specific student")
            }
        }
        
        // Upload new attachments as base64
        if let attachments = attachments, !attachments.isEmpty,
           let teamId = teamId, let mentorId = mentorId {
            let filenames = attachmentFilenames ?? []
            print("📎 Uploading \(attachments.count) new attachments...")
            try await uploadTaskAttachments(
                taskId: taskId,
                teamId: teamId,
                mentorId: mentorId,
                studentId: nil,
                isMentorAttachment: true,
                images: attachments,
                filenames: filenames
            )
            print("✅ Added new attachments to task")
        }
    }
    
    // MARK: - Update Task Status
    
    func updateTaskStatus(taskId: String, status: String) async throws -> TaskRow {
        let update = TaskUpdate(
            title: nil,
            description: nil,
            status: status,
            remark: nil,
            remark_description: nil,
            assigned_date: nil
        )
        
        let updated: TaskRow = try await client
            .from("tasks")
            .update(update)
            .eq("id", value: taskId)
            .select()
            .single()
            .execute()
            .value
        
        return updated
    }
    
    // MARK: - Move Team Task Counter
    
    func moveTeamTaskCounter(teamId: String, from: String, to: String) async throws {
        struct TeamTaskRowMini: Decodable {
            let team_id: String
            let ongoing_task: Int?
            let for_review_task: Int?
            let assigned_task: Int?
            let prepared_task: Int?
            let approved_task: Int?
            let completed_task: Int?
            let rejected_task: Int?
        }
        
        let rows: [TeamTaskRowMini] = try await client
            .from("team_task")
            .select("team_id, ongoing_task, for_review_task, assigned_task, prepared_task, approved_task, completed_task, rejected_task")
            .eq("team_id", value: teamId)
            .limit(1)
            .execute()
            .value
        
        guard let r = rows.first else { return }
        
        func dec(_ v: Int?) -> Int { max((v ?? 0) - 1, 0) }
        func inc(_ v: Int?) -> Int { (v ?? 0) + 1 }
        
        var newOngoing = r.ongoing_task
        var newForReview = r.for_review_task
        var newAssigned = r.assigned_task
        var newPrepared = r.prepared_task
        var newApproved = r.approved_task
        var newCompleted = r.completed_task
        var newRejected = r.rejected_task
        
        // Decrement old
        switch from {
        case "ongoing": newOngoing = dec(r.ongoing_task)
        case "for_review": newForReview = dec(r.for_review_task)
        case "assigned": newAssigned = dec(r.assigned_task)
        case "prepared": newPrepared = dec(r.prepared_task)
        case "approved": newApproved = dec(r.approved_task)
        case "completed": newCompleted = dec(r.completed_task)
        case "rejected": newRejected = dec(r.rejected_task)
        default: break
        }
        
        // Increment new
        switch to {
        case "ongoing": newOngoing = inc(newOngoing)
        case "for_review": newForReview = inc(newForReview)
        case "assigned": newAssigned = inc(newAssigned)
        case "prepared": newPrepared = inc(newPrepared)
        case "approved": newApproved = inc(newApproved)
        case "completed": newCompleted = inc(newCompleted)
        case "rejected": newRejected = inc(newRejected)
        default: break
        }
        
        let payload = TeamTaskCounterUpdate(
            ongoing_task: newOngoing,
            for_review_task: newForReview,
            assigned_task: newAssigned,
            prepared_task: newPrepared,
            approved_task: newApproved,
            completed_task: newCompleted,
            rejected_task: newRejected
        )
        
        _ = try await client
            .from("team_task")
            .update(payload)
            .eq("team_id", value: teamId)
            .execute()
    }
    
    // MARK: - Delete Task
    
    func deleteTask(taskId: String) async throws {
        print("🗑️ Deleting task: \(taskId)")
        
        _ = try await client
            .from("tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()
        
        print("✅ Task deleted: \(taskId)")
    }
    
    // MARK: - Task Assignees
    
    func assignTaskToStudents(taskId: String, studentIds: [String]) async throws {
        let assignees = studentIds.map { studentId in
            ["task_id": taskId, "student_id": studentId]
        }
        
        _ = try await client
            .from("task_assignees")
            .insert(assignees)
            .execute()
    }
    
    func fetchTaskAssignees(taskId: String) async throws -> [TaskAssigneeRow] {
        let assignees: [TaskAssigneeRow] = try await client
            .from("task_assignees")
            .select()
            .eq("task_id", value: taskId)
            .execute()
            .value
        
        return assignees
    }
    
    func fetchAssigneeNamesForTask(taskId: String) async throws -> [String] {
        struct AssigneeWithName: Codable {
            let student_id: String
            let people: PersonName?
            
            struct PersonName: Codable {
                let full_name: String
            }
        }
        
        let result: [AssigneeWithName] = try await client
            .from("task_assignees")
            .select("student_id, people!inner(full_name)")
            .eq("task_id", value: taskId)
            .execute()
            .value
        
        return result.compactMap { $0.people?.full_name }
    }
    
    // MARK: - Task Attachments
    
    func fetchTaskAttachments(taskId: String) async throws -> [TaskAttachmentRow] {
        let attachments: [TaskAttachmentRow] = try await client
            .from("task_attachments")
            .select()
            .eq("task_id", value: taskId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return attachments
    }
    
    func fetchTaskAttachment(attachmentId: String) async throws -> TaskAttachmentRow? {
        let attachments: [TaskAttachmentRow] = try await client
            .from("task_attachments")
            .select()
            .eq("id", value: attachmentId)
            .limit(1)
            .execute()
            .value
        
        return attachments.first
    }
    
    func deleteTaskAttachment(attachmentId: String) async throws {
        _ = try await client
            .from("task_attachments")
            .delete()
            .eq("id", value: attachmentId)
            .execute()
    }
    
    func deleteAllTaskAttachments(taskId: String) async throws {
        _ = try await client
            .from("task_attachments")
            .delete()
            .eq("task_id", value: taskId)
            .execute()
    }
    
    // MARK: - Helper Functions
    
    func fetchTaskWithAssigneeName(taskId: String) async throws -> (task: TaskRow, assigneeName: String) {
        let task = try await fetchTask(taskId: taskId)
        guard let task = task else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Task not found"])
        }
        
        let assigneeNames = try await fetchAssigneeNamesForTask(taskId: taskId)
        
        let assigneeName: String
        if assigneeNames.isEmpty {
            assigneeName = "Team Task"
        } else if assigneeNames.count == 1 {
            assigneeName = assigneeNames[0]
        } else {
            assigneeName = "All Members"
        }
        
        return (task, assigneeName)
    }
    
    // MARK: - Student/Team Helpers
    
    /// Fetch student ID by name for a specific team
    func getStudentIdByName(teamId: String, studentName: String) async throws -> String? {
        print("🔍 Looking for student: '\(studentName)' in team: \(teamId)")
        
        struct TeamMemberWithName: Codable {
            let member_id: String
            let people: PersonInfo?
            
            struct PersonInfo: Codable {
                let full_name: String
            }
        }
        
        let members: [TeamMemberWithName] = try await client
            .from("team_members")
            .select("member_id, people!inner(full_name)")
            .eq("team_id", value: teamId)
            .execute()
            .value
        
        print("📋 Found \(members.count) team members")
        
        // Find the member with matching name
        for member in members {
            if let name = member.people?.full_name {
                print("   - \(name) (\(member.member_id))")
                if name == studentName {
                    print("✅ Match found: \(member.member_id)")
                    return member.member_id
                }
            }
        }
        
        print("⚠️ No match found for: \(studentName)")
        return nil
    }
    
    /// Fetch student names for a team (excludes mentors and "Team Task")
    func getStudentNamesInTeam(teamId: String) async throws -> [String] {
        print("🔍 Fetching student names for team: \(teamId)")
        
        struct TeamMemberWithName: Codable {
            let member_id: String
            let people: PersonInfo?
            
            struct PersonInfo: Codable {
                let full_name: String
                let role: String
            }
        }
        
        let members: [TeamMemberWithName] = try await client
            .from("team_members")
            .select("member_id, people!inner(full_name, role)")
            .eq("team_id", value: teamId)
            .execute()
            .value
        
        // Filter to only include students (not mentors)
        let names = members.compactMap { member -> String? in
            guard let person = member.people,
                  person.role == "student",
                  person.full_name != "Team Task" else {
                return nil
            }
            return person.full_name
        }
        
        print("✅ Found \(names.count) students: \(names)")
        
        return names
    }
    
    // MARK: - Base64 Image Conversion Helpers
    
    /// Convert UIImage to Base64 string with size limit
    private func convertImageToBase64(image: UIImage, maxSizeKB: Int = 500) -> String? {
        // Try JPEG compression first
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        // Reduce quality if image is too large
        while let data = imageData, data.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        guard let data = imageData else { return nil }
        return data.base64EncodedString()
    }
    
    /// Convert Base64 string to UIImage
    private func convertBase64ToImage(base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    /// Detect file type from filename (renamed to avoid conflicts)
    private func detectTaskFileType(filename: String) -> String {
        // Check if it's a URL first
        if filename.hasPrefix("http://") || filename.hasPrefix("https://") {
            return "link"
        }
        
        let ext = (filename as NSString).pathExtension.lowercased()
        
        switch ext {
        case "jpg", "jpeg":
            return "image/jpeg"
        case "png":
            return "image/png"
        case "gif":
            return "image/gif"
        case "pdf":
            return "application/pdf"
        case "doc", "docx":
            return "application/msword"
        default:
            return "image/jpeg" // Default to JPEG
        }
    }
    
    /// Create a placeholder image for links (renamed to avoid conflicts)
    private func createTaskLinkPlaceholder() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            // Background
            UIColor.systemBlue.withAlphaComponent(0.1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // Link icon
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            let linkIcon = UIImage(systemName: "link", withConfiguration: iconConfig)
            linkIcon?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: 30, y: 30, width: 40, height: 40))
        }
        
        return image
    }
}
