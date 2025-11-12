//
//  ForReviewViewController.swift
//  iCohort3
//
//  Created by user@56 on 12/11/25.
//

//
//  ForReviewViewController.swift
//  iCohort3
//
//  Created by user@56 on 12/11/25.
//

import UIKit

class ForReviewViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var tasks: [[String: String]] = []

    // Label for empty state
    var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "No tasks for review yet"
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
        
        // Add empty label
        view.addSubview(emptyLabel)
        NSLayoutConstraint.activate([
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Register custom cell
        let nib = UINib(nibName: "ForReviewCollectionViewCell", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "ForReviewCollectionViewCell")
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        
        // Load sample task after delay (just like before)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.loadTasks()
        }
    }

    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        backButton.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        backButton.layer.cornerRadius = 22 // half of 44
        
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

    func loadTasks() {
        self.tasks = [
            ["title": "Task 1", "desc": "Review the updated design flow"]
        ]
        self.emptyLabel.isHidden = true
        self.collectionView.reloadData()
    }
}

// MARK: - Collection View
extension ForReviewViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tasks.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ForReviewCollectionViewCell", for: indexPath) as! ForReviewCollectionViewCell
        let task = tasks[indexPath.row]
        
        cell.configure(
            title: task["title"] ?? "",
            desc: task["desc"] ?? "",
            image: UIImage(named: "logo"),
            name: "Shreya"
        )
        
        // No tap functionality for circle button — just for show
        cell.circleButton.isUserInteractionEnabled = false
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frame.width - 40, height: 160)
    }
}
