//
//  OTPViewController.swift
//  iCohort3
//
//  Created by user@56 on 07/11/25.
//

//
//  OTPViewController.swift
//  forgotPassword
//
//  Created by user@56 on 07/11/25.
//

import UIKit

class OTPViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var otpStack: UIStackView!
    @IBOutlet weak var confirmButton: UIButton!
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI Setup
    private func setupUI() {
        // Round the confirm button
        confirmButton.layer.cornerRadius = confirmButton.frame.height / 2
        confirmButton.layer.masksToBounds = true

        // Style each OTP box inside the stack view
        for view in otpStack.arrangedSubviews {
            view.layer.cornerRadius = 16
            view.layer.borderWidth = 1
            view.layer.borderColor = UIColor.lightGray.cgColor
            view.layer.masksToBounds = true
        }
    }

    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: UIButton) {
        // Go back to previous screen
        backButton.tintColor = .white
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        print("Confirm button tapped")
        let forgotVC = forgotPasswordViewController(nibName: "forgotPasswordViewController", bundle: nil)
               forgotVC.modalPresentationStyle = .fullScreen
               present(forgotVC, animated: true, completion: nil)
        // Add OTP validation logic here
    }
}
