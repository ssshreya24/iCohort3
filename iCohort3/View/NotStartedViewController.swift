//
//  NotStartedViewController.swift
//  iCohort3
//
//  Created by user@56 on 09/11/25.
//

import UIKit

class NotStartedViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    var tasks = [
           ["title": "Task 1", "desc": "Design on-Boarding Flow"],
           ["title": "Not Started", "desc": "Redesign the UI, and try to make it like Apple native"]
       ]
       
       override func viewDidLoad() {
           super.viewDidLoad()
           
           // Register the custom cell
           let nib = UINib(nibName: "TaskCollectionViewCell", bundle: nil)
           collectionView.register(nib, forCellWithReuseIdentifier: "TaskCollectionViewCell")
           
           collectionView.dataSource = self
           collectionView.delegate = self
           collectionView.backgroundColor = .clear
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
               image: UIImage(named: "profile"), // Replace with your asset
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


