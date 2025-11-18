import UIKit

// MARK: - TaskSeeAllViewController
class TaskSeeAllViewController: UIViewController {

    private var category: TaskCategory
    private var tasks: [TaskModel]

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
    }

    // MARK: - Setup Back Button
    private func setupBackButton() {
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        backButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16).isActive = true

        // Circular white background (frosted glass style)
        let blur = UIBlurEffect(style: .systemUltraThinMaterialLight)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.layer.cornerRadius = 20
        blurView.clipsToBounds = true
        blurView.isUserInteractionEnabled = false
        backButton.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.leadingAnchor.constraint(equalTo: backButton.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: backButton.trailingAnchor),
            
            blurView.topAnchor.constraint(equalTo: backButton.topAnchor),
            blurView.bottomAnchor.constraint(equalTo: backButton.bottomAnchor)
        ])

        // Black chevron icon
        let chevron = UIImageView(image: UIImage(systemName: "chevron.backward")?.withTintColor(.black, renderingMode: .alwaysOriginal))
        chevron.translatesAutoresizingMaskIntoConstraints = false
        backButton.addSubview(chevron)
        NSLayoutConstraint.activate([
            chevron.centerXAnchor.constraint(equalTo: backButton.centerXAnchor),
            chevron.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            chevron.widthAnchor.constraint(equalToConstant: 12),
            chevron.heightAnchor.constraint(equalToConstant: 20)
        ])

        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
    }

    @objc private func backButtonPressed() {
        dismiss(animated: true)
    }

    // MARK: - Setup Title
    private func setupTitleLabel() {
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 12),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
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

