//
//  AllTasksViewController.swift
//  iCohort3
//

import UIKit

final class AllTasksViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    private var teamId: String = ""
    private var teamNo: Int = 0

    private var gradientLayer: CAGradientLayer?

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

        static func section(forStatus status: String) -> TaskSection? {
            let s = status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            switch s {
            case "assigned": return .notStarted
            case "ongoing": return .inProgress
            case "for_review": return .forReview
            case "prepared": return .prepared
            case "approved": return .approved
            case "rejected": return .rejected
            case "completed": return .completed
            default: return nil
            }
        }
    }

    private var tasksBySections: [[SupabaseManager.TaskRow]] = Array(
        repeating: [],
        count: TaskSection.allCases.count
    )

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

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackButton()
        applyBackgroundGradient()
        setupEmptyLabel()
        registerCells()
        setupCollectionView()

        Task { await bootstrapAndLoad() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear

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
        for cellName in cellNames {
            collectionView.register(UINib(nibName: cellName, bundle: nil), forCellWithReuseIdentifier: cellName)
        }
    }

    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        backButton.layer.cornerRadius = 22

        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
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
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    private func applyBackgroundGradient() {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1).cgColor,
            UIColor(white: 0.95, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(g, at: 0)
        gradientLayer = g
    }

    private func setEmptyState(_ message: String?) {
        emptyLabel.text = message ?? "No tasks available"
        emptyLabel.isHidden = (message == nil)
    }

    private func resetUIWithEmpty(_ message: String) async {
        await MainActor.run {
            self.setEmptyState(message)
            self.tasksBySections = Array(repeating: [], count: TaskSection.allCases.count)
            self.collectionView.reloadData()
        }
    }

    private func bootstrapAndLoad() async {
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

            teamId = myTeam.id
            teamNo = myTeam.teamNo

            try await SupabaseManager.shared.ensureTeamTaskRow(teamId: teamId, teamNo: teamNo)
            try await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamId, teamNo: teamNo)

            await loadAllTasksFromSupabase()
        } catch {
            print("❌ bootstrapAndLoad failed:", error)
            await resetUIWithEmpty("Failed to load")
        }
    }

    private func loadAllTasksFromSupabase() async {
        guard !teamId.isEmpty else {
            print("⚠️ teamId is empty, cannot load tasks.")
            return
        }

        do {
            async let assignedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: TaskSection.notStarted.dbStatus)
            async let ongoingRows   = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: TaskSection.inProgress.dbStatus)
            async let reviewRows    = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: TaskSection.forReview.dbStatus)
            async let preparedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: TaskSection.prepared.dbStatus)
            async let approvedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: TaskSection.approved.dbStatus)
            async let rejectedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: TaskSection.rejected.dbStatus)
            async let completedRows = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: TaskSection.completed.dbStatus)

            let (assigned, ongoing, review, prepared, approved, rejected, completed) = try await (
                assignedRows, ongoingRows, reviewRows, preparedRows, approvedRows, rejectedRows, completedRows
            )

            var buckets = Array(repeating: [SupabaseManager.TaskRow](), count: TaskSection.allCases.count)
            buckets[TaskSection.notStarted.rawValue] = assigned
            buckets[TaskSection.inProgress.rawValue] = ongoing
            buckets[TaskSection.forReview.rawValue]  = review
            buckets[TaskSection.prepared.rawValue]   = prepared
            buckets[TaskSection.approved.rawValue]   = approved
            buckets[TaskSection.rejected.rawValue]   = rejected
            buckets[TaskSection.completed.rawValue]  = completed

            let totalCount = buckets.reduce(0) { $0 + $1.count }

            await MainActor.run {
                self.tasksBySections = buckets
                self.setEmptyState(totalCount == 0 ? "No tasks available" : nil)
                self.collectionView.reloadData()
            }
        } catch {
            print("❌ Failed to load tasks:", error)
            await resetUIWithEmpty("Failed to load tasks")
        }
    }

    private func shiftStatus(taskId: String, to newSection: TaskSection) async {
        do {
            try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: newSection.dbStatus)
            try await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamId, teamNo: teamNo)
            await loadAllTasksFromSupabase()
        } catch {
            print("❌ Failed to shift status:", error)
        }
    }

    private func nextSection(for current: TaskSection) -> TaskSection? {
        switch current {
        case .notStarted: return .inProgress
        case .inProgress: return .forReview
        case .forReview:  return .prepared
        case .prepared:   return .approved
        case .approved:   return .completed
        case .rejected:   return nil
        case .completed:  return nil
        }
    }
}

extension AllTasksViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        TaskSection.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard section < tasksBySections.count else { return 0 }
        return tasksBySections[section].count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let sectionEnum = TaskSection.allCases[indexPath.section]
        let task = tasksBySections[indexPath.section][indexPath.row]
        let id = sectionEnum.cellIdentifier

        switch sectionEnum {

        case .approved:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! ApprovedCollectionViewCell
            cell.configure(title: task.title,
                           desc: task.description ?? "",
                           remark: task.remark,
                           image: UIImage(named: "logo"),
                           name: "Team \(teamNo)")
            return cell

        case .rejected:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! RejectedCollectionViewCell
            cell.configure(title: task.title,
                           desc: task.description ?? "",
                           remark: task.remark,
                           image: UIImage(named: "logo"),
                           name: "Team \(teamNo)")
            return cell

        case .inProgress:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! InProgressCollectionViewCell
            cell.configure(title: task.title,
                           desc: task.description ?? "",
                           image: UIImage(named: "logo"),
                           name: "Team \(teamNo)")
            return cell

        case .prepared:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! PreparedCollectionViewCell
            cell.configure(title: task.title,
                           desc: task.description ?? "",
                           image: UIImage(named: "logo"),
                           name: "Team \(teamNo)")
            return cell

        case .completed:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! CompletedCollectionViewCell
            cell.configure(title: task.title,
                           desc: task.description ?? "",
                           image: UIImage(named: "logo"),
                           name: "Team \(teamNo)")
            return cell

        default:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: id, for: indexPath) as! TaskCollectionViewCell
            cell.configure(title: task.title,
                           desc: task.description ?? "",
                           image: UIImage(named: "logo"),
                           name: "Team \(teamNo)")
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: "TaskSectionHeader",
            for: indexPath
        ) as! TaskSectionHeaderView

        header.titleLabel.text = TaskSection.allCases[indexPath.section].title
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

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currentSection = TaskSection.allCases[indexPath.section]
        let task = tasksBySections[indexPath.section][indexPath.row]

        guard let moveTo = nextSection(for: currentSection) else { return }
        Task { await shiftStatus(taskId: task.id, to: moveTo) }
    }
}
import Foundation

extension Array {
    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
        var results: [T] = []
        results.reserveCapacity(count)
        for element in self {
            let value = await transform(element)
            results.append(value)
        }
        return results
    }
}
