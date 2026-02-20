import UIKit

enum TaskSectionWrapper {
    case teamProfile
    case category(TaskCategory)
}

final class StudentAllTasksViewController: UIViewController {

    @IBOutlet weak var verticalCollectionView: UICollectionView!
    @IBOutlet weak var teamTitleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var addButton: UIButton!

    var teamId: String = ""
    var teamNo: Int = 0
    var teamName: String?

    // ✅ Don’t hardcode mentor id. Load from UserDefaults if available.
    var currentMentorId: String = ""

    // ✅ Members from new_teams (names), avatars generated from initials
    private var teamMemberNames: [String] = []
    private var teamMemberImages: [UIImage] = []

    // Task storage by category
    private var assignedTasks: [TaskModel] = []
    private var ongoingTasks: [TaskModel] = []   // you were storing it but not showing as a section
    private var reviewTasks: [TaskModel] = []
    private var completedTasks: [TaskModel] = []
    private var rejectedTasks: [TaskModel] = []

    // ✅ Same sections as your UI expects
    private let items: [TaskSectionWrapper] = [
        .teamProfile,
        .category(.assigned),
        .category(.review),
        .category(.completed),
        .category(.rejected)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        // ✅ mentor id from storage (optional)
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
        backButton.layer.cornerRadius = backButton.frame.height / 2
        backButton.backgroundColor = .white
        backButton.clipsToBounds = true
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        backButton.layer.shadowRadius = 4
        backButton.layer.shadowOpacity = 0.1

        addButton.layer.cornerRadius = addButton.frame.height / 2
        addButton.backgroundColor = .white
        addButton.clipsToBounds = true
        addButton.layer.shadowColor = UIColor.black.cgColor
        addButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addButton.layer.shadowRadius = 4
        addButton.layer.shadowOpacity = 0.1

        let bg = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        verticalCollectionView.backgroundColor = bg
        view.backgroundColor = bg
    }

