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
        
        // Avatar view styling - circular white background
        avatarView.layer.cornerRadius = 35
        avatarView.backgroundColor = .white
        
        // Shadow for avatar view
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        layer.shadowOpacity = 0.1
        layer.masksToBounds = false
        
        // Make sure avatar view doesn't clip for shadow
        avatarView.clipsToBounds = true
        
        // Badge styling - circular orange badge
        badgeLabel.layer.cornerRadius = 12
        badgeLabel.clipsToBounds = true
        badgeLabel.backgroundColor = UIColor(red: 1.0, green: 0.45, blue: 0.26, alpha: 1.0) // Orange color
        badgeLabel.textColor = .white
        badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textAlignment = .center
        
        // Title label styling
        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = UIColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)
        titleLabel.textAlignment = .center
    }

    func configure(with team: OngoingTeam) {
        titleLabel.text = team.name
        badgeLabel.text = "\(team.badgeCount)"
        badgeLabel.isHidden = team.badgeCount == 0

        avatarImageView.image = UIImage(systemName: "person.3.fill")
        avatarImageView.tintColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
    }
}
