//
//  ApprovedViewController.swift
//  iCohort3
//
//  Updated: TeamContextReceiver conformance + Supabase data loading
//

import UIKit

class ApprovedViewController: UIViewController, TeamContextReceiver {

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
        label.text = "No approved tasks yet"
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
        setupEmptyLabel()
        setupCollectionView()
        Task { await resolveTeamThenLoad() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Approved"
        navigationItem.leftBarButtonItem = StudentTaskScreenUIHelper.makeCloseBarButton(target: self, action: #selector(closeTapped))
        Task { await resolveTeamThenLoad() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let nib = UINib(nibName: "ApprovedCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "ApprovedCollectionViewCell")
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

    private func resolveTeamThenLoad() async {
        if teamId != nil && !teamId.isEmpty {
            await loadTasksFromSupabase(); return
        }
        if let cached = UserDefaults.standard.string(forKey: "current_team_id"), !cached.isEmpty {
            teamId = cached
            teamNo = UserDefaults.standard.integer(forKey: "current_team_number")
            await loadTasksFromSupabase(); return
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
            } else { await showEmptyState() }
        } catch {
            print("❌ ApprovedVC team resolve error:", error)
            await showEmptyState()
        }
    }

    // MARK: - Load Tasks

    private func loadTasksFromSupabase() async {
        guard let teamId = teamId, !teamId.isEmpty else { await showEmptyState(); return }
        let studentId = currentStudentPersonId
        do {
            let fetched: [SupabaseManager.TaskRow]
            if !studentId.isEmpty {
                fetched = try await SupabaseManager.shared.fetchTasksForStudentInTeam(
                    studentId: studentId, teamId: teamId, status: "approved")
            } else {
                fetched = try await SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "approved")
            }
            await MainActor.run {
                self.tasks              = fetched
                self.emptyLabel.isHidden = !fetched.isEmpty
                self.collectionView.reloadData()
            }
        } catch {
            print("❌ ApprovedVC load error:", error)
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

    // MARK: - Move Approved Task Forward

    private func promptNextStep(for task: SupabaseManager.TaskRow) {
        let alert = UIAlertController(
            title: "Choose Next Step",
            message: nil,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Move to Prepared", style: .default) { [weak self] _ in
            Task { await self?.moveApprovedTask(taskId: task.id, to: "prepared") }
        })

        alert.addAction(UIAlertAction(title: "Move to Completed", style: .default) { [weak self] _ in
            Task { await self?.moveApprovedTask(taskId: task.id, to: "completed") }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func moveApprovedTask(taskId: String, to status: String) async {
        do {
            _ = try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: status)
            if let teamId, !teamId.isEmpty {
                try? await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamId, teamNo: teamNo)
            }
            await loadTasksFromSupabase()
        } catch {
            print("❌ ApprovedVC moveApprovedTask error:", error)
            await MainActor.run {
                let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            }
        }
    }

    // MARK: - UI Setup

    private func applyBackgroundGradient() {
        AppTheme.applyScreenBackground(to: view)
        gradientLayer = view.layer.sublayers?.first(where: { $0.name == "AppThemeGradientLayer" }) as? CAGradientLayer
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource & DelegateFlowLayout

extension ApprovedViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int { tasks.count }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ApprovedCollectionViewCell", for: indexPath
        ) as! ApprovedCollectionViewCell

        let task = tasks[indexPath.row]
        cell.configure(
            title:  task.title,
            desc:   task.description ?? "",
            remark: task.remark,
            image:  UIImage(named: "logo"),
            name:   "Team \(teamNo ?? 0)",
            dueDate: task.assigned_date
        )
        cell.circleButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.circleButton.tag = indexPath.row
        cell.circleButton.addTarget(self, action: #selector(showApprovedNextStep(_:)), for: .touchUpInside)
        return cell
    }

    @objc private func showApprovedNextStep(_ sender: UIButton) {
        guard sender.tag < tasks.count else { return }
        promptNextStep(for: tasks[sender.tag])
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width - 40, height: 180)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < tasks.count else { return }
        promptNextStep(for: tasks[indexPath.item])
    }
}
