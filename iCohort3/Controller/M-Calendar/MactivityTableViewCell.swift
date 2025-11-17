//
//  MActivityTableViewCell.swift
//  iCohort3
//

import UIKit

class MactivityTableViewCell: UITableViewCell {

    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        setupUI()
    }

    private func setupUI() {

        // Same clean card style like student cell
        containerView.layer.cornerRadius = 20
        containerView.backgroundColor = .white
        containerView.layer.masksToBounds = true

        // Remove any leftover borders/shadows
        containerView.layer.borderWidth = 0
        containerView.layer.borderColor = UIColor.clear.cgColor
        containerView.layer.shadowOpacity = 0

        // Title style
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label

        // Time label pill style
        timeLabel.layer.cornerRadius = 8
        timeLabel.clipsToBounds = true
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        timeLabel.textColor = .label

        // No highlight on tap
        selectionStyle = .none

        // Clear cell backgrounds
        backgroundColor = .clear
        contentView.backgroundColor = .clear
    }

    func configure(with title: String, time: String?) {
        titleLabel.text = title
        
        if let t = time, !t.isEmpty {
            timeLabel.text = t
            timeLabel.isHidden = false
        } else {
            timeLabel.isHidden = true
        }
    }
}
