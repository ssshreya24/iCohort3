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

// MARK: - Student Profile Extension

extension SupabaseManager {
    
    // MARK: - Nested Types (outside actor context)
    
    struct StudentProfile: Codable, Sendable {
        let id: String?
        let person_id: String
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool?
        let created_at: String?
        let updated_at: String?
    }
    
    struct StudentProfileComplete: Codable, Sendable {
        let id: String
        let person_id: String
        let full_name: String?
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool
        let team_no: Int?
        let team_id: String?
        let mentor_name: String?
        let created_at: String?
        let updated_at: String?
    }
    
    struct StudentProfileUpdate: Encodable, Sendable {
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let personal_mail: String?
        let contact_number: String?
    }
    
    struct StudentProfileUpsert: Encodable, Sendable {
        let person_id: String
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let personal_mail: String?
        let contact_number: String?
        let is_profile_complete: Bool
    }
    
    struct AdminStudentOverview: Codable, Sendable {
        let person_id: String
        let full_name: String?
        let role: String
        let profile_id: String?
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let is_profile_complete: Bool?
        let team_no: Int?
        let last_profile_update: String?
        let registration_date: String?
    }
    
    struct PersonDetailRow: Codable, Sendable {
        let id: String
        let full_name: String
        let role: String
        let created_at: String?
    }
    
    // MARK: - Fetch Student Profile
    
    /// Fetch complete profile for a student by person_id
    func fetchStudentProfile(personId: String) async throws -> StudentProfileComplete? {
        let response: [StudentProfileComplete] = try await client
            .from("student_profile_complete")
            .select()
            .eq("person_id", value: personId)
            .execute()
            .value
        
        return response.first
    }
    
    /// Fetch basic profile from student_profiles table
    func fetchBasicStudentProfile(personId: String) async throws -> StudentProfile? {
        let response: [StudentProfile] = try await client
            .from("student_profiles")
            .select()
            .eq("person_id", value: personId)
            .execute()
            .value
        
        return response.first
    }
    
    // MARK: - Create/Update Student Profile
    
    /// Create or update student profile (upsert)
    func upsertStudentProfile(
        personId: String,
        firstName: String? = nil,
        lastName: String? = nil,
        department: String? = nil,
        srmMail: String? = nil,
        regNo: String? = nil,
        personalMail: String? = nil,
        contactNumber: String? = nil
    ) async throws -> String {
        // Check if profile is complete
        let isComplete = firstName != nil && !firstName!.isEmpty &&
                        lastName != nil && !lastName!.isEmpty &&
                        department != nil && !department!.isEmpty &&
                        srmMail != nil && !srmMail!.isEmpty &&
                        regNo != nil && !regNo!.isEmpty
        
        // Create the payload
        let payload = StudentProfileUpsert(
            person_id: personId,
            first_name: firstName,
            last_name: lastName,
            department: department,
            srm_mail: srmMail,
            reg_no: regNo,
            personal_mail: personalMail,
            contact_number: contactNumber,
            is_profile_complete: isComplete
        )
        
        // Upsert response
        struct UpsertResponse: Codable {
            let id: String
        }
        
        let response: [UpsertResponse] = try await client
            .from("student_profiles")
            .upsert(payload, onConflict: "person_id")
            .select("id")
            .execute()
            .value
        
        guard let profileId = response.first?.id else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to upsert profile"])
        }
        
