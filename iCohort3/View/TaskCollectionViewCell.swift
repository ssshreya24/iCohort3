//
//  TaskCollectionViewCell.swift
//  iCohort3
//
//  Created by user@56 on 09/11/25.
//

import UIKit

class TaskCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var circleButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var assignedLabel: UILabel!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!         // "Shreya"
        @IBOutlet weak var separatorView: UIView!    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        setupUI()
    }
    private func setupUI() {
            // Card style
            contentView.layer.cornerRadius = 12
            contentView.layer.masksToBounds = false
            contentView.layer.shadowColor = UIColor.black.cgColor
            contentView.layer.shadowOpacity = 0.1
            contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
            contentView.layer.shadowRadius = 5
            contentView.backgroundColor = .white

            // Profile image setup
            profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
            profileImageView.clipsToBounds = true

            // Separator line style
            separatorView.backgroundColor = .systemGray5

            // Label styles
        assignedLabel.textColor = .systemGray3
        assignedLabel.font = UIFont.systemFont(ofSize: 13)

            nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
            nameLabel.textColor = .label

            titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
            descriptionLabel.font = UIFont.systemFont(ofSize: 14)
            descriptionLabel.textColor = .darkGray

            dueDateLabel.font = UIFont.systemFont(ofSize: 13)
            dueDateLabel.textColor = .systemGray
        }

        func configure(title: String, desc: String, image: UIImage?, name: String) {
            titleLabel.text = title
            descriptionLabel.text = desc
            profileImageView.image = image
            assignedLabel.text = "Assigned To"
            nameLabel.text = name
            dueDateLabel.text = "Due Date: 03 Nov 2025"
        }

}
