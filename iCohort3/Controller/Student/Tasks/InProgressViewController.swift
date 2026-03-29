//
//  InProgressViewController.swift
//  iCohort3
//
//  Updated: TeamContextReceiver conformance, resolves teamId from UserDefaults if not injected.
//  NOTE: DashboardTask struct has been moved to DashboardTask.swift (shared model file).
//

import UIKit

final class InProgressViewController: UIViewController, TeamContextReceiver {

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - TeamContextReceiver
    var teamId: String!
    var teamNo: Int!

    private var tasks: [SupabaseManager.TaskRow] = []
    private var gradientLayer: CAGradientLayer?

    private var currentStudentPersonId: String {
        UserDefaults.standard.string(forKey: "current_person_id") ?? ""
    }

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No tasks in progress"
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
        applyBackgroundGradient()
        StudentTaskScreenUIHelper.removeLegacyHeader(from: view, collectionView: collectionView)
        setupEmptyLabel()
        setupCollectionView()
        Task { await resolveTeamThenLoad() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "In Progress"
        navigationItem.leftBarButtonItem = StudentTaskScreenUIHelper.makeCloseBarButton(target: self, action: #selector(closeTapped))
        Task { await resolveTeamThenLoad() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let nib = UINib(nibName: "InProgressCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "InProgressCollectionViewCell")
        collectionView.dataSource      = self
        collectionView.delegate        = self
        collectionView.backgroundColor = .clear
        collectionView.alwaysBounceVertical = true
        collectionView.contentInsetAdjustmentBehavior = .automatic
    }

    private func setupEmptyLabel() {
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    // MARK: - Team Resolution (injected → UserDefaults → Supabase)

    private func resolveTeamThenLoad() async {
        if teamId != nil && !teamId.isEmpty {
            await loadTasksFromSupabase()
            return
        }
        if let cached = UserDefaults.standard.string(forKey: "current_team_id"), !cached.isEmpty {
            teamId = cached
            teamNo = UserDefaults.standard.integer(forKey: "current_team_number")
            await loadTasksFromSupabase()
            return
        }
        let personId = currentStudentPersonId
        guard !personId.isEmpty else { await showEmptyState(); return }
        do {
            if let info = try await SupabaseManager.shared.fetchTeamInfoForStudent(personId: personId) {
                UserDefaults.standard.set(info.teamId,     forKey: "current_team_id")
                UserDefaults.standard.set(info.teamNumber, forKey: "current_team_number")
                teamId = info.teamId
                teamNo = info.teamNumber
                await loadTasksFromSupabase()
            } else {
                await showEmptyState()
            }
        } catch {
            print("❌ InProgressVC team resolve error:", error)
            await showEmptyState()
        }
    }

    // MARK: - Load Tasks

    private func loadTasksFromSupabase() async {
        guard let tid = teamId, !tid.isEmpty else { await showEmptyState(); return }
        let studentId = currentStudentPersonId
        do {
            let fetched: [SupabaseManager.TaskRow]
            if !studentId.isEmpty {
                fetched = try await SupabaseManager.shared.fetchTasksForStudentInTeam(
                    studentId: studentId, teamId: tid, status: "ongoing")
            } else {
                fetched = try await SupabaseManager.shared.fetchTasksForTeam(teamId: tid, status: "ongoing")
            }
            await MainActor.run {
                self.tasks               = fetched
                self.emptyLabel.isHidden = !fetched.isEmpty
                self.collectionView.reloadData()
            }
        } catch {
            print("❌ InProgressVC load error:", error)
            await showEmptyState()
        }
    }

    private func showEmptyState() async {
        await MainActor.run {
            self.tasks               = []
            self.emptyLabel.isHidden = false
            self.collectionView.reloadData()
        }
    }

    // MARK: - Submit to For Review

    private func submitTaskToForReview(taskId: String) async {
        do {
            try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: "for_review")
            do {
                if let tid = teamId, !tid.isEmpty {
                    try await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: tid)
                }
            } catch {
                print("⚠️ Counter update failed:", error)
            }
            await loadTasksFromSupabase()
        } catch {
            print("❌ Status update failed:", error)
        }
    }

    // MARK: - Task Detail

    private func openTaskDetail(for task: SupabaseManager.TaskRow) {
        let vc = TaskDetailViewController(nibName: "TaskDetailViewController", bundle: nil)

        // Explicit type annotation on assigneeImage: UIImage? avoids
        // the "'nil' requires a contextual type" compiler error.
        let assigneeImage: UIImage? = nil
        var model = DashboardTask(
            title:           task.title,
            dueDate:         formatDate(task.assigned_date),
            assigneeName:    "Team \(teamNo ?? 0)",
            assigneeImage:   assigneeImage,
            attachmentNames: [],
            status:          task.status,
            remark:          task.remark
        )
        // ✅ Pass Supabase IDs so TaskDetailVC can fetch live mentor/assignee data
        model.taskId   = task.id
        model.teamId   = task.team_id
        model.mentorId = task.mentor_id

        vc.task = model
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    private func formatDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = iso.date(from: isoString) {
            let df = DateFormatter(); df.dateFormat = "dd MMM yyyy"
            return df.string(from: date)
        }
        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]
        if let date = iso2.date(from: isoString) {
            let df = DateFormatter(); df.dateFormat = "dd MMM yyyy"
            return df.string(from: date)
        }
        return isoString
    }

    // MARK: - UI Helpers

    private func applyBackgroundGradient() {
        let g = CAGradientLayer()
        g.colors = [
            UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1).cgColor,
            UIColor(white: 0.95, alpha: 1).cgColor
        ]
        g.startPoint = CGPoint(x: 0.5, y: 0)
        g.endPoint   = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(g, at: 0)
        gradientLayer = g
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource & DelegateFlowLayout

extension InProgressViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int { tasks.count }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "InProgressCollectionViewCell", for: indexPath
        ) as! InProgressCollectionViewCell

        let task = tasks[indexPath.row]
        cell.configure(
            title: task.title,
            desc:  task.description ?? "",
            image: UIImage(named: "logo"),
            name:  "Team \(teamNo ?? 0)",
            dueDate: task.assigned_date
        )
        cell.circleButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.circleButton.tag = indexPath.row
        cell.circleButton.addTarget(self, action: #selector(submitTask(_:)), for: .touchUpInside)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        openTaskDetail(for: tasks[indexPath.row])
    }

    @objc private func submitTask(_ sender: UIButton) {
        guard sender.tag < tasks.count else { return }
        let taskId = tasks[sender.tag].id
        let alert = UIAlertController(title: "Submit for Review?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Submit", style: .default) { _ in
            Task { await self.submitTaskToForReview(taskId: taskId) }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width - 40, height: 160)
    }
}
