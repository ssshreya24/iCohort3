import UIKit

final class RequestItemCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!

    // MARK: - Callback
    private var onAction: (() -> Void)?
    private var onSecondaryAction: (() -> Void)?   // for Reject (optional)

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        avatarView.tintColor = .systemGray2
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onAction = nil
        onSecondaryAction = nil
        nameLabel.text = nil
        subtitleLabel.text = nil
        avatarView.image = nil
        actionButton.isHidden = false
        actionButton.setTitle(nil, for: .normal)
        actionButton.backgroundColor = .systemBlue
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        avatarView.layer.cornerRadius = avatarView.bounds.width / 2
    }

    // MARK: - Setup
    private func setupUI() {
        avatarView.contentMode = .scaleAspectFill
        avatarView.clipsToBounds = true

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        subtitleLabel.font = .systemFont(ofSize: 13)
        subtitleLabel.textColor = .secondaryLabel

        actionButton.layer.cornerRadius = 6
        actionButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        actionButton.backgroundColor = .systemBlue
        actionButton.setTitleColor(.white, for: .normal)
    }

    // MARK: - NEW: Student row for "Send Request" segment
    /// Shows: Name + "REG • Department" + [Send Request]
    func configureStudentRow(
        name: String,
        regNo: String,
        department: String,
        avatar: UIImage? = nil,
        onSendRequest: @escaping () -> Void
    ) {
        nameLabel.text = name
        subtitleLabel.text = "\(regNo) • \(department)"
        avatarView.image = avatar ?? UIImage(systemName: "person.circle")
        avatarView.backgroundColor = .clear

        actionButton.isHidden = false
        actionButton.setTitle("Send Request", for: .normal)
        actionButton.backgroundColor = .systemBlue

        onAction = onSendRequest
        onSecondaryAction = nil
    }

    // MARK: - NEW: Incoming request row for "Requests" segment
    /// Shows: Requester name + "Requested to join your team" + [Accept]
    /// (Reject can be handled in VC via swipe/action sheet; keeping cell simple)
    func configureIncomingRequestRow(
        requesterName: String,
        subtitle: String = "Requested to join your team",
        avatar: UIImage? = nil,
        onAccept: @escaping () -> Void
    ) {
        nameLabel.text = requesterName
        subtitleLabel.text = subtitle
        avatarView.image = avatar ?? UIImage(systemName: "person.circle.fill")
        avatarView.backgroundColor = .clear

        actionButton.isHidden = false
        actionButton.setTitle("Accept", for: .normal)
        actionButton.backgroundColor = .systemGreen

        onAction = onAccept
        onSecondaryAction = nil
    }

    // MARK: - Existing: Join team card (you already use this)
    func configureForJoin(
        adminName: String,
        avatar: UIImage?,
        teamNumber: String,
        members: [String],
        onJoin: @escaping () -> Void
    ) {
        nameLabel.text = "\(adminName) (Team \(teamNumber))"
        subtitleLabel.text = members.joined(separator: ", ")

        avatarView.image = avatar ?? UIImage(systemName: "person.circle")
        avatarView.backgroundColor = .systemGray2

        actionButton.setTitle("Join", for: .normal)
        actionButton.backgroundColor = .systemBlue
        actionButton.isHidden = false

        onAction = onJoin
        onSecondaryAction = nil
    }

    // MARK: - (Optional) Fix your old functions if you still want them
    func configureForSent(name: String, avatar: UIImage?, onSend: @escaping () -> Void) {
        nameLabel.text = name
        subtitleLabel.text = "Ready to send a request"
        avatarView.image = avatar ?? UIImage(systemName: "person.circle")
        actionButton.isHidden = false
        actionButton.setTitle("Send", for: .normal)
        actionButton.backgroundColor = .systemBlue
        onAction = onSend
        onSecondaryAction = nil
    }

    func configureForReceived(name: String, avatar: UIImage?, onAccept: @escaping () -> Void) {
        nameLabel.text = name
        subtitleLabel.text = "Requested you"
        avatarView.image = avatar ?? UIImage(systemName: "person.circle.fill")
        actionButton.setTitle("Accept", for: .normal)
        actionButton.backgroundColor = .systemGreen
        actionButton.isHidden = false
        onAction = onAccept
        onSecondaryAction = nil
    }

    // MARK: - Actions
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        onAction?()
    }
}
