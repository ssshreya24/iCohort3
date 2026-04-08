//
//  AllTasksViewController.swift
//  iCohort3
//
//  Updated: TeamContextReceiver conformance — uses injected teamId/teamNo when available,
//           falls back to Supabase fetch (existing bootstrapAndLoad logic) if not.
//

import UIKit

final class AllTasksViewController: UIViewController, TeamContextReceiver {

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - TeamContextReceiver
    // These are set by SDashboardViewController via injectTeamContext(into:)
    var teamId: String!
    var teamNo: Int!

    // Internal working copies (non-optional for existing logic)
    private var resolvedTeamId: String = ""
    private var resolvedTeamNo: Int    = 0

    private var gradientLayer: CAGradientLayer?
    private var collapsedSections: Set<Int> = []

    // MARK: - Task Sections

    enum TaskSection: Int, CaseIterable {
        case notStarted = 0, inProgress, forReview, prepared, approved, rejected, completed

        var title: String {
            switch self {
            case .notStarted: return "Not Started"
            case .inProgress: return "In Progress"
            case .forReview:  return "For Review"
            case .prepared:   return "Prepared"
            case .approved:   return "Approved"
            case .rejected:   return "Rejected"
            case .completed:  return "Completed"
            }
        }

        var cellIdentifier: String {
            switch self {
            case .notStarted: return "TaskCollectionViewCell"
            case .inProgress: return "InProgressCollectionViewCell"
            case .forReview:  return "TaskCollectionViewCell"
            case .prepared:   return "PreparedCollectionViewCell"
            case .approved:   return "ApprovedCollectionViewCell"
            case .rejected:   return "RejectedCollectionViewCell"
            case .completed:  return "CompletedCollectionViewCell"
            }
        }

        var dbStatus: String {
            switch self {
            case .notStarted: return "assigned"
            case .inProgress: return "ongoing"
            case .forReview:  return "for_review"
            case .prepared:   return "prepared"
            case .approved:   return "approved"
            case .rejected:   return "rejected"
            case .completed:  return "completed"
            }
        }
    }

    private var tasksBySections: [[SupabaseManager.TaskRow]] = Array(
        repeating: [], count: TaskSection.allCases.count)

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No tasks available"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.isHidden = true
        return label
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        AppTheme.applyScreenBackground(to: view)
        StudentTaskScreenUIHelper.removeLegacyHeader(from: view, collectionView: collectionView)
        setupEmptyLabel()
        registerCells()
        setupCollectionView()
        setupRefreshControl()
        Task { await bootstrapAndLoad() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "All Tasks"
        navigationItem.leftBarButtonItem = StudentTaskScreenUIHelper.makeCloseBarButton(target: self, action: #selector(closeTapped))
    }
    
    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        collectionView.refreshControl = refreshControl
    }
    
