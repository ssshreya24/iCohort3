//
//  OngoingTeamCell.swift
//  iCohort3
//
//  Created by user@51 on 13/11/25.
//

import UIKit

class OngoingTeamCell: UICollectionViewCell {

    @IBOutlet weak var circleView: UIView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var teamLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        // Circle
        circleView.layer.cornerRadius = 20
        circleView.layer.masksToBounds = true

        // Badge
        badgeLabel.layer.cornerRadius = badgeLabel.bounds.height / 2
        badgeLabel.clipsToBounds = true
    }
}



