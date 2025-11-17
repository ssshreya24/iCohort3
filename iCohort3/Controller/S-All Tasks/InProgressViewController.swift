//
//  InProgressViewController.swift
//  iCohort3
//
//  Created by user@56 on 12/11/25.
//

import UIKit

class InProgressViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var tasks: [[String: String]] = []

    // Empty state label
    private var emptyLabel: UILabel = {
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

        // Register custom cell
        let nib = UINib(nibName: "InProgressCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "InProgressCollectionViewCell")

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear

        // Simulate loading tasks after 2 sec
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.loadTasks()
        }
    }
    
    private func openTaskDetail(for task: [String: String]) {

        // Load the XIB
        let vc = TaskDetailViewController(nibName: "TaskDetailViewController", bundle: nil)

        // SAMPLE DATA (change as needed)
        let model = Task(
            title: task["title"] ?? "",
            dueDate: "25 Sep 2025",
            assigneeName: "Shreya",
            assigneeImage: nil,
            attachmentNames: ["UIFlow.pdf", "Design.png"]
        )

        // Set before presenting (safe way)
        vc.task = model

        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
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
        self.dismiss(animated: true, completion: nil)
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

    private func loadTasks() {
        // Example tasks
        self.tasks = [
            ["title": "Task A", "desc": "Work on Home Page UI"],
            ["title": "Task B", "desc": "API Integration for Dashboard"]
        ]
        self.emptyLabel.isHidden = true
        self.collectionView.reloadData()
    }
}

// MARK: - Collection View Setup
extension InProgressViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tasks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "InProgressCollectionViewCell", for: indexPath) as! InProgressCollectionViewCell
        let task = tasks[indexPath.row]

        cell.configure(
            title: task["title"] ?? "",
            desc: task["desc"] ?? "",
            image: UIImage(named: "logo"),
            name: "Shreya"
        )

        // Button setup
        cell.circleButton.tag = indexPath.row
        cell.circleButton.addTarget(self, action: #selector(submitTask(_:)), for: .touchUpInside)

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 40, height: 160)
    }

    @objc private func submitTask(_ sender: UIButton) {
        let index = sender.tag
        let selectedTask = tasks[index]

        // Directly open the upload screen
        openTaskDetail(for: selectedTask)
    }

}
