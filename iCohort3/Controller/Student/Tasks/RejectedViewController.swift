//
//  RejectedViewController.swift
//  iCohort3
//
//  Updated: Tapping a rejected task card prompts the student to move it
//           back to "prepared" so they can redo / resubmit their work.
//

import UIKit

class RejectedViewController: UIViewController, TeamContextReceiver {

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
        label.text = "No rejected tasks yet"
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
        navigationItem.title = "Rejected"
        navigationItem.leftBarButtonItem = StudentTaskScreenUIHelper.makeCloseBarButton(target: self, action: #selector(closeTapped))
        Task { await resolveTeamThenLoad() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let nib = UINib(nibName: "RejectedCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "RejectedCollectionViewCell")
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
            print("❌ RejectedVC team resolve error:", error)
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
                    studentId: studentId, teamId: teamId, status: "rejected")
            } else {
                fetched = try await SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "rejected")
            }
            await MainActor.run {
                self.tasks               = fetched
                self.emptyLabel.isHidden = !fetched.isEmpty
                self.collectionView.reloadData()
            }
        } catch {
            print("❌ RejectedVC load error:", error)
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

    // MARK: - Move Rejected → In Progress

    /// Called when the student taps a rejected card.
    /// Shows a contextual alert explaining the mentor's remark and offering
    /// to move the task back to "In Progress" so they can revise and resubmit their work.
    private func promptResubmit(for task: SupabaseManager.TaskRow) {
        // Build a helpful message that surfaces the mentor's remark if present.
        let remark = task.remark?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty == false
            ? task.remark!
            : "No remark provided by mentor."

        let message = """
        Mentor's feedback:
        "\(remark)"

        Move this task back to In Progress so you can revise it and submit again for review?
        """

        let alert = UIAlertController(
            title:          "Task Rejected",
            message:        message,
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Move to In Progress", style: .default) { [weak self] _ in
            Task { await self?.moveTaskToInProgress(taskId: task.id) }
        })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }

    private func moveTaskToInProgress(taskId: String) async {
        do {
            // 1. Update status in the tasks table
            try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: "ongoing")

            // 2. Keep team-level counters in sync (non-fatal if it fails)
            do {
                try await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(
                    teamId: teamId ?? "", teamNo: teamNo ?? 0)
            } catch {
                print("⚠️ RejectedVC counter sync failed (non-fatal):", error)
            }

            // 3. Reload so the card disappears from this list
            await loadTasksFromSupabase()

            // 4. Brief success toast
            await MainActor.run {
                self.showToast(message: "Task moved to In Progress ✓")
            }

        } catch {
            print("❌ RejectedVC moveTaskToInProgress failed:", error)
            await MainActor.run {
                let err = UIAlertController(title: "Error",
                                            message: error.localizedDescription,
                                            preferredStyle: .alert)
                err.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(err, animated: true)
            }
        }
    }

    // MARK: - Toast Helper

    private func showToast(message: String) {
        let toast = UILabel()
        toast.text                                  = message
        toast.textAlignment                         = .center
        toast.textColor                             = .white
        toast.font                                  = UIFont.systemFont(ofSize: 14, weight: .medium)
        toast.backgroundColor                       = UIColor(red: 0.13, green: 0.67, blue: 0.37, alpha: 1)
        toast.layer.cornerRadius                    = 18
        toast.clipsToBounds                         = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(toast)

        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -48),
            toast.heightAnchor.constraint(equalToConstant: 44)
        ])

        // Give the label generous horizontal padding via an attributed string
        let padded = "   \(message)   "
        toast.text = padded

        UIView.animate(withDuration: 0.3, delay: 1.8, options: .curveEaseOut) {
            toast.alpha = 0
        } completion: { _ in
            toast.removeFromSuperview()
        }
    }

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

extension RejectedViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int { tasks.count }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RejectedCollectionViewCell", for: indexPath
        ) as! RejectedCollectionViewCell

        let task = tasks[indexPath.row]
        cell.configure(
            title:   task.title,
            desc:    task.description ?? "",
            remark:  task.remark,
            image:   UIImage(named: "logo"),
            name:    "Team \(teamNo ?? 0)",
            dueDate: task.assigned_date
        )
        return cell
    }

    // ── Tap → prompt resubmit ──────────────────────────────────────────────
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        guard indexPath.row < tasks.count else { return }
        promptResubmit(for: tasks[indexPath.row])
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width - 40, height: 180)
    }
}
