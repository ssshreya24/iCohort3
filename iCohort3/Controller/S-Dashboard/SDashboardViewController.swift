//
//  SDashboardViewController.swift
//  iCohort3
//
//  Created by user@51 on 05/11/25.
//  Updated with Supabase name display integration
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
    
    // ✅ NEW: Add greeting label outlet
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
    
    // Track table view data
    var taskCount: Int = 0 {
        didSet {
            updateTableViewVisibility()
        }
    }
    
    var isEditingMode = false
    
    let allStatuses: [(iconName: String, title: String, color: UIColor)] = [
        ("dot.circle.fill", "Not started", .systemGray),
        ("clock.fill", "In Progress", .systemOrange),
        ("magnifyingglass.circle.fill", "For Review", .systemYellow),
        ("checkmark.circle.fill", "Approved", .systemGreen),
        ("xmark.circle.fill", "Rejected", .systemRed),
        ("cube.box.fill", "Prepared", .systemTeal),
        ("airplane.circle.fill", "Completed", .systemBlue),
        ("circle.grid.3x3.fill", "All", .black)
    ]
    
    var visibleStatuses: [(iconName: String, title: String, color: UIColor)] = []
    var removedStatuses: [(iconName: String, title: String, color: UIColor)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        visibleStatuses = allStatuses
        
        // ✅ NEW: Load student name from Supabase
        loadStudentGreeting()
        
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeleteNotification(_:)),
                                               name: .statusCardDeleteTapped,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAddNotification(_:)),
                                               name: .statusCardAddTapped,
                                               object: nil)
    }
    
    // ✅ NEW: Load student greeting from Supabase
    private func loadStudentGreeting() {
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id") else {
            print("⚠️ No person ID found, using default greeting")
            greetingLabel?.text = "Hi Student"
            return
        }
        
        print("🔄 Loading greeting for person ID:", personId)
        
        Task {
            do {
                // Fetch student greeting from Supabase
                let greeting = try await SupabaseManager.shared.getStudentGreeting(personId: personId)
                
                await MainActor.run {
                    self.greetingLabel?.text = greeting
                    print("✅ Greeting loaded:", greeting)
                }
            } catch {
                print("❌ Error fetching greeting:", error)
                
                // Fallback to stored name
                if let storedName = UserDefaults.standard.string(forKey: "current_user_name") {
                    let firstName = storedName.components(separatedBy: " ").first ?? "Student"
                    await MainActor.run {
                        self.greetingLabel?.text = "Hi \(firstName)"
                    }
                } else {
                    await MainActor.run {
                        self.greetingLabel?.text = "Hi Student"
                    }
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // ✅ NEW: Refresh greeting when view appears
        loadStudentGreeting()
        
        updateCollectionViewHeight()
        updateTableViewVisibility()
        
        // Ensure scrolling is enabled
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
    }
    
    private func setupUI() {
        applyBackgroundGradient()
        
        contentView.backgroundColor = .clear
        cardView.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        
        // Set task card to white background
        taskCard.layer.cornerRadius = 20
        taskCard.backgroundColor = .white
        
        // ✅ NEW: Configure greeting label
        if greetingLabel != nil {
            greetingLabel.font = .systemFont(ofSize: 28, weight: .bold)
            greetingLabel.textColor = .label
            greetingLabel.text = "Hi Student" // Default
        }
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.isScrollEnabled = false
        tableView.backgroundColor = .clear
        tableView.layer.cornerRadius = 20
        
        scrollView.isScrollEnabled = true
        scrollView.showsVerticalScrollIndicator = false
        
        // Add noTasksLabel to taskCard
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let g = view.layer.sublayers?.first as? CAGradientLayer {
            g.frame = view.bounds
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Ensure visibility after view appears
        taskCard.bringSubviewToFront(noTasksLabel)
        
        // Debug scroll view setup
        debugScrollView()
    }
    
    private func debugScrollView() {
        print("=== Scroll View Debug ===")
        print("ScrollView frame: \(scrollView.frame)")
        print("ScrollView bounds: \(scrollView.bounds)")
        print("ScrollView contentSize: \(scrollView.contentSize)")
        print("ContentView frame: \(contentView.frame)")
        print("ContentViewHeight constant: \(contentViewHeight.constant)")
        print("ScrollView isScrollEnabled: \(scrollView.isScrollEnabled)")
        print("========================")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
            self.updateCollectionViewHeight()
        }, completion: nil)
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
    
    // MARK: - Dynamic Height Management
    
    private func updateCollectionViewHeight() {
        let numberOfItems = isEditingMode ? (visibleStatuses.count + removedStatuses.count) : visibleStatuses.count
        let numberOfRows = ceil(CGFloat(numberOfItems) / 2.0)
        let cellHeight: CGFloat = 100
        let lineSpacing: CGFloat = 8
        let topPadding: CGFloat = 8
        let bottomPadding: CGFloat = 8
        
        let totalHeight = (numberOfRows * cellHeight) + ((numberOfRows - 1) * lineSpacing) + topPadding + bottomPadding
        collectionViewCellHeight.constant = totalHeight
        
        updateContentHeight()
    }
    
    private func updateTableViewVisibility() {
        let hasContent = taskCount > 0
        
        if hasContent {
            tableView.isHidden = false
            noTasksLabel.isHidden = true
            
            tableView.reloadData()
            tableView.layoutIfNeeded()
            
            let contentHeight = tableView.contentSize.height
            tableViewHeight.constant = min(contentHeight, 300)
            
        } else {
            tableView.isHidden = true
            noTasksLabel.isHidden = false
            
            // Increased height when showing "No tasks today"
            tableViewHeight.constant = 100
        }
        
        // Force layout update and bring label to front
        view.layoutIfNeeded()
        taskCard.layoutIfNeeded()
        taskCard.bringSubviewToFront(noTasksLabel)
        
        updateContentHeight()
    }
    
    private func updateContentHeight() {
        // Force layout first
        view.layoutIfNeeded()
        taskCard.layoutIfNeeded()
        collectionView.layoutIfNeeded()
        
        // Get actual heights
        let collectionHeight = collectionViewCellHeight.constant
        let tableAreaHeight = tableViewHeight.constant
        let tasksDueLabelHeight: CGFloat = 60
        let spacing: CGFloat = 20
        let bottomPadding: CGFloat = 60
        
        // Calculate task card total height
        let taskCardContentHeight = tasksDueLabelHeight + tableAreaHeight + bottomPadding
        
        // Total content height - add extra padding to ensure scrollability
        let totalHeight = collectionHeight + spacing + taskCardContentHeight + 100
        
        contentViewHeight.constant = totalHeight
        
        // Force immediate layout update
        contentView.setNeedsLayout()
        contentView.layoutIfNeeded()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        
        // Update scroll view content size with delay to ensure layout is complete
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Always enable scrolling
            self.scrollView.isScrollEnabled = true
            self.scrollView.alwaysBounceVertical = true
            
            // Verify scroll view frame
            print("ScrollView frame: \(self.scrollView.frame)")
            print("ContentView height: \(self.contentViewHeight.constant)")
            print("ScrollView contentSize: \(self.scrollView.contentSize)")
        }
    }
    
    // MARK: - Edit / Done
    @IBAction func editButtonTapped(_ sender: UIButton) {
        isEditingMode.toggle()
        editButton.setTitle(isEditingMode ? "Done" : "Edit", for: .normal)
        
        collectionView.reloadData()
        updateCollectionViewHeight()
    }
    
    @IBAction func profileTapped(_ sender: Any) {
        // ✅ UPDATED: Use StudentProfileViewController instead
        let vc = StudentProfileViewController(nibName: "StudentProfileViewController", bundle: nil)
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
}

// MARK: - UICollectionViewDataSource & DelegateFlowLayout
extension SDashboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if isEditingMode {
            return visibleStatuses.count + removedStatuses.count
        } else {
            return visibleStatuses.count
        }
    }
    
    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "StatusCardCell", for: indexPath) as! StatusCardCell
        
        // Make cell background clear so main gradient shows through
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .clear
        
        if isEditingMode {
            if indexPath.item < visibleStatuses.count {
                let s = visibleStatuses[indexPath.item]
                cell.iconImageView.image = UIImage(systemName: s.iconName)?.withRenderingMode(.alwaysTemplate)
                cell.iconImageView.tintColor = s.color
                cell.configure(iconName: s.iconName, title: s.title, count: 0, mode: .editing)
            } else {
                let removedIndex = indexPath.item - visibleStatuses.count
                let removed = removedStatuses[removedIndex]
                cell.configure(iconName: nil, title: removed.title, count: nil, mode: .add)
            }
        } else {
            let s = visibleStatuses[indexPath.item]
            cell.iconImageView.image = UIImage(systemName: s.iconName)?.withRenderingMode(.alwaysTemplate)
            cell.iconImageView.tintColor = s.color
            cell.configure(iconName: s.iconName, title: s.title, count: 0, mode: .normal)
        }
        
        return cell
    }
    
    func collectionView(_ cv: UICollectionView,
                        layout cvl: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cardSpacing: CGFloat = 4.0
        let sectionEdgePadding: CGFloat = 8.0
        let numberOfColumns: CGFloat = 2.0
        let totalHorizontalSpacing = (sectionEdgePadding * 2) + (cardSpacing * (numberOfColumns - 1))
        let availableWidth = cv.frame.width - totalHorizontalSpacing
        let width = availableWidth / numberOfColumns
        return CGSize(width: width, height: 100)
    }
    
    func collectionView(_ cv: UICollectionView,
                        layout cvl: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 4.0
    }
    
    func collectionView(_ cv: UICollectionView,
                        layout cvl: UICollectionViewLayout,
                        minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8.0
    }
    
    func collectionView(_ cv: UICollectionView,
                        layout cvl: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        let padding: CGFloat = 8.0
        return UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isEditingMode {
            if indexPath.item >= visibleStatuses.count {
                let removedIndex = indexPath.item - visibleStatuses.count
                restoreRemoved(at: removedIndex)
            }
            return
        }
        
        let selectedStatus = visibleStatuses[indexPath.item].title
        
        switch selectedStatus {
        case "Not started":
            let vc = NotStartedViewController(nibName: "NotStartedViewController", bundle: nil)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        case "For Review":
            let vc = ForReviewViewController(nibName: "ForReviewViewController", bundle: nil)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        case "In Progress":
            let vc = InProgressViewController(nibName: "InProgressViewController", bundle: nil)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        case "Prepared":
            let vc = PreparedViewController(nibName: "PreparedViewController", bundle: nil)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        case "Completed":
            let vc = CompletedViewController(nibName: "CompletedViewController", bundle: nil)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        case "Approved":
            let vc = ApprovedViewController(nibName: "ApprovedViewController", bundle: nil)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        case "Rejected":
            let vc = RejectedViewController(nibName: "RejectedViewController", bundle: nil)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        case "All":
            let vc = AllTasksViewController(nibName: "AllTasksViewController", bundle: nil)
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true)
        default:
            break
        }
    }
}

