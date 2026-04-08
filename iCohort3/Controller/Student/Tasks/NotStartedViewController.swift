//
//  NotStartedViewController.swift
//  iCohort3
//
//  Updated: conforms to TeamContextReceiver; self-loads teamId from UserDefaults if not injected
//

import UIKit

final class NotStartedViewController: UIViewController, TeamContextReceiver {

    @IBOutlet weak var collectionView: UICollectionView!

    // MARK: - TeamContextReceiver (injected by SDashboardViewController)
    var teamId: String!
    var teamNo: Int!

    private var tasks: [SupabaseManager.TaskRow] = []
    private var gradientLayer: CAGradientLayer?

    private var currentStudentPersonId: String {
        UserDefaults.standard.string(forKey: "current_person_id") ?? ""
    }

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No tasks have been assigned yet"
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
        setupCollectionView()
        setupEmptyLabel()
        Task { await resolveTeamThenLoad() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Not Started"
        navigationItem.leftBarButtonItem = StudentTaskScreenUIHelper.makeCloseBarButton(target: self, action: #selector(closeTapped))
        Task { await resolveTeamThenLoad() }
    }

    // MARK: - Collection View Setup

    private func setupCollectionView() {
        let nib = UINib(nibName: "TaskCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "TaskCollectionViewCell")
        collectionView.dataSource  = self
        collectionView.delegate    = self
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

    // MARK: - Team Resolution

    /// Ensures teamId is set (from injection or UserDefaults cache) before loading tasks.
    private func resolveTeamThenLoad() async {
        // Case 1: Already injected by the presenter — go straight to load
        if teamId != nil && !teamId.isEmpty {
            await loadAssignedTasksFromSupabase()
            return
        }

        // Case 2: Not injected — try UserDefaults cache
        if let cached = UserDefaults.standard.string(forKey: "current_team_id"), !cached.isEmpty {
            teamId = cached
            teamNo = UserDefaults.standard.integer(forKey: "current_team_number")
            print("ℹ️ NotStartedVC: using cached teamId \(teamId!)")
            await loadAssignedTasksFromSupabase()
            return
        }

        // Case 3: Nothing cached — fetch from Supabase using person_id
        let personId = currentStudentPersonId
        guard !personId.isEmpty else {
            print("❌ NotStartedVC: no person_id, cannot resolve team")
            await showEmptyState()
            return
        }

        do {
            if let info = try await SupabaseManager.shared.fetchTeamInfoForStudent(personId: personId) {
                // Cache for future use
                UserDefaults.standard.set(info.teamId,     forKey: "current_team_id")
                UserDefaults.standard.set(info.teamNumber, forKey: "current_team_number")
                teamId = info.teamId
                teamNo = info.teamNumber
                print("✅ NotStartedVC: resolved teamId \(teamId!) from Supabase")
                await loadAssignedTasksFromSupabase()
            } else {
                print("⚠️ NotStartedVC: student has no active team")
                await showEmptyState()
            }
        } catch {
            print("❌ NotStartedVC: team resolution error:", error)
            await showEmptyState()
        }
    }

    // MARK: - Load Tasks

    private func loadAssignedTasksFromSupabase() async {
        guard let teamId = teamId, !teamId.isEmpty else {
            print("⚠️ NotStartedVC: teamId is nil — aborting load")
            await showEmptyState()
            return
        }

        let studentId = currentStudentPersonId
        print("🔍 Loading assigned tasks | student: \(studentId) | team: \(teamId)")

        do {
            let fetched: [SupabaseManager.TaskRow]

            if !studentId.isEmpty {
                fetched = try await SupabaseManager.shared
                    .fetchTasksForStudentInTeam(
                        studentId: studentId,
                        teamId:    teamId,
                        status:    "assigned"
                    )
            } else {
                print("⚠️ No student person_id — falling back to all team tasks")
                fetched = try await SupabaseManager.shared
                    .fetchTasksForTeam(teamId: teamId, status: "assigned")
            }

            print("✅ Loaded \(fetched.count) assigned tasks")

            await MainActor.run {
                self.tasks              = fetched
                self.emptyLabel.isHidden = !fetched.isEmpty
                self.collectionView.reloadData()
            }

        } catch {
            print("❌ Failed to load assigned tasks:", error)
            await showEmptyState()
        }
    }

    private func showEmptyState() async {
        await MainActor.run {
            self.tasks              = []
            self.emptyLabel.isHidden = false
            self.collectionView.reloadData()
        }
    }

    // MARK: - Move Task to In Progress

    private func moveTaskToInProgress(taskId: String) async {
        do {
            _ = try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: "ongoing")
            if let tid = teamId, !tid.isEmpty {
                try? await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: tid)
            }
            await loadAssignedTasksFromSupabase()
        } catch {
            print("❌ Failed to move task:", error)
        }
    }

    private func moveTaskFromIndex(_ index: Int) {
        guard index < tasks.count else { return }
        let task = tasks[index]

        let alert = UIAlertController(title: "Move to In Progress?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Move", style: .destructive) { _ in
            Task { await self.moveTaskToInProgress(taskId: task.id) }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - UI Setup

    private func applyBackgroundGradient() {
        AppTheme.applyScreenBackground(to: view)
        gradientLayer = view.layer.sublayers?.first(where: { $0.name == "AppThemeGradientLayer" }) as? CAGradientLayer
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource & DelegateFlowLayout

extension NotStartedViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int { tasks.count }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TaskCollectionViewCell", for: indexPath
        ) as! TaskCollectionViewCell

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
        cell.circleButton.addTarget(self, action: #selector(moveButtonTapped(_:)), for: .touchUpInside)

        cell.gestureRecognizers?.forEach { cell.removeGestureRecognizer($0) }
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        cell.tag = indexPath.row
        cell.addGestureRecognizer(tap)

        return cell
    }

    @objc private func moveButtonTapped(_ sender: UIButton) { moveTaskFromIndex(sender.tag) }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        if let cell = gesture.view { moveTaskFromIndex(cell.tag) }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        UIEdgeInsets(top: 8, left: 20, bottom: 16, right: 20)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { 16 }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        StudentTaskScreenUIHelper.cardSize(in: collectionView, traitCollection: traitCollection, height: 160)
    }
}