        return profileId
    }
    
    // MARK: - Get Student Greeting
    
    /// Get personalized greeting for student
    func getStudentGreeting(personId: String) async throws -> String {
        // Use dictionary to avoid Sendable/actor isolation issues
        let params: [String: String] = ["p_person_id": personId]
        
        let result: String = try await client
            .rpc("get_student_greeting", params: params)
            .execute()
            .value
        
        return result
    }
    
    // MARK: - Assign Student to Team 9
    
    /// Assign a student to Team 9
    func assignStudentToTeam9(studentPersonId: String) async throws {
        // First, get Team 9's ID
        struct TeamRow: Codable {
            let id: String
        }
        
        let teams: [TeamRow] = try await client
            .from("teams")
            .select("id")
            .eq("team_no", value: 9)
            .execute()
            .value
        
        guard let teamId = teams.first?.id else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Team 9 not found"])
        }
        
        // Check if student is already in Team 9
        struct MemberCheck: Codable {
            let team_id: String
            let member_id: String
        }
        
        let existing: [MemberCheck] = try await client
            .from("team_members")
            .select()
            .eq("team_id", value: teamId)
            .eq("member_id", value: studentPersonId)
            .execute()
            .value
        
        if existing.isEmpty {
            // Add student to Team 9
            let member: [String: String] = [
                "team_id": teamId,
                "member_id": studentPersonId
            ]
            
            _ = try await client
                .from("team_members")
                .insert(member)
                .execute()
        }
    }
    
    // MARK: - Admin Functions
    
    /// Fetch all students for admin view
    func fetchAllStudentsForAdmin() async throws -> [AdminStudentOverview] {
        let students: [AdminStudentOverview] = try await client
            .from("admin_student_overview")
            .select()
            .execute()
            .value
        
        return students
    }
    
    /// Admin: Update any student profile
    func adminUpdateStudentProfile(
        profileId: String,
        adminId: String,
        update: StudentProfileUpdate
    ) async throws {
        // Update the profile
        _ = try await client
            .from("student_profiles")
            .update(update)
            .eq("id", value: profileId)
            .execute()
        
        // Log admin action
        struct AdminLog: Encodable {
            let student_profile_id: String
            let admin_id: String
            let action: String
            let changes: [String: String?]
        }
        
        let changes: [String: String?] = [
            "first_name": update.first_name,
            "last_name": update.last_name,
            "department": update.department,
            "srm_mail": update.srm_mail,
            "reg_no": update.reg_no,
            "personal_mail": update.personal_mail,
            "contact_number": update.contact_number
        ]
        
        let log = AdminLog(
            student_profile_id: profileId,
            admin_id: adminId,
            action: "updated",
            changes: changes
        )
        
        _ = try await client
            .from("profile_admin_logs")
            .insert(log)
            .execute()
    }
    
    /// Admin: Delete student profile
    func adminDeleteStudentProfile(profileId: String, adminId: String) async throws {
        // Log deletion
        struct AdminLog: Encodable {
            let student_profile_id: String
            let admin_id: String
            let action: String
        }
        
        let log = AdminLog(
            student_profile_id: profileId,
            admin_id: adminId,
            action: "deleted"
        )
        
        _ = try await client
            .from("profile_admin_logs")
            .insert(log)
            .execute()
        
        // Delete profile
        _ = try await client
            .from("student_profiles")
            .delete()
            .eq("id", value: profileId)
            .execute()
    }
    
    // MARK: - Check Profile Completion
    
    /// Check if student profile is complete
    func isStudentProfileComplete(personId: String) async throws -> Bool {
        let profile = try await fetchBasicStudentProfile(personId: personId)
        return profile?.is_profile_complete ?? false
    }
    
    // MARK: - Fetch Student ID
    
    /// Fetch student's person_id from database (useful for lookups)
    func fetchStudentId(srmMail: String) async throws -> String? {
        struct PersonRow: Codable {
            let id: String
        }
        
        let profiles: [StudentProfile] = try await client
            .from("student_profiles")
            .select()
            .eq("srm_mail", value: srmMail)
            .limit(1)
            .execute()
            .value
        
        return profiles.first?.person_id
    }
    
    /// Fetch student's person_id by registration number
    func fetchStudentId(regNo: String) async throws -> String? {
        let profiles: [StudentProfile] = try await client
            .from("student_profiles")
            .select()
            .eq("reg_no", value: regNo)
            .limit(1)
            .execute()
            .value
        
        return profiles.first?.person_id
    }
    
    /// Fetch student's person_id by name within a specific team
    func fetchStudentId(teamId: String, studentName: String) async throws -> String? {
        struct MemberWithProfile: Codable {
            let member_id: String
            let people: PersonInfo?
            
            struct PersonInfo: Codable {
                let full_name: String
            }
        }
        
        let members: [MemberWithProfile] = try await client
            .from("team_members")
            .select("member_id, people!inner(full_name)")
            .eq("team_id", value: teamId)
            .execute()
            .value
        
        // Find the member with matching name
        for member in members {
            if member.people?.full_name == studentName {
                return member.member_id
            }
        }
        
        return nil
    }
    
    /// Get current logged-in student's person_id from UserDefaults
    func getCurrentStudentId() -> String? {
        return UserDefaults.standard.string(forKey: "current_person_id")
    }
    
    /// Fetch person details by ID
    func fetchPerson(personId: String) async throws -> PersonDetailRow? {
        let persons: [PersonDetailRow] = try await client
            .from("people")
            .select()
            .eq("id", value: personId)
            .limit(1)
            .execute()
            .value
        
        return persons.first
    }
}

// MARK: - Team Management Extension

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

// MARK: - Team Student Names Extension

extension SupabaseManager {
    struct TeamStudentNameRow: Decodable, Sendable {
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
        let file_url: String?
        let file_type: String?
        let created_at: String?
    }
    
    struct TaskAttachmentInsert: Encodable, Sendable {
        let task_id: String
        let filename: String
        let file_url: String?
        let file_type: String?
    }
    
