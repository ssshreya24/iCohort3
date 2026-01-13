import UIKit

// MARK: - Models

struct OngoingTeam {
    let teamId: String
    let teamNo: Int
    let badgeCount: Int   // 🔴 ongoing_task
}

struct ReviewTask {
    let taskId: String
        let teamId: String
        let teamNo: Int
        let taskTitle: String
}
var teamMemberNames: [String: [String]] = [:]   // teamId -> [names]

// MARK: - Dashboard

class MDashboardViewController: UIViewController, ProfileViewControllerDelegate {

    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!

    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var todayCardView: UIView!
    @IBOutlet weak var todayTitleLabel: UILabel!
    @IBOutlet weak var todayCountLabel: UILabel!

    @IBOutlet weak var collectionView: UICollectionView!

    // ✅ MUST be set from login/session (this is people.id for mentor)
    var currentMentorId: String = ""
    var mentorDisplayName: String = "Mentor"

    var ongoingTeams: [OngoingTeam] = []
    var reviewTasks: [ReviewTask] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        if let img = UIImage(named: "ProfileImageMentor") {
            setProfileAvatarImage(img)
        }

        profileImageView.isUserInteractionEnabled = true

        applyBackgroundGradient()
        setupCollectionView()

        todayCardView.layer.cornerRadius = 16
        todayCardView.backgroundColor = .white
        todayCardView.layer.shadowColor = UIColor.black.cgColor
        todayCardView.layer.shadowOffset = CGSize(width: 0, height: 2)
        todayCardView.layer.shadowRadius = 8
        todayCardView.layer.shadowOpacity = 0.1

        collectionView.layer.cornerRadius = 16
        collectionView.backgroundColor = .clear

        greetingLabel.text = "Hi \(mentorDisplayName)"
        todayCountLabel.text = "0"

        Task { await loadDashboardFromSupabase() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
    }

    private func setProfileAvatarImage(_ image: UIImage) {
        profileImageView.image = image
        profileImageView.contentMode = .scaleAspectFit
        profileImageView.clipsToBounds = true
    }

    @IBAction func profileImageTapped(_ sender: UITapGestureRecognizer) {
        let vc = ProfileViewController(nibName: "ProfileViewController", bundle: nil)
        vc.modalPresentationStyle = .pageSheet
        vc.modalTransitionStyle = .coverVertical
        vc.delegate = self

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [
                .custom(identifier: .init("almostFull")) { context in
                    context.maximumDetentValue
                }
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.largestUndimmedDetentIdentifier = .init("almostFull")
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }

        present(vc, animated: true)
    }

    func profileViewController(_ controller: ProfileViewController, didUpdateAvatar image: UIImage) {
        setProfileAvatarImage(image)
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

    // MARK: - Supabase Fetch

    private let mentorId = "d9966327-b3ed-4fc8-9fbe-70c7148527f3"   // must match teams.mentor_id in DB
  

    private func loadDashboardFromSupabase() async {
        do {
            // 1) Fetch teams assigned to this mentor
            let teams = try await SupabaseManager.shared.fetchTeamsForMentor(mentorId: mentorId)
            print("✅ teams for mentor:", teams.count)

            let teamIds = teams.map { $0.id }
            for team in teams {
                let names = try await SupabaseManager.shared.fetchStudentNamesForTeam(teamId: team.id)
                teamMemberNames[team.id] = names
            }


            // 2) Fetch counters from team_task
            let taskRows = try await SupabaseManager.shared.fetchTeamTasks(teamIds: teamIds)
            print("✅ team_task rows:", taskRows.count)

            // Make a map: team_id -> TeamTaskRow
            let taskMap: [String: SupabaseManager.TeamTaskRow] = Dictionary(
                uniqueKeysWithValues: taskRows.map { ($0.team_id, $0) }
            )

            // 3) Map to Ongoing Teams section
            let mappedOngoing: [OngoingTeam] = teams.map { team in
                let counts = taskMap[team.id]
                return OngoingTeam(
                    teamId: team.id,
                    teamNo: team.team_no,
                    badgeCount: counts?.ongoing_task ?? 0
                )
            }

            // 4) Pending review total (card)
            let pendingReviewTotal = teams.reduce(0) { sum, team in
                let counts = taskMap[team.id]
                return sum + (counts?.for_review_task ?? 0)
            }

            // 5) Temporary list for "Tasks to review today"
            // (Until you have a real tasks table, we generate one line per team if for_review_task > 0)
            let mappedReview: [ReviewTask] = teams.compactMap { team in
                let counts = taskMap[team.id]
                let reviewCount = counts?.for_review_task ?? 0
                guard reviewCount > 0 else { return nil }

                return ReviewTask(
                    taskId: "pending-\(team.id)",
                    teamId: team.id,
                    teamNo: team.team_no,
                    taskTitle: "Pending reviews: \(reviewCount)"
                )
            }

            await MainActor.run {
                self.greetingLabel.text = "Hi \(self.mentorDisplayName)"
                self.ongoingTeams = mappedOngoing
                self.reviewTasks = mappedReview
                self.todayCountLabel.text = "\(pendingReviewTotal)"
                self.collectionView.reloadData()
            }

        } catch {
            print("❌ Dashboard fetch failed:", error)

            await MainActor.run {
                self.ongoingTeams = []
                self.reviewTasks = []
                self.todayCountLabel.text = "0"
                self.collectionView.reloadData()
            }
        }
    }

    // MARK: - Collection setup

    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = createLayout()
        collectionView.isUserInteractionEnabled = true
        collectionView.allowsSelection = true

        collectionView.register(EmptyStateCollectionViewCell.self, forCellWithReuseIdentifier: "EmptyCell")
    }
}

