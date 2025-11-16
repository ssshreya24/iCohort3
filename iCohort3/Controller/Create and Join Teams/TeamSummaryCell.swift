//
//  TeamSummaryCell.swift
//  iCohort3
//
//  Created by user@0 on 11/11/25.
//

import UIKit


class TeamSummaryCell: UICollectionViewCell {
    
    @IBOutlet weak var circleView: UIView!
    
    @IBOutlet weak var teamImageView: UIImageView!
        @IBOutlet weak var teamNameLabel: UILabel!

    override func awakeFromNib() {
            super.awakeFromNib()
            contentView.backgroundColor = .clear

            circleView.backgroundColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
            circleView.clipsToBounds = true
            circleView.setContentHuggingPriority(.required, for: .horizontal)
            circleView.setContentHuggingPriority(.required, for: .vertical)

            teamImageView.tintColor = .white
            teamImageView.contentMode = .scaleAspectFit
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            circleView.layer.cornerRadius = circleView.bounds.height / 2
        }

        func configure(teamName: String, icon: UIImage?) {
            teamNameLabel.text = teamName
            teamImageView.image = icon?.withRenderingMode(.alwaysTemplate)
        }
    }