    // MARK: - Create Task
    
    /// Create a new task with full attachment and assignee support
    func createTask(
        teamId: String,
        mentorId: String,
        title: String,
        description: String?,
        status: String = "assigned",
        assignedDate: Date = Date(),
        assignToAll: Bool = true,
        specificStudentId: String? = nil,
        attachments: [UIImage] = []
    ) async throws -> String {
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
        
        // Assign to students
        if assignToAll {
            // Get all team members and assign to them
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
            }
        } else if let studentId = specificStudentId {
            // Assign to specific student
            try await assignTaskToStudents(taskId: taskId, studentIds: [studentId])
        }
        
        // Upload attachments if any
        if !attachments.isEmpty {
            try await uploadTaskAttachments(taskId: taskId, images: attachments)
        }
        
        return taskId
    }
    
    /// Original simple create task (for backwards compatibility)
    func createTaskSimple(
        teamId: String,
        mentorId: String,
        title: String,
        description: String?,
        status: String = "assigned",
        assignedDate: Date = Date()
    ) async throws -> TaskRow {
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
        
        return response
    }
    
    // MARK: - Fetch Tasks
    
    /// Fetch all tasks for a team
    func fetchTasksForTeam(teamId: String) async throws -> [TaskRow] {
        let tasks: [TaskRow] = try await client
            .from("tasks")
            .select()
            .eq("team_id", value: teamId)
            .order("assigned_date", ascending: false)
            .execute()
            .value
        
        return tasks
    }
    
    /// Fetch tasks by status for a team
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
    
    /// Fetch a single task by ID
    func fetchTask(taskId: String) async throws -> TaskRow? {
        let tasks: [TaskRow] = try await client
            .from("tasks")
            .select()
            .eq("id", value: taskId)
            .execute()
            .value
        
        return tasks.first
    }
    
    /// Fetch tasks assigned to a specific student
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
    
    /// Fetch tasks for student by status
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
    
    // MARK: - Update Task
    
    /// Update task with full attachment and assignee support
    func updateTask(
        taskId: String,
        title: String? = nil,
        description: String? = nil,
        status: String? = nil,
        remark: String? = nil,
        remarkDescription: String? = nil,
        assignedDate: Date? = nil,
        attachments: [UIImage]? = nil,
        updateAssignees: Bool = false,
        assignToAll: Bool = false,
        teamId: String? = nil,
        specificStudentId: String? = nil
    ) async throws {
        // Update basic task info
        let formatter = ISO8601DateFormatter()
        
        var updateDict: [String: Any?] = [:]
        if let title = title { updateDict["title"] = title }
        if let description = description { updateDict["description"] = description }
        if let status = status { updateDict["status"] = status }
        if let remark = remark { updateDict["remark"] = remark }
        if let remarkDescription = remarkDescription { updateDict["remark_description"] = remarkDescription }
        if let assignedDate = assignedDate {
            updateDict["assigned_date"] = formatter.string(from: assignedDate)
        }
        
        if !updateDict.isEmpty {
            let update = TaskUpdate(
                title: title,
                description: description,
                status: status,
                remark: remark,
                remark_description: remarkDescription
            )
            
            _ = try await client
                .from("tasks")
                .update(update)
                .eq("id", value: taskId)
                .execute()
        }
        
        // Update assignees if requested
        if updateAssignees {
            // First, delete existing assignees
            _ = try await client
                .from("task_assignees")
                .delete()
                .eq("task_id", value: taskId)
                .execute()
            
            // Then add new assignees
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
                }
            } else if let studentId = specificStudentId {
                try await assignTaskToStudents(taskId: taskId, studentIds: [studentId])
            }
        }
        
        // Upload new attachments if provided
        if let attachments = attachments, !attachments.isEmpty {
            try await uploadTaskAttachments(taskId: taskId, images: attachments)
        }
    }
    
    /// Simple update (original version for backwards compatibility)
    func updateTaskSimple(
        taskId: String,
        title: String? = nil,
        description: String? = nil,
        status: String? = nil,
        remark: String? = nil,
        remarkDescription: String? = nil
    ) async throws {
        let update = TaskUpdate(
            title: title,
            description: description,
            status: status,
            remark: remark,
            remark_description: remarkDescription
        )
        
        _ = try await client
            .from("tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()
    }
    
    /// Update task status
    func updateTaskStatus(taskId: String, status: String) async throws {
        let update = TaskUpdate(
            title: nil,
            description: nil,
            status: status,
            remark: nil,
            remark_description: nil
        )
        
        _ = try await client
            .from("tasks")
            .update(update)
            .eq("id", value: taskId)
            .execute()
    }
    
    // MARK: - Delete Task
    
    /// Delete a task
    func deleteTask(taskId: String) async throws {
        _ = try await client
            .from("tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()
    }
    
    // MARK: - Task Assignees
    
    /// Assign task to specific students
    func assignTaskToStudents(taskId: String, studentIds: [String]) async throws {
        let assignees = studentIds.map { studentId in
            ["task_id": taskId, "student_id": studentId]
        }
        
        _ = try await client
            .from("task_assignees")
            .insert(assignees)
            .execute()
    }
    
    /// Fetch assignees for a task
    func fetchTaskAssignees(taskId: String) async throws -> [TaskAssigneeRow] {
        let assignees: [TaskAssigneeRow] = try await client
            .from("task_assignees")
            .select()
            .eq("task_id", value: taskId)
            .execute()
            .value
        
        return assignees
    }
    
    /// Get student names for task assignees
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
    
    /// Upload task attachments to Supabase Storage and save metadata
    private func uploadTaskAttachments(taskId: String, images: [UIImage]) async throws {
        for (index, image) in images.enumerated() {
            // Convert image to JPEG data
            guard let imageData = image.jpegData(compressionQuality: 0.8) else {
                print("⚠️ Failed to convert image \(index) to data")
                continue
            }
            
            // Generate unique filename
            let timestamp = Int(Date().timeIntervalSince1970)
            let filename = "task_\(taskId)_\(timestamp)_\(index).jpg"
            let filePath = "\(taskId)/\(filename)"
            
            do {
                // Upload to Supabase Storage
                _ = try await client.storage
                    .from("task-attachments")
                    .upload(
                        path: filePath,
                        file: imageData,
                        options: .init(contentType: "image/jpeg")
                    )
                
                // Get public URL
                let publicURL = try client.storage
                    .from("task-attachments")
                    .getPublicURL(path: filePath)
                
                // Save metadata to database
                _ = try await addTaskAttachment(
                    taskId: taskId,
                    filename: filename,
                    fileUrl: publicURL.absoluteString,
                    fileType: "image/jpeg"
                )
                
                print("✅ Uploaded attachment: \(filename)")
            } catch {
                print("❌ Failed to upload attachment \(index): \(error)")
                // Continue with other attachments even if one fails
            }
        }
    }
    
    /// Download attachment images from URLs
    func downloadTaskAttachmentImages(taskId: String) async throws -> [UIImage] {
        let attachments = try await fetchTaskAttachments(taskId: taskId)
        var images: [UIImage] = []
        
        for attachment in attachments {
            guard let urlString = attachment.file_url,
                  let url = URL(string: urlString) else {
                continue
            }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    images.append(image)
                }
            } catch {
                print("⚠️ Failed to download attachment: \(error)")
            }
        }
        
        return images
    }
    
    /// Add attachment metadata to task
    func addTaskAttachment(
        taskId: String,
        filename: String,
        fileUrl: String?,
        fileType: String?
    ) async throws -> TaskAttachmentRow {
        let attachment = TaskAttachmentInsert(
            task_id: taskId,
            filename: filename,
            file_url: fileUrl,
            file_type: fileType
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
    
    /// Fetch attachments for a task
    func fetchTaskAttachments(taskId: String) async throws -> [TaskAttachmentRow] {
        let attachments: [TaskAttachmentRow] = try await client
            .from("task_attachments")
            .select()
            .eq("task_id", value: taskId)
            .execute()
            .value
        
        return attachments
    }
    
    /// Delete attachment
    func deleteTaskAttachment(attachmentId: String) async throws {
        _ = try await client
            .from("task_attachments")
            .delete()
            .eq("id", value: attachmentId)
            .execute()
    }
    
    // MARK: - Helper Functions
    
    /// Create task and assign to all team members (backwards compatibility)
    func createTaskForWholeTeam(
        teamId: String,
        mentorId: String,
        title: String,
        description: String?,
        assignedDate: Date = Date()
    ) async throws -> TaskRow {
        let formatter = ISO8601DateFormatter()
        
        let task = TaskInsert(
            team_id: teamId,
            mentor_id: mentorId,
            title: title,
            description: description,
            status: "assigned",
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
        
        // Get all team members
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
        
        // Assign to all members
        if !studentIds.isEmpty {
            try await assignTaskToStudents(taskId: taskId, studentIds: studentIds)
        }
        
        return response
    }
    
    /// Fetch task with assignee name
    func fetchTaskWithAssigneeName(taskId: String) async throws -> (task: TaskRow, assigneeName: String) {
        let task = try await fetchTask(taskId: taskId)
        guard let task = task else {
            throw NSError(domain: "SupabaseManager", code: -1,
                         userInfo: [NSLocalizedDescriptionKey: "Task not found"])
        }
        
        // Get assignee names
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
}
