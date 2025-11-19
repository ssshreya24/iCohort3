import UIKit

struct OngoingTeam {
    let name: String
    let badgeCount: Int
}

struct ReviewTask {
    let teamName: String
    let taskTitle: String
}

class MDashboardViewController: UIViewController {

    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var todayCardView: UIView!
    @IBOutlet weak var todayTitleLabel: UILabel!
    @IBOutlet weak var todayCountLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!

    var ongoingTeams: [OngoingTeam] = []
    var reviewTasks: [ReviewTask] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyBackgroundGradient()
        setupCollectionView()
        
        greetingLabel.text = "Hi User"
        
        todayCardView.layer.cornerRadius = 16
        todayCardView.backgroundColor = .white
        todayCardView.layer.shadowColor = UIColor.black.cgColor
        todayCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        todayCardView.layer.shadowRadius = 8
        todayCardView.layer.shadowOpacity = 0.1
        
        collectionView.layer.cornerRadius = 16
        collectionView.backgroundColor = .clear
        
        loadSampleDataWithDelay()
    }

    @IBAction func profileTapped(_ sender: Any) {
        let vc = ProfileViewController(nibName: "ProfileViewController", bundle: nil)
        vc.modalPresentationStyle = .pageSheet
        vc.modalTransitionStyle = .coverVertical

        if let sheet = vc.sheetPresentationController {
            let topGap: CGFloat = 0
            sheet.detents = [
                .custom(identifier: .init("almostFull")) { context in
                    context.maximumDetentValue - topGap
                }
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.largestUndimmedDetentIdentifier = .init("almostFull")
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        present(vc, animated: true)
    }

    private func applyBackgroundGradient() {
        let g = CAGradientLayer()
        g.frame = view.bounds
        g.colors = [
            UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1).cgColor,
            UIColor(white: 0.95, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(g, at: 0)
    }

    func loadSampleDataWithDelay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.loadSampleData()
        }
    }

    func loadSampleData() {
        greetingLabel.text = "Hi Arshad"
        
        ongoingTeams = [
            OngoingTeam(name: "Team 7", badgeCount: 3),
            OngoingTeam(name: "Team 8", badgeCount: 1),
            OngoingTeam(name: "Team 9", badgeCount: 4),
            OngoingTeam(name: "Team 10", badgeCount: 1),
            OngoingTeam(name: "Team 11", badgeCount: 2),
            OngoingTeam(name: "Team 12", badgeCount: 5),
            OngoingTeam(name: "Team 13", badgeCount: 3)
        ]
        
        reviewTasks = [
            ReviewTask(teamName: "Team 9", taskTitle: "Upload UI/UX Colour Palette"),
            ReviewTask(teamName: "Team 7", taskTitle: "Flow of Features and Functionalities"),
            ReviewTask(teamName: "Team 12", taskTitle: "User Research with proof"),
            ReviewTask(teamName: "Team 8", taskTitle: "Final design review and approval"),
            ReviewTask(teamName: "Team 10", taskTitle: "Sprint planning documentation")
        ]
        
        todayCountLabel.text = "\(reviewTasks.count)"
        
        UIView.transition(with: collectionView,
                         duration: 0.3,
                         options: .transitionCrossDissolve,
                         animations: {
            self.collectionView.reloadData()
        })
    }

    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = createLayout()
        
        collectionView.register(EmptyStateCollectionViewCell.self, forCellWithReuseIdentifier: "EmptyCell")
    }
}

// MARK: - Layouts
extension MDashboardViewController {

    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            return sectionIndex == 0 ? self.horizontalSection() : self.verticalSection()
        }
    }

    func horizontalSection() -> NSCollectionLayoutSection {
        if ongoingTeams.isEmpty {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
            return section
        }

        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(90), heightDimension: .absolute(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = .init(top: 8, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 8
        return section
    }

    func verticalSection() -> NSCollectionLayoutSection {
        if reviewTasks.isEmpty {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 8, leading: 16, bottom: 20, trailing: 16)
            return section
        }

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 16, bottom: 20, trailing: 16)
        section.interGroupSpacing = 12
        return section
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension MDashboardViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return ongoingTeams.isEmpty ? 1 : ongoingTeams.count }
        return reviewTasks.isEmpty ? 1 : reviewTasks.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
            if ongoingTeams.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath) as! EmptyStateCollectionViewCell
                cell.configure(with: "You're not assigned to any teams at the moment.")
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OngoingCell", for: indexPath) as! OngoingCollectionViewCell
                let item = ongoingTeams[indexPath.item]
                cell.configure(with: item)
                return cell
            }
        } else {
            if reviewTasks.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath) as! EmptyStateCollectionViewCell
                cell.configure(with: "No tasks to review Today")
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReviewCell", for: indexPath) as! ReviewCollectionViewCell
                let item = reviewTasks[indexPath.item]
                cell.configure(with: item)
                return cell
            }
        }
    }

    // ✅ Updated didSelectItemAt with modal presentation
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 && !ongoingTeams.isEmpty {
            let selectedTeam = ongoingTeams[indexPath.item]
            
            let studentVC = StudentAllTasksViewController(nibName: "StudentAllTasksViewController", bundle: nil)
            studentVC.teamName = selectedTeam.name
            studentVC.modalPresentationStyle = .fullScreen
            studentVC.modalTransitionStyle = .coverVertical
            self.present(studentVC, animated: true)
        }

        if indexPath.section == 1 && !reviewTasks.isEmpty {
            print("Open task:", reviewTasks[indexPath.item].taskTitle)
        }
    }
}

// MARK: - Empty State Cell
class EmptyStateCollectionViewCell: UICollectionViewCell {
    let messageLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = UIColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        label.font = .systemFont(ofSize: 15)
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func setupUI() {
        contentView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            messageLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }

    func configure(with message: String) {
        messageLabel.text = message
    }
}

