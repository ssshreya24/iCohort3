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

        // Card view styling - white rounded card
        cardView.layer.cornerRadius = 12
        cardView.backgroundColor = .white
        
        // Shadow for card
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 6
        layer.shadowOpacity = 0.08
        layer.masksToBounds = false
        
        // Make sure card doesn't clip shadow
        cardView.clipsToBounds = true
        
        // Team label styling - bold
        teamLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        teamLabel.textColor = UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.0)
        
        // Task label styling - regular
        taskLabel.font = .systemFont(ofSize: 14, weight: .regular)
        taskLabel.textColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        taskLabel.numberOfLines = 2
        
        // Chevron styling
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
        chevronImageView.contentMode = .scaleAspectFit
    }

    func configure(with item: ReviewTask) {
        teamLabel.text = item.teamName
        taskLabel.text = item.taskTitle
    }
}