    @objc private func handleRefresh() {
        Task { await loadAllTasksFromSupabase() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView.dataSource  = self
        collectionView.delegate    = self
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .automatic
        collectionView.register(
            TaskSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "TaskSectionHeader"
        )
    }

    private func setupEmptyLabel() {
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func registerCells() {
        let cellNames = [
            "TaskCollectionViewCell",
            "InProgressCollectionViewCell",
            "PreparedCollectionViewCell",
            "ApprovedCollectionViewCell",
            "RejectedCollectionViewCell",
            "CompletedCollectionViewCell"
        ]
        for name in cellNames {
            collectionView.register(
                UINib(nibName: name, bundle: nil), forCellWithReuseIdentifier: name)
        }
    }

    // MARK: - Bootstrap & Load

    /// Resolves teamId/teamNo from injection → UserDefaults cache → Supabase fetch,
    /// then loads all tasks.
    private func bootstrapAndLoad() async {
        // Priority 1: injected by SDashboardViewController
        if let injected = teamId, !injected.isEmpty {
            resolvedTeamId = injected
            resolvedTeamNo = teamNo ?? 0
            await syncCountersAndLoad()
            return
        }

        // Priority 2: UserDefaults cache
        if let cached = UserDefaults.standard.string(forKey: "current_team_id"), !cached.isEmpty {
            resolvedTeamId = cached
            resolvedTeamNo = UserDefaults.standard.integer(forKey: "current_team_number")
            await syncCountersAndLoad()
            return
        }

        // Priority 3: Supabase fetch
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              !personId.isEmpty else {
            await resetUIWithEmpty("No user logged in")
            return
        }

        do {
            let myTeam = try await SupabaseManager.shared.fetchCurrentUsersTeamFromNewTeams(personId: personId)
            guard let myTeam else {
                await resetUIWithEmpty("No team assigned yet")
                return
            }
            UserDefaults.standard.set(myTeam.id,     forKey: "current_team_id")
            UserDefaults.standard.set(myTeam.teamNo, forKey: "current_team_number")
            resolvedTeamId = myTeam.id
            resolvedTeamNo = myTeam.teamNo
            await syncCountersAndLoad()
        } catch {
            print("❌ AllTasksVC bootstrapAndLoad failed:", error)
            await resetUIWithEmpty("Failed to load")
        }
    }

    private func syncCountersAndLoad() async {
        do {
            try await SupabaseManager.shared.ensureTeamTaskRow(
                teamId: resolvedTeamId, teamNo: resolvedTeamNo)
            try await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(
                teamId: resolvedTeamId, teamNo: resolvedTeamNo)
        } catch {
            print("⚠️ Counter sync failed (non-fatal):", error)
        }
        await loadAllTasksFromSupabase()
    }

    private func loadAllTasksFromSupabase() async {
        guard let resolvedTeamId = teamId, !resolvedTeamId.isEmpty else {
            await resetUIWithEmpty("No Team Context")
            return
        }
        
        do {
            async let a = SupabaseManager.shared.fetchTasksForTeam(teamId: resolvedTeamId, status: TaskSection.notStarted.dbStatus)
            async let b = SupabaseManager.shared.fetchTasksForTeam(teamId: resolvedTeamId, status: TaskSection.inProgress.dbStatus)
            async let c = SupabaseManager.shared.fetchTasksForTeam(teamId: resolvedTeamId, status: TaskSection.forReview.dbStatus)
            async let d = SupabaseManager.shared.fetchTasksForTeam(teamId: resolvedTeamId, status: TaskSection.prepared.dbStatus)
            async let e = SupabaseManager.shared.fetchTasksForTeam(teamId: resolvedTeamId, status: TaskSection.approved.dbStatus)
            async let f = SupabaseManager.shared.fetchTasksForTeam(teamId: resolvedTeamId, status: TaskSection.rejected.dbStatus)
            async let g = SupabaseManager.shared.fetchTasksForTeam(teamId: resolvedTeamId, status: TaskSection.completed.dbStatus)

            let (assigned, ongoing, review, prepared, approved, rejected, completed) =
                try await (a, b, c, d, e, f, g)

            var buckets = Array(repeating: [SupabaseManager.TaskRow](), count: TaskSection.allCases.count)
            buckets[TaskSection.notStarted.rawValue] = assigned
            buckets[TaskSection.inProgress.rawValue] = ongoing
            buckets[TaskSection.forReview.rawValue]  = review
            buckets[TaskSection.prepared.rawValue]   = prepared
            buckets[TaskSection.approved.rawValue]   = approved
            buckets[TaskSection.rejected.rawValue]   = rejected
            buckets[TaskSection.completed.rawValue]  = completed

            let total = buckets.reduce(0) { $0 + $1.count }

            await MainActor.run {
                self.tasksBySections = buckets
                self.setEmptyState(total == 0 ? "No tasks available" : nil)
                self.collectionView.reloadData()
                self.collectionView.refreshControl?.endRefreshing()
            }
        } catch {
            print("❌ AllTasksVC load failed:", error)
            await resetUIWithEmpty("Failed to load tasks")
            await MainActor.run { self.collectionView.refreshControl?.endRefreshing() }
        }
    }

    private func setEmptyState(_ message: String?) {
        emptyLabel.text    = message ?? "No tasks available"
        emptyLabel.isHidden = (message == nil)
    }

    private func resetUIWithEmpty(_ message: String) async {
        await MainActor.run {
            self.setEmptyState(message)
            self.tasksBySections = Array(repeating: [], count: TaskSection.allCases.count)
            self.collectionView.reloadData()
        }
    }

    // MARK: - Status Shift

    private func shiftStatus(taskId: String, to newSection: TaskSection) async {
        do {
            _ = try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: newSection.dbStatus)
            try await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(
                teamId: resolvedTeamId, teamNo: resolvedTeamNo)
            await loadAllTasksFromSupabase()
        } catch {
            print("❌ AllTasksVC status shift failed:", error)
        }
    }

    private func nextSection(for current: TaskSection) -> TaskSection? {
        switch current {
        case .notStarted: return .inProgress
        case .inProgress: return .forReview
        case .forReview:  return .prepared
        case .prepared:   return .approved
        case .approved:   return .completed
        case .rejected, .completed: return nil
        }
    }

    // MARK: - UI Setup

    private func applyBackgroundGradient() {
        AppTheme.applyScreenBackground(to: view)
        gradientLayer = view.layer.sublayers?.first(where: { $0.name == "AppThemeGradientLayer" }) as? CAGradientLayer
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource & DelegateFlowLayout

extension AllTasksViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        TaskSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        if collapsedSections.contains(section) { return 0 }
        guard section < tasksBySections.count else { return 0 }
        return tasksBySections[section].count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let sectionEnum = TaskSection.allCases[indexPath.section]
        let task        = tasksBySections[indexPath.section][indexPath.row]
        let id          = sectionEnum.cellIdentifier
        let teamLabel   = "Team \(resolvedTeamNo)"

        switch sectionEnum {
        case .approved:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ApprovedCollectionViewCell
            cell.configure(title: task.title, desc: task.description ?? "", remark: task.remark, image: UIImage(named: "logo"), name: teamLabel, dueDate: task.assigned_date)
            return cell
        case .rejected:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! RejectedCollectionViewCell
            cell.configure(title: task.title, desc: task.description ?? "", remark: task.remark, image: UIImage(named: "logo"), name: teamLabel, dueDate: task.assigned_date)
            return cell
        case .inProgress:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! InProgressCollectionViewCell
            cell.configure(title: task.title, desc: task.description ?? "", image: UIImage(named: "logo"), name: teamLabel, dueDate: task.assigned_date)
            return cell
        case .prepared:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! PreparedCollectionViewCell
            cell.configure(title: task.title, desc: task.description ?? "", image: UIImage(named: "logo"), name: teamLabel, dueDate: task.assigned_date)
            return cell
        case .completed:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! CompletedCollectionViewCell
            cell.configure(title: task.title, desc: task.description ?? "", image: UIImage(named: "logo"), name: teamLabel, dueDate: task.assigned_date)
            return cell
        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! TaskCollectionViewCell
            cell.configure(title: task.title, desc: task.description ?? "", image: UIImage(named: "logo"), name: teamLabel, dueDate: task.assigned_date)
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind, withReuseIdentifier: "TaskSectionHeader", for: indexPath
        ) as! TaskSectionHeaderView
        
        let section = indexPath.section
        header.configure(
            title: TaskSection.allCases[section].title,
            isCollapsed: collapsedSections.contains(section)
        )
        
        header.toggleAction = { [weak self] in
            guard let self = self else { return }
            if self.collapsedSections.contains(section) {
                self.collapsedSections.remove(section)
            } else {
                self.collapsedSections.insert(section)
            }
            self.collectionView.reloadSections(IndexSet(integer: section))
        }
        
        return header
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 40)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cardWidth = Self.cardWidth(for: collectionView)
        let task = tasksBySections[indexPath.section][indexPath.row]
        let height = Self.estimatedCellHeight(
            title: task.title,
            desc: task.description ?? "",
            cardWidth: cardWidth
        )
        return CGSize(width: cardWidth, height: height)
    }

