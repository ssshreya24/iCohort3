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
    
    // Callbacks
    var onEllipsisMenu: ((TaskCardCellNew) -> Void)?
    var onAttachmentTapped: (() -> Void)?
    var onDeleteTapped: ((TaskCardCellNew) -> Void)?
    
    private var currentAttachments: [UIImage] = []
    
    // MARK: - Stored constraints
    private var remarkTitleTopConstraint: NSLayoutConstraint?
    private var remarkTitleLeadingConstraint: NSLayoutConstraint?
    private var remarkDescLeadingConstraint: NSLayoutConstraint?
    private var remarkDescTrailingConstraint: NSLayoutConstraint?
    private var remarkDescBaselineConstraint: NSLayoutConstraint?
    private var separatorTopConstraint: NSLayoutConstraint?
    private var dateTopConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        cardView.layer.cornerRadius = 15
        cardView.layer.masksToBounds = true

        profileImage.layer.cornerRadius = 20
        profileImage.clipsToBounds = true

        remarkTitleLabel.isHidden = true
        remarkDescriptionLabel.isHidden = true

        // Allow manual constraints
        remarkTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        remarkDescriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        separatorLine.translatesAutoresizingMaskIntoConstraints = false
        
        remarkTitleLabel.setContentHuggingPriority(.required, for: .horizontal)
        remarkTitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)

        remarkDescriptionLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        remarkDescriptionLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        remarkDescriptionLabel.numberOfLines = 0
        
        // Setup ellipsis button menu
        setupEllipsisButton()
        
        // Setup attachment button
        attachmentButton.addTarget(self, action: #selector(attachmentButtonTapped), for: .touchUpInside)
        applyTheme()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        remarkTitleLabel.isHidden = true
        remarkDescriptionLabel.isHidden = true

        // Deactivate all dynamic constraints
        remarkTitleTopConstraint?.isActive = false
        remarkTitleLeadingConstraint?.isActive = false
        remarkDescLeadingConstraint?.isActive = false
        remarkDescTrailingConstraint?.isActive = false
        remarkDescBaselineConstraint?.isActive = false
        separatorTopConstraint?.isActive = false
        dateTopConstraint?.isActive = false
        
        onEllipsisMenu = nil
        onAttachmentTapped = nil
        onDeleteTapped = nil
        currentAttachments = []
        
        // Reset attachment button
        attachmentButton.setTitle("0 Attachments", for: .normal)
        attachmentButton.isHidden = true
    }
    
    @objc func attachmentButtonTapped() {
        onAttachmentTapped?()
    }
    
    private func applyTheme() {
        let isDark = traitCollection.userInterfaceStyle == .dark
        AppTheme.styleElevatedCard(cardView, cornerRadius: 15)
        cardView.backgroundColor = isDark
            ? UIColor(red: 0.27, green: 0.30, blue: 0.37, alpha: 0.98)
            : .white
        assignedToLabel.textColor = .secondaryLabel
        nameLabel.textColor = .label
        descriptionLabel.textColor = isDark ? UIColor(white: 0.86, alpha: 1) : .secondaryLabel
        taskTitleLabel.textColor = .label
        remarkTitleLabel.textColor = .label
        remarkDescriptionLabel.textColor = .secondaryLabel
        dateLabel.textColor = .secondaryLabel
        separatorLine.backgroundColor = UIColor.separator.withAlphaComponent(isDark ? 0.28 : 0.18)
        attachmentButton.setTitleColor(isDark ? .white : .systemBlue, for: .normal)
        attachmentButton.tintColor = isDark ? .white : .systemBlue
        elipsisTapped.tintColor = isDark ? .white : .label
    }

    static func makeAssignedAvatar(from displayName: String, size: CGSize = CGSize(width: 40, height: 40)) -> UIImage {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let components = trimmed.split(whereSeparator: \.isWhitespace)
        let initials = components.prefix(2).compactMap { $0.first }.map { String($0).uppercased() }.joined()
        let fallback = initials.isEmpty ? "T" : initials

        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: rect).addClip()
            UIColor.systemGray5.setFill()
            UIRectFill(rect)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.36, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let textSize = fallback.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            fallback.draw(in: textRect, withAttributes: attributes)
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
            self.onDeleteTapped?(self)
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
            guard let self = self else { return }
            self.onDeleteTapped?(self)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(editAction)
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
        attachments: [UIImage]? = nil,
        attachmentCount: Int = 0
    ) {

        profileImage.image = profile
        profileImage.contentMode = .scaleAspectFill
        assignedToLabel.text = assignedTo
        nameLabel.text = name
        descriptionLabel.text = desc
        dateLabel.text = "Due Date: \(date)"
        
        // Set task title
        taskTitleLabel.text = title ?? "Untitled Task"
        
        // Configure attachments
        currentAttachments = attachments ?? []
        let visibleAttachmentCount = attachmentCount > 0 ? attachmentCount : currentAttachments.count
        if visibleAttachmentCount > 0 {
            let count = visibleAttachmentCount
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
            dateTopConstraint?.isActive = false
            return
        }

        // -------- REMARK PRESENT → Completed / Rejected --------
        remarkTitleLabel.isHidden = false
        remarkDescriptionLabel.isHidden = false

        remarkTitleLabel.text = remark
        remarkDescriptionLabel.text = remarkDesc

        // Deactivate old constraints
        remarkTitleTopConstraint?.isActive = false
        remarkTitleLeadingConstraint?.isActive = false
        remarkDescLeadingConstraint?.isActive = false
        remarkDescTrailingConstraint?.isActive = false
        remarkDescBaselineConstraint?.isActive = false
        separatorTopConstraint?.isActive = false
        dateTopConstraint?.isActive = false

        // Position remarkTitleLabel below description
        remarkTitleTopConstraint = remarkTitleLabel.topAnchor.constraint(
            equalTo: descriptionLabel.bottomAnchor,
            constant: 10
        )
        remarkTitleTopConstraint?.isActive = true

        remarkTitleLeadingConstraint = remarkTitleLabel.leadingAnchor.constraint(
            equalTo: cardView.leadingAnchor,
            constant: 12
        )
        remarkTitleLeadingConstraint?.isActive = true

        // Position remarkDescriptionLabel next to remarkTitleLabel
        remarkDescLeadingConstraint = remarkDescriptionLabel.leadingAnchor.constraint(
            equalTo: remarkTitleLabel.trailingAnchor,
            constant: 6
        )
        remarkDescLeadingConstraint?.isActive = true

        remarkDescTrailingConstraint = remarkDescriptionLabel.trailingAnchor.constraint(
            lessThanOrEqualTo: cardView.trailingAnchor,
            constant: -12
        )
        remarkDescTrailingConstraint?.isActive = true

        remarkDescBaselineConstraint = remarkDescriptionLabel.firstBaselineAnchor.constraint(
            equalTo: remarkTitleLabel.firstBaselineAnchor
        )
        remarkDescBaselineConstraint?.isActive = true

        // Separator moves down below remark description
        separatorTopConstraint = separatorLine.topAnchor.constraint(
            equalTo: remarkDescriptionLabel.bottomAnchor,
            constant: 10
        )
        separatorTopConstraint?.isActive = true

        // Date below the separator
        dateTopConstraint = dateLabel.topAnchor.constraint(
            equalTo: separatorLine.bottomAnchor,
            constant: 10
        )
        dateTopConstraint?.isActive = true
        
        self.layoutIfNeeded()
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
