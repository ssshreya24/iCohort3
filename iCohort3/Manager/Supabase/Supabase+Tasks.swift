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
        
        // ✅ FIXED: Assign to students using new_teams (not team_members)
        if assignToAll {
            let studentIds = try await getStudentIdsFromNewTeams(teamId: teamId)
            print("📋 Found \(studentIds.count) team members from new_teams")
            
            if !studentIds.isEmpty {
                try await assignTaskToStudents(taskId: taskId, studentIds: studentIds)
                print("✅ Assigned to \(studentIds.count) students")
            } else {
                print("⚠️ No students found in new_teams for teamId: \(teamId)")
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
        
        // Sync counters for mentor dashboard
        try? await recalculateAndSyncTeamTaskCounters(teamId: teamId)
        
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
            if attachment.file_type == "link" {
                let linkImage = createTaskLinkPlaceholder()
                images.append(linkImage)
                print("✅ Loaded link placeholder: \(attachment.filename)")
                continue
            }
            
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
    
    func fetchTasksForTeam(teamId: String, status: String) async throws -> [TaskRow] {
        let tasks: [TaskRow] = try await client
            .from("tasks")
            .select()
            .eq("team_id", value: teamId)
            .eq("status", value: status)
            .order("assigned_date", ascending: false)
            .execute()
            .value
        print("✅ Fetched \(tasks.count) tasks for status: \(status)")
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
        
        // ✅ FIXED: Update assignees using new_teams (not team_members)
        if updateAssignees {
            print("🔄 Updating assignees...")
            
            _ = try await client
                .from("task_assignees")
                .delete()
                .eq("task_id", value: taskId)
                .execute()
            
            if assignToAll, let teamId = teamId {
                let studentIds = try await getStudentIdsFromNewTeams(teamId: teamId)
                print("📋 Found \(studentIds.count) members from new_teams for update")
                
                if !studentIds.isEmpty {
                    try await assignTaskToStudents(taskId: taskId, studentIds: studentIds)
                    print("✅ Assigned to \(studentIds.count) students")
                } else {
                    print("⚠️ No students found in new_teams for teamId: \(teamId)")
                }
            } else if let studentId = specificStudentId {
                try await assignTaskToStudents(taskId: taskId, studentIds: [studentId])
                print("✅ Assigned to specific student: \(studentId)")
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
        
        // Sync counters for mentor dashboard
        try? await recalculateAndSyncTeamTaskCounters(teamId: updated.team_id)
        
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
        
        var newOngoing   = r.ongoing_task
        var newForReview = r.for_review_task
        var newAssigned  = r.assigned_task
        var newPrepared  = r.prepared_task
        var newApproved  = r.approved_task
        var newCompleted = r.completed_task
        var newRejected  = r.rejected_task
        
        switch from {
        case "ongoing":    newOngoing   = dec(r.ongoing_task)
        case "for_review": newForReview = dec(r.for_review_task)
        case "assigned":   newAssigned  = dec(r.assigned_task)
        case "prepared":   newPrepared  = dec(r.prepared_task)
        case "approved":   newApproved  = dec(r.approved_task)
        case "completed":  newCompleted = dec(r.completed_task)
        case "rejected":   newRejected  = dec(r.rejected_task)
        default: break
        }
        
        switch to {
        case "ongoing":    newOngoing   = inc(newOngoing)
        case "for_review": newForReview = inc(newForReview)
        case "assigned":   newAssigned  = inc(newAssigned)
        case "prepared":   newPrepared  = inc(newPrepared)
        case "approved":   newApproved  = inc(newApproved)
        case "completed":  newCompleted = inc(newCompleted)
        case "rejected":   newRejected  = inc(newRejected)
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
        
        // Fetch task first to get teamId for counter sync
        let task = try? await fetchTask(taskId: taskId)
        let teamId = task?.team_id
        
        _ = try await client
            .from("tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()
        
        if let tid = teamId {
            try? await recalculateAndSyncTeamTaskCounters(teamId: tid)
        }
        
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
    
    // MARK: - Fetch Tasks for a Specific Student in a Team
        
        /// Fetches tasks assigned to a specific student (by person_id UUID)
        /// that belong to the given team, filtered by status.
        /// This is what the student dashboard uses.
        func fetchTasksForStudentInTeam(
            studentId: String,
            teamId: String,
            status: String
        ) async throws -> [TaskRow] {
            print("🔍 fetchTasksForStudentInTeam: student=\(studentId) team=\(teamId) status=\(status)")

            // Step 1: Get all task_ids assigned to this student
            let assignees: [TaskAssigneeRow] = try await client
                .from("task_assignees")
                .select()
                .eq("student_id", value: studentId)
                .execute()
                .value

            print("📋 Found \(assignees.count) total assignments for student")
            guard !assignees.isEmpty else { return [] }

            let taskIds = assignees.map { $0.task_id }

            // Step 2: Fetch tasks matching those IDs, filtered by team + status
            let tasks: [TaskRow] = try await client
                .from("tasks")
                .select()
                .in("id", values: taskIds)
                .eq("team_id", value: teamId)
                .eq("status", value: status)
                .order("assigned_date", ascending: false)
                .execute()
                .value

            print("✅ Found \(tasks.count) tasks for student in team with status '\(status)'")
            return tasks
        }

        /// All statuses for a student in a team (for full dashboard)
        func fetchAllTasksForStudentInTeam(
            studentId: String,
            teamId: String
        ) async throws -> [TaskRow] {
            print("🔍 fetchAllTasksForStudentInTeam: student=\(studentId) team=\(teamId)")

            let assignees: [TaskAssigneeRow] = try await client
                .from("task_assignees")
                .select()
                .eq("student_id", value: studentId)
                .execute()
                .value

            guard !assignees.isEmpty else { return [] }

            let taskIds = assignees.map { $0.task_id }

            let tasks: [TaskRow] = try await client
                .from("tasks")
                .select()
                .in("id", values: taskIds)
                .eq("team_id", value: teamId)
                .order("assigned_date", ascending: false)
                .execute()
                .value

            print("✅ Found \(tasks.count) total tasks for student in team")
            return tasks
        }
    
    // MARK: - Resolve Assignee Name from new_teams (KEY FIX)
    
    /// Resolves the display name for a task by matching task_assignees IDs
    /// against new_teams columns directly — bypasses the broken people table join.
    func resolveAssigneeNameFromNewTeams(taskId: String, teamId: String) async throws -> String {
        
        // Step 1: Get assignee IDs stored in task_assignees
        let assignees = try await fetchTaskAssignees(taskId: taskId)
        
        guard !assignees.isEmpty else {
            print("⚠️ No assignees found for task \(taskId) → showing 'Team Task'")
            return "Team Task"
        }
        
        let assigneeIds = Set(assignees.map { $0.student_id })
        
        // Step 2: Fetch the new_teams row for this team
        struct NewTeamFull: Decodable {
            let id: String
            let createdById: String
            let createdByName: String
            let member2Id: String?
            let member2Name: String?
            let member3Id: String?
            let member3Name: String?
            
            enum CodingKeys: String, CodingKey {
                case id
                case createdById   = "created_by_id"
                case createdByName = "created_by_name"
                case member2Id     = "member2_id"
                case member2Name   = "member2_name"
                case member3Id     = "member3_id"
                case member3Name   = "member3_name"
            }
        }
        
        let rows: [NewTeamFull] = try await client
            .from("new_teams")
            .select("id, created_by_id, created_by_name, member2_id, member2_name, member3_id, member3_name")
            .execute()
            .value
        
        guard let team = rows.first(where: { $0.id == teamId }) else {
            print("⚠️ No new_teams row found for teamId: \(teamId)")
            return "Team Task"
        }
        
        // Step 3: Build id → name map from new_teams columns
        var idToName: [String: String] = [:]
        idToName[team.createdById] = team.createdByName
        if let id = team.member2Id, let name = team.member2Name, !id.isEmpty { idToName[id] = name }
        if let id = team.member3Id, let name = team.member3Name, !id.isEmpty { idToName[id] = name }
        
        let totalMembers = idToName.count
        
        // Step 4: Match assignee IDs to names
        let matchedNames = assigneeIds.compactMap { idToName[$0] }
        
        print("🔍 Task \(taskId): assigneeIds=\(assigneeIds), matched=\(matchedNames), totalMembers=\(totalMembers)")
        
        if matchedNames.count == totalMembers && totalMembers > 1 {
            return "All Members"
        } else if matchedNames.count == 1 {
            return matchedNames[0]
        } else if matchedNames.count > 1 {
            return matchedNames.sorted().joined(separator: ", ")
        }
        
        // Fallback: if IDs don't match names (e.g. all members assigned but IDs differ)
        if assigneeIds.count == totalMembers {
            return "All Members"
        }
        
        return "Team Task"
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
        
        let assigneeName = try await resolveAssigneeNameFromNewTeams(
            taskId: taskId,
            teamId: task.team_id
        )
        
        return (task, assigneeName)
    }
    
    // MARK: - Student/Team Helpers
    
    /// Get all student IDs directly from new_teams columns
    func getStudentIdsFromNewTeams(teamId: String) async throws -> [String] {
        print("🔍 Fetching student IDs from new_teams for teamId: \(teamId)")

        struct NewTeamIds: Decodable {
            let id: String
            let createdById: String
            let member2Id: String?
            let member3Id: String?

            enum CodingKeys: String, CodingKey {
                case id
                case createdById = "created_by_id"
                case member2Id   = "member2_id"
                case member3Id   = "member3_id"
            }
        }

        let rows: [NewTeamIds] = try await client
            .from("new_teams")
            .select("id, created_by_id, member2_id, member3_id")
            .execute()
            .value

        guard let team = rows.first(where: { $0.id == teamId }) else {
            print("⚠️ No new_teams row found for id: \(teamId)")
            return []
        }

        let ids = [team.createdById, team.member2Id, team.member3Id]
            .compactMap { $0 }
            .filter { !$0.isEmpty }

        print("✅ Found student IDs: \(ids)")
        return ids
    }

    /// Fetch student ID by name for a specific team
    func getStudentIdByName(teamId: String, studentName: String) async throws -> String? {
        print("🔍 Looking for student: '\(studentName)' in new_teams teamId: \(teamId)")

        struct NewTeamRowMini: Decodable {
            let id: String
            let createdById: String
            let createdByName: String
            let member2Id: String?
            let member2Name: String?
            let member3Id: String?
            let member3Name: String?

            enum CodingKeys: String, CodingKey {
                case id
                case createdById   = "created_by_id"
                case createdByName = "created_by_name"
                case member2Id     = "member2_id"
                case member2Name   = "member2_name"
                case member3Id     = "member3_id"
                case member3Name   = "member3_name"
            }
        }

        let rows: [NewTeamRowMini] = try await client
            .from("new_teams")
            .select("id, created_by_id, created_by_name, member2_id, member2_name, member3_id, member3_name")
            .execute()
            .value

        guard let team = rows.first(where: { $0.id == teamId }) else {
            print("⚠️ No new_teams row found for id: \(teamId)")
            return nil
        }

        let target = normalizeName(studentName)

        let candidates: [(name: String, id: String)] = [
            (team.createdByName, team.createdById),
            (team.member2Name ?? "", team.member2Id ?? ""),
            (team.member3Name ?? "", team.member3Id ?? "")
        ].filter { !$0.name.isEmpty && !$0.id.isEmpty }

        print("📋 Candidates in team:")
        candidates.forEach { print("   - \($0.name) (\($0.id))") }

        if let match = candidates.first(where: { normalizeName($0.name) == target }) {
            print("✅ Match found: \(match.id)")
            return match.id
        }

        if let match = candidates.first(where: {
            normalizeName($0.name).contains(target) || target.contains(normalizeName($0.name))
        }) {
            print("✅ Loose match found: \(match.id)")
            return match.id
        }

        print("⚠️ No match found for: \(studentName)")
        return nil
    }

    private func normalizeName(_ s: String) -> String {
        s.trimmingCharacters(in: .whitespacesAndNewlines)
         .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
         .lowercased()
    }

    /// Fetch student names for a team
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
        
        let names = members.compactMap { member -> String? in
            guard let person = member.people,
                  person.role == "student",
                  person.full_name != "Team Task" else { return nil }
            return person.full_name
        }
        
        print("✅ Found \(names.count) students: \(names)")
        return names
    }
    
    // MARK: - Base64 Image Conversion Helpers
    
    private func convertImageToBase64(image: UIImage, maxSizeKB: Int = 500) -> String? {
        var compression: CGFloat = 0.8
        var imageData = image.jpegData(compressionQuality: compression)
        
        while let data = imageData, data.count > maxSizeKB * 1024 && compression > 0.1 {
            compression -= 0.1
            imageData = image.jpegData(compressionQuality: compression)
        }
        
        guard let data = imageData else { return nil }
        return data.base64EncodedString()
    }
    
    private func convertBase64ToImage(base64String: String) -> UIImage? {
        guard let imageData = Data(base64Encoded: base64String) else { return nil }
        return UIImage(data: imageData)
    }
    
    private func detectTaskFileType(filename: String) -> String {
        if filename.hasPrefix("http://") || filename.hasPrefix("https://") { return "link" }
        
        let ext = (filename as NSString).pathExtension.lowercased()
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png":         return "image/png"
        case "gif":         return "image/gif"
        case "pdf":         return "application/pdf"
        case "doc", "docx": return "application/msword"
        default:            return "image/jpeg"
        }
    }
    
    private func createTaskLinkPlaceholder() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.systemBlue.withAlphaComponent(0.1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            let linkIcon = UIImage(systemName: "link", withConfiguration: iconConfig)
            linkIcon?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
                .draw(in: CGRect(x: 30, y: 30, width: 40, height: 40))
        }
    }
}
