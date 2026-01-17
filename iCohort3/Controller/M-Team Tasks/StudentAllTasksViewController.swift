import UIKit

enum TaskSectionWrapper {
    case teamProfile
    case category(TaskCategory)
}

class StudentAllTasksViewController: UIViewController {

    @IBOutlet weak var verticalCollectionView: UICollectionView!
    @IBOutlet weak var teamTitleLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var addButton: UIButton!

    var teamId: String = ""
    var teamNo: Int = 0
    var teamName: String?
    var currentMentorId: String = "d9966327-b3ed-4fc8-9fbe-70c7148527f3"

    var teamMemberNames: [String] = []
    var teamMemberImages: [UIImage] = []
    var ongoingTasks: [TaskModel] = []


    // Task storage by category
    var assignedTasks: [TaskModel] = []
    var mentorId: String = ""
    

    var reviewTasks: [TaskModel] = []
    var completedTasks: [TaskModel] = []
    var rejectedTasks: [TaskModel] = []

    let items: [TaskSectionWrapper] = [
        .teamProfile,
        .category(.assigned),
        
        .category(.review),
        .category(.completed),
        .category(.rejected)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupCollectionView()
        setupTitle()
        
        Task {
            await loadTeamMembersFromSupabase()
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

    // MARK: - Load Data from Supabase

    private func loadTeamMembersFromSupabase() async {
        guard !teamId.isEmpty else {
            print("⚠️ teamId is empty, cannot load members.")
            return
        }

        do {
            let names = try await SupabaseManager.shared.fetchStudentNamesForTeam(teamId: teamId)

            await MainActor.run {
                self.teamMemberNames = names
                self.verticalCollectionView.reloadData()
            }
        } catch {
            print("❌ Failed to load team members:", error)
        }
    }

    private func loadTasksFromSupabase() async {
        guard !teamId.isEmpty else { return }

        do {
            let allTasks = try await SupabaseManager.shared.fetchTasksForTeam(teamId: teamId)

            var assigned: [TaskModel] = []
            var ongoing: [TaskModel] = []
            var review: [TaskModel] = []
            var completed: [TaskModel] = []
            var rejected: [TaskModel] = []

            for taskRow in allTasks {
                let task = await TaskModel.from(taskRow: taskRow)
                let s = taskRow.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                switch s {
                case "assigned":
                    assigned.append(task)
                case "ongoing":
                    ongoing.append(task)        // ✅ FIXED
                case "for_review":
                    review.append(task)
                case "completed":
                    completed.append(task)
                case "rejected":
                    rejected.append(task)
                default:
                    break
                }
            }

            await MainActor.run {
                self.assignedTasks = assigned
                self.ongoingTasks = ongoing     // ✅
                self.reviewTasks = review
                self.completedTasks = completed
                self.rejectedTasks = rejected
                self.verticalCollectionView.reloadData()
            }

            }

         catch {
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

    func presentNewTaskViewController(isEditMode: Bool,
                                     task: TaskModel? = nil,
                                     category: TaskCategory? = nil,
                                     taskIndex: Int? = nil) {
        let newTaskVC = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)

        newTaskVC.delegate = self
        newTaskVC.teamMemberImages = teamMemberImages
        newTaskVC.teamMemberNames = teamMemberNames
        newTaskVC.teamId = teamId
        newTaskVC.mentorId = currentMentorId

        if isEditMode, let task = task, let category = category, let taskIndex = taskIndex {
            newTaskVC.isEditMode = true
            newTaskVC.existingTaskId = task.id
            newTaskVC.existingTitle = task.title
            newTaskVC.existingDescription = task.desc
            newTaskVC.existingDate = task.assignedDate
            newTaskVC.selectedMemberName = task.name
            newTaskVC.existingAttachments = task.attachments ?? []
            newTaskVC.editingTaskIndex = taskIndex
            newTaskVC.editingCategory = category
        }

        newTaskVC.modalPresentationStyle = .pageSheet
        if let sheet = newTaskVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(newTaskVC, animated: true)
    }

    // MARK: - Attachment Viewer

    func presentAttachmentViewer(attachments: [UIImage]) {
        let viewerVC = AttachmentViewerViewController(attachments: attachments)
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

    private func updateTasksArray(for category: TaskCategory, with tasks: [TaskModel]) {
        switch category {
        case .assigned: assignedTasks = tasks
        case .review: reviewTasks = tasks
        case .completed: completedTasks = tasks
        case .rejected: rejectedTasks = tasks
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
            guard let self = self else { return }

            Task {
                do {
                    if let taskId = task.id {
                        try await SupabaseManager.shared.deleteTask(taskId: taskId)
                    }

                    await MainActor.run {
                        var tasks = self.getTasksArray(for: category)
                        guard index >= 0 && index < tasks.count else { return }

                        tasks.remove(at: index)
                        self.updateTasksArray(for: category, with: tasks)

                        UIView.animate(withDuration: 0.3) {
                            self.verticalCollectionView.reloadData()
                        }

                        let successAlert = UIAlertController(
                            title: "Task Deleted",
                            message: "Task successfully deleted",
                            preferredStyle: .alert
                        )
                        successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(successAlert, animated: true)
                    }
                } catch {
                    print("❌ Failed to delete task:", error)
                    
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

// MARK: - NewTaskDelegate (FIXED)

extension StudentAllTasksViewController: NewTaskDelegate {

    func didAssignTask(to memberName: String, description: String, date: Date, title: String, attachments: [UIImage]) {
        Task {
            do {
                print("🔄 Creating task for: \(memberName)")
                
                // Determine if assigning to all or specific student
                let assignToAll = (memberName == "All Members")
                var specificStudentId: String? = nil
                
                if !assignToAll {
                    // Get the student ID for the selected member
                    specificStudentId = try await SupabaseManager.shared.fetchStudentId(
                        teamId: teamId,
                        studentName: memberName
                    )
                    
                    guard specificStudentId != nil else {
                        throw NSError(domain: "StudentAllTasksVC", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Could not find student ID for \(memberName)"])
                    }
                    
                    print("✅ Found student ID: \(specificStudentId!) for \(memberName)")
                }
                
                // Create task with attachments
                let taskId = try await SupabaseManager.shared.createTask(
                    teamId: teamId,
                    mentorId: currentMentorId,
                    title: title,
                    description: description,
                    assignedDate: date,
                    assignToAll: assignToAll,
                    specificStudentId: specificStudentId,
                    attachments: attachments
                )

                print("✅ Task created with ID: \(taskId)")
                print("✅ Attachments uploaded: \(attachments.count)")
                
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
                print("❌ Failed to create task:", error)
                
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

    func didUpdateTask(at index: Int, memberName: String, description: String, date: Date, title: String, attachments: [UIImage]) {
        Task {
            do {
                // Find the task being edited from all categories
                guard let taskId = findTaskId(at: index) else {
                    throw NSError(domain: "StudentAllTasksVC", code: -1,
                                userInfo: [NSLocalizedDescriptionKey: "Task ID not found"])
                }
                
                print("🔄 Updating task: \(taskId)")
                
                // Determine assignee updates
                let assignToAll = (memberName == "All Members")
                var specificStudentId: String? = nil
                
                if !assignToAll {
                    specificStudentId = try await SupabaseManager.shared.fetchStudentId(
                        teamId: teamId,
                        studentName: memberName
                    )
                    
                    guard specificStudentId != nil else {
                        throw NSError(domain: "StudentAllTasksVC", code: -1,
                                    userInfo: [NSLocalizedDescriptionKey: "Could not find student ID for \(memberName)"])
                    }
                    
                    print("✅ Found student ID: \(specificStudentId!) for \(memberName)")
                }
                
                // Update task with assignees and attachments
                try await SupabaseManager.shared.updateTask(
                    taskId: taskId,
                    title: title,
                    description: description,
                    assignedDate: date,
                    attachments: attachments,
                    updateAssignees: true,
                    assignToAll: assignToAll,
                    teamId: teamId,
                    mentorId: mentorId,                 // ✅ ADD THIS
                    specificStudentId: specificStudentId
                

                )
                
                print("✅ Task updated successfully")
                print("✅ Assignees updated: \(memberName)")
                print("✅ Attachments uploaded: \(attachments.count)")
                
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
                print("❌ Failed to update task:", error)
                
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
        // Combine all tasks in order
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
                guard let self = self else { return }
                self.presentNewTaskViewController(isEditMode: true, task: task, category: category, taskIndex: taskIndex)
            }

            cell.onViewAttachments = { [weak self] attachments in
                guard let self = self else { return }
                self.presentAttachmentViewer(attachments: attachments)
            }

            cell.onDeleteTask = { [weak self] taskIndex in
                guard let self = self else { return }

                let tasks = self.getTasksArray(for: category)
                guard taskIndex >= 0 && taskIndex < tasks.count else { return }

                let taskToDelete = tasks[taskIndex]
                self.deleteTask(in: category, at: taskIndex, task: taskToDelete)
            }

            cell.seeAllTapped = { [weak self] in
                guard let self = self else { return }

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

        let item = items[indexPath.row]
        switch item {
        case .teamProfile:
            return CGSize(width: collectionView.frame.width, height: 110)
        case .category:
            return CGSize(width: collectionView.frame.width, height: 240)
        }
    }
}
