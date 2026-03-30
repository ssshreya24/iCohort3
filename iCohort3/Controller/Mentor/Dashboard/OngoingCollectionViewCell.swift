import UIKit

final class OngoingCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func layoutSubviews() {
        super.layoutSubviews()
        badgeLabel.layer.cornerRadius = badgeLabel.bounds.height / 2
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.backgroundColor = .clear

        // Avatar view styling
        avatarView.layer.cornerRadius = 35
        avatarView.backgroundColor = .white
        avatarView.clipsToBounds = true

        // Shadow for the whole cell
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
        layer.shadowPath = UIBezierPath(
            roundedRect: CGRect(x: 12, y: 4, width: 70, height: 70),
            cornerRadius: 35
        ).cgPath

        // Badge styling
        badgeLabel.clipsToBounds = true
        badgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.45, blue: 0.26, alpha: 1.0)
        badgeLabel.textColor = .white
        badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textAlignment = .center
        badgeLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        badgeLabel.setContentHuggingPriority(.required, for: .horizontal)

        // Title label
        titleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        // Default icon
        avatarImageView.image = UIImage(systemName: "person.3.fill")
        avatarImageView.tintColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        avatarImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 28, weight: .regular)
    }

    func configure(with team: OngoingTeam) {
        titleLabel.text = "Team \(team.teamNo)"

        if team.activeTaskCount > 0 {
            badgeLabel.text = "\(team.activeTaskCount)"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }
}
