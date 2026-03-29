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
        navigationItem.title = "Approved"
        navigationItem.leftBarButtonItem = StudentTaskScreenUIHelper.makeCloseBarButton(target: self, action: #selector(closeTapped))
        Task { await resolveTeamThenLoad() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
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
        let sheet = UIAlertController(
            title: "Choose Next Step",
            message: "This task was accepted. What should happen next?",
            preferredStyle: .actionSheet
        )

        sheet.addAction(UIAlertAction(title: "Move to Prepared", style: .default) { [weak self] _ in
            Task { await self?.moveApprovedTask(taskId: task.id, to: "prepared") }
        })

        sheet.addAction(UIAlertAction(title: "Move to Completed", style: .default) { [weak self] _ in
            Task { await self?.moveApprovedTask(taskId: task.id, to: "completed") }
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = collectionView
            popover.sourceRect = CGRect(x: collectionView.bounds.midX, y: collectionView.bounds.midY, width: 1, height: 1)
        }

        present(sheet, animated: true)
    }

    private func moveApprovedTask(taskId: String, to status: String) async {
        do {
            try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: status)
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
        return cell
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