    /// Returns a card width that is at most 600pt (for iPad), otherwise full-width minus padding.
    static func cardWidth(for collectionView: UICollectionView) -> CGFloat {
        let available = collectionView.frame.width - 40
        return min(available, 600)
    }

    /// Computes dynamic card height based on content.
    static func estimatedCellHeight(title: String, desc: String, cardWidth: CGFloat) -> CGFloat {
        // Available width for title (leaves ~108pt for profile image + name + padding)
        let titleWidth = cardWidth - 24 - 108      // 24 = leading (12 card + 12 button spacing)
        let descWidth  = cardWidth - 32             // 16 leading + 16 trailing

        let titleFont = UIFont.systemFont(ofSize: 15, weight: .semibold)
        let descFont  = UIFont.systemFont(ofSize: 13)

        let titleHeight = title.boundingRect(
            with: CGSize(width: titleWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: titleFont],
            context: nil
        ).height.rounded(.up)

        let trimmedDesc = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        let descHeight: CGFloat
        if trimmedDesc.isEmpty {
            descHeight = 0
        } else {
            descHeight = trimmedDesc.boundingRect(
                with: CGSize(width: descWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: descFont],
                context: nil
            ).height.rounded(.up)
        }

        // Layout breakdown:
        // 12 top padding (card) + 12 button top + max(titleHeight, 25) + spacing(30) + descHeight
        // + spacing(30 if desc, else 10) + 1 separator + 2 + 15 dueDate + 15 bottom + 8 cell padding
        let titleRow   = max(titleHeight, 25)
        let afterTitle: CGFloat = trimmedDesc.isEmpty ? 10 : 30
        let afterDesc: CGFloat  = trimmedDesc.isEmpty ? 0  : 30
        let chrome: CGFloat = 12 + 12 + afterTitle + afterDesc + 1 + 2 + 15 + 15 + 16
        let computed = chrome + titleRow + descHeight
        return max(computed, 110)  // minimum sensible card height
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 20, bottom: 16, right: 20)
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let currentSection = TaskSection.allCases[indexPath.section]
        let task           = tasksBySections[indexPath.section][indexPath.row]
        guard let moveTo   = nextSection(for: currentSection) else { return }
        Task { await shiftStatus(taskId: task.id, to: moveTo) }
    }
}

// MARK: - Array async helper

extension Array {
    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
        var results: [T] = []
        results.reserveCapacity(count)
        for element in self { results.append(await transform(element)) }
        return results
    }
}
