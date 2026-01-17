//
//  InProgressViewController.swift
//  iCohort3
//

import UIKit

struct DashboardTask {
    let title: String
    let dueDate: String
    let assigneeName: String
    let assigneeImage: UIImage?
    let attachmentNames: [String]
}

final class InProgressViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    var teamId: String = "2e64ae77-8e03-43af-90f1-341838ebbd8a"
    var teamNo: Int = 9

    private var tasks: [SupabaseManager.TaskRow] = []

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No tasks in progress"
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

        let nib = UINib(nibName: "InProgressCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "InProgressCollectionViewCell")

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear

        Task { await loadOngoingTasksFromSupabase() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await loadOngoingTasksFromSupabase() }
    }

    // MARK: - Fetch

    private func loadOngoingTasksFromSupabase() async {
        do {
            let fetched = try await SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "ongoing")

            await MainActor.run {
                self.tasks = fetched
                self.emptyLabel.isHidden = !fetched.isEmpty
                self.collectionView.isHidden = fetched.isEmpty
                self.collectionView.reloadData()
            }
        } catch {
            print("❌ Failed to load ongoing tasks:", error)
            await MainActor.run {
                self.tasks = []
                self.emptyLabel.isHidden = false
                self.collectionView.isHidden = true
                self.collectionView.reloadData()
            }
        }
    }

    // MARK: - Submit to For Review

    private func submitTaskToForReview(taskId: String) async {
        do {
            let updated = try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: "for_review")
            print("✅ Task status updated:", updated.id, updated.status)

            // ✅ Counter update should NOT block the main status update
            do {
                try await SupabaseManager.shared.moveTeamTaskCounter(teamId: teamId, from: "ongoing", to: "for_review")
                print("✅ team_task counters updated")
            } catch {
                print("⚠️ Counter update failed (but status changed):", error)
            }

            await loadOngoingTasksFromSupabase()

        } catch {
            print("❌ Status update failed:", error)
        }
    }


    // MARK: - OPEN TASK DETAIL

    private func openTaskDetail(for task: SupabaseManager.TaskRow) {
        let vc = TaskDetailViewController(nibName: "TaskDetailViewController", bundle: nil)

        let model = DashboardTask(
            title: task.title,
            dueDate: formatDate(task.assigned_date),
            assigneeName: "Team \(teamNo)",
            assigneeImage: nil,
            attachmentNames: []
        )

        vc.task = model
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }

    private func formatDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = iso.date(from: isoString) {
            let df = DateFormatter()
            df.dateFormat = "dd MMM yyyy"
            return df.string(from: date)
        }

        let iso2 = ISO8601DateFormatter()
        iso2.formatOptions = [.withInternetDateTime]
        if let date2 = iso2.date(from: isoString) {
            let df = DateFormatter()
            df.dateFormat = "dd MMM yyyy"
            return df.string(from: date2)
        }

        return isoString
    }

    // MARK: - BACK BUTTON

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
}

// MARK: - COLLECTION VIEW

extension InProgressViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tasks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "InProgressCollectionViewCell",
            for: indexPath
        ) as! InProgressCollectionViewCell

        let task = tasks[indexPath.row]

        cell.configure(
            title: task.title,
            desc: task.description ?? "",
            image: UIImage(named: "logo"),
            name: "Team \(teamNo)"
        )

        // prevent stacking targets due to cell reuse
        cell.circleButton.removeTarget(nil, action: nil, for: .allEvents)
        cell.circleButton.tag = indexPath.row
        cell.circleButton.addTarget(self, action: #selector(submitTask(_:)), for: .touchUpInside)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        openTaskDetail(for: tasks[indexPath.row])
    }

    @objc private func submitTask(_ sender: UIButton) {
        let index = sender.tag
        guard index < tasks.count else { return }

        let taskId = tasks[index].id

        let alert = UIAlertController(title: "Submit for Review?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Submit", style: .default, handler: { _ in
            Task { await self.submitTaskToForReview(taskId: taskId) }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width - 40, height: 160)
    }
}
