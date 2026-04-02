//
//  SDashboardViewController.swift
//  iCohort3
//
//  ✅ FIXED: Only shows tasks assigned TODAY in the tasks section.
//            Uses proper timezone-aware date comparison.
//

import UIKit
import Supabase

extension Notification.Name {
    static let tasksDidUpdate = Notification.Name("TasksDidUpdate")
}

class SDashboardViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var taskCard: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var tasksDueTodayLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var greetingLabel: UILabel!

    private let codeGreetingLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .label
        label.text = "Hi user"
        label.numberOfLines = 1
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let noTasksLabel: UILabel = {
        let label = UILabel()
        label.text = "No tasks today"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = .systemGray
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    @IBOutlet weak var contentViewHeight: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var collectionViewCellHeight: NSLayoutConstraint!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!

    private let rowHeight: CGFloat = 88

    private var currentTeamId: String? { UserDefaults.standard.string(forKey: "current_team_id") }
    private var currentTeamNo: Int     { UserDefaults.standard.integer(forKey: "current_team_number") }

    var statusCounts: [String: Int] = [:]
    private var tasksForTable: [SupabaseManager.TaskRow] = []
    var isEditingMode = false

    private var realtimeChannel: RealtimeChannelV2?
    private var refreshTimer: Timer?
    private let pollInterval: TimeInterval = 30

    let allStatuses: [(iconName: String, title: String, color: UIColor)] = [
        ("dot.circle.fill",             "Not started", .systemGray),
        ("clock.fill",                  "In Progress",  .systemOrange),
        ("magnifyingglass.circle.fill", "For Review",   .systemYellow),
        ("checkmark.circle.fill",       "Approved",     .systemGreen),
        ("xmark.circle.fill",           "Rejected",     .systemRed),
        ("cube.box.fill",               "Prepared",     .systemTeal),
        ("airplane.circle.fill",        "Completed",    .systemBlue),
        ("circle.grid.3x3.fill",        "All",          .black)
    ]

    var visibleStatuses: [(iconName: String, title: String, color: UIColor)] = []
    var removedStatuses: [(iconName: String, title: String, color: UIColor)] = []

    // MARK: - Shared date formatters (created once, reused everywhere)

    /// Parses ISO8601 dates like "2026-03-31T00:00:00+00:00" or "2026-03-31T00:00:00Z"
    private let isoParser: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    private let isoParserNoFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    /// Calendar using the device's current timezone for "is today" checks
    private let localCalendar = Calendar.current

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        visibleStatuses = allStatuses
        loadStudentGreeting()
        loadAndCacheTeamInfo()

        NotificationCenter.default.addObserver(self, selector: #selector(handleTasksDidUpdate),
                                               name: .tasksDidUpdate, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleDeleteNotification(_:)),
                                               name: .statusCardDeleteTapped, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAddNotification(_:)),
                                               name: .statusCardAddTapped, object: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStudentGreeting()
        loadDashboardData()
        updateCollectionViewHeight()
        updateTableViewVisibility()
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        startRealtimeAndPolling()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stopRealtimeAndPolling()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        taskCard.bringSubviewToFront(noTasksLabel)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
        applyHeaderFloatingControls()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyHeaderFloatingControls()
        }
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.updateCollectionViewHeight()
        }, completion: nil)
    }

    deinit {
        stopRealtimeAndPolling()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Realtime + Polling

    private func startRealtimeAndPolling() {
        subscribeRealtime()
        stopPolling()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: pollInterval,
                                            repeats: true) { [weak self] _ in
            self?.loadDashboardData()
        }
    }

    private func stopRealtimeAndPolling() { stopRealtime(); stopPolling() }

    private func subscribeRealtime() {
        stopRealtime()
        guard let teamId = currentTeamId, !teamId.isEmpty else { return }
        realtimeChannel = SupabaseManager.shared.subscribeToTaskChanges(teamId: teamId) { [weak self] in
            self?.loadDashboardData()
        }
    }

    private func stopRealtime() {
        SupabaseManager.shared.unsubscribe(channel: realtimeChannel)
        realtimeChannel = nil
    }

    private func stopPolling() { refreshTimer?.invalidate(); refreshTimer = nil }

    @objc private func handleTasksDidUpdate() { loadDashboardData() }

    // MARK: - Team Info Loader

    private func loadAndCacheTeamInfo() {
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              !personId.isEmpty else { return }
        if currentTeamId != nil { subscribeRealtime(); return }
        Task {
            do {
                if let teamInfo = try await SupabaseManager.shared.fetchTeamInfoForStudent(personId: personId) {
                    await MainActor.run {
                        UserDefaults.standard.set(teamInfo.teamId,     forKey: "current_team_id")
                        UserDefaults.standard.set(teamInfo.teamNumber, forKey: "current_team_number")
                        self.subscribeRealtime()
                    }
                }
            } catch { print("❌ loadAndCacheTeamInfo:", error) }
        }
    }

    // MARK: - Greeting

    private func loadStudentGreeting() {
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id") else {
            codeGreetingLabel.text = "Hi user"; return
        }
        Task {
            do {
                let g = try await SupabaseManager.shared.getStudentGreeting(personId: personId)
                await MainActor.run { self.codeGreetingLabel.text = g }
            } catch { await MainActor.run { self.codeGreetingLabel.text = "Hi user" } }
        }
    }

    // MARK: - Dashboard Data

    private func loadDashboardData() {
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              let teamId   = currentTeamId else {
            if let personId = UserDefaults.standard.string(forKey: "current_person_id") {
                Task {
                    if let info = try? await SupabaseManager.shared.fetchTeamInfoForStudent(personId: personId) {
                        await MainActor.run {
                            UserDefaults.standard.set(info.teamId,     forKey: "current_team_id")
                            UserDefaults.standard.set(info.teamNumber, forKey: "current_team_number")
                            self.subscribeRealtime()
                        }
                        self.loadDashboardData()
                    }
                }
            }
            return
        }
        Task {
            do {
                let tasks = try await SupabaseManager.shared
                    .fetchAllTasksForStudentInTeam(studentId: personId, teamId: teamId)
                await MainActor.run {
                    self.updateUIWithTasks(tasks)
                    self.scrollView.refreshControl?.endRefreshing()
                }
            } catch {
                print("❌ loadDashboardData:", error)
                await MainActor.run { self.scrollView.refreshControl?.endRefreshing() }
            }
        }
    }

    // MARK: - ✅ Timezone-aware "is today" date check

    /// Parses any ISO8601 string into a Date, trying with and without fractional seconds.
    private func parseISO(_ string: String) -> Date? {
        isoParser.date(from: string) ?? isoParserNoFrac.date(from: string)
    }

    /// Returns true if the ISO8601 date string falls on today in the device's local timezone.
    private func isAssignedToday(_ isoString: String) -> Bool {
        // Try full ISO parse first
        if let date = parseISO(isoString) {
            return localCalendar.isDateInToday(date)
        }
        // Fallback: compare just the yyyy-MM-dd prefix using a local-timezone formatter
        let localDayFormatter = DateFormatter()
        localDayFormatter.dateFormat    = "yyyy-MM-dd"
        localDayFormatter.locale        = Locale(identifier: "en_US_POSIX")
        localDayFormatter.timeZone      = .current
        let todayString = localDayFormatter.string(from: Date())
        // Strip the date portion from the raw string (first 10 chars)
        let rawPrefix = String(isoString.prefix(10))
        return rawPrefix == todayString
    }

    private func updateUIWithTasks(_ tasks: [SupabaseManager.TaskRow]) {
        // ── Status counts for the cards grid ──────────────────
        var counts: [String: Int] = [:]
        for status in allStatuses { counts[status.title] = 0 }
        for task in tasks {
            let key: String
            switch task.status.lowercased() {
            case "not_started","not started","assigned": key = "Not started"
            case "ongoing","in progress","in_progress":  key = "In Progress"
            case "for_review","for review":              key = "For Review"
            case "prepared":  key = "Prepared"
            case "approved":  key = "Approved"
            case "completed": key = "Completed"
            case "rejected":  key = "Rejected"
            default:          key = ""
            }
            if !key.isEmpty { counts[key] = (counts[key] ?? 0) + 1 }
        }
        counts["All"] = tasks.count
        self.statusCounts = counts

        // ── ✅ TODAY-ONLY filter ───────────────────────────────
        // Show active tasks (assigned / ongoing) that were assigned TODAY.
        // Uses timezone-aware comparison so UTC dates don't bleed into yesterday/tomorrow.
        self.tasksForTable = tasks.filter { task in
            let s = task.status.lowercased()
            let isActive = s == "not_started" || s == "not started" || s == "assigned"
                        || s == "ongoing"     || s == "in progress" || s == "in_progress"
            return isActive && isAssignedToday(task.assigned_date)
        }

        // ── Header text ───────────────────────────────────────
        let count = self.tasksForTable.count
        switch count {
        case 0:  tasksDueTodayLabel.text = "No tasks due today"
        case 1:  tasksDueTodayLabel.text = "You have 1 task due today"
        default: tasksDueTodayLabel.text = "You have \(count) tasks due today"
        }

        self.collectionView.reloadData()
        updateTableViewVisibility()
    }

    @objc private func handleRefresh() { loadDashboardData() }

    // MARK: - Setup UI

    private func setupUI() {
        AppTheme.applyScreenBackground(to: view)
        contentView.backgroundColor    = .clear
        cardView.backgroundColor       = .clear
        collectionView.backgroundColor = .clear
        AppTheme.styleCard(taskCard, cornerRadius: 20)

        tasksDueTodayLabel.font          = UIFont.systemFont(ofSize: 17, weight: .semibold)
        tasksDueTodayLabel.textColor     = .label
        tasksDueTodayLabel.textAlignment = .left

        applyHeaderFloatingControls()

        installCodeGreetingLabel()

        collectionView.dataSource             = self
        collectionView.delegate               = self
        collectionView.dragDelegate           = self
        collectionView.dropDelegate           = self
        collectionView.dragInteractionEnabled = true

        tableView.dataSource      = self
        tableView.delegate        = self
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle  = .none
        tableView.layer.cornerRadius = 20
        registerTaskCellIfNeeded()

        scrollView.isScrollEnabled              = true
        scrollView.showsVerticalScrollIndicator = false

        let rc = UIRefreshControl()
        rc.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        scrollView.refreshControl = rc

        taskCard.addSubview(noTasksLabel)
        setupNoTasksLabelConstraints()
    }

    private func applyHeaderFloatingControls() {
        let iconColor: UIColor = traitCollection.userInterfaceStyle == .dark ? .white : .black

        AppTheme.styleNativeFloatingControl(editButton, cornerRadius: editButton.bounds.height / 2)
        editButton.setTitleColor(.black, for: .normal)
        editButton.tintColor = .black
        if var config = editButton.configuration {
            config.baseForegroundColor = .black
            config.baseBackgroundColor = .clear
            editButton.configuration = config
        }

        guard let profileButton else { return }
        AppTheme.styleNativeFloatingControl(profileButton, cornerRadius: profileButton.bounds.height / 2)
        profileButton.tintColor = iconColor
        if var config = profileButton.configuration {
            config.baseForegroundColor = iconColor
            config.baseBackgroundColor = .clear
            profileButton.configuration = config
        }
    }

    private func installCodeGreetingLabel() {
        if let connectedLabel = greetingLabel { connectedLabel.isHidden = true; connectedLabel.text = "" }
        guard let legacyLabel = findLegacyStoryboardGreeting(in: cardView) else {
            if codeGreetingLabel.superview == nil {
                contentView.addSubview(codeGreetingLabel)
                NSLayoutConstraint.activate([
                    codeGreetingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
                    codeGreetingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
                    codeGreetingLabel.trailingAnchor.constraint(lessThanOrEqualTo: contentView.trailingAnchor, constant: -88)
                ])
            }
            return
        }
        legacyLabel.isHidden = true; legacyLabel.text = ""
        guard codeGreetingLabel.superview == nil else { return }
        legacyLabel.superview?.addSubview(codeGreetingLabel)
        NSLayoutConstraint.activate([
            codeGreetingLabel.topAnchor.constraint(equalTo: legacyLabel.topAnchor),
            codeGreetingLabel.leadingAnchor.constraint(equalTo: legacyLabel.leadingAnchor),
            codeGreetingLabel.trailingAnchor.constraint(lessThanOrEqualTo: legacyLabel.trailingAnchor),
            codeGreetingLabel.heightAnchor.constraint(equalTo: legacyLabel.heightAnchor)
        ])
    }

    private func findLegacyStoryboardGreeting(in rootView: UIView?) -> UILabel? {
        guard let rootView else { return nil }
        for subview in rootView.subviews {
            if let label = subview as? UILabel,
               let text  = label.text?.trimmingCharacters(in: .whitespacesAndNewlines),
               text.lowercased().hasPrefix("hi user") { return label }
            if let found = findLegacyStoryboardGreeting(in: subview) { return found }
        }
        return nil
    }


    private func registerTaskCellIfNeeded() {
        let bundle = Bundle(for: tasksDueTodayTableViewCell.self)
        if bundle.path(forResource: "tasksDueTodayTableViewCell", ofType: "nib") != nil {
            tableView.register(UINib(nibName: "tasksDueTodayTableViewCell", bundle: bundle),
                               forCellReuseIdentifier: "TaskCell")
        } else {
            tableView.register(tasksDueTodayTableViewCell.self, forCellReuseIdentifier: "TaskCell")
        }
    }

    private func setupNoTasksLabelConstraints() {
        NSLayoutConstraint.activate([
            noTasksLabel.centerXAnchor.constraint(equalTo: taskCard.centerXAnchor),
            noTasksLabel.topAnchor.constraint(equalTo: tasksDueTodayLabel.bottomAnchor, constant: 40),
            noTasksLabel.leadingAnchor.constraint(equalTo: taskCard.leadingAnchor, constant: 20),
            noTasksLabel.trailingAnchor.constraint(equalTo: taskCard.trailingAnchor, constant: -20),
            noTasksLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 50)
        ])
    }

    // MARK: - Dynamic Height Management

    private func updateCollectionViewHeight() {
        let count = isEditingMode ? (visibleStatuses.count + removedStatuses.count) : visibleStatuses.count
        let rows  = ceil(CGFloat(count) / 2.0)
        collectionViewCellHeight.constant = (rows * 100) + ((rows - 1) * 8) + 16
        updateContentHeight()
    }

    private func updateTableViewVisibility() {
        let count = tasksForTable.count
        if count > 0 {
            tableView.isHidden    = false
            noTasksLabel.isHidden = true
            tableViewHeight.constant = CGFloat(count) * rowHeight
            tableView.reloadData()
        } else {
            tableView.isHidden       = true
            noTasksLabel.isHidden    = false
            tableViewHeight.constant = 60
        }
        view.layoutIfNeeded()
        taskCard.layoutIfNeeded()
        taskCard.bringSubviewToFront(noTasksLabel)
        updateContentHeight()
    }

    private func updateContentHeight() {
        view.layoutIfNeeded()
        let tvBottom = tableView.frame.origin.y + tableViewHeight.constant
        var total: CGFloat = tvBottom + 120
        if total < view.frame.height + 20 { total = view.frame.height + 20 }
        contentViewHeight.constant = total
        contentView.setNeedsLayout(); contentView.layoutIfNeeded()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            self.scrollView.isScrollEnabled = true
            self.scrollView.alwaysBounceVertical = true
            self.scrollView.contentSize = CGSize(width: self.view.frame.width, height: total)
        }
    }

    // MARK: - Status VC Navigation

    private func openStatusScreen(for title: String) {
        switch title {
        case "Not started": injectTeamContext(into: NotStartedViewController(nibName: "NotStartedViewController", bundle: nil))
        case "In Progress": injectTeamContext(into: InProgressViewController(nibName: "InProgressViewController", bundle: nil))
        case "For Review":  injectTeamContext(into: ForReviewViewController(nibName: "ForReviewViewController", bundle: nil))
        case "Prepared":    injectTeamContext(into: PreparedViewController(nibName: "PreparedViewController", bundle: nil))
        case "Approved":    injectTeamContext(into: ApprovedViewController(nibName: "ApprovedViewController", bundle: nil))
        case "Completed":   injectTeamContext(into: CompletedViewController(nibName: "CompletedViewController", bundle: nil))
        case "Rejected":    injectTeamContext(into: RejectedViewController(nibName: "RejectedViewController", bundle: nil))
        case "All":         injectTeamContext(into: AllTasksViewController(nibName: "AllTasksViewController", bundle: nil))
        default: break
        }
    }

    private func injectTeamContext(into vc: UIViewController & TeamContextReceiver) {
        if let teamId = currentTeamId {
            vc.teamId = teamId; vc.teamNo = currentTeamNo; presentTaskScreen(vc); return
        }
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id") else {
            showNoTeamAlert(); return
        }
        Task { await fetchTeamAndPresent(vc: vc, personId: personId) }
    }

    private func fetchTeamAndPresent(vc: UIViewController & TeamContextReceiver, personId: String) async {
        do {
            guard let info = try await SupabaseManager.shared.fetchTeamInfoForStudent(personId: personId)
            else { await MainActor.run { self.showNoTeamAlert() }; return }
            await MainActor.run {
                UserDefaults.standard.set(info.teamId,     forKey: "current_team_id")
                UserDefaults.standard.set(info.teamNumber, forKey: "current_team_number")
                vc.teamId = info.teamId; vc.teamNo = info.teamNumber
                self.presentTaskScreen(vc)
            }
        } catch { await MainActor.run { self.showNoTeamAlert() } }
    }

    private func presentTaskScreen(_ vc: UIViewController) {
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        nav.navigationBar.prefersLargeTitles = true
        present(nav, animated: true)
    }

    private func showNoTeamAlert() {
        let alert = UIAlertController(title: "No Team Found",
                                      message: "You are not part of a team yet.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @IBAction func editButtonTapped(_ sender: UIButton) {
        isEditingMode.toggle()
        editButton.setTitle(isEditingMode ? "Done" : "Edit", for: .normal)
        collectionView.reloadData(); updateCollectionViewHeight()
    }

    @IBAction func profileTapped(_ sender: Any) {
        let vc = SProfileViewController(nibName: "SProfileViewController", bundle: nil)
        vc.modalPresentationStyle = .pageSheet; vc.modalTransitionStyle = .coverVertical
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.custom(identifier: .init("almostFull")) { ctx in ctx.maximumDetentValue }]
            sheet.prefersGrabberVisible = true; sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(vc, animated: true)
    }
}

