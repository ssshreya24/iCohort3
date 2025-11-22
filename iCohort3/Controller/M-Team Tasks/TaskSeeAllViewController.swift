import UIKit

// Protocol to notify parent about changes
protocol TaskSeeAllDelegate: AnyObject {
    func didUpdateTask(in category: TaskCategory, at index: Int, with task: TaskModel)
    func didDeleteTask(in category: TaskCategory, at index: Int)
}

// MARK: - TaskSeeAllViewController
class TaskSeeAllViewController: UIViewController {

    weak var delegate: TaskSeeAllDelegate?
    
    private var category: TaskCategory
    private var tasks: [TaskModel]
    
    // Store team member data for editing
    var teamMemberImages: [UIImage] = []
    var teamMemberNames: [String] = []

    // UI Elements
    private let backButton = UIButton()
    private let titleLabel = UILabel()
    private let collectionView: UICollectionView

    // MARK: - Init
    init(category: TaskCategory, tasks: [TaskModel]) {
        self.category = category
        self.tasks = tasks

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        transitioningDelegate = self // custom transition
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)

        setupBackButton()
        setupTitleLabel()
        setupCollectionView()
        
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

    // MARK: - Setup Back Button
    private func setupBackButton() {
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])

        // Make the button circular
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 22
        backButton.layer.masksToBounds = true

        // Black chevron
        let chevron = UIImage(
            systemName: "chevron.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        )?.withTintColor(.black, renderingMode: .alwaysOriginal)

        backButton.setImage(chevron, for: .normal)

        // Center image
        backButton.imageView?.contentMode = .scaleAspectFit

        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
    }

    @objc private func backButtonPressed() {
        self.dismiss(animated: true)
    }

    private func setupTitleLabel() {
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])

        switch category {
        case .assigned:
            titleLabel.text = "Assigned"
            titleLabel.textColor = .systemBlue
        case .review:
            titleLabel.text = "For Review"
            titleLabel.textColor = .systemYellow
        case .completed:
            titleLabel.text = "Completed"
            titleLabel.textColor = .systemGreen
        case .rejected:
            titleLabel.text = "Rejected"
            titleLabel.textColor = .systemRed
        }
    }

    // MARK: - Setup Collection View
    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "TaskCardCellNew", bundle: nil), forCellWithReuseIdentifier: "TaskCardCellNew")
    }
    
    // MARK: - Handle Delete Task
    @objc private func handleDeleteTask(_ notification: Notification) {
        guard let cell = notification.userInfo?["cell"] as? TaskCardCellNew,
              let indexPath = collectionView.indexPath(for: cell) else {
            return
        }
        
        // Show confirmation
        let alert = UIAlertController(
            title: "Delete Task",
            message: "Are you sure you want to delete this task?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            
            // Remove from local array
            self.tasks.remove(at: indexPath.row)
            
            // Notify delegate
            self.delegate?.didDeleteTask(in: self.category, at: indexPath.row)
            
            // Update UI
            self.collectionView.deleteItems(at: [indexPath])
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Present Edit Task
    private func presentEditTask(at index: Int) {
        let task = tasks[index]
        
        let newTaskVC = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)
        newTaskVC.delegate = self
        
        // Pass team member data
        newTaskVC.teamMemberImages = teamMemberImages
        newTaskVC.teamMemberNames = teamMemberNames
        
        // Configure for edit mode
        newTaskVC.isEditMode = true
        newTaskVC.existingTitle = task.title
        newTaskVC.existingDescription = task.desc
        newTaskVC.existingDate = task.assignedDate
        newTaskVC.selectedMemberName = task.name
        newTaskVC.existingAttachments = task.attachments ?? []
        newTaskVC.editingTaskIndex = index
        
        newTaskVC.modalPresentationStyle = .pageSheet
        if let sheet = newTaskVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(newTaskVC, animated: true)
    }
    
    // MARK: - Present Attachment Viewer
    private func presentAttachmentViewer(attachments: [UIImage]) {
        let viewerVC = AttachmentViewerViewController(attachments: attachments)
        viewerVC.modalPresentationStyle = .fullScreen
        viewerVC.modalTransitionStyle = .crossDissolve
        present(viewerVC, animated: true)
    }
}

// MARK: - NewTaskDelegate
extension TaskSeeAllViewController: NewTaskDelegate {
    func didAssignTask(to memberName: String, description: String, date: Date, title: String, attachments: [UIImage]) {
        // Not used in edit mode, but required by protocol
    }
    
    func didUpdateTask(at index: Int, memberName: String, description: String, date: Date, title: String, attachments: [UIImage]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yyyy"
        let dateString = dateFormatter.string(from: date)
        
        // Update local task
        let updatedTask = TaskModel(
            name: memberName,
            desc: description,
            date: dateString,
            remark: tasks[index].remark,
            remarkDesc: tasks[index].remarkDesc,
            title: title,
            attachments: attachments,
            assignedDate: date
        )
        
        tasks[index] = updatedTask
        
        // Notify delegate to update parent view controller
        delegate?.didUpdateTask(in: category, at: index, with: updatedTask)
        
        // Reload the specific cell
        collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
        
        // Show confirmation
        let alert = UIAlertController(
            title: "Task Updated",
            message: "Task '\(title)' successfully updated",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CollectionView
extension TaskSeeAllViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tasks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TaskCardCellNew", for: indexPath) as! TaskCardCellNew
        let task = tasks[indexPath.row]

        cell.configure(
            profile: UIImage(named: "Student"),
            assignedTo: "Assigned To",
            name: task.name,
            desc: task.desc,
            date: task.date,
            remark: task.remark,
            remarkDesc: task.remarkDesc,
            title: task.title,
            attachments: task.attachments
        )
        
        // Handle ellipsis menu for edit
        cell.onEllipsisMenu = { [weak self] _ in
            guard let self = self else { return }
            self.presentEditTask(at: indexPath.row)
        }
        
        // Handle attachment viewer
        cell.onAttachmentTapped = { [weak self] attachments in
            guard let self = self else { return }
            self.presentAttachmentViewer(attachments: attachments)
        }
        
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let task = tasks[indexPath.row]
        
        // Adjust height based on whether task has remarks
        var height: CGFloat = 170
        if task.remark != nil && task.remarkDesc != nil {
            height = 200
        }
        
        return CGSize(width: collectionView.frame.width, height: height)
    }
}

// MARK: - Custom Transition
extension TaskSeeAllViewController: UIViewControllerTransitioningDelegate {

    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideInFromRightAnimator()
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return SlideOutToRightAnimator()
    }
}

// MARK: - Slide In From Right
class SlideInFromRightAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.35 }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let toView = transitionContext.view(forKey: .to) else { return }
        let container = transitionContext.containerView
        container.addSubview(toView)

        // Start off-screen to the right
        toView.frame = container.bounds.offsetBy(dx: container.bounds.width, dy: 0)

        UIView.animate(withDuration: 0.35, animations: {
            toView.frame = container.bounds
        }) { finished in
            transitionContext.completeTransition(finished)
        }
    }
}

// MARK: - Slide Out To Right
class SlideOutToRightAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval { 0.35 }

    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to) else { return }

        let container = transitionContext.containerView

        // Add the destination view behind the current view
        container.insertSubview(toView, belowSubview: fromView)

        // Final position: pushed to the right
        let finalFrame = fromView.frame.offsetBy(dx: container.bounds.width, dy: 0)

        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {
            fromView.frame = finalFrame
        }, completion: { finished in
            transitionContext.completeTransition(finished)
        })
    }
}


