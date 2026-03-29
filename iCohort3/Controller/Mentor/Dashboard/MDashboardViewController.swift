//
//  MDashboardViewController.swift
//  iCohort3
//

import UIKit
import PostgREST
import Supabase

// MARK: - Models

struct OngoingTeam {
    let teamId:          String
    let teamNo:          Int
    let activeTaskCount: Int
}

struct ReviewTask {
    let taskId:    String
    let taskTitle: String
    let teamId:    String
    let teamNo:    Int
    let dueDate:   String   // formatted "dd MMM yyyy"
}

var teamMemberNames: [String: [String]] = [:]

// MARK: - Dashboard

class MDashboardViewController: UIViewController, ProfileViewControllerDelegate {

    @IBOutlet weak var greetingLabel:    UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var separatorView:    UIView!
    @IBOutlet weak var todayCardView:    UIView!
    @IBOutlet weak var todayTitleLabel:  UILabel!
    @IBOutlet weak var todayCountLabel:  UILabel!
    @IBOutlet weak var collectionView:   UICollectionView!

    private let notificationButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        let symbolConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        config.image = UIImage(systemName: "bell", withConfiguration: symbolConfig)
        config.baseForegroundColor = .black
        button.configuration = config
        return button
    }()

    private let notificationBadgeLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = .systemRed
        label.textColor = .white
        label.font = .systemFont(ofSize: 11, weight: .bold)
        label.textAlignment = .center
        label.layer.cornerRadius = 10
        label.clipsToBounds = true
        label.isHidden = true
        return label
    }()

    var currentMentorId:    String = ""
    var mentorDisplayName:  String = "Mentor"

    var ongoingTeams: [OngoingTeam] = []
    var reviewTasks:  [ReviewTask]  = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        greetingLabel?.text = "Hi Mentor"

        if let personId = UserDefaults.standard.string(forKey: "current_person_id") {
            currentMentorId = personId
        }

        loadMentorGreeting()
        loadMentorAvatar()

        profileImageView.isUserInteractionEnabled = true
        applyBackgroundGradient()
        styleProfileButton()
        setupNotificationButton()
        setupCollectionView()

        todayCardView.layer.cornerRadius  = 16
        todayCardView.backgroundColor     = .white
        todayCardView.layer.shadowColor   = UIColor.black.cgColor
        todayCardView.layer.shadowOffset  = CGSize(width: 0, height: 2)
        todayCardView.layer.shadowRadius  = 8
        todayCardView.layer.shadowOpacity = 0.1

        collectionView.layer.cornerRadius = 16
        collectionView.backgroundColor    = .clear

        todayCountLabel.text = "0"

        Task { await loadDashboardFromSupabase() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadMentorGreeting()
        loadMentorAvatar()
        refreshNotificationBadge()
        Task { await loadDashboardFromSupabase() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.clipsToBounds = true
        profileImageView.contentMode = .scaleAspectFill
        syncProfileButtonSize()
    }

    private func styleProfileButton() {
        profileImageView.backgroundColor = .white
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        profileImageView.layer.shadowColor = UIColor.black.cgColor
        profileImageView.layer.shadowOpacity = 0.08
        profileImageView.layer.shadowRadius = 8
        profileImageView.layer.shadowOffset = CGSize(width: 0, height: 3)
        profileImageView.layer.masksToBounds = false
        profileImageView.tintColor = .black
        syncProfileButtonSize()
    }

    private func syncProfileButtonSize() {
        for constraint in profileImageView.constraints {
            if constraint.firstAttribute == .width || constraint.firstAttribute == .height {
                constraint.constant = 40
            }
        }
        profileImageView.layer.cornerRadius = 20
    }

    private func setupNotificationButton() {
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
        view.addSubview(notificationButton)
        view.addSubview(notificationBadgeLabel)

        notificationButton.backgroundColor = .white
        notificationButton.layer.cornerRadius = 20
        notificationButton.layer.shadowColor = UIColor.black.cgColor
        notificationButton.layer.shadowOpacity = 0.08
        notificationButton.layer.shadowRadius = 8
        notificationButton.layer.shadowOffset = CGSize(width: 0, height: 3)
        notificationButton.clipsToBounds = false

        NSLayoutConstraint.activate([
            notificationButton.widthAnchor.constraint(equalToConstant: 40),
            notificationButton.heightAnchor.constraint(equalToConstant: 40),
            notificationButton.trailingAnchor.constraint(equalTo: profileImageView.leadingAnchor, constant: -12),
            notificationButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),

            notificationBadgeLabel.centerXAnchor.constraint(equalTo: notificationButton.trailingAnchor, constant: -2),
            notificationBadgeLabel.centerYAnchor.constraint(equalTo: notificationButton.topAnchor, constant: 2),
            notificationBadgeLabel.heightAnchor.constraint(equalToConstant: 20),
            notificationBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])
    }

    private func refreshNotificationBadge() {
        guard !currentMentorId.isEmpty else {
            notificationBadgeLabel.isHidden = true
            return
        }
        let unread = NotificationManager.shared.unreadCount(role: "mentor", personId: currentMentorId)
        notificationBadgeLabel.text = unread > 99 ? "99+" : "\(unread)"
        notificationBadgeLabel.isHidden = unread == 0
    }

    // MARK: - Greeting

    private func loadMentorGreeting() {
        if let stored = UserDefaults.standard.string(forKey: "current_user_name"), !stored.isEmpty {
            let first = stored.components(separatedBy: " ").first ?? "Mentor"
            mentorDisplayName      = first
            greetingLabel?.text    = "Hi \(first)"
        }

        guard !currentMentorId.isEmpty else { return }

        Task {
            do {
                let greeting = try await SupabaseManager.shared.getMentorGreeting(personId: currentMentorId)
                let name = greeting.replacingOccurrences(of: "Hi ", with: "")
                await MainActor.run {
                    self.mentorDisplayName = name
                    self.greetingLabel?.text = greeting
                    if !name.isEmpty && name != "Mentor" {
                        UserDefaults.standard.set(name, forKey: "current_user_name")
                    }
                }
            } catch {
                print("❌ loadMentorGreeting:", error)
            }
        }
    }

    // MARK: - Profile

    private func setProfileAvatarImage(_ image: UIImage) {
        profileImageView.backgroundColor = .white
        profileImageView.image       = image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
    }

    private func loadMentorAvatar() {
        guard !currentMentorId.isEmpty else {
            profileImageView.image = UIImage(systemName: "person.crop.circle")
            profileImageView.tintColor = .black
            profileImageView.contentMode = .center
            return
        }

        Task {
            if let profile = try? await SupabaseManager.shared.fetchBasicMentorProfile(personId: currentMentorId),
               let base64 = profile.profile_picture,
               let image = SupabaseManager.shared.base64ToImage(base64String: base64) {
                await MainActor.run {
                    self.profileImageView.tintColor = nil
                    self.setProfileAvatarImage(image)
                }
            } else if let cached = SupabaseManager.shared.cachedProfilePhotoBase64(personId: currentMentorId, role: "mentor"),
                      let image = SupabaseManager.shared.base64ToImage(base64String: cached) {
                await MainActor.run {
                    self.profileImageView.tintColor = nil
                    self.setProfileAvatarImage(image)
                }
            } else {
                await MainActor.run {
                    self.profileImageView.image = UIImage(systemName: "person.crop.circle")
                    self.profileImageView.tintColor = .black
                    self.profileImageView.contentMode = .center
                }
            }
        }
    }

    @IBAction func profileImageTapped(_ sender: UITapGestureRecognizer) {
        let vc = ProfileViewController(nibName: "ProfileViewController", bundle: nil)
        vc.modalPresentationStyle = .pageSheet
        vc.modalTransitionStyle   = .coverVertical
        vc.delegate               = self

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [
                .custom(identifier: .init("almostFull")) { ctx in ctx.maximumDetentValue }
            ]
            sheet.prefersGrabberVisible  = true
            sheet.preferredCornerRadius  = 24
            sheet.largestUndimmedDetentIdentifier          = .init("almostFull")
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(vc, animated: true)
    }

    func profileViewController(_ controller: ProfileViewController, didUpdateAvatar image: UIImage) {
        setProfileAvatarImage(image)
    }

    // MARK: - Gradient

    private func applyBackgroundGradient() {
        let g       = CAGradientLayer()
        g.frame     = view.bounds
        g.colors    = [UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1).cgColor,
                       UIColor(white: 0.95, alpha: 1).cgColor]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint   = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(g, at: 0)
    }

    // MARK: - Supabase Load

    private func loadDashboardFromSupabase() async {
        guard !currentMentorId.isEmpty else {
            await MainActor.run {
                self.collectionView.refreshControl?.endRefreshing()
                self.ongoingTeams        = []
                self.reviewTasks         = []
                self.todayCountLabel.text = "0"
                self.collectionView.reloadData()
            }
            return
        }

        do {
            // ── 1. Teams for this mentor ──────────────────────────────────────
            let teams   = try await SupabaseManager.shared.fetchTeamsForMentor(mentorId: currentMentorId)
            let teamIds = teams.map { $0.id }

            // ── 2. Member name cache ──────────────────────────────────────────
            for team in teams {
                var names = [team.createdByName]
                if let n2 = team.member2Name, !n2.trimmingCharacters(in: .whitespaces).isEmpty { names.append(n2) }
                if let n3 = team.member3Name, !n3.trimmingCharacters(in: .whitespaces).isEmpty { names.append(n3) }
                teamMemberNames[team.id] = names
            }

            // ── 3. Parallel fetch counters & real review tasks ────────────────
            async let taskRowsFetch = SupabaseManager.shared.fetchTeamTasks(teamIds: teamIds)
            async let mappedReviewFetch = fetchRealReviewTasks(teamIds: teamIds)
            
            let (taskRows, mappedReview) = try await (taskRowsFetch, mappedReviewFetch)
            
            // Build dictionary in smaller, explicit steps to aid type-checker
            let pairs: [(String, SupabaseManager.TeamTaskRow)] = taskRows.map { row in
                return (row.team_id, row)
            }
            let taskMap: [String: SupabaseManager.TeamTaskRow] = Dictionary(uniqueKeysWithValues: pairs)

            // ── 4. Ongoing teams section ──────────────────────────────────────
            var mappedOngoing: [OngoingTeam] = []
            mappedOngoing.reserveCapacity(teams.count)
            for team in teams {
                let c = taskMap[team.id]
                let assigned = c?.assigned_task ?? 0
                mappedOngoing.append(OngoingTeam(teamId: team.id, teamNo: team.teamNo, activeTaskCount: assigned))
            }

            // ── 5. "Today" badge = total for_review count ─────────────────────
            var totalReviewCount  = 0
            var totalTasksOverall = 0
            for t in teams {
                totalReviewCount  += (taskMap[t.id]?.for_review_task ?? 0)
                totalTasksOverall += (taskMap[t.id]?.total_task ?? 0)
            }

            await MainActor.run {
                self.ongoingTeams         = mappedOngoing
                self.reviewTasks          = mappedReview
                self.todayTitleLabel.text = "Tasks to Review"
                self.todayCountLabel.text = "\(totalReviewCount)"
                NotificationManager.shared.processMentorSubmissionCount(totalReviewCount, personId: self.currentMentorId)
                self.refreshNotificationBadge()
                self.collectionView.reloadData()
                self.collectionView.refreshControl?.endRefreshing()
            }

        } catch {
            print("❌ MDashboardViewController.loadDashboardFromSupabase:", error)
            await MainActor.run {
                self.ongoingTeams         = []
                self.reviewTasks          = []
                self.todayCountLabel.text = "0"
                self.refreshNotificationBadge()
                self.collectionView.reloadData()
                self.collectionView.refreshControl?.endRefreshing()
            }
        }
    }

    @objc private func notificationButtonTapped() {
        guard !currentMentorId.isEmpty else { return }
        let notifications = NotificationManager.shared.notifications(role: "mentor", personId: currentMentorId)
        let message: String
        if notifications.isEmpty {
            message = "No notifications yet."
        } else {
            message = notifications.prefix(5).map { item in
                "• \(item.title)\n\(item.body)"
            }.joined(separator: "\n\n")
        }

        let alert = UIAlertController(title: "Notifications", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            NotificationManager.shared.markAllAsRead(role: "mentor", personId: self.currentMentorId)
            self.refreshNotificationBadge()
        })
        present(alert, animated: true)
    }

    // Fetch individual for_review task rows (title + team info) for all mentor teams
    private func fetchRealReviewTasks(teamIds: [String]) async throws -> [ReviewTask] {
        guard !teamIds.isEmpty else { return [] }

        struct ReviewRow: Decodable {
            let id:            String
            let title:         String
            let assigned_date: String?
            let team_id:       String
        }

        // Supabase "in" filter on team_id for all mentors' teams
        let rows: [ReviewRow] = try await SupabaseManager.shared.client
            .from("tasks")
            .select("id, title, assigned_date, team_id")
            .eq("status", value: "for_review")
            .in("team_id", values: teamIds)
            .order("assigned_date", ascending: false)
            .execute()
            .value

        // Build a teamNo lookup from the cached names map (keys are teamIds)
        // We need teamNo — fetch it from new_teams once per unique teamId
        var teamNoCache: [String: Int] = [:]
        for teamId in teamIds {
            if let teams = try? await SupabaseManager.shared.fetchTeamsForMentor(mentorId: currentMentorId) {
                for t in teams { teamNoCache[t.id] = t.teamNo }
                break   // one call is enough — same list
            }
        }

        let iso1 = ISO8601DateFormatter()
        iso1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let iso2 = ISO8601DateFormatter()
        let df   = DateFormatter()
        df.dateFormat = "dd MMM yyyy"

        return rows.map { row in
            var dueStr = "—"
            if let raw = row.assigned_date,
               let d   = iso1.date(from: raw) ?? iso2.date(from: raw) {
                dueStr = df.string(from: d)
            }
            return ReviewTask(
                taskId:    row.id,
                taskTitle: row.title,
                teamId:    row.team_id,
                teamNo:    teamNoCache[row.team_id] ?? 0,
                dueDate:   dueStr
            )
        }
    }

    // MARK: - Collection View Setup

    func setupCollectionView() {
        collectionView.delegate              = self
        collectionView.dataSource            = self
        collectionView.collectionViewLayout  = createLayout()
        collectionView.isUserInteractionEnabled = true
        collectionView.allowsSelection       = true

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl

        collectionView.register(
            EmptyStateCollectionViewCell.self,
            forCellWithReuseIdentifier: "EmptyCell"
        )
    }

    @objc private func handleRefresh() {
        Task { await loadDashboardFromSupabase() }
    }
}

