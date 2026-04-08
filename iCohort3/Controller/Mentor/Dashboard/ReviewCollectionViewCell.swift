import UIKit

final class ReviewCollectionViewCell: UICollectionViewCell {

    // ✅ Keep these only if you ever need them later (optional)
    var teamId: String = ""
    var teamNo: Int = 0
    var taskId: String = ""
    var taskTitle: String = ""

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var taskLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    @IBOutlet weak var taskCardButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()

        // ✅ Keep interaction clean
        isUserInteractionEnabled = true
        contentView.isUserInteractionEnabled = true

        // Subviews should NOT block tap on the cell
        cardView.isUserInteractionEnabled = false
        taskCardButton.isUserInteractionEnabled = false
        chevronImageView.isUserInteractionEnabled = false
        teamLabel.isUserInteractionEnabled = false
        taskLabel.isUserInteractionEnabled = false

        // Card styling
        cardView.layer.cornerRadius = 12
        cardView.backgroundColor = .white
        cardView.clipsToBounds = true
        contentView.backgroundColor = .clear

        // Shadow on cell (not cardView, because cardView clips)
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.08
        layer.masksToBounds = false

        // Labels
        teamLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        teamLabel.textColor = .black
        teamLabel.numberOfLines = 1

        taskLabel.font = .systemFont(ofSize: 14, weight: .regular)
        taskLabel.textColor = .black
        taskLabel.numberOfLines = 1
        taskLabel.lineBreakMode = .byTruncatingTail

        // Chevron
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .black
        chevronImageView.contentMode = .scaleAspectFit

        taskCardButton.setTitle(nil, for: .normal)
    }

    // ✅ Use this for DB-driven content
    func configure(with item: ReviewTask) {

        // ✅ IMPORTANT: store values so the cell does not keep empty defaults
        self.teamId = item.teamId
        self.teamNo = item.teamNo
        self.taskId = item.taskId
        self.taskTitle = item.taskTitle

        // ✅ UI
        teamLabel.text = "Team \(item.teamNo)"
        taskLabel.text = item.taskTitle
    }

    // Optional: visual feedback for tap
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.2) {
                self.cardView.alpha = self.isHighlighted ? 0.7 : 1.0
                self.transform = self.isHighlighted
                    ? CGAffineTransform(scaleX: 0.98, y: 0.98)
                    : .identity
            }
        }
    }

    // ✅ Avoid reused cells showing old data
    override func prepareForReuse() {
        super.prepareForReuse()

        // reset stored props
        teamId = ""
        teamNo = 0
        taskId = ""
        taskTitle = ""

        // reset UI
        teamLabel.text = nil
        taskLabel.text = nil
        cardView.alpha = 1.0
        transform = .identity
    }
}
