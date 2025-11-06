//
//  forgotPasswordViewController.swift
//  iCohort3
//
//  Created by user@56 on 06/11/25.
//

import UIKit

class forgotPasswordViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let forgotPasswordView = Bundle.main.loadNibNamed("forgotPassword", owner: nil, options: nil)?.first as? forgotPassword {
            forgotPasswordView.frame = view.bounds
            forgotPasswordView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(forgotPasswordView)
        }
    }
}

