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
    
    // Store team member data
    let teamMemberImages: [UIImage] = [
        UIImage(named: "Student") ?? UIImage(),
        UIImage(named: "Student") ?? UIImage(),
        UIImage(named: "Student") ?? UIImage()
    ]
    let teamMemberNames: [String] = ["Shruti", "Ananya", "Rahul"]
    
    // Store all tasks
    var assignedTasks: [TaskModel] = []
    var reviewTasks: [TaskModel] = []
    var completedTasks: [TaskModel] = []
    var rejectedTasks: [TaskModel] = []
    
    @IBAction func backButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func addButtonTapped(_ sender: Any) {
        presentNewTaskViewController(isEditMode: false)
    }
    
    func presentNewTaskViewController(isEditMode: Bool, task: TaskModel? = nil, category: TaskCategory? = nil, taskIndex: Int? = nil) {
        let newTaskVC = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)
        
        // Set delegate
        newTaskVC.delegate = self
        
        // Pass team member data
        newTaskVC.teamMemberImages = teamMemberImages
        newTaskVC.teamMemberNames = teamMemberNames
        
        // Configure for edit mode if needed
        if isEditMode, let task = task, let category = category, let taskIndex = taskIndex {
            newTaskVC.isEditMode = true
            newTaskVC.existingTitle = task.title
            newTaskVC.existingDescription = task.desc
            newTaskVC.existingDate = task.assignedDate
            newTaskVC.selectedMemberName = task.name
            newTaskVC.existingAttachments = task.attachments ?? []
            newTaskVC.editingTaskIndex = taskIndex
            
            // Store category for update
            newTaskVC.editingCategory = category
        }
        
        newTaskVC.modalPresentationStyle = .pageSheet
        if let sheet = newTaskVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(newTaskVC, animated: true)
    }
    
    var teamName: String?

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
        
        if let teamName = teamName {
            teamTitleLabel.text = teamName
        }

        if let teamName = teamName {
            self.title = teamName
        }
        
        // Initialize with sample data
        initializeSampleData()
        
        // Listen for delete notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeleteTask(_:)),
            name: NSNotification.Name("DeleteTask"),
            object: nil
        )
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
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
    
    @objc func handleDeleteTask(_ notification: Notification) {
        guard notification.userInfo?["cell"] is TaskCardCellNew else {
            return
        }
        
        // Find and remove the task
        // Note: In a real app, you'd need to track which category the cell belongs to
        verticalCollectionView.reloadData()
    }
    
    func presentAttachmentViewer(attachments: [UIImage]) {
        let viewerVC = AttachmentViewerViewController(attachments: attachments)
        viewerVC.modalPresentationStyle = .fullScreen
        viewerVC.modalTransitionStyle = .crossDissolve
        present(viewerVC, animated: true)
    }
    
    // MARK: - Helper to get tasks array for category
    private func getTasksArray(for category: TaskCategory) -> [TaskModel] {
        switch category {
        case .assigned: return assignedTasks
        case .review: return reviewTasks
        case .completed: return completedTasks
        case .rejected: return rejectedTasks
        }
    }
    
    // MARK: - Helper to update tasks array for category
    private func updateTasksArray(for category: TaskCategory, with tasks: [TaskModel]) {
        switch category {
        case .assigned: assignedTasks = tasks
        case .review: reviewTasks = tasks
        case .completed: completedTasks = tasks
        case .rejected: rejectedTasks = tasks
        }
    }
}

// MARK: - TaskSeeAllDelegate
extension StudentAllTasksViewController: TaskSeeAllDelegate {
    func didUpdateTask(in category: TaskCategory, at index: Int, with task: TaskModel) {
        // Update the appropriate array
        var tasks = getTasksArray(for: category)
        if index < tasks.count {
            tasks[index] = task
            updateTasksArray(for: category, with: tasks)
        }
        
        // Reload collection view
        verticalCollectionView.reloadData()
    }
    
    func didDeleteTask(in category: TaskCategory, at index: Int) {
        // Remove from the appropriate array
        var tasks = getTasksArray(for: category)
        if index < tasks.count {
            tasks.remove(at: index)
            updateTasksArray(for: category, with: tasks)
        }
        
        // Reload collection view
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
        
        // Show confirmation
        let alert = UIAlertController(
            title: "Task Assigned",
            message: "Task '\(title)' successfully assigned to \(memberName)",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Reload collection view
        verticalCollectionView.reloadData()
    }
    
    func didUpdateTask(at index: Int, memberName: String, description: String, date: Date, title: String, attachments: [UIImage]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        let dateString = dateFormatter.string(from: date)
        
        // Find which category this task belongs to using the stored category in NewTaskViewController
        // For now, we'll search through all categories
        var found = false
        
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
                found = true
                break
            }
        }
        
        // Show confirmation
        let alert = UIAlertController(
            title: "Task Updated",
            message: "Task '\(title)' successfully updated",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
        
        // Reload collection view
        verticalCollectionView.reloadData()
    }
}

// MARK: - COLLECTION VIEW
extension StudentAllTasksViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return items.count
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

            // Use the stored team member data
            cell.configureProfiles(
                images: teamMemberImages,
                names: teamMemberNames
            )

            return cell

        case .category(let category):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TaskSectionCell",
                for: indexPath
            ) as! TaskSectionCell

            // Pass the appropriate tasks based on category
            let tasksForCategory = getTasksArray(for: category)
            
            cell.configureSection(type: category, tasks: tasksForCategory)
            
            // Handle edit action
            cell.onEditTask = { [weak self] task, taskIndex in
                guard let self = self else { return }
                self.presentNewTaskViewController(isEditMode: true, task: task, category: category, taskIndex: taskIndex)
            }
            
            // Handle attachment viewer
            cell.onViewAttachments = { [weak self] attachments in
                guard let self = self else { return }
                self.presentAttachmentViewer(attachments: attachments)
            }

            cell.seeAllTapped = { [weak self] in
                guard let self = self else { return }

                let tasks = self.getTasksArray(for: category)

                let seeAllVC = TaskSeeAllViewController(category: category, tasks: tasks)
                seeAllVC.delegate = self
                
                // Pass team member data for editing
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
        case .category(_):
            return CGSize(width: collectionView.frame.width, height: 240)
        }
    }
}
