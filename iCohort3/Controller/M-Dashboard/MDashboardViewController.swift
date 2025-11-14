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
        setupCollectionView()
        
        todayCardView.layer.cornerRadius = 16
        
        collectionView.layer.cornerRadius = 16
        // Empty arrays - showing empty states
    }

    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = createLayout()
        
        // Register the empty state cell
        collectionView.register(EmptyStateCollectionViewCell.self, forCellWithReuseIdentifier: "EmptyCell")
    }
    
}


extension MDashboardViewController {
    
    func createLayout() -> UICollectionViewLayout {
        return UICollectionViewCompositionalLayout { sectionIndex, _ in
            return sectionIndex == 0 ?
                self.horizontalSection() :
                self.verticalSection()
        }
    }

    func horizontalSection() -> NSCollectionLayoutSection {
        // Check if empty state
        if ongoingTeams.isEmpty {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .absolute(60))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                   heightDimension: .absolute(60))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
            
            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                    heightDimension: .absolute(40))
            section.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
            ]
            return section
        }
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(84),
                                              heightDimension: .absolute(110))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .absolute(110))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)

        // header
        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                heightDimension: .absolute(40))
        section.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
        ]
        return section
    }

    func verticalSection() -> NSCollectionLayoutSection {
        // Check if empty state
        if reviewTasks.isEmpty {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                                  heightDimension: .absolute(60))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            
            let group = NSCollectionLayoutGroup.vertical(
                layoutSize: itemSize,
                subitems: [item]
            )
            
            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 8, leading: 16, bottom: 20, trailing: 16)
            
            let headerSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .absolute(40)
            )
            section.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(
                    layoutSize: headerSize,
                    elementKind: UICollectionView.elementKindSectionHeader,
                    alignment: .top
                )
            ]
            
            return section
        }
        
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: itemSize,
            subitems: [item]
        )

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 0, bottom: 20, trailing: 0)

        let headerSize = NSCollectionLayoutSize(
            widthDimension: .fractionalWidth(1.0),
            heightDimension: .absolute(40)
        )
        section.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(
                layoutSize: headerSize,
                elementKind: UICollectionView.elementKindSectionHeader,
                alignment: .top
            )
        ]

        return section
    }
}


extension MDashboardViewController: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return ongoingTeams.isEmpty ? 1 : ongoingTeams.count
        } else {
            return reviewTasks.isEmpty ? 1 : reviewTasks.count
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
            if ongoingTeams.isEmpty {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "EmptyCell", for: indexPath
                ) as! EmptyStateCollectionViewCell
                cell.configure(with: "You're not assigned to any teams at the moment.")
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "OngoingCell", for: indexPath
                ) as! OngoingCollectionViewCell
                let item = ongoingTeams[indexPath.item]
                cell.configure(with: item)
                return cell
            }
        } else {
            if reviewTasks.isEmpty {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "EmptyCell", for: indexPath
                ) as! EmptyStateCollectionViewCell
                cell.configure(with: "No tasks to review Today")
                return cell
            } else {
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: "ReviewCell", for: indexPath
                ) as! ReviewCollectionViewCell
                let item = reviewTasks[indexPath.item]
                cell.configure(with: item)
                return cell
            }
        }
    }

    // HEADER
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader",
            for: indexPath
        ) as! SectionHeaderView
        
        header.titleLabel.text = indexPath.section == 0
            ? "Ongoing Tasks"
            : "Tasks to Review Today"
        
        return header
    }
}

extension MDashboardViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
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
