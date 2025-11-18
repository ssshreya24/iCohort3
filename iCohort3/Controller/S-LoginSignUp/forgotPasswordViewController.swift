//
//  forgotPasswordViewController.swift
//  iCohort3
//
//  Created by user@56 on 07/11/25.
//

import UIKit

class forgotPasswordViewController: UIViewController {

    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var confirmPassword: UIView!
    @IBOutlet weak var passwordContainer: UIView!

    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlaceholders()
        confirmButton.tintColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupPlaceholders() {
        newPasswordTextField.placeholder = "Enter the new password"
        confirmPasswordTextField.placeholder = "Confirm the new password"
        newPasswordTextField.textColor = .black
        confirmPasswordTextField.textColor = .black
        newPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
    }

    private func setupUI() {
        passwordContainer.layer.cornerRadius = 20
        passwordContainer.layer.masksToBounds = true
        passwordContainer.backgroundColor = .white
        confirmPassword.layer.cornerRadius = 20
        confirmPassword.layer.masksToBounds = true
        confirmButton.layer.cornerRadius = 20
        confirmButton.layer.masksToBounds = true
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        print("Confirm button tapped - Password reset successful")

        // Always navigate to LoginViewController and replace window root
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = storyboard.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController else {
            print("❌ Could not load SLoginVC")
            return
        }

        // Wrap in navigation controller
        let navController = UINavigationController(rootViewController: loginVC)
        navController.modalPresentationStyle = .fullScreen

        // Replace window root
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            window.rootViewController = navController
            window.makeKeyAndVisible()
            return
        } else if let window = view.window {
            window.rootViewController = navController
            window.makeKeyAndVisible()
            return
        }

        // Fallback: present modally
        present(navController, animated: true, completion: nil)
    }

    // robust back: pop if possible; otherwise dismiss modally
    @objc private func backTapped() {
        print("Back button tapped")
        
        if let nav = navigationController, nav.viewControllers.count > 1 {
            // We're in a nav stack and not at root
            nav.popViewController(animated: true)
            return
        }
        
        // Otherwise dismiss modally
        dismiss(animated: true, completion: nil)
    }
}