// MARK: - UITableViewDataSource & Delegate
extension SDashboardViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return taskCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)
        // Configure your cell here
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
}

// MARK: - Drag & Drop Reordering
extension SDashboardViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        guard isEditingMode, indexPath.item < visibleStatuses.count else { return [] }
        let item = visibleStatuses[indexPath.item]
        let provider = NSItemProvider(object: item.title as NSString)
        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = item
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        performDropWith coordinator: UICollectionViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }
        
        coordinator.items.forEach { dropItem in
            guard let sourceIndexPath = dropItem.sourceIndexPath,
                  let dragged = dropItem.dragItem.localObject as? (iconName: String, title: String, color: UIColor)
            else { return }
            
            let dest = min(destinationIndexPath.item, visibleStatuses.count - 1)
            
            collectionView.performBatchUpdates {
                visibleStatuses.remove(at: sourceIndexPath.item)
                visibleStatuses.insert(dragged, at: dest)
                collectionView.deleteItems(at: [sourceIndexPath])
                collectionView.insertItems(at: [IndexPath(item: dest, section: 0)])
            }
            coordinator.drop(dropItem.dragItem, toItemAt: IndexPath(item: dest, section: 0))
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        dropSessionDidUpdate session: UIDropSession,
                        withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        guard isEditingMode else {
            return UICollectionViewDropProposal(operation: .forbidden)
        }
        
        if collectionView.hasActiveDrag {
            if let dest = destinationIndexPath, dest.item <= visibleStatuses.count - 1 {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                return UICollectionViewDropProposal(operation: .forbidden)
            }
        }
        
        return UICollectionViewDropProposal(operation: .forbidden)
    }
}

