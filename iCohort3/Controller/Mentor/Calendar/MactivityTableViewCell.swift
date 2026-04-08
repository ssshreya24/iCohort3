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
        
        if #available(iOS 17.0, *) {
            registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
                self.applyTheme()
            }
        }
    }
    
    private func setupUI() {
        // Title style
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)

        // Time label pill style
        timeLabel.layer.cornerRadius = 8
        timeLabel.clipsToBounds = true
        timeLabel.textAlignment = .center
        timeLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        // No highlight on tap
        selectionStyle = .none

        // Clear cell backgrounds
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        applyTheme()
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
    
    private func applyTheme() {
        AppTheme.styleElevatedCard(containerView, cornerRadius: 20)
        containerView.backgroundColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.27, green: 0.30, blue: 0.37, alpha: 0.98)
            : .white
        titleLabel.textColor = .label
        timeLabel.textColor = AppTheme.accent
        timeLabel.backgroundColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.systemFill
    }
}