    private func setupCollectionView() {
        verticalCollectionView.delegate = self
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
        } else if let teamName = teamName {
            teamTitleLabel.text = teamName
            self.title = teamName
        } else {
            teamTitleLabel.text = "Team"
            self.title = "Team"
        }
    }

    // MARK: - Load Members from new_teams

    private func loadTeamMembersFromNewTeams() async {
        guard !teamId.isEmpty else {
            print("⚠️ teamId is empty, cannot load members.")
            return
        }

        do {
            // ✅ FROM new_teams (created_by_name, member2_name, member3_name)
            let names = try await SupabaseManager.shared.fetchMemberNamesFromNewTeams(teamId: teamId)

            let avatars = names.map { Self.makeInitialAvatar(from: $0, size: CGSize(width: 44, height: 44)) }

            await MainActor.run {
                self.teamMemberNames = names
                self.teamMemberImages = avatars
                print("✅ Loaded \(names.count) team members from new_teams")
                self.verticalCollectionView.reloadData()
            }
        } catch {
            print("❌ Failed to load team members from new_teams:", error)
        }
    }

    // MARK: - Load Tasks
    private func loadTasksFromSupabase() async {
        guard !teamId.isEmpty else {
            print("⚠️ teamId is empty, cannot load tasks.")
            return
        }

        do {
            // 🔥 Fetch each status separately (parallel for speed)
            async let assignedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "assigned")
            async let ongoingRows   = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "ongoing")
            async let reviewRows    = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "for_review")
            async let completedRows = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "completed")
            async let rejectedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "rejected")

            let (assignedData,
                 ongoingData,
                 reviewData,
                 completedData,
                 rejectedData) = try await (
                    assignedRows,
                    ongoingRows,
                    reviewRows,
                    completedRows,
                    rejectedRows
            )

            print("✅ Assigned:", assignedData.count)
            print("✅ Ongoing:", ongoingData.count)
            print("✅ Review:", reviewData.count)
            print("✅ Completed:", completedData.count)
            print("✅ Rejected:", rejectedData.count)

            // Convert to TaskModel
            let assigned = await withTaskGroup(of: TaskModel.self) { group -> [TaskModel] in
                for row in assignedData {
                    group.addTask { await TaskModel.from(taskRow: row) }
                }
                return await group.reduce(into: []) { $0.append($1) }
            }

            let ongoing = await withTaskGroup(of: TaskModel.self) { group -> [TaskModel] in
                for row in ongoingData {
                    group.addTask { await TaskModel.from(taskRow: row) }
                }
                return await group.reduce(into: []) { $0.append($1) }
            }

            let review = await withTaskGroup(of: TaskModel.self) { group -> [TaskModel] in
                for row in reviewData {
                    group.addTask { await TaskModel.from(taskRow: row) }
                }
                return await group.reduce(into: []) { $0.append($1) }
            }

            let completed = await withTaskGroup(of: TaskModel.self) { group -> [TaskModel] in
                for row in completedData {
                    group.addTask { await TaskModel.from(taskRow: row) }
                }
                return await group.reduce(into: []) { $0.append($1) }
            }

            let rejected = await withTaskGroup(of: TaskModel.self) { group -> [TaskModel] in
                for row in rejectedData {
                    group.addTask { await TaskModel.from(taskRow: row) }
                }
                return await group.reduce(into: []) { $0.append($1) }
            }

            await MainActor.run {
                self.assignedTasks = assigned
                self.ongoingTasks = ongoing
                self.reviewTasks = review
                self.completedTasks = completed
                self.rejectedTasks = rejected

                self.verticalCollectionView.reloadData()
            }

        } catch {
            print("❌ Failed to load tasks:", error)
        }
    }


    // MARK: - Actions

    @IBAction func backButtonTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func addButtonTapped(_ sender: Any) {
        presentNewTaskViewController(isEditMode: false)
    }

    // MARK: - Present NewTask VC

    private func presentNewTaskViewController(isEditMode: Bool,
                                              task: TaskModel? = nil,
                                              category: TaskCategory? = nil,
                                              taskIndex: Int? = nil) {

        let newTaskVC = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)

        newTaskVC.delegate = self
        newTaskVC.teamMemberImages = teamMemberImages
        newTaskVC.teamMemberNames = teamMemberNames
        newTaskVC.teamId = teamId
        newTaskVC.mentorId = currentMentorId

        if isEditMode, let task, let category, let taskIndex {
            newTaskVC.isEditMode = true
            newTaskVC.existingTaskId = task.id
            newTaskVC.existingTitle = task.title
            newTaskVC.existingDescription = task.desc
            newTaskVC.existingDate = task.assignedDate
            newTaskVC.selectedMemberName = task.name
            newTaskVC.existingAttachments = task.attachments ?? []
            newTaskVC.editingTaskIndex = taskIndex
            newTaskVC.editingCategory = category
            if let filenames = task.attachmentFilenames {
                newTaskVC.attachmentFilenames = filenames
            }
        }

        newTaskVC.modalPresentationStyle = .pageSheet
        if let sheet = newTaskVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(newTaskVC, animated: true)
    }

    // MARK: - Attachment Viewer

    private func presentAttachmentViewer(attachments: [UIImage], filenames: [String] = []) {
        let viewerVC = AttachmentViewerViewController(
            attachments: attachments,
            attachmentFilenames: filenames
        )
        viewerVC.modalPresentationStyle = .fullScreen
        viewerVC.modalTransitionStyle = .crossDissolve
        present(viewerVC, animated: true)
    }

    // MARK: - Helpers

    private func getTasksArray(for category: TaskCategory) -> [TaskModel] {
        switch category {
        case .assigned: return assignedTasks
        case .review: return reviewTasks
        case .completed: return completedTasks
        case .rejected: return rejectedTasks
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
                    if let taskId = task.id {
                        try await SupabaseManager.shared.deleteTask(taskId: taskId)
                    }

                    await self.loadTasksFromSupabase()

                    await MainActor.run {
                        let successAlert = UIAlertController(
                            title: "Task Deleted",
                            message: "Task successfully deleted",
                            preferredStyle: .alert
                        )
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(successAlert, animated: true)
                    }
                } catch {
                    await MainActor.run {
                        let errorAlert = UIAlertController(
                            title: "Error",
                            message: "Failed to delete task. Please try again.",
                            preferredStyle: .alert
                        )
                        errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(errorAlert, animated: true)
                    }
                }
            }
        })

        present(alert, animated: true)
    }

    // MARK: - Initial Avatar Generator (first letter of first name)

    private static func makeInitialAvatar(from fullName: String, size: CGSize) -> UIImage {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let first = trimmed.components(separatedBy: .whitespacesAndNewlines).first ?? trimmed
        let initial = String(first.prefix(1)).uppercased()
        let letter = initial.isEmpty ? "?" : initial

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)

            UIColor.systemGray5.setFill()
            ctx.fill(rect)

            // circle
            let path = UIBezierPath(ovalIn: rect)
            path.addClip()
            UIColor.systemGray4.setFill()
            ctx.fill(rect)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.45, weight: .semibold),
                .foregroundColor: UIColor.label
            ]

            let textSize = letter.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            letter.draw(in: textRect, withAttributes: attributes)
        }
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

    func didAssignTask(to memberName: String,
                       description: String,
                       date: Date,
                       title: String,
                       attachments: [UIImage],
                       attachmentFilenames: [String]) {

        Task {
            do {
                let assignToAll = (memberName == "All Members" || memberName == "Team Task")
                var specificStudentId: String? = nil

                if !assignToAll {
                    specificStudentId = try await SupabaseManager.shared.getStudentIdByName(
                        teamId: teamId,
                        studentName: memberName
                    )
                    guard specificStudentId != nil else {
                        throw NSError(domain: "StudentAllTasksVC", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Could not find student ID for \(memberName)"])
                    }
                }

                _ = try await SupabaseManager.shared.createTask(
                    teamId: teamId,
                    mentorId: currentMentorId,
                    title: title,
                    description: description,
                    status: "assigned",
                    assignedDate: date,
                    assignToAll: assignToAll,
                    specificStudentId: specificStudentId,
                    attachments: attachments,
                    attachmentFilenames: attachmentFilenames
                )

                await loadTasksFromSupabase()

                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Task Assigned",
                        message: "Task '\(title)' successfully assigned to \(memberName)",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    let errorAlert = UIAlertController(
                        title: "Error",
                        message: "Failed to create task: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }

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
                    throw NSError(domain: "StudentAllTasksVC", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Task ID not found"])
                }

                let assignToAll = (memberName == "All Members" || memberName == "Team Task")
                var specificStudentId: String? = nil

                if !assignToAll {
                    specificStudentId = try await SupabaseManager.shared.getStudentIdByName(
                        teamId: teamId,
                        studentName: memberName
                    )
                    guard specificStudentId != nil else {
                        throw NSError(domain: "StudentAllTasksVC", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Could not find student ID for \(memberName)"])
                    }
                }

                try await SupabaseManager.shared.updateTask(
                    taskId: taskId,
                    title: title,
                    description: description,
                    assignedDate: date,
                    attachments: attachments,
                    attachmentFilenames: attachmentFilenames,
                    updateAssignees: true,
                    assignToAll: assignToAll,
                    teamId: teamId,
                    mentorId: currentMentorId,
                    specificStudentId: specificStudentId
                )

                await loadTasksFromSupabase()

                await MainActor.run {
                    let alert = UIAlertController(
                        title: "Task Updated",
                        message: "Task '\(title)' successfully updated",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(alert, animated: true)
                }
            } catch {
                await MainActor.run {
                    let errorAlert = UIAlertController(
                        title: "Error",
                        message: "Failed to update task: \(error.localizedDescription)",
                        preferredStyle: .alert
                    )
                    errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(errorAlert, animated: true)
                }
            }
        }
    }

    private func findTaskId(at index: Int) -> String? {
        let allTasks = assignedTasks + reviewTasks + completedTasks + rejectedTasks
        guard index >= 0 && index < allTasks.count else { return nil }
        return allTasks[index].id
    }
}

// MARK: - Collection View

extension StudentAllTasksViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 1 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let item = items[indexPath.row]

        switch item {

        case .teamProfile:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TeamProfileRowCell",
                for: indexPath
            ) as! TeamProfileRowCell

            cell.configureProfiles(images: teamMemberImages, names: teamMemberNames, teamNo: teamNo)
            return cell

        case .category(let category):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TaskSectionCell",
                for: indexPath
            ) as! TaskSectionCell

            let tasksForCategory = getTasksArray(for: category)
            cell.configureSection(type: category, tasks: tasksForCategory)

            cell.onEditTask = { [weak self] task, taskIndex in
                guard let self else { return }
                self.presentNewTaskViewController(isEditMode: true, task: task, category: category, taskIndex: taskIndex)
            }

            cell.onViewAttachments = { [weak self] attachments, filenames in
                guard let self else { return }
                self.presentAttachmentViewer(attachments: attachments, filenames: filenames)
            }

            cell.onDeleteTask = { [weak self] taskIndex in
                guard let self else { return }
                let tasks = self.getTasksArray(for: category)
                guard taskIndex >= 0 && taskIndex < tasks.count else { return }
                let taskToDelete = tasks[taskIndex]
                self.deleteTask(in: category, at: taskIndex, task: taskToDelete)
            }

            cell.seeAllTapped = { [weak self] in
                guard let self else { return }

                let tasks = self.getTasksArray(for: category)
                let seeAllVC = TaskSeeAllViewController(category: category, tasks: tasks)
                seeAllVC.delegate = self
                seeAllVC.teamMemberImages = self.teamMemberImages
                seeAllVC.teamMemberNames = self.teamMemberNames
                seeAllVC.teamId = self.teamId
                seeAllVC.mentorId = self.currentMentorId

                seeAllVC.modalPresentationStyle = .fullScreen
                seeAllVC.modalTransitionStyle = .coverVertical
                self.present(seeAllVC, animated: true)
            }

            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        switch items[indexPath.row] {
        case .teamProfile:
            return CGSize(width: collectionView.frame.width, height: 110)
        case .category:
            return CGSize(width: collectionView.frame.width, height: 240)
        }
    }
}
