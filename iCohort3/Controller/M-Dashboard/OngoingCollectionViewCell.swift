//
//  OngoingCollectionViewCell.swift
//  iCohort3
//
//  Created by user@51 on 14/11/25.
//

import UIKit

class OngoingCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var avatarView: UIView!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        avatarView.layer.cornerRadius = 35
        avatarView.clipsToBounds = true

        badgeLabel.layer.cornerRadius = 10
        badgeLabel.clipsToBounds = true
    }

    func configure(with team: OngoingTeam) {
        titleLabel.text = team.name
        badgeLabel.text = "\(team.badgeCount)"
        badgeLabel.isHidden = team.badgeCount == 0

        avatarImageView.image = UIImage(systemName: "person.3.fill")
        avatarImageView.tintColor = .darkGray
    }
}

