//
//  ForReviewViewController.swift
//  iCohort3
//
//  Updated: TeamContextReceiver conformance + Supabase data loading
//

import UIKit

class ForReviewViewController: UIViewController, TeamContextReceiver {

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
        label.text = "No tasks for review yet"
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
        setupBackButton()
        applyBackgroundGradient()
        setupEmptyLabel()
        setupCollectionView()
        Task { await resolveTeamThenLoad() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await resolveTeamThenLoad() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer?.frame = view.bounds
    }

    // MARK: - Setup

    private func setupCollectionView() {
        let nib = UINib(nibName: "TaskCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "TaskCollectionViewCell")
        collectionView.dataSource  = self
        collectionView.delegate    = self
        collectionView.backgroundColor = .clear
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
            print("❌ ForReviewVC team resolve error:", error)
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
                    studentId: studentId, teamId: teamId, status: "for_review")
            } else {
                fetched = try await SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "for_review")
            }
            await MainActor.run {
                self.tasks              = fetched
                self.emptyLabel.isHidden = !fetched.isEmpty
                self.collectionView.reloadData()
            }
        } catch {
            print("❌ ForReviewVC load error:", error)
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

    // MARK: - UI Setup

    private func setupBackButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.backgroundColor    = UIColor(white: 1.0, alpha: 0.8)
        btn.layer.cornerRadius = 22
        let cfg = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        btn.setImage(UIImage(systemName: "chevron.left", withConfiguration: cfg), for: .normal)
        btn.tintColor = .black
        btn.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            btn.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            btn.widthAnchor.constraint(equalToConstant: 44),
            btn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func backButtonTapped() {
        if let nav = navigationController { nav.popViewController(animated: true) }
        else { dismiss(animated: true) }
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
}

// MARK: - UICollectionViewDataSource & DelegateFlowLayout

extension ForReviewViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

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
        cell.circleButton.isUserInteractionEnabled = false
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width - 40, height: 160)
    }
}
