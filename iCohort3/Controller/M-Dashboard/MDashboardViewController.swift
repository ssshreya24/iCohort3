import UIKit

// MARK: - Models

struct OngoingTeam {
    let teamId: String
    let teamNo: Int
    let activeTaskCount: Int
}

struct ReviewTask {
    let taskId: String
    let teamId: String
    let teamNo: Int
    let taskTitle: String
}
var teamMemberNames: [String: [String]] = [:]

// MARK: - Dashboard

class MDashboardViewController: UIViewController, ProfileViewControllerDelegate {

    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!

    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var todayCardView: UIView!
    @IBOutlet weak var todayTitleLabel: UILabel!
    @IBOutlet weak var todayCountLabel: UILabel!

    @IBOutlet weak var collectionView: UICollectionView!

    // ✅ Updated: Gets person_id from UserDefaults
    var currentMentorId: String = ""
    var mentorDisplayName: String = "Mentor"

    var ongoingTeams: [OngoingTeam] = []
    var reviewTasks: [ReviewTask] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ✅ Set default greeting immediately to avoid showing nothing
        greetingLabel?.text = "Hi Mentor"
        
        // ✅ Get mentor ID from UserDefaults
        if let personId = UserDefaults.standard.string(forKey: "current_person_id") {
            currentMentorId = personId
            print("✅ Current mentor ID loaded:", currentMentorId)
        } else {
            print("⚠️ No current_person_id found in UserDefaults")
        }
        
        // ✅ Load mentor greeting from Supabase
        loadMentorGreeting()

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

        todayCountLabel.text = "0"

        // Load dashboard data
        Task { await loadDashboardFromSupabase() }
    }
    
    // ✅ IMPROVED: Load mentor greeting from Supabase with better error handling
    private func loadMentorGreeting() {
        // First, try to use stored name as immediate fallback
        if let storedName = UserDefaults.standard.string(forKey: "current_user_name"), !storedName.isEmpty {
            let firstName = storedName.components(separatedBy: " ").first ?? "Mentor"
            self.mentorDisplayName = firstName
            self.greetingLabel?.text = "Hi \(firstName)"
            print("✅ Using stored name immediately:", firstName)
        }
        
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"), !personId.isEmpty else {
            print("⚠️ No person ID found, keeping default/stored greeting")
            return
        }
        
        print("🔄 Loading greeting for person ID:", personId)
        
        Task {
            do {
                // Fetch mentor greeting from Supabase
                let greeting = try await SupabaseManager.shared.getMentorGreeting(personId: personId)
                
                // Extract just the name from "Hi [Name]" format
                let name = greeting.replacingOccurrences(of: "Hi ", with: "")
                
                await MainActor.run {
                    self.mentorDisplayName = name
                    self.greetingLabel?.text = greeting
                    print("✅ Greeting loaded:", greeting)
                    
                    // Also store the name for future use
                    if !name.isEmpty && name != "Mentor" {
                        UserDefaults.standard.set(name, forKey: "current_user_name")
                    }
                }
            } catch {
                print("❌ Error fetching greeting:", error)
                // Keep the existing greeting (already set from stored name or default)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ✅ Refresh greeting when view appears (in case profile was updated)
        loadMentorGreeting()
        
        // ✅ Reload dashboard data
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

    private func loadDashboardFromSupabase() async {
        // ✅ Use currentMentorId from UserDefaults
        guard !currentMentorId.isEmpty else {
            print("❌ No mentor ID available")
            await MainActor.run {
                self.ongoingTeams = []
                self.reviewTasks = []
                self.todayCountLabel.text = "0"
                self.collectionView.reloadData()
            }
            return
        }
        
        print("🔄 Loading dashboard for mentor ID:", currentMentorId)
        
        do {
            // 1) Fetch teams assigned to this mentor
            let teams = try await SupabaseManager.shared.fetchTeamsForMentor(mentorId: currentMentorId)
            print("✅ Found \(teams.count) teams for mentor")

            let teamIds = teams.map { $0.id }
            
            // 2) Fetch student names for each team
            for team in teams {
                let names = try await SupabaseManager.shared.fetchStudentNamesForTeam(teamId: team.id)
                teamMemberNames[team.id] = names
            }

            // 3) Fetch counters from team_task
            let taskRows = try await SupabaseManager.shared.fetchTeamTasks(teamIds: teamIds)
            print("✅ Found task data for \(taskRows.count) teams")

            // Make a map: team_id -> TeamTaskRow
            let taskMap: [String: SupabaseManager.TeamTaskRow] = Dictionary(
                uniqueKeysWithValues: taskRows.map { ($0.team_id, $0) }
            )

            // 4) Map to Ongoing Teams section
            let mappedOngoing: [OngoingTeam] = teams.map { team in
                let counts = taskMap[team.id]

                let assigned = counts?.assigned_task ?? 0
                let ongoing  = counts?.ongoing_task ?? 0
                let review   = counts?.for_review_task ?? 0
                let prepared = counts?.prepared_task ?? 0
                let approved = counts?.approved_task ?? 0

                let active = assigned + ongoing + review + prepared + approved

                return OngoingTeam(
                    teamId: team.id,
                    teamNo: team.team_no,
                    activeTaskCount: active
                )
            }

            // 5) Pending review total (card)
            let pendingReviewTotal = teams.reduce(0) { sum, team in
                let counts = taskMap[team.id]
                return sum + (counts?.for_review_task ?? 0)
            }

            // 6) Temporary list for "Tasks to review today"
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
                self.ongoingTeams = mappedOngoing
                self.reviewTasks = mappedReview
                self.todayCountLabel.text = "\(pendingReviewTotal)"
                self.collectionView.reloadData()
                
                print("✅ Dashboard loaded: \(mappedOngoing.count) teams, \(pendingReviewTotal) reviews pending")
            }

        } catch {
            print("❌ Dashboard fetch failed:", error)
            print("   Error details: \(error.localizedDescription)")

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
