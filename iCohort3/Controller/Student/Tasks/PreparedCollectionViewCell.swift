////
////  PreparedCollectionViewCell.swift
////  iCohort3
////
////  Created by user@56 on 12/11/25.
////
//
//import UIKit
//
//class PreparedCollectionViewCell: UICollectionViewCell {
//
//    @IBOutlet weak var circleButton: UIButton!
//    @IBOutlet weak var titleLabel: UILabel!
//    @IBOutlet weak var descriptionLabel: UILabel!
//    @IBOutlet weak var profileImageView: UIImageView!
//    @IBOutlet weak var assignedLabel: UILabel!
//    @IBOutlet weak var dueDateLabel: UILabel!
//    @IBOutlet weak var nameLabel: UILabel!         // "Shreya"
//    @IBOutlet weak var separatorView: UIView!
//    
//    @IBOutlet weak var cardView: UIView!   // 👈 new IBOutlet
//    
//    private var gradientLayer: CAGradientLayer?
//    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        setupUI()
//    }
//    
//    private func setupUI() {
//        cardView.layer.cornerRadius = 15
//        cardView.layer.masksToBounds = false
//        cardView.backgroundColor = .white
//        cardView.layer.shadowColor = UIColor.black.cgColor
//        cardView.layer.shadowOpacity = 0.1
//        cardView.layer.shadowOffset = CGSize(width: 0, height: 3)
//        cardView.layer.shadowRadius = 6
//        
//        // Profile image setup
//        profileImageView.layer.cornerRadius = profileImageView.frame.width / 2
//        profileImageView.clipsToBounds = true
//        
//        // Separator line
//        separatorView.backgroundColor = .systemGray5
//        
//        // Label styles
//        assignedLabel.textColor = .systemGray3
//        assignedLabel.font = UIFont.systemFont(ofSize: 13)
//        
//        nameLabel.font = UIFont.systemFont(ofSize: 15, weight: .medium)
//        nameLabel.textColor = .label
//        
//        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
//        descriptionLabel.font = UIFont.systemFont(ofSize: 14)
//        descriptionLabel.textColor = .darkGray
//    }
//    
//    func configure(title: String, desc: String, image: UIImage?, name: String) {
//        titleLabel.text = title
//        descriptionLabel.text = desc
//        profileImageView.image = image
//        assignedLabel.text = "Assigned To"
//        nameLabel.text = name
//        dueDateLabel.text = "Due Date: 03 Nov 2025"
//    }
//}
