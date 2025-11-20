//
//  SDashboardViewController.swift
//  iCohort3
//
//  Created by user@51 on 05/11/25.
//  Updated to fix editing mode tapping and add All view
//

import UIKit

class SDashboardViewController: UIViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cardView2: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var taskCard: UIView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var tasksDueTodayLabel: UILabel!
    private let noTasksLabel: UILabel = {
            let label = UILabel()
            label.text = "No tasks due today"
            label.textAlignment = .center
            label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
            label.textColor = .darkGray
            label.alpha = 0 // initially hidden
            return label
        }()
    
    @IBOutlet weak var collectionViewCellHeight: NSLayoutConstraint!
    // If true, we're in edit mode
    var isEditingMode = false
    
    // All statuses (master list)
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
    
    // Visible statuses currently on dashboard (order can change)
    var visibleStatuses: [(iconName: String, title: String, color: UIColor)] = []
    
    // Statuses removed by tapping minus — kept so they can be re-added later.
    var removedStatuses: [(iconName: String, title: String, color: UIColor)] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyBackgroundGradient()
        taskCard.addSubview(noTasksLabel)
        noTasksLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            noTasksLabel.topAnchor.constraint(equalTo: tasksDueTodayLabel.bottomAnchor, constant: 20),
            noTasksLabel.centerXAnchor.constraint(equalTo: taskCard.centerXAnchor)
        ])


        
        cardView.backgroundColor = .clear
        collectionView.backgroundColor = .clear
        cardView2.layer.cornerRadius = 30
        taskCard.layer.cornerRadius = 30
        
        collectionView.dataSource = self
        collectionView.delegate = self
        
        collectionView.dragDelegate = self
        collectionView.dropDelegate = self
        collectionView.dragInteractionEnabled = true
        
        self.extendedLayoutIncludesOpaqueBars = true
        self.edgesForExtendedLayout = [.bottom, .top]
        tableView.contentInsetAdjustmentBehavior = .never
        
        // Start with all statuses visible
        visibleStatuses = allStatuses
        
        // Notifications from cell actions
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleDeleteNotification(_:)),
                                               name: .statusCardDeleteTapped,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleAddNotification(_:)),
                                               name: .statusCardAddTapped,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    override func viewDidAppear(_ animated: Bool) {
         super.viewDidAppear(animated)
         
         // Animate the label after a delay
         noTasksLabel.transform = CGAffineTransform(translationX: 0, y: 20) // start slightly below
         DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
             UIView.animate(withDuration: 0.5) {
                 self.noTasksLabel.alpha = 1
                 self.noTasksLabel.transform = .identity
             }
         }
     }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        coordinator.animate(alongsideTransition: { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let g = view.layer.sublayers?.first as? CAGradientLayer {
            g.frame = view.bounds
        }
    }
    
    // MARK: - Edit / Done
    @IBAction func editButtonTapped(_ sender: UIButton) {
        isEditingMode.toggle()
        editButton.setTitle(isEditingMode ? "Done" : "Edit", for: .normal)
        
        // when leaving edit mode -> stop wiggle handled by cells on configure
        // when entering edit mode -> show wiggle via cells
        collectionView.reloadData()
    }
    
    @IBAction func profileTapped(_ sender: Any) {
        let vc = SProfileViewController(nibName: "SProfileViewController", bundle: nil)
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
        // When editing, show visible cards + an add-card for each removed card.
        // When not editing, only show visible cards.
        if isEditingMode {
            return visibleStatuses.count + removedStatuses.count
        } else {
            return visibleStatuses.count
        }
    }
    
    func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(withReuseIdentifier: "StatusCardCell", for: indexPath) as! StatusCardCell
        
        if isEditingMode {
            // index < visible => normal/editing cell
            if indexPath.item < visibleStatuses.count {
                let s = visibleStatuses[indexPath.item]
                cell.iconImageView.image = UIImage(systemName: s.iconName)?.withRenderingMode(.alwaysTemplate)
                cell.iconImageView.tintColor = s.color
                cell.configure(iconName: s.iconName, title: s.title, count: 0, mode: .editing)
            } else {
                // Add card representing a removed status
                let removedIndex = indexPath.item - visibleStatuses.count
                let removed = removedStatuses[removedIndex]
                // Show title of removed so user knows what will be re-added
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
        // CRITICAL: Don't allow card taps in editing mode
        // Only action buttons (+ and -) should work in editing mode
        if isEditingMode {
            // If this is an add-card, allow it (same behavior as tapping the + button)
            if indexPath.item >= visibleStatuses.count {
                let removedIndex = indexPath.item - visibleStatuses.count
                restoreRemoved(at: removedIndex)
            }
            // Otherwise, ignore the tap completely
            return
        }
        
        // When not editing, open the appropriate VC
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

// MARK: - Drag & Drop Reordering
extension SDashboardViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
    
    func collectionView(_ collectionView: UICollectionView,
                        itemsForBeginning session: UIDragSession,
                        at indexPath: IndexPath) -> [UIDragItem] {
        // Drag only allowed when editing and only for visible items (not add-cards).
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
            
            // We only allow reordering within visibleStatuses. Ignore drops that target add-card positions.
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
            // allow move if destination is within visible range
            if let dest = destinationIndexPath, dest.item <= visibleStatuses.count - 1 {
                return UICollectionViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
            } else {
                // forbid dropping into add-cards area
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
        // Only allow delete from visible area
        guard indexPath.item < visibleStatuses.count else { return }
        
        // Move the status from visible -> removed
        let removed = visibleStatuses.remove(at: indexPath.item)
        removedStatuses.append(removed)
        
        // Update UI with animation
        collectionView.performBatchUpdates({
            collectionView.deleteItems(at: [indexPath])
            // If we are in editing mode and now we have to show an add-card (because removedStatuses.count increased),
            // insert that add-card at the end of the collection view.
            if isEditingMode {
                let addIndex = IndexPath(item: visibleStatuses.count + removedStatuses.count - 1, section: 0)
                collectionView.insertItems(at: [addIndex])
            }
        }, completion: nil)
    }
    
    @objc func handleAddNotification(_ notification: Notification) {
        guard let cell = notification.object as? StatusCardCell,
              let indexPath = collectionView.indexPath(for: cell) else { return }
        
        // add action arrives only for add-cards (index >= visible.count)
        guard indexPath.item >= visibleStatuses.count else { return }
        let removedIndex = indexPath.item - visibleStatuses.count
        restoreRemoved(at: removedIndex)
    }
    
    // helper to restore removed status at end of visible list
    func restoreRemoved(at removedIndex: Int) {
        guard removedIndex >= 0 && removedIndex < removedStatuses.count else { return }
        let toRestore = removedStatuses.remove(at: removedIndex)
        visibleStatuses.append(toRestore)
        
        // reload collection view to reflect changes (animate if you want)
        collectionView.reloadData()
    }
}
