//
//  AdminSignUpViewController.swift
//  iCohort3
//
//  SIMPLIFIED VERSION - Email and Password Only
//

import UIKit
import FirebaseAuth

class AdminSignUpViewController: UIViewController {
    
    @IBOutlet weak var mailView: UIView!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var passView: UIView!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var confirmPassView: UIView!
    @IBOutlet weak var confirmPassTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    
    private var loadingIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupPlaceholders()
    }
    
    // MARK: - UI Setup
    func setupUI() {
        let radius: CGFloat = 20
        
        // Apply corner radius to all views
        let views = [mailView, passView, confirmPassView]
        
        for view in views {
            view?.layer.cornerRadius = radius
            view?.clipsToBounds = true
        }
        
        registerButton?.layer.cornerRadius = radius
        registerButton?.clipsToBounds = true
    }
    
    func setupPlaceholders() {
        mailTextField.placeholder = "Enter admin email"
        passTextField.placeholder = "Enter password"
        confirmPassTextField.placeholder = "Confirm password"
        
        // Make password fields secure
        passTextField.isSecureTextEntry = true
        confirmPassTextField.isSecureTextEntry = true
    }

    @IBAction func registerButton(_ sender: Any) {
        print("\n===========================================")
        print("🎯 ADMIN REGISTRATION STARTED")
        print("===========================================")
        
        view.endEditing(true)
        
        guard let email = mailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !email.isEmpty else {
            print("❌ Validation failed: Email is empty")
            showAlert(title: "Error", message: "Please enter admin email")
            return
        }
        print("✅ Email:", email)
        
        guard let password = passTextField.text, !password.isEmpty else {
            print("❌ Validation failed: Password is empty")
            showAlert(title: "Error", message: "Please enter password")
            return
        }
        print("✅ Password length:", password.count)
        
        guard let confirmPassword = confirmPassTextField.text, !confirmPassword.isEmpty else {
            print("❌ Validation failed: Confirm password is empty")
            showAlert(title: "Error", message: "Please confirm password")
            return
        }
        
        guard password == confirmPassword else {
            print("❌ Validation failed: Passwords don't match")
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }
        print("✅ Passwords match")
        
        guard password.count >= 6 else {
            print("❌ Validation failed: Password too short")
            showAlert(title: "Weak Password", message: "Password must be at least 6 characters")
            return
        }
        print("✅ Password strength validated")
        
        print("\n🚀 All validations passed!")
        print("📝 Starting Firebase Auth registration...")
        print("===========================================\n")
        
        (sender as? UIButton)?.isEnabled = false
        showLoadingIndicator()
        
        // Create Firebase Auth user
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                print("\n❌ Firebase Auth FAILED")
                print("Error code:", (error as NSError).code)
                print("Error domain:", (error as NSError).domain)
                print("Error description:", error.localizedDescription)
                print("Full error:", error)
                print("===========================================\n")
                
                self.hideLoadingIndicator()
                (sender as? UIButton)?.isEnabled = true
                self.showAlert(title: "Signup Failed", message: error.localizedDescription)
                return
            }
            
            guard let user = result?.user else {
                print("\n❌ Firebase Auth succeeded but no user returned")
                print("===========================================\n")
                
                self.hideLoadingIndicator()
                (sender as? UIButton)?.isEnabled = true
                self.showAlert(title: "Error", message: "Failed to create admin account")
                return
            }
            
            print("\n🎉 Firebase Auth SUCCESS!")
            print("User ID:", user.uid)
            print("Email:", user.email ?? "N/A")
            print("===========================================\n")
            
            // Send verification email
            user.sendEmailVerification { emailError in
                if let emailError = emailError {
                    print("⚠️  Email verification send failed:", emailError.localizedDescription)
                } else {
                    print("✅ Verification email sent")
                }
            }
            
            self.hideLoadingIndicator()
            (sender as? UIButton)?.isEnabled = true
            
            self.showAlert(
                title: "Success",
                message: "Admin account created successfully. You can now login."
            ) {
                print("✅ Navigating back to login")
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @IBAction func backButton(_ sender: Any) {
        if let navigationController = navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: - Helper Methods
    
    private func showLoadingIndicator() {
        DispatchQueue.main.async {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.center = self.view.center
            indicator.startAnimating()
            self.view.addSubview(indicator)
            self.view.isUserInteractionEnabled = false
            self.loadingIndicator = indicator
            print("🔄 Loading indicator shown")
        }
    }
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.loadingIndicator?.stopAnimating()
            self.loadingIndicator?.removeFromSuperview()
            self.view.isUserInteractionEnabled = true
            self.loadingIndicator = nil
            print("✋ Loading indicator hidden")
        }
    }
    
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                completion?()
            })
            self.present(alert, animated: true)
        }
    }
}
