//
//  SDashboardViewController.swift
//  iCohort3
//
//  Updated: passes teamId + teamNo to all status view controllers
//  Fixed: compiler type-check timeout by splitting switch into openStatusScreen + injectTeamContext
//

import UIKit

class SDashboardViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var taskCard: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var tasksDueTodayLabel: UILabel!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var greetingLabel: UILabel!
    
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
    
    // MARK: - Team Info (loaded once after login)
    
    private var currentTeamId: String? {
        UserDefaults.standard.string(forKey: "current_team_id")
    }
    private var currentTeamNo: Int {
        UserDefaults.standard.integer(forKey: "current_team_number")
    }
    
    var taskCount: Int = 0 {
        didSet { updateTableViewVisibility() }
    }
    
    var isEditingMode = false
    
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
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        visibleStatuses = allStatuses
        loadStudentGreeting()
        loadAndCacheTeamInfo()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeleteNotification(_:)),
                                               name: .statusCardDeleteTapped,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAddNotification(_:)),
                                               name: .statusCardAddTapped,
                                               object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadStudentGreeting()
        updateCollectionViewHeight()
        updateTableViewVisibility()
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        taskCard.bringSubviewToFront(noTasksLabel)
        debugScrollView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let g = view.layer.sublayers?.first as? CAGradientLayer {
            g.frame = view.bounds
        }
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.updateCollectionViewHeight()
        }, completion: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Team Info Loader
    
    private func loadAndCacheTeamInfo() {
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              !personId.isEmpty else {
            print("⚠️ loadAndCacheTeamInfo: no person_id in UserDefaults")
            return
        }
        if currentTeamId != nil { return }
        
        Task {
            do {
                if let teamInfo = try await SupabaseManager.shared.fetchTeamInfoForStudent(personId: personId) {
                    await MainActor.run {
                        UserDefaults.standard.set(teamInfo.teamId,     forKey: "current_team_id")
                        UserDefaults.standard.set(teamInfo.teamNumber, forKey: "current_team_number")
                        print("✅ Cached team: id=\(teamInfo.teamId), no=\(teamInfo.teamNumber)")
                    }
                } else {
                    print("⚠️ Student has no active team yet")
                }
            } catch {
                print("❌ loadAndCacheTeamInfo error:", error)
            }
        }
    }
    
    // MARK: - Greeting
    
    private func loadStudentGreeting() {
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id") else {
            greetingLabel?.text = "Hi Student"
            return
        }
        Task {
            do {
                let greeting = try await SupabaseManager.shared.getStudentGreeting(personId: personId)
                await MainActor.run { self.greetingLabel?.text = greeting }
            } catch {
                if let storedName = UserDefaults.standard.string(forKey: "current_user_name") {
                    let firstName = storedName.components(separatedBy: " ").first ?? "Student"
                    await MainActor.run { self.greetingLabel?.text = "Hi \(firstName)" }
                } else {
                    await MainActor.run { self.greetingLabel?.text = "Hi Student" }
                }
            }
        }
    }
    
    // MARK: - Setup UI
    
    private func setupUI() {
        applyBackgroundGradient()
        
        contentView.backgroundColor    = .clear
        cardView.backgroundColor       = .clear
        collectionView.backgroundColor = .clear
        
        taskCard.layer.cornerRadius = 20
        taskCard.backgroundColor    = .white
        
        if greetingLabel != nil {
            greetingLabel.font      = .systemFont(ofSize: 28, weight: .bold)
            greetingLabel.textColor = .label
            greetingLabel.text      = "Hi Student"
        }
        
        collectionView.dataSource             = self
        collectionView.delegate               = self
        collectionView.dragDelegate           = self
        collectionView.dropDelegate           = self
        collectionView.dragInteractionEnabled = true
        
        tableView.dataSource         = self
        tableView.delegate           = self
        tableView.isScrollEnabled    = false
        tableView.backgroundColor    = .clear
        tableView.layer.cornerRadius = 20
        
        scrollView.isScrollEnabled              = true
        scrollView.showsVerticalScrollIndicator = false
        
        taskCard.addSubview(noTasksLabel)
        setupNoTasksLabelConstraints()
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
    
    private func applyBackgroundGradient() {
        let g = CAGradientLayer()
        g.frame = view.bounds
        g.colors = [
            UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1).cgColor,
            UIColor(white: 0.95, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint   = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(g, at: 0)
    }
    
    // MARK: - Dynamic Height Management
    
    private func updateCollectionViewHeight() {
        let count            = isEditingMode ? (visibleStatuses.count + removedStatuses.count) : visibleStatuses.count
        let rows             = ceil(CGFloat(count) / 2.0)
        let cellH: CGFloat   = 100
        let spacing: CGFloat = 8
        let pad: CGFloat     = 8
        collectionViewCellHeight.constant = (rows * cellH) + ((rows - 1) * spacing) + pad * 2
        updateContentHeight()
    }
    
    private func updateTableViewVisibility() {
        if taskCount > 0 {
            tableView.isHidden    = false
            noTasksLabel.isHidden = true
            tableView.reloadData()
            tableView.layoutIfNeeded()
            tableViewHeight.constant = min(tableView.contentSize.height, 300)
        } else {
            tableView.isHidden       = true
            noTasksLabel.isHidden    = false
            tableViewHeight.constant = 100
        }
        view.layoutIfNeeded()
        taskCard.layoutIfNeeded()
        taskCard.bringSubviewToFront(noTasksLabel)
        updateContentHeight()
    }
    
    private func updateContentHeight() {
        view.layoutIfNeeded()
        let cvHeight: CGFloat  = collectionViewCellHeight.constant
        let tvHeight: CGFloat  = tableViewHeight.constant
        let total: CGFloat     = cvHeight + 20 + 60 + tvHeight + 60 + 100
        contentViewHeight.constant = total
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
        let delay: DispatchTime = .now() + 0.1
        DispatchQueue.main.asyncAfter(deadline: delay) {
            self.scrollView.isScrollEnabled      = true
            self.scrollView.alwaysBounceVertical = true
        }
    }
    
    private func debugScrollView() {
        print("ScrollView contentSize: \(scrollView.contentSize)")
        print("ContentViewHeight: \(contentViewHeight.constant)")
    }
    
    // MARK: - Status VC Navigation
    //
    // Two separate methods so Swift type-checks each concrete VC independently.
    // Putting all 8 cases + presentStatusVC(_:) in one expression caused the
    // "unable to type-check expression in reasonable time" compiler error.
    
    /// Instantiates the correct VC for the tapped status and passes it to injectTeamContext.
    private func openStatusScreen(for title: String) {
        switch title {
        case "Not started":
            let vc = NotStartedViewController(nibName: "NotStartedViewController", bundle: nil)
            injectTeamContext(into: vc)
        case "In Progress":
            let vc = InProgressViewController(nibName: "InProgressViewController", bundle: nil)
            injectTeamContext(into: vc)
        case "For Review":
            let vc = ForReviewViewController(nibName: "ForReviewViewController", bundle: nil)
            injectTeamContext(into: vc)
        case "Prepared":
            let vc = PreparedViewController(nibName: "PreparedViewController", bundle: nil)
            injectTeamContext(into: vc)
        case "Approved":
            let vc = ApprovedViewController(nibName: "ApprovedViewController", bundle: nil)
            injectTeamContext(into: vc)
        case "Completed":
            let vc = CompletedViewController(nibName: "CompletedViewController", bundle: nil)
            injectTeamContext(into: vc)
        case "Rejected":
            let vc = RejectedViewController(nibName: "RejectedViewController", bundle: nil)
            injectTeamContext(into: vc)
        case "All":
            let vc = AllTasksViewController(nibName: "AllTasksViewController", bundle: nil)
            injectTeamContext(into: vc)
        default:
            break
        }
    }
    
    private func injectTeamContext(into vc: UIViewController & TeamContextReceiver) {
        if let teamId = currentTeamId {
            vc.teamId = teamId
            vc.teamNo = currentTeamNo
            vc.modalPresentationStyle = .fullScreen
            present(vc, animated: true)
            return
        }
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id") else {
            showNoTeamAlert()
            return
        }
        Task { await fetchTeamAndPresent(vc: vc, personId: personId) }
    }

    private func fetchTeamAndPresent(vc: UIViewController & TeamContextReceiver, personId: String) async {
        do {
            let info = try await SupabaseManager.shared.fetchTeamInfoForStudent(personId: personId)
            guard let info else {
                await MainActor.run { self.showNoTeamAlert() }
                return
            }
            let tid: String = info.teamId
            let tno: Int    = info.teamNumber
            await MainActor.run {
                UserDefaults.standard.set(tid, forKey: "current_team_id")
                UserDefaults.standard.set(tno, forKey: "current_team_number")
                vc.teamId = tid
                vc.teamNo = tno
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            }
        } catch {
            await MainActor.run { self.showNoTeamAlert() }
        }
    }
    
    private func showNoTeamAlert() {
        let alert = UIAlertController(
            title: "No Team Found",
            message: "You are not part of a team yet. Please join or create a team first.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    // MARK: - Actions
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        isEditingMode.toggle()
        editButton.setTitle(isEditingMode ? "Done" : "Edit", for: .normal)
        collectionView.reloadData()
        updateCollectionViewHeight()
    }
    
    @IBAction func profileTapped(_ sender: Any) {
        let vc = SProfileViewController(nibName: "SProfileViewController", bundle: nil)
        vc.modalPresentationStyle = .pageSheet
        vc.modalTransitionStyle   = .coverVertical
        
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
}

// MARK: - TeamContextReceiver Protocol

protocol TeamContextReceiver: AnyObject {
    var teamId: String! { get set }
    var teamNo: Int!    { get set }
}

// MARK: - UICollectionViewDataSource & DelegateFlowLayout

extension SDashboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ cv: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        isEditingMode ? visibleStatuses.count + removedStatuses.count : visibleStatuses.count
    }
    
    func collectionView(_ cv: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(
            withReuseIdentifier: "StatusCardCell", for: indexPath) as! StatusCardCell
        cell.backgroundColor             = .clear
        cell.contentView.backgroundColor = .clear
        
        if isEditingMode {
            if indexPath.item < visibleStatuses.count {
                let s = visibleStatuses[indexPath.item]
                cell.iconImageView.image     = UIImage(systemName: s.iconName)?.withRenderingMode(.alwaysTemplate)
                cell.iconImageView.tintColor = s.color
                cell.configure(iconName: s.iconName, title: s.title, count: 0, mode: .editing)
            } else {
                let removed = removedStatuses[indexPath.item - visibleStatuses.count]
                cell.configure(iconName: nil, title: removed.title, count: nil, mode: .add)
            }
        } else {
            let s = visibleStatuses[indexPath.item]
            cell.iconImageView.image     = UIImage(systemName: s.iconName)?.withRenderingMode(.alwaysTemplate)
            cell.iconImageView.tintColor = s.color
            cell.configure(iconName: s.iconName, title: s.title, count: 0, mode: .normal)
        }
        return cell
    }
    
    func collectionView(_ cv: UICollectionView,
                        layout cvl: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = (8.0 * 2) + (4.0 * 1)
        let width = (cv.frame.width - padding) / 2.0
        return CGSize(width: width, height: 100)
    }
    
    func collectionView(_ cv: UICollectionView, layout cvl: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { 4 }
    
    func collectionView(_ cv: UICollectionView, layout cvl: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat { 8 }
    
    func collectionView(_ cv: UICollectionView, layout cvl: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
    }
    
    // ✅ Delegates to openStatusScreen(for:) — keeps didSelectItemAt simple
    // so the compiler doesn't have to type-check 8 VC initialisations at once.
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        if isEditingMode {
            if indexPath.item >= visibleStatuses.count {
                restoreRemoved(at: indexPath.item - visibleStatuses.count)
            }
            return
        }
        let title: String = visibleStatuses[indexPath.item].title
        openStatusScreen(for: title)
    }
}

// MARK: - UITableViewDataSource & Delegate

extension SDashboardViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int { taskCount }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
    }
    
    func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat { UITableView.automaticDimension }
    
    func tableView(_ tableView: UITableView,
                   estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat { 60 }
}

