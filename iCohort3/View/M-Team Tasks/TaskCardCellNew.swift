import UIKit

class TaskCardCellNew: UICollectionViewCell {

    @IBOutlet weak var cardView: UIView!

    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var assignedToLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!

    @IBOutlet weak var remarkTitleLabel: UILabel!
    @IBOutlet weak var remarkDescriptionLabel: UILabel!

    @IBOutlet weak var separatorLine: UIView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var cardTapped: UIButton!
    
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
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        remarkTitleLabel.isHidden = true
        remarkDescriptionLabel.isHidden = true

        remarkTitleTopConstraint?.isActive = false
        remarkDescTopConstraint?.isActive = false
        dateTopConstraint?.isActive = false
    }

    func configure(
        profile: UIImage?,
        assignedTo: String,
        name: String,
        desc: String,
        date: String,
        remark: String?,
        remarkDesc: String?
    ) {

        profileImage.image = profile
        assignedToLabel.text = assignedTo
        nameLabel.text = name
        descriptionLabel.text = desc
        dateLabel.text = "Due Date: \(date)"

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

