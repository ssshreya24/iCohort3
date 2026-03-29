//
//  ActivityTableViewCell.swift
//  iCohort3
//
//  Created by user@51 on 11/11/25.
//

import UIKit

class ActivityTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {
        containerView.layer.cornerRadius = 16
        timeLabel.layer.cornerRadius = 8
        timeLabel.clipsToBounds = true
        timeLabel.textAlignment = .center
    }

    func configure(with title: String, time: String?) {
        titleLabel.text = title
        if let time = time {
            timeLabel.text = time
            timeLabel.isHidden = false
        } else {
            timeLabel.isHidden = true
        }
    }
}

