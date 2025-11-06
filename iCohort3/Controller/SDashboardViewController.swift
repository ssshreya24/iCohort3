//
//  SDashboardViewController.swift
//  iCohort3
//
//  Created by user@51 on 05/11/25.
//

import UIKit

class SDashboardViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var cardView2: UIView!
    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var taskCard: UIView!
    
    @IBOutlet weak var editButton: UIButton!
    
    var isEditingMode = false
        
        // Data source for collection view (icon + title)
        var statuses: [(iconName: String, title: String)] = [
            ("dot.circle.fill", "Not started"),
            ("clock.fill", "In Progress"),
            ("magnifyingglass.circle.fill", "For Review"),
            ("checkmark.circle.fill", "Approved"),
            ("xmark.circle.fill", "Rejected"),
            ("cube.box.fill", "Prepared"),
            ("airplane.circle.fill", "Completed"),
            ("circle.grid.3x3.fill", "All")
        ]
        
        override func viewDidLoad() {
            super.viewDidLoad()
            applyBackgroundGradient()
            
            cardView.backgroundColor = .clear
            collectionView.backgroundColor = .clear
            cardView2.layer.cornerRadius = 30
            taskCard.layer.cornerRadius = 30
            
            collectionView.dataSource = self
            collectionView.delegate = self
            
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
            collectionView.dragInteractionEnabled = true
        }
        
        private func applyBackgroundGradient() {
            let g = CAGradientLayer()
            g.frame = view.bounds
            g.colors = [
                UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1).cgColor, // top blue
                UIColor(white: 0.95, alpha: 1).cgColor // bottom light gray
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
        
        @IBAction func editButtonTapped(_ sender: UIButton) {
            isEditingMode.toggle()
            editButton.setTitle(isEditingMode ? "Done" : "Edit", for: .normal)
            collectionView.reloadData()
        }
    }

    // MARK: - UICollectionViewDataSource & UICollectionViewDelegateFlowLayout

    extension SDashboardViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        
        func collectionView(_ cv: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return statuses.count
        }
        
        func collectionView(_ cv: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = cv.dequeueReusableCell(withReuseIdentifier: "StatusCardCell", for: indexPath) as! StatusCardCell
            let s = statuses[indexPath.item]
            cell.iconImageView.image = UIImage(systemName: s.iconName)
            cell.titleLabel.text = s.title
            cell.countLabel.text = "0"
            cell.configure(title: s.title, count: 0, isEditing: isEditingMode)
            return cell
        }
        
        func collectionView(_ cv: UICollectionView,
                            layout cvl: UICollectionViewLayout,
                            sizeForItemAt indexPath: IndexPath) -> CGSize {
            let padding: CGFloat = 16
            let availableWidth = cv.frame.width - padding
            let width = (availableWidth / 2) - 8
            return CGSize(width: width, height: 100)
        }
        
        func collectionView(_ cv: UICollectionView,
                            layout cvl: UICollectionViewLayout,
                            minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
            return 12
        }
        
        func collectionView(_ cv: UICollectionView,
                            layout cvl: UICollectionViewLayout,
                            minimumLineSpacingForSectionAt section: Int) -> CGFloat {
            return 12
        }
    }

    // MARK: - Drag and Drop Reordering

    extension SDashboardViewController: UICollectionViewDragDelegate, UICollectionViewDropDelegate {
        
        func collectionView(_ collectionView: UICollectionView,
                            itemsForBeginning session: UIDragSession,
                            at indexPath: IndexPath) -> [UIDragItem] {
            guard isEditingMode else { return [] }
            let item = statuses[indexPath.item]
            let itemProvider = NSItemProvider(object: item.title as NSString) // ✅ fixed here
            let dragItem = UIDragItem(itemProvider: itemProvider)
            dragItem.localObject = item
            return [dragItem]
        }
        
        func collectionView(_ collectionView: UICollectionView,
                            performDropWith coordinator: UICollectionViewDropCoordinator) {
            guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

            coordinator.items.forEach { item in
                guard let sourceIndexPath = item.sourceIndexPath,
                      let draggedItem = item.dragItem.localObject as? (iconName: String, title: String)
                else { return }
                
                collectionView.performBatchUpdates {
                    statuses.remove(at: sourceIndexPath.item)
                    statuses.insert(draggedItem, at: destinationIndexPath.item)
                    collectionView.deleteItems(at: [sourceIndexPath])
                    collectionView.insertItems(at: [destinationIndexPath])
                }
                coordinator.drop(item.dragItem, toItemAt: destinationIndexPath)
            }
        }
    }

    
    
    
    
    

