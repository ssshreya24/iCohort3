//
//  StudentAllTasksViewController.swift
//  iCohort3
//
//  ✅ FIXED:
//    - task_attachments.team_id is always nil — FK references old `teams` table not `new_teams`
//    - Attachments base64-encoded before Supabase insert (plain INSERT, no upsert)
//    - didAssignTask / didUpdateTask both call fixed saveAttachments helper
//

import UIKit
import Supabase
import PostgREST

enum TaskSectionWrapper {
    case teamProfile
    case category(TaskCategory)
}

final class StudentAllTasksViewController: UIViewController {

    @IBOutlet weak var verticalCollectionView: UICollectionView!
    @IBOutlet weak var teamTitleLabel:          UILabel!
    @IBOutlet weak var backButton:              UIButton!
    @IBOutlet weak var addButton:               UIButton!

    var teamId:   String = ""
    var teamNo:   Int    = 0
    var teamName: String?

    var currentMentorId: String = ""

    private var teamMemberNames:  [String]   = []
    private var teamMemberImages: [UIImage]  = []

    private var assignedTasks:  [TaskModel] = []
    private var ongoingTasks:   [TaskModel] = []
    private var reviewTasks:    [TaskModel] = []
    private var completedTasks: [TaskModel] = []
    private var rejectedTasks:  [TaskModel] = []

    private let items: [TaskSectionWrapper] = [
        .teamProfile,
        .category(.assigned),
        .category(.review),
        .category(.completed),
        .category(.rejected)
    ]

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        if let mid = UserDefaults.standard.string(forKey: "current_person_id"), !mid.isEmpty {
            currentMentorId = mid
        }

        setupUI()
        setupCollectionView()
        setupTitle()

        Task {
            await loadTeamMembersFromNewTeams()
            await loadTasksFromSupabase()
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        [backButton, addButton].forEach { btn in
            guard let btn else { return }
            btn.layer.cornerRadius  = btn.frame.height / 2
            btn.backgroundColor     = .white
            btn.clipsToBounds       = true
            btn.layer.shadowColor   = UIColor.black.cgColor
            btn.layer.shadowOffset  = CGSize(width: 0, height: 2)
            btn.layer.shadowRadius  = 4
            btn.layer.shadowOpacity = 0.1
        }

        let bg = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        verticalCollectionView.backgroundColor = bg
        view.backgroundColor = bg
    }

    private func setupCollectionView() {
        verticalCollectionView.delegate   = self
        verticalCollectionView.dataSource = self

        verticalCollectionView.register(
            UINib(nibName: "TeamProfileRowCell", bundle: nil),
            forCellWithReuseIdentifier: "TeamProfileRowCell"
        )
        verticalCollectionView.register(
            UINib(nibName: "TaskSectionCell", bundle: nil),
            forCellWithReuseIdentifier: "TaskSectionCell"
        )
    }

    private func setupTitle() {
        if !teamId.isEmpty {
            let title = "Team \(teamNo)"
            teamTitleLabel.text = title
            self.title = title
        } else if let teamName {
            teamTitleLabel.text = teamName
            self.title = teamName
        } else {
            teamTitleLabel.text = "Team"
            self.title = "Team"
        }
    }

    // MARK: - Load Members

    private func loadTeamMembersFromNewTeams() async {
        guard !teamId.isEmpty else { return }
        do {
            let names   = try await SupabaseManager.shared.fetchMemberNamesFromNewTeams(teamId: teamId)
            let avatars = names.map { Self.makeInitialAvatar(from: $0, size: CGSize(width: 44, height: 44)) }
            await MainActor.run {
                self.teamMemberNames  = names
                self.teamMemberImages = avatars
                self.verticalCollectionView.reloadData()
            }
        } catch {
            print("❌ loadTeamMembersFromNewTeams:", error)
        }
    }

    // MARK: - Load Tasks

