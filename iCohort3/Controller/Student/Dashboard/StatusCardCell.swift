//
//  StatusCardCell.swift
//  iCohort3
//
//  Created by user@51 on 06/11/25.
//

import UIKit

enum StatusCardMode {
    case normal
    case editing      // show minus icon
    case add          // show plus icon
}

class StatusCardCell: UICollectionViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var actionButton: UIButton!   // 🔥 Only one button now
    
    private var currentMode: StatusCardMode = .normal

    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.backgroundColor = .clear
        self.contentView.backgroundColor = .clear
        
        applyFloatingCardStyle()
        
        iconImageView.clipsToBounds = true
        iconImageView.contentMode = .scaleAspectFit
        titleLabel.textColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        }
        countLabel.textColor = .label
        
        actionButton.isHidden = true
        actionButton.tintColor = .systemRed
        actionButton.layer.zPosition = 10
    }

    override var isHighlighted: Bool {
        didSet {
            animateFloatingState()
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
        containerView.layer.shadowPath = UIBezierPath(
            roundedRect: containerView.bounds,
            cornerRadius: containerView.layer.cornerRadius
        ).cgPath
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyFloatingCardStyle()
        }
    }
    
    func configure(iconName: String?, title: String?, count: Int?, mode: StatusCardMode) {
        currentMode = mode
        
        switch mode {
            
        case .normal:
            titleLabel.text = title
            countLabel.text = count.map { "\($0)" } ?? ""
            
            iconImageView.isHidden = false
            if let icon = iconName {
                iconImageView.image = UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate)
            }
            
            actionButton.isHidden = true
            stopWiggle()
            
        case .editing:
            titleLabel.text = title
            countLabel.text = count.map { "\($0)" } ?? ""
            
            iconImageView.isHidden = false
            if let icon = iconName {
                iconImageView.image = UIImage(systemName: icon)?.withRenderingMode(.alwaysTemplate)
            }
            
            actionButton.isHidden = false
            actionButton.tintColor = .systemRed
            actionButton.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
            
            startWiggle()
            
        case .add:
            titleLabel.text = title ?? "Add"
            countLabel.text = ""
            iconImageView.isHidden = true
            
            actionButton.isHidden = false
            actionButton.tintColor = .systemGreen
            actionButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
            
            stopWiggle()
        }
    }
    
    // MARK: - Action Button
    @IBAction func actionButtonTapped(_ sender: UIButton) {
        switch currentMode {
        case .editing:
            NotificationCenter.default.post(name: .statusCardDeleteTapped, object: self)
        case .add:
            NotificationCenter.default.post(name: .statusCardAddTapped, object: self)
        case .normal:
            break
        }
    }
    
    // MARK: - Wiggle Animation (Reminders-style)
    private func startWiggle() {
        if containerView.layer.animation(forKey: "wiggle") != nil { return }
        
        let angle = 0.02
        let wiggle = CAKeyframeAnimation(keyPath: "transform.rotation")
        wiggle.values = [-angle, angle]
        wiggle.autoreverses = true
        wiggle.duration = 0.12
        wiggle.repeatCount = .infinity
        containerView.layer.add(wiggle, forKey: "wiggle")
        
        let nudge = CAKeyframeAnimation(keyPath: "transform.translation.x")
        nudge.values = [-1.5, 1.5]
        nudge.autoreverses = true
        nudge.duration = 0.12
        nudge.repeatCount = .infinity
        containerView.layer.add(nudge, forKey: "nudge")
    }
    
    private func stopWiggle() {
        containerView.layer.removeAnimation(forKey: "wiggle")
        containerView.layer.removeAnimation(forKey: "nudge")
    }

    private func applyFloatingCardStyle() {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let darkCardColor = UIColor(red: 0.27, green: 0.30, blue: 0.37, alpha: 0.98)

        containerView.layer.cornerRadius = 16
        containerView.layer.masksToBounds = false
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppTheme.borderColor.resolvedColor(with: traitCollection).cgColor
        containerView.backgroundColor = isDarkMode
            ? darkCardColor
            : .white

        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOpacity = isDarkMode ? 0.10 : 0.0
        containerView.layer.shadowOffset = CGSize(width: 0, height: 3)
        containerView.layer.shadowRadius = isDarkMode ? 8 : 0

        titleLabel.textColor = isDarkMode ? .white : .black
        countLabel.textColor = isDarkMode ? .white : .black
    }

    private func animateFloatingState() {
        UIView.animate(withDuration: 0.18,
                       delay: 0,
                       usingSpringWithDamping: 0.86,
                       initialSpringVelocity: 0.6,
                       options: [.allowUserInteraction, .beginFromCurrentState]) {
            if self.isHighlighted {
                self.containerView.transform = CGAffineTransform(translationX: 0, y: -4).scaledBy(x: 0.985, y: 0.985)
                self.containerView.layer.shadowOpacity = self.traitCollection.userInterfaceStyle == .dark ? 0.14 : 0.04
            } else {
                self.containerView.transform = .identity
                self.containerView.layer.shadowOpacity = self.traitCollection.userInterfaceStyle == .dark ? 0.10 : 0.0
            }
        }
    }
}

extension Notification.Name {
    static let statusCardDeleteTapped = Notification.Name("StatusCardDeleteTapped")
    static let statusCardAddTapped = Notification.Name("StatusCardAddTapped")
}