// MARK: - ReviewViewControllerDelegate

extension MDashboardViewController: ReviewViewControllerDelegate {
    func reviewViewController(_ vc: ReviewViewController,
                              didChangeStatusTo status: String,
                              forTaskId taskId: String) {
        // Refresh dashboard so reviewed task disappears from the list
        Task { await loadDashboardFromSupabase() }
    }
}

// MARK: - Layout

extension MDashboardViewController {

    func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] idx, _ in
            idx == 0 ? self?.horizontalSection() ?? NSCollectionLayoutSection(group: .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(100))))
                     : self?.verticalSection()   ?? NSCollectionLayoutSection(group: .init(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(80))))
        }
    }

    func horizontalSection() -> NSCollectionLayoutSection {
        if ongoingTeams.isEmpty {
            return emptySection(height: 60)
        }
        let item  = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .absolute(90), heightDimension: .absolute(100)))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: .init(widthDimension: .absolute(90), heightDimension: .absolute(100)), subitems: [item])
        let sec   = NSCollectionLayoutSection(group: group)
        sec.orthogonalScrollingBehavior = .continuous
        sec.contentInsets               = .init(top: 8, leading: 16, bottom: 16, trailing: 16)
        sec.interGroupSpacing           = 8
        sec.boundarySupplementaryItems  = [sectionHeader(height: 40)]
        return sec
    }

    func verticalSection() -> NSCollectionLayoutSection {
        if reviewTasks.isEmpty {
            return emptySection(height: 60)
        }
        let item  = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80)))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .estimated(80)), subitems: [item])
        let sec   = NSCollectionLayoutSection(group: group)
        sec.contentInsets              = .init(top: 8, leading: 16, bottom: 20, trailing: 16)
        sec.interGroupSpacing          = 12
        sec.boundarySupplementaryItems = [sectionHeader(height: 40)]
        return sec
    }

    private func emptySection(height: CGFloat) -> NSCollectionLayoutSection {
        let item  = NSCollectionLayoutItem(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height)))
        let group = NSCollectionLayoutGroup.vertical(layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height)), subitems: [item])
        let sec   = NSCollectionLayoutSection(group: group)
        sec.contentInsets              = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
        sec.boundarySupplementaryItems = [sectionHeader(height: 40)]
        return sec
    }

    private func sectionHeader(height: CGFloat) -> NSCollectionLayoutBoundarySupplementaryItem {
        NSCollectionLayoutBoundarySupplementaryItem(
            layoutSize:  .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(height)),
            elementKind: UICollectionView.elementKindSectionHeader,
            alignment:   .top
        )
    }
}

