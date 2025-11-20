import UIKit

enum TaskCategory {
    case assigned
    case review
    case completed
    case rejected
}

struct TaskModel {
    var name: String
    var desc: String
    var date: String
    var remark: String?
    var remarkDesc: String?
    var title: String?
    var attachments: [UIImage]?
    var assignedDate: Date?
}

class TaskSectionCell: UICollectionViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var horizontalCollectionView: UICollectionView!
    
    // Closures to notify parent VC
    var seeAllTapped: (() -> Void)?
    var onEditTask: ((TaskModel, Int) -> Void)?
    var onViewAttachments: (([UIImage]) -> Void)?
    
    @IBAction func seeAllButtonPressed(_ sender: UIButton) {
        seeAllTapped?()
    }

    private var category: TaskCategory = .assigned
    private var tasks: [TaskModel] = []

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
    func configureSection(type: TaskCategory, tasks: [TaskModel]) {
        self.category = type
        self.tasks = tasks

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
    
    // Backward compatibility - configures with dummy data if tasks not provided
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
            tasks = [
                TaskModel(name: "Shreya", desc: "UI redesign work", date: "03 Nov 2025", remark: nil, remarkDesc: nil, title: "Redesign Dashboard", attachments: [], assignedDate: nil),
                TaskModel(name: "Lakshy", desc: "Fix login flow", date: "05 Nov 2025", remark: nil, remarkDesc: nil, title: "Login Bug Fix", attachments: [], assignedDate: nil)
            ]

        case .review:
            tasks = [
                TaskModel(name: "Shruti", desc: "API integration pending review", date: "10 Nov 2025", remark: nil, remarkDesc: nil, title: "API Integration", attachments: [], assignedDate: nil),
                TaskModel(name: "Karan", desc: "Check Figma alignment", date: "11 Nov 2025", remark: nil, remarkDesc: nil, title: "Design Review", attachments: [], assignedDate: nil),
                TaskModel(name: "Aaliya", desc: "Verify data mapping", date: "12 Nov 2025", remark: nil, remarkDesc: nil, title: "Data Verification", attachments: [], assignedDate: nil)
            ]

        case .completed:
            tasks = [
                TaskModel(
                    name: "Rahul",
                    desc: "Database migration done",
                    date: "01 Nov 2025",
                    remark: "Remark",
                    remarkDesc: "Excellent work! All changes merged.",
                    title: "Database Migration",
                    attachments: [],
                    assignedDate: nil
                ),
                TaskModel(
                    name: "Shreya",
                    desc: "Prototype completed",
                    date: "28 Oct 2025",
                    remark: "Remark",
                    remarkDesc: "Meets all UI expectations.",
                    title: "Prototype Design",
                    attachments: [],
                    assignedDate: nil
                )
            ]

        case .rejected:
            tasks = [
                TaskModel(
                    name: "Arjun",
                    desc: "UI not matching design",
                    date: "20 Oct 2025",
                    remark: "Remark",
                    remarkDesc: "Revise entire layout as soon as possible.",
                    title: "UI Implementation",
                    attachments: [],
                    assignedDate: nil
                ),
                TaskModel(
                    name: "Riya",
                    desc: "Incorrect business logic",
                    date: "21 Oct 2025",
                    remark: "Remark",
                    remarkDesc: "Wrong formula applied in calculations.",
                    title: "Logic Implementation",
                    attachments: [],
                    assignedDate: nil
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
        return tasks.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath)
    -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TaskCardCellNew",
            for: indexPath
        ) as! TaskCardCellNew
        
        let task = tasks[indexPath.row]
        
        cell.configure(
            profile: UIImage(named: "Student"),
            assignedTo: "Assigned To",
            name: task.name,
            desc: task.desc,
            date: task.date,
            remark: task.remark,
            remarkDesc: task.remarkDesc,
            title: task.title,
            attachments: task.attachments
        )
        
        // Handle ellipsis menu for edit/delete
        cell.onEllipsisMenu = { [weak self] tappedCell in
            guard let self = self else { return }
            self.onEditTask?(task, indexPath.row)
        }
        
        // Handle attachment button tap
        cell.onAttachmentTapped = { [weak self] attachments in
            guard let self = self else { return }
            self.onViewAttachments?(attachments)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        switch category {
        case .completed, .rejected:
            return CGSize(width: 300, height: 200)   // bigger height for remark section
            
        default:
            return CGSize(width: 300, height: 170)   // normal height
        }
    }
}
