import UIKit

// MARK: - TaskSeeAllViewController
class TaskSeeAllViewController: UIViewController {

    private var category: TaskCategory
    private var tasks: [TaskModel]

    // UI Elements
    private let editButton = UIButton()
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
        setupEditButton()
        setupTitleLabel()
        setupCollectionView()
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
            systemName: "chevron.backward",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        )?.withTintColor(.black, renderingMode: .alwaysOriginal)

        backButton.setImage(chevron, for: .normal)

        // Center image
        backButton.imageView?.contentMode = .scaleAspectFit

        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
    }


    @objc private func backButtonPressed() {
        dismiss(animated: true)
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
    
    private func setupEditButton() {
        view.addSubview(editButton)
        editButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            editButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            editButton.widthAnchor.constraint(equalToConstant: 70), // Extra width for "Edit"
            editButton.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Same style as back button
        editButton.backgroundColor = .white
        editButton.layer.cornerRadius = 22
        editButton.layer.masksToBounds = true

        // Text instead of icon
        editButton.setTitle("Edit", for: .normal)
        editButton.setTitleColor(.black, for: .normal)
        editButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)

        editButton.addTarget(self, action: #selector(editButtonPressed), for: .touchUpInside)
    }


    @objc private func editButtonPressed() {
        let newTaskVC = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)

        newTaskVC.modalPresentationStyle = .pageSheet
        
        if let sheet = newTaskVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(newTaskVC, animated: true)
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
            remarkDesc: task.remarkDesc
        )
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 170)
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
        guard let fromView = transitionContext.view(forKey: .from) else { return }

        UIView.animate(withDuration: 0.35, animations: {
            fromView.frame = fromView.frame.offsetBy(dx: fromView.frame.width, dy: 0)
        }) { finished in
            transitionContext.completeTransition(finished)
        }
    }
}

