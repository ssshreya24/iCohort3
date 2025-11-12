//
//  MemberAvatarCell.swift
//  iCohort3
//
//  Created by user@0 on 12/11/25.
//

import UIKit

class MemberAvatarCell: UICollectionViewCell {

        @IBOutlet weak var avatarImageView: UIImageView!
        @IBOutlet weak var addButton: UIButton!

        private var onAdd: (() -> Void)?

        override func awakeFromNib() {
            super.awakeFromNib()
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.clipsToBounds = true
            addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            addButton.tintColor = .systemBlue
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
        }

        func configure(slot: TeamViewController.MemberSlot, onAdd: @escaping () -> Void) {
            self.onAdd = onAdd

            switch slot {
            case .filled(let image):
                avatarImageView.image = image
                addButton.isHidden = true

            case .empty:
                avatarImageView.image = UIImage(systemName: "person.crop.circle")
                addButton.isHidden = true

            case .addSlot:
                avatarImageView.image = UIImage(systemName: "person.crop.circle")
                addButton.isHidden = false
            }
        }

        @IBAction func addButtonTapped(_ sender: UIButton) {
            onAdd?()
        }
    }