// MARK: - TeamContextReceiver
protocol TeamContextReceiver: AnyObject {
    var teamId: String! { get set }
    var teamNo: Int!    { get set }
}

// MARK: - UICollectionViewDataSource & DelegateFlowLayout
extension SDashboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        isEditingMode ? visibleStatuses.count + removedStatuses.count : visibleStatuses.count
    }
    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "StatusCardCell", for: indexPath) as! StatusCardCell
        cell.backgroundColor = .clear; cell.contentView.backgroundColor = .clear
        if isEditingMode {
            if indexPath.item < visibleStatuses.count {
                let s = visibleStatuses[indexPath.item]; let count = statusCounts[s.title] ?? 0
                cell.iconImageView.image = UIImage(systemName: s.iconName)?.withRenderingMode(.alwaysTemplate)
                cell.iconImageView.tintColor = s.color
                cell.configure(iconName: s.iconName, title: s.title, count: count, mode: .editing)
            } else {
                let r = removedStatuses[indexPath.item - visibleStatuses.count]
                cell.configure(iconName: nil, title: r.title, count: nil, mode: .add)
            }
        } else {
            let s = visibleStatuses[indexPath.item]; let count = statusCounts[s.title] ?? 0
            cell.iconImageView.image = UIImage(systemName: s.iconName)?.withRenderingMode(.alwaysTemplate)
            cell.iconImageView.tintColor = s.color
            cell.configure(iconName: s.iconName, title: s.title, count: count, mode: .normal)
        }
        return cell
    }
    func collectionView(_ cv: UICollectionView, layout cvl: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: (cv.frame.width - 20) / 2.0, height: 100)
    }
    func collectionView(_ cv: UICollectionView, layout cvl: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { 4 }
    func collectionView(_ cv: UICollectionView, layout cvl: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat { 8 }
    func collectionView(_ cv: UICollectionView, layout cvl: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets { UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditingMode {
            if indexPath.item >= visibleStatuses.count { restoreRemoved(at: indexPath.item - visibleStatuses.count) }
            return
        }
        openStatusScreen(for: visibleStatuses[indexPath.item].title)
    }
}

// MARK: - Date Formatting
extension SDashboardViewController {
    func formatDisplayDate(_ isoString: String) -> String {
        if let date = parseISO(isoString) {
            let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none
            return f.string(from: date)
        }
        return String(isoString.prefix(10))
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SDashboardViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { tasksForTable.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        registerTaskCellIfNeeded()
        let cell: tasksDueTodayTableViewCell
        if let r = tableView.dequeueReusableCell(withIdentifier: "TaskCell") as? tasksDueTodayTableViewCell {
            cell = r
        } else if let l = Bundle(for: tasksDueTodayTableViewCell.self)
            .loadNibNamed("tasksDueTodayTableViewCell", owner: nil)?.first as? tasksDueTodayTableViewCell {
            cell = l
        } else {
            cell = tasksDueTodayTableViewCell(style: .default, reuseIdentifier: "TaskCell")
        }
        let task = tasksForTable[indexPath.row]
        cell.configure(title:           task.title,
                       dueLabel:        formatDisplayDate(task.assigned_date),
                       descriptionText: task.description ?? "",
                       colorIndex:      indexPath.row)
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { rowHeight }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let task = tasksForTable[indexPath.row]
        let vc   = TaskDetailViewController(nibName: "TaskDetailViewController", bundle: nil)
        var model = DashboardTask(title: task.title, dueDate: formatDisplayDate(task.assigned_date),
                                  assigneeName: "Team \(currentTeamNo)", assigneeImage: nil,
                                  attachmentNames: [], status: task.status, remark: task.remark)
        model.taskId = task.id; model.teamId = task.team_id ?? (currentTeamId ?? ""); model.mentorId = task.mentor_id
        vc.task = model; vc.modalPresentationStyle = .fullScreen; present(vc, animated: true)
    }
}

// MARK: - Drag & Drop
extension SDashboardViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        guard isEditingMode, indexPath.item < visibleStatuses.count else { return [] }
        let item = visibleStatuses[indexPath.item]
        let drag = UIDragItem(itemProvider: NSItemProvider(object: item.title as NSString))
        drag.localObject = item; return [drag]
    }
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let dest = coordinator.destinationIndexPath else { return }
        coordinator.items.forEach { dropItem in
            guard let src = dropItem.sourceIndexPath,
                  let dragged = dropItem.dragItem.localObject as? (iconName: String, title: String, color: UIColor) else { return }
            let d = min(dest.item, visibleStatuses.count - 1)
            collectionView.performBatchUpdates {
                visibleStatuses.remove(at: src.item); visibleStatuses.insert(dragged, at: d)
                collectionView.deleteItems(at: [src]); collectionView.insertItems(at: [IndexPath(item: d, section: 0)])
            }
            coordinator.drop(dropItem.dragItem, toItemAt: IndexPath(item: d, section: 0))
        }
    }
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard isEditingMode else { return UICollectionViewDropProposal(operation: .forbidden) }
        if collectionView.hasActiveDrag, let dest = destinationIndexPath, dest.item <= visibleStatuses.count - 1 {
            return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
}

// MARK: - Add / Delete Notifications
extension SDashboardViewController {
    @objc func handleDeleteNotification(_ notification: Notification) {
        guard let cell = notification.object as? StatusCardCell,
              let indexPath = collectionView.indexPath(for: cell),
              indexPath.item < visibleStatuses.count else { return }
        let removed = visibleStatuses.remove(at: indexPath.item); removedStatuses.append(removed)
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
            if isEditingMode {
                collectionView.insertItems(at: [IndexPath(item: visibleStatuses.count + removedStatuses.count - 1, section: 0)])
            }
        }, completion: { _ in self.updateCollectionViewHeight() })
    }
    @objc func handleAddNotification(_ notification: Notification) {
        guard let cell = notification.object as? StatusCardCell,
              let indexPath = collectionView.indexPath(for: cell),
              indexPath.item >= visibleStatuses.count else { return }
        restoreRemoved(at: indexPath.item - visibleStatuses.count)
    }
    func restoreRemoved(at index: Int) {
        guard index >= 0, index < removedStatuses.count else { return }
        visibleStatuses.append(removedStatuses.remove(at: index))
        collectionView.reloadData(); updateCollectionViewHeight()
    }
}
