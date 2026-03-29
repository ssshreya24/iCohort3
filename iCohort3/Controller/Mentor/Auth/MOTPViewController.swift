//
//  MOTPViewController.swift
//

import UIKit

class MOTPViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var otpStack: UIStackView!
    @IBOutlet weak var confirmButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        // ensure your custom back button is wired to backButtonTapped in XIB
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide system nav bar so only custom button shows
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
        // Debug print to see nav presence
        print("OTP back tapped, nav:", navigationController as Any)
        navigationController?.popViewController(animated: true)
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        // push forget password so it sits on the same nav stack
        let forgotVC = MForgetPasswordViewController(nibName: "MForgetPasswordViewController", bundle: nil)
        navigationController?.pushViewController(forgotVC, animated: true)
    }
}
