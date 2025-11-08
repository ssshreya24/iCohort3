//
//  AnnouncementTableViewCell.swift
//  iCohort3
//
//  Created by user@51 on 08/11/25.
//

import UIKit

class AnnouncementCell: UITableViewCell {
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var bodyLabel: UILabel!
    @IBOutlet weak var tagLabel: UILabel!
    @IBOutlet weak var metaLabel: UILabel!

    override func awakeFromNib() {
        
        super.awakeFromNib()
        containerView.layer.cornerRadius = 14
        containerView.layer.masksToBounds = true

        // shadow on contentView (so container stays clipped)
        contentView.layer.shadowColor = UIColor.black.cgColor
        contentView.layer.shadowOpacity = 0.06
        contentView.layer.shadowRadius = 6
        contentView.layer.shadowOffset = CGSize(width: 0, height: 3)
        contentView.layer.masksToBounds = false

        tagLabel.layer.masksToBounds = true
        tagLabel.layer.cornerRadius = 12
        tagLabel.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        tagLabel.textColor = .white
        tagLabel.textAlignment = .center
    }

    func configure(with a: Announcement) {
        titleLabel.text = a.title
        bodyLabel.text = a.body
        if let t = a.tag {
            tagLabel.isHidden = false
            tagLabel.text = " \(t) "
            // simple color mapping
            if t.lowercased().contains("event") {
                tagLabel.backgroundColor = UIColor(red: 0.18, green: 0.78, blue: 0.42, alpha: 1) // green
            } else {
                tagLabel.backgroundColor = UIColor(red: 0.95, green: 0.74, blue: 0.18, alpha: 1) // orange
            }
        } else {
            tagLabel.isHidden = true
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        metaLabel.text = "\(formatter.string(from: a.createdAt)) • BY \(a.author.uppercased())"
    }
}

