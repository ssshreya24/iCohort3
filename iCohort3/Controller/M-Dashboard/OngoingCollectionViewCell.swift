import UIKit

final class OngoingCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

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

        // Badge styling
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.clipsToBounds = true
        badgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.45, blue: 0.26, alpha: 1.0)
        badgeLabel.textColor = .white
        badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textAlignment = .center

        // Title label
        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        titleLabel.textAlignment = .center

        // Default icon
        avatarImageView.image = UIImage(systemName: "person.3.fill")
        avatarImageView.tintColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    }

    func configure(with team: OngoingTeam) {
        titleLabel.text = "Team \(team.teamNo)"

        if team.activeTaskCount > -1 {
            badgeLabel.text = "\(team.activeTaskCount)"
            badgeLabel.isHidden = false
        } else {
            badgeLabel.isHidden = true
        }
    }


}
