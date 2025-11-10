//
//  StatusCardCell.swift
//  iCohort3
//
//  Created by user@51 on 06/11/25.
//

import UIKit

class StatusCardCell: UICollectionViewCell {
    
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var editIndicator: UIButton!

    override func awakeFromNib() {
           super.awakeFromNib()
           
           // Rounded card style
           containerView.layer.cornerRadius = 16
           containerView.layer.masksToBounds = false
           containerView.layer.shadowColor = UIColor.black.cgColor
           containerView.layer.shadowOpacity = 0.08
           containerView.layer.shadowOffset = CGSize(width: 0, height: 3)
           containerView.layer.shadowRadius = 5
           
           // Default background color
           containerView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.9)
           
           // Make icon circular
           iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
           iconImageView.clipsToBounds = true
           iconImageView.tintColor = UIColor.systemBlue
           
           editIndicator.isHidden = true
           editIndicator.tintColor = .systemRed
           editIndicator.setImage(UIImage(systemName: "minus.circle.fill"), for: .normal)
       }
       
       override func layoutSubviews() {
           super.layoutSubviews()
           // Ensure the icon stays circular on rotation or resizing
           iconImageView.layer.cornerRadius = iconImageView.frame.width / 2
       }
       
       func configure(title: String, count: Int, isEditing: Bool) {
           titleLabel.text = title
           countLabel.text = "\(count)"
           
           // Toggle edit indicator
           editIndicator.isHidden = !isEditing
           
           // Add a small shake animation in editing mode (like Reminders app)
           if isEditing {
               startWiggle()
           } else {
               stopWiggle()
           }
       }
       
       // MARK: - Edit (Delete) Action
       @IBAction func deleteTapped(_ sender: UIButton) {
           print("🗑️ Delete tapped for \(titleLabel.text ?? "")")
       }
   }

   // MARK: - Wiggle Animation (Reminders style)
   extension StatusCardCell {
       
       private func startWiggle() {
           // Prevent duplicate animation
           guard containerView.layer.animation(forKey: "wiggle") == nil else { return }
           
           let angle = 0.02
           let wiggle = CAKeyframeAnimation(keyPath: "transform.rotation")
           wiggle.values = [-angle, angle]
           wiggle.autoreverses = true
           wiggle.duration = 0.15
           wiggle.repeatCount = Float.infinity
           containerView.layer.add(wiggle, forKey: "wiggle")
       }
       
       private func stopWiggle() {
           containerView.layer.removeAnimation(forKey: "wiggle")
       }
   }
