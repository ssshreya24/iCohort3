//
//  AllTasksViewController.swift
//  iCohort3
//

import UIKit

final class AllTasksViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    // ✅ TEMP (later you'll pass from previous screen)
    var teamId: String = "PUT_ANY_TEAM_UUID_HERE"
    var teamNo: Int = 9

    // Sections for different task statuses (KEEP AS-IS)
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

        // ✅ Mapping UI section -> DB status
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

    // ✅ REAL data: tasks grouped by section
    private var tasksBySections: [[SupabaseManager.TaskRow]] = Array(
        repeating: [],
        count: TaskSection.allCases.count
    )

    // Empty state label
    private let emptyLabel: UILabel = {
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

        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        registerCells()

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear

        collectionView.register(
            TaskSectionHeaderView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: "TaskSectionHeader"
        )

        Task { await loadAllTasksFromSupabase() }
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
        dismiss(animated: true)
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

    // MARK: - ✅ Load tasks from DB and bucket them by status

    private func loadAllTasksFromSupabase() async {
        do {
            let tasks = try await SupabaseManager.shared.fetchTasksForTeam(teamId: teamId)

            var buckets: [[SupabaseManager.TaskRow]] = Array(
                repeating: [],
                count: TaskSection.allCases.count
            )

            for task in tasks {
                switch task.status {
                case "assigned":
                    buckets[TaskSection.notStarted.rawValue].append(task)

                case "ongoing":
                    buckets[TaskSection.inProgress.rawValue].append(task)

                case "for_review":
                    buckets[TaskSection.forReview.rawValue].append(task)

                case "prepared":
                    buckets[TaskSection.prepared.rawValue].append(task)

                case "approved":
                    buckets[TaskSection.approved.rawValue].append(task)

                case "rejected":
                    buckets[TaskSection.rejected.rawValue].append(task)

                case "completed":
                    buckets[TaskSection.completed.rawValue].append(task)

                default:
                    break
                }
            }

            let total = buckets.reduce(0) { $0 + $1.count }

            await MainActor.run {
                self.tasksBySections = buckets
                self.emptyLabel.isHidden = total > 0
                self.collectionView.reloadData()
            }

        } catch {
            print("❌ Failed to load tasks:", error)
            await MainActor.run {
                self.tasksBySections = Array(repeating: [], count: TaskSection.allCases.count)
                self.emptyLabel.isHidden = false
                self.collectionView.reloadData()
            }
        }
    }

    // MARK: - ✅ Shift task status (THIS is what updates tasks + team_task counters)

    private func shiftStatus(taskId: String, to newSection: TaskSection) async {
        do {
            // ✅ Update ONLY tasks.status
            // Trigger on tasks table will auto-update team_task counts
            try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: newSection.dbStatus)

            // ✅ Reload to reflect the moved task in correct section
            await loadAllTasksFromSupabase()

        } catch {
            print("❌ Failed to shift status:", error)
        }
    }
}

// MARK: - Collection View
extension AllTasksViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        TaskSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section < tasksBySections.count else { return 0 }
        return tasksBySections[section].count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let sectionEnum = TaskSection.allCases[indexPath.section]
        let task = tasksBySections[indexPath.section][indexPath.row]
        let cellIdentifier = sectionEnum.cellIdentifier

        switch sectionEnum {

        case .approved:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! ApprovedCollectionViewCell
            cell.configure(
                title: task.title,
                desc: task.description ?? "",
                remark: task.remark,
                image: UIImage(named: "logo"),
                name: "Team \(teamNo)"
            )
            return cell

        case .rejected:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! RejectedCollectionViewCell
            cell.configure(
                title: task.title,
                desc: task.description ?? "",
                remark: task.remark,
                image: UIImage(named: "logo"),
                name: "Team \(teamNo)"
            )
            return cell

        case .inProgress:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! InProgressCollectionViewCell
            cell.configure(
                title: task.title,
                desc: task.description ?? "",
                image: UIImage(named: "logo"),
                name: "Team \(teamNo)"
            )
            return cell

        case .prepared:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! PreparedCollectionViewCell
            cell.configure(
                title: task.title,
                desc: task.description ?? "",
                image: UIImage(named: "logo"),
                name: "Team \(teamNo)"
            )
            return cell

        case .completed:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! CompletedCollectionViewCell
            cell.configure(
                title: task.title,
                desc: task.description ?? "",
                image: UIImage(named: "logo"),
                name: "Team \(teamNo)"
            )
            return cell

        default: // notStarted, forReview
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! TaskCollectionViewCell
            cell.configure(
                title: task.title,
                desc: task.description ?? "",
                image: UIImage(named: "logo"),
                name: "Team \(teamNo)"
            )
            return cell
        }
    }

    // Section header
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "TaskSectionHeader",
            for: indexPath
        ) as! TaskSectionHeaderView

        let sectionEnum = TaskSection.allCases[indexPath.section]
        header.titleLabel.text = sectionEnum.title
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
        CGSize(width: collectionView.frame.width - 40, height: 180)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 20, bottom: 16, right: 20)
    }

    // ✅ Example: tap on task to move it forward (TEMP demo)
    // Later you can replace with buttons in each cell.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentSection = TaskSection.allCases[indexPath.section]
        let task = tasksBySections[indexPath.section][indexPath.row]

        // Demo flow:
        // Not Started -> In Progress -> For Review -> Prepared -> Approved -> Completed
        // Rejected stays rejected.
        let nextSection: TaskSection?

        switch currentSection {
        case .notStarted: nextSection = .inProgress
        case .inProgress: nextSection = .forReview
        case .forReview: nextSection = .prepared
        case .prepared: nextSection = .approved
        case .approved: nextSection = .completed
        case .rejected: nextSection = nil
        case .completed: nextSection = nil
        }

        guard let moveTo = nextSection else { return }

        Task { await shiftStatus(taskId: task.id, to: moveTo) }
    }
}
