//
//  NotStartedViewController.swift
//  iCohort3
//
//  Created by user@56 on 09/11/25.
//

import UIKit

class NotStartedViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var tasks: [[String: String]] = [] // Start empty

        // Label for empty state
        var emptyLabel: UILabel = {
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
            
            applyBackgroundGradient()
            // Add empty label
            view.addSubview(emptyLabel)
            NSLayoutConstraint.activate([
                emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            
            // Register the custom cell
            let nib = UINib(nibName: "TaskCollectionViewCell", bundle: nil)
            collectionView.register(nib, forCellWithReuseIdentifier: "TaskCollectionViewCell")
            
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.backgroundColor = .clear
            
            // Show task after 6 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.loadTasks()
            }
        }
    private func applyBackgroundGradient() {
                let g = CAGradientLayer()
                g.frame = view.bounds
                g.colors = [
                    UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1).cgColor, // top blue
                    UIColor(white: 0.95, alpha: 1).cgColor // bottom light gray
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
            // Add your task
            self.tasks = [
                ["title": "Task 1", "desc": "Design on-Boarding Flow"]
            ]
            
            // Hide empty label
            self.emptyLabel.isHidden = true
            
            // Reload collection view
            self.collectionView.reloadData()
        }
    }

    extension NotStartedViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
        
        func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
            return tasks.count
        }
        
        func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TaskCollectionViewCell", for: indexPath) as! TaskCollectionViewCell
            let task = tasks[indexPath.row]
            
            cell.configure(
                title: task["title"] ?? "",
                desc: task["desc"] ?? "",
                image: UIImage(named: "logo"),
                name: "Shreya"
            )
            
            // Circle button click
            cell.circleButton.tag = indexPath.row
            cell.circleButton.addTarget(self, action: #selector(moveTask(_:)), for: .touchUpInside)
            
            return cell
        }
        
        func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
            return CGSize(width: collectionView.frame.width - 40, height: 160)
        }
        
        @objc func moveTask(_ sender: UIButton) {
            let index = sender.tag
            let alert = UIAlertController(title: "Move to In Progress?", message: nil, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Move", style: .destructive, handler: { _ in
                self.tasks.remove(at: index)
                self.collectionView.reloadData()
                
                // Show empty label if no tasks left
                if self.tasks.isEmpty {
                    self.emptyLabel.isHidden = false
                }
            }))
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            present(alert, animated: true)
        }
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


