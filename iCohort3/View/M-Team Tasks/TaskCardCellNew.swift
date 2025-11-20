import UIKit

class TaskCardCellNew: UICollectionViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var assignedToLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var taskTitleLabel: UILabel!
    @IBOutlet weak var remarkTitleLabel: UILabel!
    @IBOutlet weak var remarkDescriptionLabel: UILabel!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var elipsisTapped: UIButton!
    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    
    // Callback for ellipsis button
    var onEllipsisMenu: ((TaskCardCellNew) -> Void)?
    var onAttachmentTapped: (([UIImage]) -> Void)?
    
    private var currentAttachments: [UIImage] = []
    
    // MARK: - Stored constraints
    private var remarkTitleTopConstraint: NSLayoutConstraint?
    private var remarkDescTopConstraint: NSLayoutConstraint?
    private var dateTopConstraint: NSLayoutConstraint?
    private var cardBottomConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()

        backgroundColor = UIColor(hex: "#F2F2F7")

        cardView.backgroundColor = .white
        cardView.layer.cornerRadius = 15
        cardView.layer.masksToBounds = true

        profileImage.layer.cornerRadius = 20
        profileImage.clipsToBounds = true

        remarkTitleLabel.isHidden = true
        remarkDescriptionLabel.isHidden = true

        // allow manual constraints
        remarkTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        remarkDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false

        // ✨ MUST-HAVE (bottom constraint for expansion)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        cardView.translatesAutoresizingMaskIntoConstraints = false
        
        remarkTitleLabel.setContentHuggingPriority(.required, for: .horizontal)
        remarkTitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        remarkDescriptionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        remarkDescriptionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        // This is needed so completed/rejected can expand height
        cardBottomConstraint =
            cardView.bottomAnchor.constraint(equalTo: dateLabel.bottomAnchor, constant: 12)
        cardBottomConstraint?.isActive = true
        
        // Setup ellipsis button menu
        setupEllipsisButton()
        
        // Setup attachment button
        attachmentButton.addTarget(self, action: #selector(attachmentButtonTapped), for: .touchUpInside)
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        remarkTitleLabel.isHidden = true
        remarkDescriptionLabel.isHidden = true

        remarkTitleTopConstraint?.isActive = false
        remarkDescTopConstraint?.isActive = false
        dateTopConstraint?.isActive = false
        
        onEllipsisMenu = nil
        onAttachmentTapped = nil
        currentAttachments = []
        
        // Reset attachment button
        attachmentButton.setTitle("0 Attachments", for: .normal)
        attachmentButton.isHidden = true
    }
    
    @objc func attachmentButtonTapped() {
        if !currentAttachments.isEmpty {
            onAttachmentTapped?(currentAttachments)
        }
    }
    
    func setupEllipsisButton() {
        if #available(iOS 14.0, *) {
            elipsisTapped.showsMenuAsPrimaryAction = true
            elipsisTapped.menu = createMenu()
        } else {
            elipsisTapped.addTarget(self, action: #selector(ellipsisButtonTapped), for: .touchUpInside)
        }
    }
    
    @available(iOS 14.0, *)
    func createMenu() -> UIMenu {
        let editAction = UIAction(title: "Edit", image: UIImage(systemName: "pencil")) { [weak self] _ in
            guard let self = self else { return }
            self.onEllipsisMenu?(self)
        }
        
        let deleteAction = UIAction(title: "Delete", image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.showDeleteConfirmation()
        }
        
        return UIMenu(title: "", children: [editAction, deleteAction])
    }
    
    @objc func ellipsisButtonTapped() {
        // Fallback for iOS < 14
        let alert = UIAlertController(title: "Task Options", message: nil, preferredStyle: .actionSheet)
        
        let editAction = UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.onEllipsisMenu?(self)
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(editAction)
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        if let viewController = self.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }
    
    func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Delete Task",
            message: "Are you sure you want to delete this task?",
            preferredStyle: .alert
        )
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            // Post notification to delete task
            NotificationCenter.default.post(
                name: NSNotification.Name("DeleteTask"),
                object: nil,
                userInfo: ["cell": self]
            )
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        if let viewController = self.window?.rootViewController {
            viewController.present(alert, animated: true)
        }
    }

    func configure(
        profile: UIImage?,
        assignedTo: String,
        name: String,
        desc: String,
        date: String,
        remark: String?,
        remarkDesc: String?,
        title: String? = nil,
        attachments: [UIImage]? = nil
    ) {

        profileImage.image = profile
        assignedToLabel.text = assignedTo
        nameLabel.text = name
        descriptionLabel.text = desc
        dateLabel.text = "Due Date: \(date)"
        
        // Set task title
        taskTitleLabel.text = title ?? "Untitled Task"
        
        // Configure attachments
        currentAttachments = attachments ?? []
        if !currentAttachments.isEmpty {
            let count = currentAttachments.count
            let attachmentText = count == 1 ? "1 Attachment" : "\(count) Attachments"
            attachmentButton.setTitle(attachmentText, for: .normal)
            attachmentButton.isHidden = false
        } else {
            attachmentButton.setTitle("0 Attachments", for: .normal)
            attachmentButton.isHidden = true
        }

        // -------- NO REMARKS → Assigned / Review --------
        if remark == nil || remarkDesc == nil {
            remarkTitleLabel.isHidden = true
            remarkDescriptionLabel.isHidden = true

            // Reset date position to NORMAL
            dateTopConstraint?.isActive = false
            dateTopConstraint = dateLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 10)
            dateTopConstraint?.isActive = true

            return
        }

        // -------- REMARK PRESENT → Completed / Rejected --------
        remarkTitleLabel.isHidden = false
        remarkDescriptionLabel.isHidden = false

        remarkTitleLabel.text = remark
        remarkDescriptionLabel.text = remarkDesc

        remarkTitleTopConstraint?.isActive = false
        remarkDescTopConstraint?.isActive = false
        dateTopConstraint?.isActive = false

        // --- BOTH LABELS BELOW DESCRIPTION ---
        remarkTitleTopConstraint =
            remarkTitleLabel.topAnchor.constraint(equalTo: descriptionLabel.bottomAnchor, constant: 8)
        remarkTitleTopConstraint?.isActive = true

        // --- HORIZONTAL LAYOUT FOR SAME LINE ---

        // Red "REMARK:"
        remarkTitleLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 12).isActive = true

        // Black description next to it
        remarkDescriptionLabel.leadingAnchor.constraint(equalTo: remarkTitleLabel.trailingAnchor, constant: 6).isActive = true

        // Keep both aligned on baseline
        remarkDescriptionLabel.firstBaselineAnchor.constraint(equalTo: remarkTitleLabel.firstBaselineAnchor).isActive = true

        // Allow text to expand but not break layout
        remarkDescriptionLabel.trailingAnchor.constraint(lessThanOrEqualTo: cardView.trailingAnchor, constant: -12).isActive = true

        // Separator moves down
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.topAnchor.constraint(equalTo: remarkDescriptionLabel.bottomAnchor, constant: 8).isActive = true

        // Date below the separator
        dateTopConstraint =
            dateLabel.topAnchor.constraint(equalTo: separatorLine.bottomAnchor, constant: 8)
        dateTopConstraint?.isActive = true

        // cardView height expands automatically because bottom is pinned
    }
}

// HEX COLOR
extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r = CGFloat((int >> 16) & 0xFF) / 255.0
        let g = CGFloat((int >> 8) & 0xFF) / 255.0
        let b = CGFloat(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
