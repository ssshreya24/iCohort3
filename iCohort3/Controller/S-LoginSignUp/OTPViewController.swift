//
//  OTPViewController.swift
//  iCohort3
//
//  Created by user@56 on 07/11/25.
//

import UIKit

class OTPViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var otpStack: UIStackView!
    @IBOutlet weak var confirmButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        backButton.tintColor = .white
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupUI() {
        confirmButton.layer.cornerRadius = confirmButton.frame.height / 2
        confirmButton.layer.masksToBounds = true

        for view in otpStack.arrangedSubviews {
            view.layer.cornerRadius = 16
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.lightGray.cgColor
            view.layer.masksToBounds = true
        }
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        print("OTP back tapped, nav:", navigationController as Any)
        
        // Try navigation pop first
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            return
        }
        
        // If no navigation controller or we're the root, dismiss modally
        dismiss(animated: true, completion: nil)
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        print("Confirm button tapped")
        
        let forgotVC = forgotPasswordViewController(nibName: "forgotPasswordViewController", bundle: nil)
        
        // Try to push if we have a navigation controller
        if let nav = navigationController {
            nav.pushViewController(forgotVC, animated: true)
        } else {
            // Otherwise present modally
            forgotVC.modalPresentationStyle = .fullScreen
            present(forgotVC, animated: true, completion: nil)
        }
    }
}