// MARK: - Handle Add / Delete from cells
extension SDashboardViewController {
    
    @objc func handleDeleteNotification(_ notification: Notification) {
        guard let cell = notification.object as? StatusCardCell,
              let indexPath = collectionView.indexPath(for: cell) else { return }
        guard indexPath.item < visibleStatuses.count else { return }
        
        let removed = visibleStatuses.remove(at: indexPath.item)
        removedStatuses.append(removed)
        
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
            if isEditingMode {
                let addIndex = IndexPath(item: visibleStatuses.count + removedStatuses.count - 1, section: 0)
                collectionView.insertItems(at: [addIndex])
            }
        }, completion: { _ in
            self.updateCollectionViewHeight()
        })
    }
    
    @objc func handleAddNotification(_ notification: Notification) {
        guard let cell = notification.object as? StatusCardCell,
              let indexPath = collectionView.indexPath(for: cell) else { return }
        
        guard indexPath.item >= visibleStatuses.count else { return }
        let removedIndex = indexPath.item - visibleStatuses.count
        restoreRemoved(at: removedIndex)
    }
    
    func restoreRemoved(at removedIndex: Int) {
        guard removedIndex >= 0 && removedIndex < removedStatuses.count else { return }
        let toRestore = removedStatuses.remove(at: removedIndex)
        visibleStatuses.append(toRestore)
        
        collectionView.reloadData()
        updateCollectionViewHeight()
    }
}
