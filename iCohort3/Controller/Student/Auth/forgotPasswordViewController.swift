//
//  forgotPasswordViewController.swift
//  iCohort3
//
//  ✅ Updated to work with custom OTP system
//  ✅ Only updates database password (no Auth dependency)
//

import UIKit

class forgotPasswordViewController: UIViewController {

    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var confirmPassword: UIView!
    @IBOutlet weak var passwordContainer: UIView!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    
    private var loadingIndicator: UIActivityIndicatorView?
    private var role: SupabaseManager.PasswordResetUserRole = .student

    func configure(role: SupabaseManager.PasswordResetUserRole) {
        self.role = role
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlaceholders()
        confirmButton.backgroundColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
        confirmButton.setTitleColor(.white, for: .normal)
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
        view.endEditing(true)
        
        // Validate inputs
        guard let newPassword = newPasswordTextField.text, !newPassword.isEmpty else {
            showAlert(title: "Error", message: "Please enter a new password")
            return
        }
        
        guard let confirmPasswordText = confirmPasswordTextField.text, !confirmPasswordText.isEmpty else {
            showAlert(title: "Error", message: "Please confirm your password")
            return
        }
        
        // Check if passwords match
        guard newPassword == confirmPasswordText else {
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }
        
        // Validate password strength
        guard newPassword.count >= 6 else {
            showAlert(title: "Weak Password", message: "Password must be at least 6 characters")
            return
        }
        
        // Get email from UserDefaults
        guard let email = UserDefaults.standard.string(forKey: "forgot_password_email") else {
            showAlert(title: "Error", message: "Session expired. Please start the process again.")
            return
        }
        
        // Disable button and show loading
        confirmButton.isEnabled = false
        showLoadingIndicator()
        
        // ✅ Update password using custom system (database only)
        updatePassword(email: email, newPassword: newPassword)
    }
    
    private func updatePassword(email: String, newPassword: String) {
        Task {
            do {
                print("\n===========================================")
                print("📝 UPDATING PASSWORD (CUSTOM SYSTEM)")
                print("===========================================")
                print("Email:", email)
                
                try await SupabaseManager.shared.updatePassword(email: email, newPassword: newPassword, role: role)
                
                print("✅ Password updated successfully in database")
                
                // ✅ Clean up OTP from database
                try await SupabaseManager.shared.deleteOTP(email: email)
                
                print("✅ OTP cleaned up")
                print("===========================================\n")
                
                // Clear stored email
                UserDefaults.standard.removeObject(forKey: "forgot_password_email")
                UserDefaults.standard.removeObject(forKey: "forgot_password_role")
                
                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    
                    // Show success message and navigate to login
                    showAlert(
                        title: "Success",
                        message: "Your password has been reset successfully. Please login with your new password."
                    ) {
                        self.navigateToLogin()
                    }
                }
                
            } catch {
                print("❌ Password update error:", error.localizedDescription)
                print("===========================================\n")
                
                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    showAlert(title: "Error", message: "Failed to update password. Please try again.")
                }
            }
        }
    }
    
    private func navigateToLogin() {
        print("Navigating to login screen")
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC: UIViewController

        switch role {
        case .student:
            guard let vc = storyboard.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController else {
                print("❌ Could not load SLoginVC")
                return
            }
            loginVC = vc
        case .mentor:
            guard let vc = storyboard.instantiateViewController(withIdentifier: "MLoginVC") as? MLoginSignUpViewController else {
                print("❌ Could not load MLoginVC")
                return
            }
            loginVC = vc
        case .admin:
            loginVC = AdminLoginViewController(nibName: "AdminLoginViewController", bundle: nil)
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

    @objc private func backTapped() {
        print("Back button tapped")
        
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func showLoadingIndicator() {
        hideLoadingIndicator()
        
        DispatchQueue.main.async {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
            indicator.center = self.view.center
            indicator.startAnimating()
            
            let backdrop = UIView(frame: self.view.bounds)
            backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            backdrop.tag = 9999
            backdrop.addSubview(indicator)
            
            self.view.addSubview(backdrop)
            self.view.isUserInteractionEnabled = false
            
            self.loadingIndicator = indicator
        }
    }
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.view.viewWithTag(9999)?.removeFromSuperview()
            self.loadingIndicator?.stopAnimating()
            self.loadingIndicator?.removeFromSuperview()
            self.loadingIndicator = nil
            self.view.isUserInteractionEnabled = true
        }
    }
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
            self.present(alert, animated: true)
        }
    }
}