    private func loadTasksFromSupabase() async {
        guard !teamId.isEmpty else { return }
        do {
            async let assignedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "assigned")
            async let ongoingRows   = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "ongoing")
            async let reviewRows    = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "for_review")
            async let completedRows = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "completed")
            async let rejectedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "rejected")

            let (aData, oData, rData, cData, xData) = try await
                (assignedRows, ongoingRows, reviewRows, completedRows, rejectedRows)

            let assigned  = await convert(aData)
            let ongoing   = await convert(oData)
            let review    = await convert(rData)
            let completed = await convert(cData)
            let rejected  = await convert(xData)

            await MainActor.run {
                self.assignedTasks  = assigned
                self.ongoingTasks   = ongoing
                self.reviewTasks    = review
                self.completedTasks = completed
                self.rejectedTasks  = rejected
                self.verticalCollectionView.reloadData()
            }
        } catch {
            print("❌ loadTasksFromSupabase:", error)
        }
    }

    private func convert(_ rows: [SupabaseManager.TaskRow]) async -> [TaskModel] {
        await withTaskGroup(of: TaskModel.self) { group -> [TaskModel] in
            for row in rows { group.addTask { await TaskModel.from(taskRow: row) } }
            return await group.reduce(into: []) { $0.append($1) }
        }
    }

    // MARK: - Actions

    @IBAction func backButtonTapped(_ sender: Any) { dismiss(animated: true) }

    @IBAction func addButtonTapped(_ sender: Any) {
        presentNewTaskViewController(isEditMode: false)
    }

    // MARK: - Present NewTask VC

    private func presentNewTaskViewController(isEditMode: Bool,
                                              task: TaskModel? = nil,
                                              category: TaskCategory? = nil,
                                              taskIndex: Int? = nil) {
        let vc      = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)
        vc.delegate = self
        vc.teamMemberImages = teamMemberImages
        vc.teamMemberNames  = teamMemberNames
        vc.teamId           = teamId
        vc.mentorId         = currentMentorId

        if isEditMode, let task, let category, let taskIndex {
            vc.isEditMode          = true
            vc.existingTaskId      = task.id
            vc.existingTitle       = task.title
            vc.existingDescription = task.desc
            vc.existingDate        = task.assignedDate
            vc.selectedMemberName  = task.name
            vc.existingAttachments = task.attachments ?? []
            vc.editingTaskIndex    = taskIndex
            vc.editingCategory     = category
            if let fn = task.attachmentFilenames { vc.attachmentFilenames = fn }
        }

        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    // MARK: - Attachment Viewer

    private func presentAttachmentViewer(attachments: [UIImage], filenames: [String] = []) {
        let vc = AttachmentViewerViewController(attachments: attachments, attachmentFilenames: filenames)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle   = .crossDissolve
        present(vc, animated: true)
    }

    // MARK: - Helpers

    func getTasksArray(for category: TaskCategory) -> [TaskModel] {
        switch category {
        case .assigned:  return assignedTasks
        case .review:    return reviewTasks
        case .completed: return completedTasks
        case .rejected:  return rejectedTasks
        }
    }

    private func deleteTask(in category: TaskCategory, at index: Int, task: TaskModel) {
        let alert = UIAlertController(
            title: "Delete Task",
            message: "Are you sure you want to delete '\(task.title ?? "this task")'?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            Task {
                do {
                    if let id = task.id { try await SupabaseManager.shared.deleteTask(taskId: id) }
                    await self.loadTasksFromSupabase()
                    await MainActor.run {
                        let ok = UIAlertController(title: "Task Deleted",
                                                   message: "Task deleted successfully.",
                                                   preferredStyle: .alert)
                        ok.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ok, animated: true)
                    }
                } catch {
                    await MainActor.run {
                        let err = UIAlertController(title: "Error",
                                                    message: "Failed to delete task.",
                                                    preferredStyle: .alert)
                        err.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(err, animated: true)
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Save Attachments to Supabase
    //
    // ⚠️  team_id is ALWAYS nil.
    //     task_attachments.team_id has a FK → old `teams` table (not `new_teams`).
    //     Passing a new_teams UUID causes: "violates foreign key constraint
    //     task_attachments_team_id_fkey". Since the column is nullable and
    //     task_id + mentor_id fully identify the attachment, we omit team_id.

    private func saveAttachments(
        taskId:      String,
        filenames:   [String],
        images:      [UIImage]
    ) async {
        guard !filenames.isEmpty else { return }

        struct AttachmentInsert: Encodable {
            let task_id:           String
            let filename:          String
            let file_type:         String
            let file_data:         String?   // base64, nil for URLs
            let mentor_id:         String?
            let team_id:           String?   // always nil — avoids FK violation
            let student_id:        String?
            let mentor_attachment: Bool
        }

        let mentorPersonId = currentMentorId.isEmpty ? nil : currentMentorId

        for (i, filename) in filenames.enumerated() {
            let isLink = filename.hasPrefix("http://") || filename.hasPrefix("https://")

            // Encode to base64 only for real files
            var base64Data: String? = nil
            if !isLink && i < images.count {
                base64Data = images[i].jpegData(compressionQuality: 0.75)?.base64EncodedString()
            }

            let ext = (filename as NSString).pathExtension.lowercased()
            let mimeType: String = {
                if isLink { return "text/url" }
                switch ext {
                case "pdf":        return "application/pdf"
                case "jpg","jpeg": return "image/jpeg"
                case "png":        return "image/png"
                case "doc","docx": return "application/msword"
                default:           return "application/octet-stream"
                }
            }()

            let row = AttachmentInsert(
                task_id:           taskId,
                filename:          filename,
                file_type:         mimeType,
                file_data:         base64Data,
                mentor_id:         mentorPersonId,
                team_id:           nil,          // ← always nil, avoids FK violation
                student_id:        nil,
                mentor_attachment: true
            )

            do {
                try await SupabaseManager.shared.client
                    .from("task_attachments")
                    .insert(row)               // plain INSERT — no upsert needed
                    .execute()
                print("✅ Attachment saved: \(filename)")
            } catch {
                print("❌ Attachment save failed (\(filename)):", error)
            }
        }
    }

    // MARK: - Initial Avatar

    static func makeInitialAvatar(from fullName: String, size: CGSize) -> UIImage {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let first   = trimmed.components(separatedBy: .whitespacesAndNewlines).first ?? trimmed
        let letter  = String(first.prefix(1)).uppercased().isEmpty
            ? "?" : String(first.prefix(1)).uppercased()

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()
            UIColor.systemGray4.setFill()
            ctx.fill(rect)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.45, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let ts = letter.size(withAttributes: attrs)
            letter.draw(in: CGRect(x: (size.width - ts.width) / 2,
                                   y: (size.height - ts.height) / 2,
                                   width: ts.width, height: ts.height),
                        withAttributes: attrs)
        }
    }
}

// MARK: - ReviewViewControllerDelegate

extension StudentAllTasksViewController: ReviewViewControllerDelegate {
    func reviewViewController(_ vc: ReviewViewController,
                              didChangeStatusTo status: String,
                              forTaskId taskId: String) {
        Task { await loadTasksFromSupabase() }
    }
}

// MARK: - TaskSeeAllDelegate

extension StudentAllTasksViewController: TaskSeeAllDelegate {
    func didUpdateTask(in category: TaskCategory, at index: Int, with task: TaskModel) {
        Task { await loadTasksFromSupabase() }
    }
    func didDeleteTask(in category: TaskCategory, at index: Int) {
        Task { await loadTasksFromSupabase() }
    }
}

// MARK: - NewTaskDelegate

extension StudentAllTasksViewController: NewTaskDelegate {

    // MARK: Assign new task

    func didAssignTask(to memberName: String,
                       description: String,
                       date: Date,
                       title: String,
                       attachments: [UIImage],
                       attachmentFilenames: [String]) {
        Task {
            do {
                let assignToAll     = (memberName == "All Members" || memberName == "Team Task")
                var specificStudentId: String? = nil

                if !assignToAll {
                    specificStudentId = try await SupabaseManager.shared
                        .getStudentIdByName(teamId: teamId, studentName: memberName)
                    guard specificStudentId != nil else {
                        throw NSError(domain: "SATVC", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey:
                                                    "Student ID not found for \(memberName)"])
                    }
                }

                // ── 1. Create task row (no attachments passed — we save them separately) ──
                let taskId = try await createTaskRow(
                    title:            title,
                    description:      description,
                    date:             date,
                    assignToAll:      assignToAll,
                    specificStudentId: specificStudentId
                )

                // ── 2. Save attachments with team_id: nil fix ─────────────────
                await saveAttachments(
                    taskId:    taskId,
                    filenames: attachmentFilenames,
                    images:    attachments
                )

                await loadTasksFromSupabase()

                await MainActor.run {
                    let a = UIAlertController(title: "Task Assigned ✅",
                                              message: "'\(title)' assigned to \(memberName)",
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }

            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Error",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            }
        }
    }

    // MARK: Update existing task

    func didUpdateTask(at index: Int,
                       memberName: String,
                       description: String,
                       date: Date,
                       title: String,
                       attachments: [UIImage],
                       attachmentFilenames: [String]) {
        Task {
            do {
                guard let taskId = findTaskId(at: index) else {
                    throw NSError(domain: "SATVC", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Task ID not found"])
                }

                let assignToAll     = (memberName == "All Members" || memberName == "Team Task")
                var specificStudentId: String? = nil

                if !assignToAll {
                    specificStudentId = try await SupabaseManager.shared
                        .getStudentIdByName(teamId: teamId, studentName: memberName)
                    guard specificStudentId != nil else {
                        throw NSError(domain: "SATVC", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey:
                                                    "Student ID not found for \(memberName)"])
                    }
                }

                // ── 1. Update task row fields ─────────────────────────────────
                try await updateTaskRow(
                    taskId:           taskId,
                    title:            title,
                    description:      description,
                    date:             date,
                    assignToAll:      assignToAll,
                    specificStudentId: specificStudentId
                )

                // ── 2. Save any new attachments with team_id: nil fix ─────────
                await saveAttachments(
                    taskId:    taskId,
                    filenames: attachmentFilenames,
                    images:    attachments
                )

                await loadTasksFromSupabase()

                await MainActor.run {
                    let a = UIAlertController(title: "Task Updated ✅",
                                              message: "'\(title)' updated successfully",
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }

            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Error",
                                              message: error.localizedDescription,
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            }
        }
    }

    // MARK: - Internal Supabase helpers

    /// Creates a task row and returns its new UUID string.
    private func createTaskRow(title: String,
                               description: String,
                               date: Date,
                               assignToAll: Bool,
                               specificStudentId: String?) async throws -> String {

        struct TaskInsert: Encodable {
            let team_id:       String
            let mentor_id:     String
            let title:         String
            let description:   String
            let status:        String
            let assigned_date: String
        }
        struct CreatedRow: Decodable { let id: String }

        let payload = TaskInsert(
            team_id:       teamId,
            mentor_id:     currentMentorId,
            title:         title,
            description:   description,
            status:        "assigned",
            assigned_date: ISO8601DateFormatter().string(from: date)
        )

        let created: [CreatedRow] = try await SupabaseManager.shared.client
            .from("tasks")
            .insert(payload)
            .select("id")
            .execute()
            .value

        guard let taskId = created.first?.id else {
            throw NSError(domain: "SATVC", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Task created but ID not returned"])
        }

        // Insert task_assignees row
        if !assignToAll, let studentId = specificStudentId {
            try await insertAssigneeRow(taskId: taskId, studentId: studentId)
        } else if assignToAll {
            // Assign to all members in the team
            await insertAssigneesForAllMembers(taskId: taskId)
        }

        return taskId
    }

    /// Updates an existing task row's editable fields.
    private func updateTaskRow(taskId: String,
                               title: String,
                               description: String,
                               date: Date,
                               assignToAll: Bool,
                               specificStudentId: String?) async throws {

        struct TaskUpdate: Encodable {
            let title:         String
            let description:   String
            let assigned_date: String
            let updated_at:    String
        }

        try await SupabaseManager.shared.client
            .from("tasks")
            .update(TaskUpdate(
                title:         title,
                description:   description,
                assigned_date: ISO8601DateFormatter().string(from: date),
                updated_at:    ISO8601DateFormatter().string(from: Date())
            ))
            .eq("id", value: taskId)
            .execute()

        // Update assignees: delete old, insert new
        try await SupabaseManager.shared.client
            .from("task_assignees")
            .delete()
            .eq("task_id", value: taskId)
            .execute()

        if !assignToAll, let studentId = specificStudentId {
            try await insertAssigneeRow(taskId: taskId, studentId: studentId)
        } else if assignToAll {
            await insertAssigneesForAllMembers(taskId: taskId)
        }
    }

    private func insertAssigneeRow(taskId: String, studentId: String) async throws {
        struct AssigneeInsert: Encodable { let task_id: String; let student_id: String }
        try await SupabaseManager.shared.client
            .from("task_assignees")
            .insert(AssigneeInsert(task_id: taskId, student_id: studentId))
            .execute()
    }

    private func insertAssigneesForAllMembers(taskId: String) async {
        do {
            struct TeamRow: Decodable {
                let created_by_id: String
                let member2_id: String?
                let member3_id: String?
            }
            let rows: [TeamRow] = try await SupabaseManager.shared.client
                .from("new_teams")
                .select("created_by_id, member2_id, member3_id")
                .eq("id", value: teamId)
                .limit(1)
                .execute()
                .value

            guard let team = rows.first else { return }

            var ids: [String] = [team.created_by_id]
            if let m2 = team.member2_id { ids.append(m2) }
            if let m3 = team.member3_id { ids.append(m3) }

            for id in ids {
                if let _ = try? await insertAssigneeRow(taskId: taskId, studentId: id) {}
                else { try? await insertAssigneeRow(taskId: taskId, studentId: id) }
            }
        } catch {
            print("⚠️ insertAssigneesForAllMembers failed (non-fatal):", error)
        }
    }

    private func findTaskId(at index: Int) -> String? {
        let all = assignedTasks + reviewTasks + completedTasks + rejectedTasks
        guard index >= 0, index < all.count else { return nil }
        return all[index].id
    }
}

// MARK: - Collection View

extension StudentAllTasksViewController: UICollectionViewDelegate,
                                         UICollectionViewDataSource,
                                         UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int { items.count }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        switch items[indexPath.row] {

        case .teamProfile:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TeamProfileRowCell", for: indexPath) as! TeamProfileRowCell
            cell.configureProfiles(images: teamMemberImages, names: teamMemberNames, teamNo: teamNo)
            return cell

        case .category(let category):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TaskSectionCell", for: indexPath) as! TaskSectionCell

            let tasks = getTasksArray(for: category)
            cell.configureSection(type: category, tasks: tasks)

            cell.onEditTask = { [weak self] task, idx in
                guard let self else { return }
                self.presentNewTaskViewController(
                    isEditMode: true, task: task, category: category, taskIndex: idx)
            }

            cell.onViewAttachments = { [weak self] attachments, filenames in
                self?.presentAttachmentViewer(attachments: attachments, filenames: filenames)
            }

            cell.onDeleteTask = { [weak self] idx in
                guard let self else { return }
                let list = self.getTasksArray(for: category)
                guard idx >= 0, idx < list.count else { return }
                self.deleteTask(in: category, at: idx, task: list[idx])
            }

            cell.seeAllTapped = { [weak self] in
                guard let self else { return }
                let seeAllVC = TaskSeeAllViewController(
                    category: category,
                    tasks: self.getTasksArray(for: category)
                )
                seeAllVC.delegate         = self
                seeAllVC.reviewDelegate   = self
                seeAllVC.teamMemberImages = self.teamMemberImages
                seeAllVC.teamMemberNames  = self.teamMemberNames
                seeAllVC.teamId           = self.teamId
                seeAllVC.mentorId         = self.currentMentorId
                seeAllVC.modalPresentationStyle = .fullScreen
                seeAllVC.modalTransitionStyle   = .coverVertical
                self.present(seeAllVC, animated: true)
            }

            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch items[indexPath.row] {
        case .teamProfile: return CGSize(width: collectionView.frame.width, height: 110)
        case .category:    return CGSize(width: collectionView.frame.width, height: 240)
        }
    }
}
