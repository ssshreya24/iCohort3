import UIKit

// MARK: - Struct Model
struct OngoingTeam {
    let name: String
    let badge: Int
}

class MDashboardViewController: UIViewController {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!

    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var todayCardView: UIView!
    @IBOutlet weak var todayCountLabel: UILabel!

    @IBOutlet weak var ongoingTitleLabel: UILabel!
    @IBOutlet weak var ongoingCollectionView: UICollectionView!

    @IBOutlet weak var reviewTitleLabel: UILabel!
    @IBOutlet weak var reviewStackView: UIStackView!

    // MARK: - Data
    var ongoingTeams: [OngoingTeam] = []
    var reviewTasks: [[String: String]] = []
    
    // Empty state labels
    var teamsEmptyLabel: UILabel?
    var reviewEmptyLabel: UILabel?


    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupGradients()

        // Register Custom Cell
        ongoingCollectionView.register(
            UINib(nibName: "OngoingTeamCell", bundle: nil),
            forCellWithReuseIdentifier: "OngoingTeamCell"
        )

        ongoingCollectionView.dataSource = self
        ongoingCollectionView.delegate = self
        
        todayCardView.layer.cornerRadius = 20

        setupCollectionView()
        
        // Show empty states initially
        showInitialEmptyStates()
        
        // Load data after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            self?.loadData()
            self?.updateUI()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        // update all gradient layers dynamically during rotation/layout
        updateGradientFrames(in: view)
        updateGradientFrames(in: contentView)
    }


    // MARK: - Gradient Setup
    private func setupGradients() {
        addGradient(to: view)
        addGradient(to: contentView)
    }

    private func addGradient(to targetView: UIView) {
        // Prevent adding duplicate layers
        if let _ = targetView.layer.sublayers?.first(where: { $0.name == "dashboardGradient" }) {
            return
        }

        let gradient = CAGradientLayer()
        gradient.name = "dashboardGradient"

        gradient.colors = [
            UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1).cgColor,
            UIColor(white: 0.95, alpha: 1).cgColor
        ]

        gradient.locations = [0.0, 1.0]
        gradient.startPoint = CGPoint(x: 0.5, y: 0)
        gradient.endPoint = CGPoint(x: 0.5, y: 1)
        gradient.frame = targetView.bounds

        targetView.layer.insertSublayer(gradient, at: 0)
    }

    private func updateGradientFrames(in targetView: UIView) {
        if let gradient = targetView.layer.sublayers?.first(where: { $0.name == "dashboardGradient" }) as? CAGradientLayer {
            gradient.frame = targetView.bounds
        }
    }


    // MARK: - Collection View Setup
    func setupCollectionView() {
        let flow = UICollectionViewFlowLayout()
        flow.scrollDirection = .horizontal
        flow.itemSize = CGSize(width: 100, height: 110)
        flow.minimumLineSpacing = 2
        flow.sectionInset = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        ongoingCollectionView.collectionViewLayout = flow
        ongoingCollectionView.showsHorizontalScrollIndicator = false
        ongoingCollectionView.backgroundColor = .clear
    }


    // MARK: - Initial Empty States
    func showInitialEmptyStates() {
        // Hide card and show count as 0
        todayCardView.isHidden = false
        todayCountLabel.text = "0"
        
        // Show "No Teams Assigned Yet" in collection view area
        let teamsLabel = UILabel()
        teamsLabel.text = "No Teams Assigned Yet"
        teamsLabel.textAlignment = .center
        teamsLabel.font = .systemFont(ofSize: 16, weight: .medium)
        teamsLabel.textColor = .gray
        teamsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        ongoingCollectionView.addSubview(teamsLabel)
        
        NSLayoutConstraint.activate([
            teamsLabel.centerXAnchor.constraint(equalTo: ongoingCollectionView.centerXAnchor),
            teamsLabel.centerYAnchor.constraint(equalTo: ongoingCollectionView.centerYAnchor)
        ])
        
        teamsEmptyLabel = teamsLabel
        
        // Show "No Tasks Assigned Yet" in review section
        let reviewLabel = UILabel()
        reviewLabel.text = "No Tasks Assigned Yet"
        reviewLabel.textAlignment = .center
        reviewLabel.font = .systemFont(ofSize: 16, weight: .medium)
        reviewLabel.textColor = .gray
        reviewLabel.translatesAutoresizingMaskIntoConstraints = false
        
        reviewStackView.addArrangedSubview(reviewLabel)
        reviewEmptyLabel = reviewLabel
    }
    
    // MARK: - Remove Empty States
    func removeEmptyStates() {
        teamsEmptyLabel?.removeFromSuperview()
        teamsEmptyLabel = nil
        
        reviewEmptyLabel?.removeFromSuperview()
        reviewEmptyLabel = nil
    }


    // MARK: - Load Data
    func loadData() {
        ongoingTeams = [
            OngoingTeam(name: "Team 7", badge: 2),
            OngoingTeam(name: "Team 8", badge: 1),
            OngoingTeam(name: "Team 9", badge: 5),
            OngoingTeam(name: "Team 10", badge: 3),
            OngoingTeam(name: "Team 11", badge: 0)
        ]

        reviewTasks = [
            ["team": "Team 9", "task": "Upload UI/UX Colour Palette"],
            ["team": "Team 7", "task": "Flow of Features and Functionalities"],
            ["team": "Team 12", "task": "User Research with proof"]
        ]
    }


    // MARK: - Update UI
    func updateUI() {
        let hasData = !ongoingTeams.isEmpty || !reviewTasks.isEmpty

        if hasData {
            // Remove empty state labels
            removeEmptyStates()
            
            todayCountLabel.text = "\(reviewTasks.count)"
            setupReviewTasks()
            
            // Reload collection view with animation
            UIView.transition(with: ongoingCollectionView, duration: 0.3, options: .transitionCrossDissolve) {
                self.ongoingCollectionView.reloadData()
            }
        }
    }


    // MARK: - Review Section
    func setupReviewTasks() {
        reviewStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for item in reviewTasks {
            let card = createTaskCard(team: item["team"] ?? "", task: item["task"] ?? "")
            reviewStackView.addArrangedSubview(card)
        }
    }

    func createTaskCard(team: String, task: String) -> UIView {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.backgroundColor = .white
        view.heightAnchor.constraint(equalToConstant: 70).isActive = true

        let title = UILabel()
        title.font = .boldSystemFont(ofSize: 16)
        title.text = team

        let detail = UILabel()
        detail.font = .systemFont(ofSize: 14)
        detail.textColor = .darkGray
        detail.text = task

        let arrow = UIImageView(image: UIImage(systemName: "chevron.right"))
        arrow.tintColor = .gray

        let stack = UIStackView(arrangedSubviews: [title, detail])
        stack.axis = .vertical
        stack.spacing = 4

        view.addSubview(stack)
        view.addSubview(arrow)

        stack.translatesAutoresizingMaskIntoConstraints = false
        arrow.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            arrow.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            arrow.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        return view
    }


    // MARK: - Empty State (Not used in this flow)
    func showEmptyState() {
        let label = UILabel()
        label.text = "No Tasks Assigned Yet"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .semibold)
        label.textColor = .gray
        label.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 50)
        ])
    }
}


// MARK: - Collection View Extension
extension MDashboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return ongoingTeams.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OngoingTeamCell", for: indexPath) as! OngoingTeamCell

        let team = ongoingTeams[indexPath.item]

        cell.teamLabel.text = team.name
        cell.badgeLabel.text = "\(team.badge)"
        cell.iconImageView.image = UIImage(systemName: "person.3.fill")

        return cell
    }
}