// MARK: - Layout

extension MDashboardViewController {

    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            sectionIndex == 0 ? self.horizontalSection() : self.verticalSection()
        }
    }

    func horizontalSection() -> NSCollectionLayoutSection {
        if ongoingTeams.isEmpty {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)

            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
            section.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                           elementKind: UICollectionView.elementKindSectionHeader,
                                                           alignment: .top)
            ]
            return section
        }

        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(90), heightDimension: .absolute(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .absolute(90), heightDimension: .absolute(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.orthogonalScrollingBehavior = .continuous
        section.contentInsets = .init(top: 8, leading: 16, bottom: 16, trailing: 16)
        section.interGroupSpacing = 8

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        section.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                       elementKind: UICollectionView.elementKindSectionHeader,
                                                       alignment: .top)
        ]
        return section
    }

    func verticalSection() -> NSCollectionLayoutSection {
        if reviewTasks.isEmpty {
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(60))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)

            let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)
            section.contentInsets = .init(top: 8, leading: 16, bottom: 20, trailing: 16)

            let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
            section.boundarySupplementaryItems = [
                NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                           elementKind: UICollectionView.elementKindSectionHeader,
                                                           alignment: .top)
            ]
            return section
        }

        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(80))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let group = NSCollectionLayoutGroup.vertical(layoutSize: itemSize, subitems: [item])

        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = .init(top: 8, leading: 16, bottom: 20, trailing: 16)
        section.interGroupSpacing = 12

        let headerSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(40))
        section.boundarySupplementaryItems = [
            NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerSize,
                                                       elementKind: UICollectionView.elementKindSectionHeader,
                                                       alignment: .top)
        ]
        return section
    }
}

// MARK: - DataSource

extension MDashboardViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        section == 0 ? (ongoingTeams.isEmpty ? 1 : ongoingTeams.count)
                     : (reviewTasks.isEmpty ? 1 : reviewTasks.count)
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
                cell.configure(with: item)   // ✅ FIX
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
                cell.configure(with: item)  // ✅ FIX
                return cell
            }
        }
    }


    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader",
            for: indexPath
        ) as! SectionHeaderView

        header.titleLabel.text = indexPath.section == 0 ? "Ongoing Tasks" : "Tasks To Review Today"
        return header
    }
}

// MARK: - Delegate

extension MDashboardViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {

        if indexPath.section == 0 && !ongoingTeams.isEmpty {
            let selected = ongoingTeams[indexPath.item]
            let vc = StudentAllTasksViewController(nibName: "StudentAllTasksViewController", bundle: nil)
            vc.teamId = selected.teamId
            vc.teamNo = selected.teamNo
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            return
        }

        if indexPath.section == 1 && !reviewTasks.isEmpty {
            let selected = reviewTasks[indexPath.item]

            let reviewVC = ReviewViewController(nibName: "ReviewViewController", bundle: nil)
            reviewVC.teamId = selected.teamId
            reviewVC.teamNo = selected.teamNo
            reviewVC.taskId = selected.taskId
            reviewVC.taskTitle = selected.taskTitle

            reviewVC.modalPresentationStyle = .fullScreen
            present(reviewVC, animated: true)
        }

    }
}
