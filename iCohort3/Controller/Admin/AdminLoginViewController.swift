//
//  AdminLoginViewController.swift
//  iCohort3
//
//  SIMPLIFIED VERSION - Email and Password Only
//

import UIKit
import FirebaseAuth

class AdminLoginViewController: UIViewController {
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var emailView: UIView!
    @IBOutlet weak var passwordView: UIView!
    
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        
        // Auto-login if admin is already authenticated
        if Auth.auth().currentUser != nil {
            print("✅ Admin already logged in, navigating to dashboard")
            handleLoginSuccess()
        }
    }
    
    // MARK: - UI Setup
    func setupUI() {
        let radius: CGFloat = 20
        
        emailView?.layer.cornerRadius = radius
        emailView?.clipsToBounds = true
        
        passwordView?.layer.cornerRadius = radius
        passwordView?.clipsToBounds = true
        
        signInButton?.layer.cornerRadius = radius
        signInButton?.clipsToBounds = true
        
        registerButton?.layer.cornerRadius = radius
        registerButton?.clipsToBounds = true
        
        emailTextField.placeholder = "Enter admin email"
        passwordTextField.placeholder = "Enter password"
        passwordTextField.isSecureTextEntry = true
    }
    
    // MARK: - Navigation
    private func navigateToSignUp() {
        let signUpVC = AdminSignUpViewController(nibName: "AdminSignUpViewController", bundle: nil)
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    func handleLoginSuccess() {
        print("✅ Admin logged in successfully")
        
        // Navigate to Admin Approval Dashboard
        let approvalVC = AdminApprovalViewController()
        let navController = UINavigationController(rootViewController: approvalVC)
        navController.modalPresentationStyle = .fullScreen
        
        let window = view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        
        guard let window = window else { return }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = navController
            window.makeKeyAndVisible()
        }
    }
    
    // MARK: - Actions
    @IBAction func signInTapped(_ sender: UIButton) {
        print("\n===========================================")
        print("🎯 ADMIN LOGIN STARTED")
        print("===========================================")
        
        view.endEditing(true)
        
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !email.isEmpty else {
            print("❌ Validation failed: Email is empty")
            showAlert(title: "Error", message: "Please enter your email")
            return
        }
        print("✅ Email:", email)
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            print("❌ Validation failed: Password is empty")
            showAlert(title: "Error", message: "Please enter your password")
            return
        }
        print("✅ Password provided")
        
        print("\n🚀 Starting Firebase Auth login...")
        print("===========================================\n")
        
        signInButton.isEnabled = false
        showLoadingIndicator()
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            self.hideLoadingIndicator()
            self.signInButton.isEnabled = true
            
            if let error = error {
                print("\n❌ Firebase Auth LOGIN FAILED")
                print("Error code:", (error as NSError).code)
                print("Error domain:", (error as NSError).domain)
                print("Error description:", error.localizedDescription)
                print("Full error:", error)
                print("===========================================\n")
                
                self.showAlert(title: "Login Failed", message: error.localizedDescription)
                return
            }
            
            guard let user = result?.user else {
                print("\n❌ Login succeeded but no user returned")
                print("===========================================\n")
                
                self.showAlert(title: "Error", message: "Login failed")
                return
            }
            
            print("\n🎉 Firebase Auth LOGIN SUCCESS!")
            print("User ID:", user.uid)
            print("Email:", user.email ?? "N/A")
            print("Email verified:", user.isEmailVerified)
            print("===========================================\n")
            
            // Navigate to dashboard
            self.handleLoginSuccess()
        }
    }
    
    @IBAction func registerTapped(_ sender: Any) {
        print("Register button tapped. Navigating to AdminSignUpViewController.")
        navigateToSignUp()
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
    
    func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
