import UIKit

enum TaskSectionWrapper {
    case teamProfile
    case category(TaskCategory)
}

class StudentAllTasksViewController: UIViewController {

    @IBOutlet weak var verticalCollectionView: UICollectionView!
    @IBOutlet weak var teamTitleLabel: UILabel!
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    @IBAction func backButtonTapped(_ sender: Any) {
            self.dismiss(animated: true)
        }
    // Add this property to receive team name
    var teamName: String? // ← NEW

    // FINAL LIST OF ALL ROWS
    let items: [TaskSectionWrapper] = [
        .teamProfile,
        .category(.assigned),
        .category(.review),
        .category(.completed),
        .category(.rejected)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // BACK BUTTON
            backButton.layer.cornerRadius = backButton.frame.height / 2
            backButton.backgroundColor = .white
            backButton.clipsToBounds = true

            // PLUS BUTTON
            addButton.layer.cornerRadius = addButton.frame.height / 2
            addButton.backgroundColor = .white
            addButton.clipsToBounds = true
        let bg = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        verticalCollectionView.backgroundColor = bg
        view.backgroundColor = bg

        // Delegates
        verticalCollectionView.delegate = self
        verticalCollectionView.dataSource = self

        // Register Team Profile cell
        verticalCollectionView.register(
            UINib(nibName: "TeamProfileRowCell", bundle: nil),
            forCellWithReuseIdentifier: "TeamProfileRowCell"
        )

        // Register Task Section cell
        verticalCollectionView.register(
            UINib(nibName: "TaskSectionCell", bundle: nil),
            forCellWithReuseIdentifier: "TaskSectionCell"
        )
        if let teamName = teamName {
               teamTitleLabel.text = teamName   // ← HERE
           }

        // Optional: Show team name in navigation or label
        if let teamName = teamName {
            self.title = teamName
        }
    }
}

// MARK: - COLLECTION VIEW
extension StudentAllTasksViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let item = items[indexPath.row]

        switch item {

        case .teamProfile:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TeamProfileRowCell",
                for: indexPath
            ) as! TeamProfileRowCell

            // Dummy data for now
            cell.configureProfiles(
                images: [
                    UIImage(named: "Student") ?? UIImage(),
                    UIImage(named: "Student") ?? UIImage(),
                    UIImage(named: "Student") ?? UIImage()
                ],
                names: ["Shruti", "Ananya", "Rahul"]
            )

            return cell

        case .category(let category):
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "TaskSectionCell",
                for: indexPath
            ) as! TaskSectionCell

            cell.configureSection(type: category)

            cell.seeAllTapped = { [weak self] in
                guard let self = self else { return }

                var tasks: [TaskModel] = []
                switch category {
                case .assigned:
                    tasks = [
                        TaskModel(name: "Shreya", desc: "UI redesign work", date: "03 Nov 2025", remark: nil, remarkDesc: nil),
                        TaskModel(name: "Lakshy", desc: "Fix login flow", date: "05 Nov 2025", remark: nil, remarkDesc: nil)
                    ]
                case .review:
                    tasks = [
                        TaskModel(name: "Shruti", desc: "API integration pending review", date: "10 Nov 2025", remark: nil, remarkDesc: nil),
                        TaskModel(name: "Karan", desc: "Check Figma alignment", date: "11 Nov 2025", remark: nil, remarkDesc: nil),
                        TaskModel(name: "Aaliya", desc: "Verify data mapping", date: "12 Nov 2025", remark: nil, remarkDesc: nil)
                    ]
                case .completed:
                    tasks = [
                        TaskModel(name: "Rahul", desc: "Database migration done", date: "01 Nov 2025", remark: "Remark", remarkDesc: "Excellent work! All changes merged."),
                        TaskModel(name: "Shreya", desc: "Prototype completed", date: "28 Oct 2025", remark: "Remark", remarkDesc: "Meets all UI expectations.")
                    ]
                case .rejected:
                    tasks = [
                        TaskModel(name: "Arjun", desc: "UI not matching design", date: "20 Oct 2025", remark: "Remark", remarkDesc: "Revise entire layout as soon as possible."),
                        TaskModel(name: "Riya", desc: "Incorrect business logic", date: "21 Oct 2025", remark: "Remark", remarkDesc: "Wrong formula applied in calculations.")
                    ]
                }

                let seeAllVC = TaskSeeAllViewController(category: category, tasks: tasks)
                seeAllVC.modalPresentationStyle = .overFullScreen
                seeAllVC.modalTransitionStyle = .coverVertical
                self.present(seeAllVC, animated: true)
            }

            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let item = items[indexPath.row]

        switch item {
        case .teamProfile:
            return CGSize(width: collectionView.frame.width, height: 110)
        case .category(_):
            return CGSize(width: collectionView.frame.width, height: 240)
        }
    }
}

