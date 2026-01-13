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

    // Passed from Mentor Dashboard
    var teamId: String = ""
    var teamNo: Int = 0
    var teamName: String?

    // Team members (names from DB)
    var teamMemberNames: [String] = []

    // Optional: you can keep empty & let cell use default "Student" image
    var teamMemberImages: [UIImage] = []

    // Tasks (TEMP sample)
    var assignedTasks: [TaskModel] = []
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

        backButton.layer.cornerRadius = backButton.frame.height / 2
        backButton.backgroundColor = .white
        backButton.clipsToBounds = true

        addButton.layer.cornerRadius = addButton.frame.height / 2
        addButton.backgroundColor = .white
        addButton.clipsToBounds = true

        let bg = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        verticalCollectionView.backgroundColor = bg
        view.backgroundColor = bg

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

        // Title
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

        initializeSampleData()

        // ✅ IMPORTANT: actually fetch members from Supabase
        Task { await loadTeamMembersFromSupabase() }
    }

    // MARK: - Fetch Team Members (Supabase)

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

        if isEditMode, let task = task, let category = category, let taskIndex = taskIndex {
            newTaskVC.isEditMode = true
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

    // MARK: - Sample Data (TEMP)

    func initializeSampleData() {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"

        assignedTasks = [
            TaskModel(name: "Shreya", desc: "UI redesign work", date: "03 Nov 2025", remark: nil, remarkDesc: nil, title: "Redesign Dashboard", attachments: [], assignedDate: dateFormatter.date(from: "03 Nov 2025")),
            TaskModel(name: "Lakshy", desc: "Fix login flow", date: "05 Nov 2025", remark: nil, remarkDesc: nil, title: "Login Bug Fix", attachments: [], assignedDate: dateFormatter.date(from: "05 Nov 2025"))
        ]

        reviewTasks = [
            TaskModel(name: "Shruti", desc: "API integration pending review", date: "10 Nov 2025", remark: nil, remarkDesc: nil, title: "API Integration", attachments: [], assignedDate: dateFormatter.date(from: "10 Nov 2025")),
            TaskModel(name: "Karan", desc: "Check Figma alignment", date: "11 Nov 2025", remark: nil, remarkDesc: nil, title: "Design Review", attachments: [], assignedDate: dateFormatter.date(from: "11 Nov 2025")),
            TaskModel(name: "Aaliya", desc: "Verify data mapping", date: "12 Nov 2025", remark: nil, remarkDesc: nil, title: "Data Verification", attachments: [], assignedDate: dateFormatter.date(from: "12 Nov 2025"))
        ]

        completedTasks = [
            TaskModel(name: "Rahul", desc: "Database migration done", date: "01 Nov 2025", remark: "Remark", remarkDesc: "Excellent work! All changes merged.", title: "Database Migration", attachments: [], assignedDate: dateFormatter.date(from: "01 Nov 2025")),
            TaskModel(name: "Shreya", desc: "Prototype completed", date: "28 Oct 2025", remark: "Remark", remarkDesc: "Meets all UI expectations.", title: "Prototype Design", attachments: [], assignedDate: dateFormatter.date(from: "28 Oct 2025"))
        ]

        rejectedTasks = [
            TaskModel(name: "Arjun", desc: "UI not matching design", date: "20 Oct 2025", remark: "Remark", remarkDesc: "Revise entire layout as soon as possible.", title: "UI Implementation", attachments: [], assignedDate: dateFormatter.date(from: "20 Oct 2025")),
            TaskModel(name: "Riya", desc: "Incorrect business logic", date: "21 Oct 2025", remark: "Remark", remarkDesc: "Wrong formula applied in calculations.", title: "Logic Implementation", attachments: [], assignedDate: dateFormatter.date(from: "21 Oct 2025"))
        ]
    }

    // MARK: - Attachments Viewer

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
        })

        present(alert, animated: true)
    }
}

// MARK: - TaskSeeAllDelegate

extension StudentAllTasksViewController: TaskSeeAllDelegate {

    func didUpdateTask(in category: TaskCategory, at index: Int, with task: TaskModel) {
        var tasks = getTasksArray(for: category)
        if index < tasks.count {
            tasks[index] = task
            updateTasksArray(for: category, with: tasks)
        }
        verticalCollectionView.reloadData()
    }

    func didDeleteTask(in category: TaskCategory, at index: Int) {
        var tasks = getTasksArray(for: category)
        guard index >= 0 && index < tasks.count else { return }
        tasks.remove(at: index)
        updateTasksArray(for: category, with: tasks)
        verticalCollectionView.reloadData()
    }
}

// MARK: - NewTaskDelegate

extension StudentAllTasksViewController: NewTaskDelegate {

    func didAssignTask(to memberName: String, description: String, date: Date, title: String, attachments: [UIImage]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        let dateString = dateFormatter.string(from: date)

        let newTask = TaskModel(
            name: memberName,
            desc: description,
            date: dateString,
            remark: nil,
            remarkDesc: nil,
            title: title,
            attachments: attachments,
            assignedDate: date
        )

        assignedTasks.append(newTask)

        let alert = UIAlertController(
            title: "Task Assigned",
            message: "Task '\(title)' successfully assigned to \(memberName)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)

        verticalCollectionView.reloadData()
    }

    func didUpdateTask(at index: Int, memberName: String, description: String, date: Date, title: String, attachments: [UIImage]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        let dateString = dateFormatter.string(from: date)

        for category in [TaskCategory.assigned, .review, .completed, .rejected] {
            var tasks = getTasksArray(for: category)
            if index < tasks.count {
                tasks[index] = TaskModel(
                    name: memberName,
                    desc: description,
                    date: dateString,
                    remark: tasks[index].remark,
                    remarkDesc: tasks[index].remarkDesc,
                    title: title,
                    attachments: attachments,
                    assignedDate: date
                )
                updateTasksArray(for: category, with: tasks)
                break
            }
        }

        let alert = UIAlertController(
            title: "Task Updated",
            message: "Task '\(title)' successfully updated",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)

        verticalCollectionView.reloadData()
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

            // ✅ Use DB names (images can be empty; cell uses default)
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
