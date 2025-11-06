//
//  OTPView.swift
//  iCohort3
//
//  Created by user@56 on 06/11/25.
//

import UIKit

class OTPView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
    
    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var otpStack: UIStackView!
    override func awakeFromNib() {
            super.awakeFromNib()
            setupUI()
        }
        
        private func setupUI() {
            // Initial confirm button color (light gray)
        
        
            confirmButton.layer.cornerRadius = confirmButton.frame.height / 2
            
                confirmButton.layer.masksToBounds = true
            for view in otpStack.arrangedSubviews {
                    view.layer.cornerRadius = 16
                    view.layer.borderWidth = 1
                    view.layer.borderColor = UIColor.lightGray.cgColor
                    view.layer.masksToBounds = true
                }
        }

}
