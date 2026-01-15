import UIKit

class TaskSectionCell: UICollectionViewCell {

    @IBOutlet weak var heightConstrainnt: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var seeAllButton: UIButton!
    @IBOutlet weak var horizontalCollectionView: UICollectionView!
    
    // Closures to notify parent VC
    var seeAllTapped: (() -> Void)?
    var onEditTask: ((TaskModel, Int) -> Void)?
    var onViewAttachments: (([UIImage]) -> Void)?
    var onDeleteTask: ((Int) -> Void)?
    
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

    // MARK: CONFIGURE SECTION (Primary method - uses real data)
    func configureSection(type: TaskCategory, tasks: [TaskModel]) {
        self.category = type
        self.tasks = tasks

        // Update title and color based on category
        titleLabel.text = type.displayName
        titleLabel.textColor = type.displayColor

        horizontalCollectionView.reloadData()
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
        
        // Configure cell with task data
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
        
        // Handle ellipsis menu for edit
        cell.onEllipsisMenu = { [weak self] tappedCell in
            guard let self = self else { return }
            self.onEditTask?(task, indexPath.row)
        }
        
        // Handle attachment button tap
        cell.onAttachmentTapped = { [weak self] attachments in
            guard let self = self else { return }
            self.onViewAttachments?(attachments)
        }
        
        // Handle delete - parent will show confirmation alert
        cell.onDeleteTapped = { [weak self] tappedCell in
            guard let self = self else { return }
            self.onDeleteTask?(indexPath.row)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let task = tasks[indexPath.row]
        
        // Adjust height based on whether remarks are present
        let hasRemarks = task.remark != nil && task.remarkDesc != nil
        let height: CGFloat = hasRemarks ? 200 : 170
        
        return CGSize(width: 300, height: height)
    }
}
