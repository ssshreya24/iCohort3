//
//  MemberAvatarCell.swift
//  iCohort3
//
//  Created by user@0 on 12/11/25.
//

import UIKit

class MemberAvatarCell: UICollectionViewCell {
    
    @IBOutlet weak var avatarContainerView: UIView!

        @IBOutlet weak var avatarImageView: UIImageView!
        @IBOutlet weak var addButton: UIButton!

        private var onAdd: (() -> Void)?

        override func awakeFromNib() {
            super.awakeFromNib()
            

                    backgroundColor = .clear
                    contentView.backgroundColor = .clear

                    // container background (card)
            avatarContainerView.backgroundColor = .appBackground
                    avatarContainerView.layer.masksToBounds = true

                    avatarImageView.contentMode = .scaleAspectFit
                    avatarImageView.clipsToBounds = true
            avatarImageView.tintColor = .darkGray

            addButton.backgroundColor = .darkGray
                addButton.layer.cornerRadius = addButton.frame.height / 2
                addButton.clipsToBounds = true
            let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)  // smaller icon
            addButton.setImage(UIImage(systemName: "plus", withConfiguration: config), for: .normal)

                addButton.tintColor = .white
            addButton.layer.borderColor = UIColor.white.cgColor
                addButton.layer.borderWidth = 2
        }

        override func layoutSubviews() {
            super.layoutSubviews()

                    // Make the whole view a circle
                    let d = min(avatarContainerView.bounds.width, avatarContainerView.bounds.height)
                    avatarContainerView.layer.cornerRadius = d / 2

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
                addButton.isHidden = true
            }
        }

        @IBAction func addButtonTapped(_ sender: UIButton) {
            onAdd?()
        }
    }
extension UIColor {
    static let appBackground = UIColor(red: 239/255, green: 239/255, blue: 245/255, alpha: 1)
}

