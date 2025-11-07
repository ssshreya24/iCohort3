//
//  forgotPassword.swift
//  iCohort3
//
//  Created by user@56 on 06/11/25.
//

import UIKit

class forgotPassword: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
  
    @IBOutlet weak var confirmPasswordContainer: UIView!
    @IBOutlet weak var passwordContainer: UIView!
    
    @IBOutlet weak var confirmButton: UIButton!
    override func awakeFromNib() {
            super.awakeFromNib()
            setupUI()
        }
        
        private func setupUI() {
            // Initial confirm button color (light gray)
        
        
            passwordContainer.layer.cornerRadius = 20
            passwordContainer.layer.masksToBounds = true
            passwordContainer.backgroundColor = UIColor.white

            confirmPasswordContainer.layer.cornerRadius = 20
            confirmPasswordContainer.layer.masksToBounds = true
            confirmPasswordContainer.backgroundColor = UIColor.white

            confirmButton.layer.cornerRadius = 20
            confirmButton.layer.masksToBounds = true
                }
        }