// MARK: - Drag & Drop

extension SDashboardViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        guard isEditingMode, indexPath.item < visibleStatuses.count else { return [] }
        let item     = visibleStatuses[indexPath.item]
        let provider = NSItemProvider(object: item.title as NSString)
        let drag     = UIDragItem(itemProvider: provider)
        drag.localObject = item
        return [drag]
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let dest = coordinator.destinationIndexPath else { return }
        coordinator.items.forEach { dropItem in
            guard let src = dropItem.sourceIndexPath,
                  let dragged = dropItem.dragItem.localObject
                    as? (iconName: String, title: String, color: UIColor)
            else { return }
            let d = min(dest.item, visibleStatuses.count - 1)
            collectionView.performBatchUpdates {
                visibleStatuses.remove(at: src.item)
                visibleStatuses.insert(dragged, at: d)
                collectionView.deleteItems(at: [src])
                collectionView.insertItems(at: [IndexPath(item: d, section: 0)])
            }
            coordinator.drop(dropItem.dragItem, toItemAt: IndexPath(item: d, section: 0))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?)
    -> UICollectionViewDropProposal {
        guard isEditingMode else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        if collectionView.hasActiveDrag,
           let dest = destinationIndexPath,
           dest.item <= visibleStatuses.count - 1 {
            return UICollectionViewDropProposal(operation: .move,
                                                intent: .insertAtDestinationIndexPath)
        }
        return UICollectionViewDropProposal(operation: .forbidden)
    }
}

// MARK: - Add / Delete Notifications

extension SDashboardViewController {
    
    @objc func handleDeleteNotification(_ notification: Notification) {
        guard let cell      = notification.object as? StatusCardCell,
              let indexPath = collectionView.indexPath(for: cell),
              indexPath.item < visibleStatuses.count else { return }
        
        let removed = visibleStatuses.remove(at: indexPath.item)
        removedStatuses.append(removed)
        
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
            if isEditingMode {
                let addIndex = IndexPath(
                    item: visibleStatuses.count + removedStatuses.count - 1, section: 0)
                collectionView.insertItems(at: [addIndex])
            }
        }, completion: { _ in self.updateCollectionViewHeight() })
    }
    
    @objc func handleAddNotification(_ notification: Notification) {
        guard let cell      = notification.object as? StatusCardCell,
              let indexPath = collectionView.indexPath(for: cell),
              indexPath.item >= visibleStatuses.count else { return }
        restoreRemoved(at: indexPath.item - visibleStatuses.count)
    }
    
    func restoreRemoved(at index: Int) {
        guard index >= 0, index < removedStatuses.count else { return }
        visibleStatuses.append(removedStatuses.remove(at: index))
        collectionView.reloadData()
        updateCollectionViewHeight()
    }
}
