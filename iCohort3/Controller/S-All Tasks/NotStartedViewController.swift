//
//  NotStartedViewController.swift
//  iCohort3
//

import UIKit

final class NotStartedViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!

    // ✅ TEMP: later you will pass these from previous screen
    var teamId: String = "2e64ae77-8e03-43af-90f1-341838ebbd8a"
    var teamNo: Int = 9

    // ✅ Real tasks from Supabase
    private var tasks: [SupabaseManager.TaskRow] = []

    // Label for empty state
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No tasks have been assigned yet"
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

        let nib = UINib(nibName: "TaskCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "TaskCollectionViewCell")

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear

        Task { await loadAssignedTasksFromSupabase() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await loadAssignedTasksFromSupabase() }
    }

    private func loadAssignedTasksFromSupabase() async {
        do {
            // ✅ “Not Started” = status 'assigned'
            let fetched = try await SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "assigned")

            await MainActor.run {
                self.tasks = fetched
                self.emptyLabel.isHidden = !fetched.isEmpty
                self.collectionView.reloadData()
            }

        } catch {
            print("❌ Failed to load assigned tasks:", error)
            await MainActor.run {
                self.tasks = []
                self.emptyLabel.isHidden = false
                self.collectionView.reloadData()
            }
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
        backButton.tintColor = UIColor.black

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

    // MARK: - Move assigned -> ongoing (updates tasks table; trigger updates team_task)

    private func moveTaskToInProgress(taskId: String) async {
        do {
            try await SupabaseManager.shared.updateTaskStatus(taskId: taskId, status: "ongoing")
            await loadAssignedTasksFromSupabase()
        } catch {
            print("❌ Failed to move task:", error)
        }
    }

    // Unified move function for both card tap & button
    private func moveTaskFromIndex(_ index: Int) {
        guard index < tasks.count else { return }
        let task = tasks[index]

        let alert = UIAlertController(title: "Move to In Progress?", message: nil, preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Move", style: .destructive, handler: { _ in
            Task { await self.moveTaskToInProgress(taskId: task.id) }
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - Collection View

extension NotStartedViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        tasks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TaskCollectionViewCell",
            for: indexPath
        ) as! TaskCollectionViewCell

        let task = tasks[indexPath.row]

        cell.configure(
            title: task.title,
            desc: task.description ?? "",
            image: UIImage(named: "logo"),
            name: "Team \(teamNo)"
        )

        // Button click
        cell.circleButton.tag = indexPath.row
        cell.circleButton.addTarget(self, action: #selector(moveButtonTapped(_:)), for: .touchUpInside)

        // Card tap gesture
        cell.tag = indexPath.row
        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        cell.addGestureRecognizer(tap)
        cell.isUserInteractionEnabled = true

        return cell
    }

    @objc private func moveButtonTapped(_ sender: UIButton) {
        moveTaskFromIndex(sender.tag)
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let cell = gesture.view else { return }
        moveTaskFromIndex(cell.tag)
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width - 40, height: 160)
    }
}
