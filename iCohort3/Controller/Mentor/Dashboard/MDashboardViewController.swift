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

private struct DashboardNotificationItem: Codable {
    let id: UUID
    let title: String
    let body: String
    let createdAt: Date
    var isRead: Bool
}

private final class NotificationManager {
    static let shared = NotificationManager()

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {}

    func unreadCount(role: String, personId: String) -> Int {
        notifications(role: role, personId: personId).filter { !$0.isRead }.count
    }

    func notifications(role: String, personId: String) -> [DashboardNotificationItem] {
        guard let data = defaults.data(forKey: notificationsKey(role: role, personId: personId)),
              let items = try? decoder.decode([DashboardNotificationItem].self, from: data) else {
            return []
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }

    func markAllAsRead(role: String, personId: String) {
        var items = notifications(role: role, personId: personId)
        for index in items.indices {
            items[index].isRead = true
        }
        save(items, role: role, personId: personId)
    }

    func processMentorSubmissionCount(_ totalReviewCount: Int, personId: String) {
        let role = "mentor"
        let lastCountKey = submissionCountKey(role: role, personId: personId)
        let previousCount = defaults.integer(forKey: lastCountKey)

        defer {
            defaults.set(totalReviewCount, forKey: lastCountKey)
        }

        guard totalReviewCount > previousCount, totalReviewCount > 0 else { return }

        let newSubmissionCount = totalReviewCount - previousCount
        let title = newSubmissionCount == 1 ? "New task to review" : "New tasks to review"
        let body = newSubmissionCount == 1
            ? "1 new task was submitted for your review."
            : "\(newSubmissionCount) new tasks were submitted for your review."

        var items = notifications(role: role, personId: personId)
        items.insert(
            DashboardNotificationItem(
                id: UUID(),
                title: title,
                body: body,
                createdAt: Date(),
                isRead: false
            ),
            at: 0
        )
        save(Array(items.prefix(20)), role: role, personId: personId)
    }

    private func save(_ items: [DashboardNotificationItem], role: String, personId: String) {
        guard let data = try? encoder.encode(items) else { return }
        defaults.set(data, forKey: notificationsKey(role: role, personId: personId))
    }

    private func notificationsKey(role: String, personId: String) -> String {
        "dashboard_notifications_\(role)_\(personId)"
    }

    private func submissionCountKey(role: String, personId: String) -> String {
        "dashboard_submission_count_\(role)_\(personId)"
    }
}

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
        config.baseForegroundColor = AppTheme.accent
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

    private var greetingTrailingConstraint: NSLayoutConstraint?

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
        AppTheme.applyScreenBackground(to: view)
        styleProfileButton()
        setupNotificationButton()
        setupCollectionView()

        AppTheme.styleCard(todayCardView, cornerRadius: 16)

        todayTitleLabel.numberOfLines = 1
        todayTitleLabel.adjustsFontSizeToFitWidth = true
        todayTitleLabel.minimumScaleFactor = 0.85

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
        AppTheme.applyScreenBackground(to: view)
        syncProfileButtonSize()
        notificationButton.layer.cornerRadius = notificationButton.bounds.width / 2
    }

    private func styleProfileButton() {
        profileImageView.backgroundColor = AppTheme.floatingBackground
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        AppTheme.applyShadow(to: profileImageView)
        profileImageView.clipsToBounds = true
        profileImageView.tintColor = .label
        syncProfileButtonSize()
    }

    private func syncProfileButtonSize() {
        profileImageView.layoutIfNeeded()
        profileImageView.layer.cornerRadius = profileImageView.bounds.width / 2
        if profileImageView.image == nil {
            profileImageView.contentMode = .center
        }
    }

    private func setupNotificationButton() {
        notificationButton.addTarget(self, action: #selector(notificationButtonTapped), for: .touchUpInside)
        view.addSubview(notificationButton)
        view.addSubview(notificationBadgeLabel)

        AppTheme.styleFloatingControl(notificationButton, cornerRadius: 20)
        notificationButton.clipsToBounds = false

        NSLayoutConstraint.activate([
            notificationButton.widthAnchor.constraint(equalToConstant: 44),
            notificationButton.heightAnchor.constraint(equalToConstant: 44),
            notificationButton.trailingAnchor.constraint(equalTo: profileImageView.leadingAnchor, constant: -10),
            notificationButton.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor),

            notificationBadgeLabel.centerXAnchor.constraint(equalTo: notificationButton.trailingAnchor, constant: -2),
            notificationBadgeLabel.centerYAnchor.constraint(equalTo: notificationButton.topAnchor, constant: 2),
            notificationBadgeLabel.heightAnchor.constraint(equalToConstant: 20),
            notificationBadgeLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ])

        if let greetingLabel {
            greetingTrailingConstraint?.isActive = false
            let trailing = greetingLabel.trailingAnchor.constraint(lessThanOrEqualTo: notificationButton.leadingAnchor, constant: -18)
            trailing.priority = .required
            trailing.isActive = true
            greetingTrailingConstraint = trailing
        }
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
        profileImageView.backgroundColor = AppTheme.floatingBackground
        profileImageView.image       = image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
    }

    private func loadMentorAvatar() {
        let name = UserDefaults.standard.string(forKey: "current_user_name") ?? "Mentor"
        let initial = String(name.first ?? "M")
        let placeholderImage = UIImage.generateAvatar(initials: initial)

        guard !currentMentorId.isEmpty else {
            profileImageView.image = placeholderImage
            profileImageView.tintColor = nil
            profileImageView.contentMode = .scaleAspectFill
            return
        }

        Task {
            _ = try? await SupabaseManager.shared.fetchBasicMentorProfile(personId: currentMentorId)

            await MainActor.run {
                if let cachedAvatar = SupabaseManager.shared.cachedProfilePhotoBase64(personId: self.currentMentorId, role: "mentor"),
                   let image = SupabaseManager.shared.base64ToImage(base64String: cachedAvatar) {
                    self.profileImageView.tintColor = nil
                    self.setProfileAvatarImage(image)
                } else {
                    self.profileImageView.image = placeholderImage
                    self.profileImageView.tintColor = nil
                    self.profileImageView.contentMode = .scaleAspectFill
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
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(vc, animated: true)
    }

    func profileViewController(_ controller: ProfileViewController, didUpdateAvatar image: UIImage) {
        setProfileAvatarImage(image)
    }

    // MARK: - Gradient

    private func applyBackgroundGradient() {
        AppTheme.applyScreenBackground(to: view)
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
        if let teams = try? await SupabaseManager.shared.fetchTeamsForMentor(mentorId: currentMentorId) {
            for t in teams {
                teamNoCache[t.id] = t.teamNo
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
        let itemSize = NSCollectionLayoutSize(widthDimension: .absolute(108), heightDimension: .absolute(122))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
        let sec   = NSCollectionLayoutSection(group: group)
        sec.orthogonalScrollingBehavior = .continuous
        sec.contentInsets               = .init(top: 8, leading: 16, bottom: 4, trailing: 16)
        sec.interGroupSpacing           = 12
        sec.boundarySupplementaryItems  = [sectionHeader(height: 40)]
        return sec
    }

    func verticalSection() -> NSCollectionLayoutSection {
        if reviewTasks.isEmpty {
            return emptySection(height: 60)
        }
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(68))
        )
        let group = NSCollectionLayoutGroup.vertical(
            layoutSize: .init(widthDimension: .fractionalWidth(1), heightDimension: .absolute(68)),
            subitems: [item]
        )
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
