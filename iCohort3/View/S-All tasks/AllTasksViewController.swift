//
//  AllTasksViewController.swift
//  iCohort3
//
//  Created by user@51 on 20/11/25.
//

import UIKit

class AllTasksViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    // Sections for different task statuses
    enum TaskSection: Int, CaseIterable {
        case notStarted = 0
        case inProgress
        case forReview
        case prepared
        case approved
        case rejected
        case completed
        
        var title: String {
            switch self {
            case .notStarted: return "Not Started"
            case .inProgress: return "In Progress"
            case .forReview: return "For Review"
            case .prepared: return "Prepared"
            case .approved: return "Approved"
            case .rejected: return "Rejected"
            case .completed: return "Completed"
            }
        }
        
        var cellIdentifier: String {
            switch self {
            case .notStarted: return "TaskCollectionViewCell"
            case .inProgress: return "InProgressCollectionViewCell"
            case .forReview: return "TaskCollectionViewCell"
            case .prepared: return "PreparedCollectionViewCell"
            case .approved: return "ApprovedCollectionViewCell"
            case .rejected: return "RejectedCollectionViewCell"
            case .completed: return "CompletedCollectionViewCell"
            }
        }
    }
    
    // Data structure to hold tasks by section
    var tasksBySections: [[String: Any]] = []
    
    // Empty state label
    var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No tasks available"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
        applyBackgroundGradient()
        
        // Add empty label
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Register all custom cells
        registerCells()
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        
        // Register header with unique identifier
        collectionView.register(
            TaskSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "TaskSectionHeader"
        )
        
        // Load all tasks
        loadAllTasks()
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
        
        for cellName in cellNames {
            let nib = UINib(nibName: cellName, bundle: nil)
            collectionView.register(nib, forCellWithReuseIdentifier: cellName)
        }
    }

    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        backButton.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        backButton.layer.cornerRadius = 22
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let arrowImage = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(arrowImage, for: .normal)
        backButton.tintColor = .black
        
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
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

    func loadAllTasks() {
        // Simulate loading tasks from all statuses
        // In real app, you'd fetch from your data source
        tasksBySections = []
        
        for section in TaskSection.allCases {
            let sectionData: [String: Any] = [
                "section": section,
                "tasks": getSampleTasks(for: section)
            ]
            tasksBySections.append(sectionData)
        }
        
        // Check if we have any tasks at all
        let totalTasks = tasksBySections.reduce(0) { count, sectionData in
            if let tasks = sectionData["tasks"] as? [[String: String]] {
                return count + tasks.count
            }
            return count
        }
        
        emptyLabel.isHidden = totalTasks > 0
        collectionView.reloadData()
    }
    
    private func getSampleTasks(for section: TaskSection) -> [[String: String]] {
        // Sample data for each section
        switch section {
        case .notStarted:
            return [
                ["title": "Setup Database", "desc": "Configure PostgreSQL database", "remark": ""],
                ["title": "Design Mockups", "desc": "Create UI/UX designs", "remark": ""]
            ]
        case .inProgress:
            return [
                ["title": "API Integration", "desc": "Integrate payment gateway", "remark": ""]
            ]
        case .forReview:
            return [
                ["title": "Code Review", "desc": "Review authentication module", "remark": ""]
            ]
        case .prepared:
            return [
                ["title": "Documentation", "desc": "Prepare technical documentation", "remark": ""]
            ]
        case .approved:
            return [
                ["title": "Feature Release", "desc": "Deploy new dashboard", "remark": "Looks great!"]
            ]
        case .rejected:
            return [
                ["title": "Bug Fix", "desc": "Fix dashboard alignment", "remark": "Incomplete implementation"],
                ["title": "Onboarding", "desc": "Create user onboarding flow", "remark": ""]
            ]
        case .completed:
            return [
                ["title": "Login Module", "desc": "Complete authentication system", "remark": ""]
            ]
        }
    }
}

// MARK: - Collection View
extension AllTasksViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return TaskSection.allCases.count
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section < tasksBySections.count,
              let tasks = tasksBySections[section]["tasks"] as? [[String: String]] else {
            return 0
        }
        return tasks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let sectionEnum = tasksBySections[indexPath.section]["section"] as? TaskSection,
              let tasks = tasksBySections[indexPath.section]["tasks"] as? [[String: String]],
              indexPath.row < tasks.count else {
            return UICollectionViewCell()
        }
        
        let task = tasks[indexPath.row]
        let cellIdentifier = sectionEnum.cellIdentifier
        
        // Dequeue the appropriate cell type based on section
        switch sectionEnum {
        case .approved:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ApprovedCollectionViewCell
            cell.configure(
                title: task["title"] ?? "",
                desc: task["desc"] ?? "",
                remark: task["remark"],
                image: UIImage(named: "logo"),
                name: "Shreya"
            )
            return cell
            
        case .rejected:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! RejectedCollectionViewCell
            cell.configure(
                title: task["title"] ?? "",
                desc: task["desc"] ?? "",
                remark: task["remark"],
                image: UIImage(named: "logo"),
                name: "Shreya"
            )
            return cell
            
        case .inProgress:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! InProgressCollectionViewCell
            cell.configure(
                title: task["title"] ?? "",
                desc: task["desc"] ?? "",
                image: UIImage(named: "logo"),
                name: "Shreya"
            )
            return cell
            
        case .prepared:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PreparedCollectionViewCell
            cell.configure(
                title: task["title"] ?? "",
                desc: task["desc"] ?? "",
                image: UIImage(named: "logo"),
                name: "Shreya"
            )
            return cell
            
        case .completed:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! CompletedCollectionViewCell
            cell.configure(
                title: task["title"] ?? "",
                desc: task["desc"] ?? "",
                image: UIImage(named: "logo"),
                name: "Shreya"
            )
            return cell
            
        default: // notStarted, forReview
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! TaskCollectionViewCell
            cell.configure(
                title: task["title"] ?? "",
                desc: task["desc"] ?? "",
                image: UIImage(named: "logo"),
                name: "Shreya"
            )
            return cell
        }
    }
    
    // Section header
    func collectionView(_ collectionView: UICollectionView,
                       viewForSupplementaryElementOfKind kind: String,
                       at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "TaskSectionHeader",
                for: indexPath
            ) as! TaskSectionHeaderView
            
            if let sectionEnum = tasksBySections[indexPath.section]["section"] as? TaskSection {
                header.titleLabel.text = sectionEnum.title
            }
            
            return header
        }
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: collectionView.frame.width, height: 40)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 40, height: 180)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                       layout collectionViewLayout: UICollectionViewLayout,
                       insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 8, left: 20, bottom: 16, right: 20)
    }
}
