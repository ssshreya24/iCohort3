//
//  ReviewCollectionViewCell.swift
//  iCohort3
//
//  Created by user@51 on 14/11/25.
//

import UIKit

class ReviewCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var teamLabel: UILabel!
    @IBOutlet weak var taskLabel: UILabel!
    @IBOutlet weak var chevronImageView: UIImageView!
    @IBOutlet weak var taskCardButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        cardView.layer.cornerRadius = 12
        cardView.layer.masksToBounds = true

        chevronImageView.image = UIImage(systemName: "chevron.right")
    }

    func configure(with item: ReviewTask) {
        teamLabel.text = item.teamName
        taskLabel.text = item.taskTitle
    }
}