// MARK: - DataSource

extension MDashboardViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        section == 0
            ? (ongoingTeams.isEmpty ? 1 : ongoingTeams.count)
            : (reviewTasks.isEmpty  ? 1 : reviewTasks.count)
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
            if ongoingTeams.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath) as! EmptyStateCollectionViewCell
                cell.configure(with: "You're not assigned to any teams at the moment.")
                return cell
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OngoingCell", for: indexPath) as! OngoingCollectionViewCell
            cell.configure(with: ongoingTeams[indexPath.item])
            return cell

        } else {
            if reviewTasks.isEmpty {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyCell", for: indexPath) as! EmptyStateCollectionViewCell
                cell.configure(with: "No tasks to review today")
                return cell
            }
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ReviewCell", for: indexPath) as! ReviewCollectionViewCell
            cell.configure(with: reviewTasks[indexPath.item])
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind:          UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "SectionHeader",
            for:             indexPath
        ) as! SectionHeaderView
        header.titleLabel.text = indexPath.section == 0 ? "Ongoing Tasks" : "Tasks To Review Today"
        return header
    }
}

// MARK: - Delegate

extension MDashboardViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {

        // Section 0 → open StudentAllTasksViewController
        if indexPath.section == 0, !ongoingTeams.isEmpty {
            let item = ongoingTeams[indexPath.item]
            let vc   = StudentAllTasksViewController(nibName: "StudentAllTasksViewController", bundle: nil)
            vc.teamId = item.teamId
            vc.teamNo = item.teamNo
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            return
        }

        // Section 1 → open ReviewViewController for the specific task
        if indexPath.section == 1, !reviewTasks.isEmpty {
            let item = reviewTasks[indexPath.item]

            let vc         = ReviewViewController(nibName: "ReviewViewController", bundle: nil)
            vc.taskId      = item.taskId
            vc.teamId      = item.teamId
            vc.teamNo      = item.teamNo
            vc.taskTitle   = item.taskTitle
            vc.delegate    = self   // so dashboard refreshes after reject/complete

            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
        }
    }
}
