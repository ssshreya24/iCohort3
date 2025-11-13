//
//  RequestItemCell.swift
//  iCohort3
//
//  Created by user@0 on 12/11/25.
//

import UIKit

class RequestItemCell: UICollectionViewCell {

    // MARK: - Outlets
    @IBOutlet weak var avatarView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var actionButton: UIButton!

    // MARK: - Callback
    private var onAction: (() -> Void)?

    // MARK: - Lifecycle
    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
        avatarView.tintColor = .systemGray2
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

    // MARK: - Configurations

    /// For “Requests Sent” section — show button
    func configureForSent(name: String, avatar: UIImage?, onSend: @escaping () -> Void) {
        nameLabel.text = name
        subtitleLabel.text = "Ready to send a request"
        avatarView.image = avatar ?? UIImage(systemName: "person.circle")
        actionButton.isHidden = false
        actionButton.setTitle("Send", for: .normal)
        onAction = onSend
    }

    /// For “Requests Received” section — hide button, show team info
    func configureForReceived(name: String, teamNumber: String, members: [String]) {
        nameLabel.text = "\(name) (Team \(teamNumber))"
        subtitleLabel.text = "Members: \(members.joined(separator: ", "))"
        avatarView.image = UIImage(systemName: "person.circle")
        actionButton.isHidden = true
        avatarView.backgroundColor = .systemGray2
    }

    // MARK: - Actions
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        onAction?()
    }
}
