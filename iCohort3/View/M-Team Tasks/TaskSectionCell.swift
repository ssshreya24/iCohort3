import UIKit

enum TaskCategory {
    case assigned
    case review
    case completed
    case rejected
}

struct TaskModel {
    let name: String
    let desc: String
    let date: String
    let remark: String?        // For completed / rejected
    let remarkDesc: String?    // For completed / rejected
}

class TaskSectionCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var horizontalCollectionView: UICollectionView!
    // Closure to notify parent VC
    var seeAllTapped: (() -> Void)?
    @IBAction func seeAllButtonPressed(_ sender: UIButton) {
        seeAllTapped?()
    }


    private var category: TaskCategory = .assigned
    private var dummyData: [TaskModel] = []

    override func awakeFromNib() {
        super.awakeFromNib()

        let bg = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        backgroundColor = bg
        contentView.backgroundColor = bg

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 16

        horizontalCollectionView.collectionViewLayout = layout
        horizontalCollectionView.showsHorizontalScrollIndicator = false

        horizontalCollectionView.delegate = self
        horizontalCollectionView.dataSource = self

        horizontalCollectionView.register(
            UINib(nibName: "TaskCardCellNew", bundle: nil),
            forCellWithReuseIdentifier: "TaskCardCellNew"
        )
    }

    // MARK: CONFIGURE SECTION
    func configureSection(type: TaskCategory) {
        self.category = type
        loadDummyData()

        switch type {
        case .assigned:
            titleLabel.text = "Assigned"
            titleLabel.textColor = .systemBlue

        case .review:
            titleLabel.text = "For Review"
            titleLabel.textColor = .systemYellow

        case .completed:
            titleLabel.text = "Completed"
            titleLabel.textColor = .systemGreen

        case .rejected:
            titleLabel.text = "Rejected"
            titleLabel.textColor = .systemRed
        }

        horizontalCollectionView.reloadData()
    }

    // MARK: LOAD DUMMY DATA
    private func loadDummyData() {

        switch category {

        case .assigned:
            dummyData = [
                TaskModel(name: "Shreya", desc: "UI redesign work", date: "03 Nov 2025", remark: nil, remarkDesc: nil),
                TaskModel(name: "Lakshy", desc: "Fix login flow", date: "05 Nov 2025", remark: nil, remarkDesc: nil)
            ]

        case .review:
            dummyData = [
                TaskModel(name: "Shruti", desc: "API integration pending review", date: "10 Nov 2025", remark: nil, remarkDesc: nil),
                TaskModel(name: "Karan", desc: "Check Figma alignment", date: "11 Nov 2025", remark: nil, remarkDesc: nil),
                TaskModel(name: "Aaliya", desc: "Verify data mapping", date: "12 Nov 2025", remark: nil, remarkDesc: nil)
            ]

        case .completed:
            dummyData = [
                TaskModel(
                    name: "Rahul",
                    desc: "Database migration done",
                    date: "01 Nov 2025",
                    remark: "Remark",
                    remarkDesc: "Excellent work! All changes merged."
                ),
                TaskModel(
                    name: "Shreya",
                    desc: "Prototype completed",
                    date: "28 Oct 2025",
                    remark: "Remark",
                    remarkDesc: "Meets all UI expectations."
                )
            ]

        case .rejected:
            dummyData = [
                TaskModel(
                    name: "Arjun",
                    desc: "UI not matching design",
                    date: "20 Oct 2025",
                    remark: "Remark",
                    remarkDesc: "Revise entire layout as soon as possible."
                ),
                TaskModel(
                    name: "Riya",
                    desc: "Incorrect business logic",
                    date: "21 Oct 2025",
                    remark: "Remark",
                    remarkDesc: "Wrong formula applied in calculations."
                )
            ]
        }
    }
}

extension TaskSectionCell:
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return dummyData.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TaskCardCellNew",
            for: indexPath
        ) as! TaskCardCellNew
        
        let task = dummyData[indexPath.row]
        
        cell.configure(
            profile: UIImage(named: "Student"),
            assignedTo: "Assigned To",
            name: task.name,
            desc: task.desc,
            date: task.date,
            remark: task.remark,
            remarkDesc: task.remarkDesc
        )
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch category {
        case .completed, .rejected:
            return CGSize(width: 300, height: 170)   // bigger height for remark section
            
        default:
            return CGSize(width: 300, height: 170)   // normal height
        }
    }
}
