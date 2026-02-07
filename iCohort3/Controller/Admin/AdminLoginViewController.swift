//
//  AdminLoginViewController.swift
//  iCohort3
//
//  ✅ SUPABASE ONLY - No Firebase dependencies
//

import UIKit

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
        
        let dashboardVC = AdminDashboardViewController()
        navigationController?.pushViewController(dashboardVC, animated: true)
    }
    
    // MARK: - Actions
    @IBAction func signInTapped(_ sender: UIButton) {
        print("\n===========================================")
        print("🎯 ADMIN LOGIN STARTED (SUPABASE)")
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
        
        print("\n🚀 Starting Supabase authentication...")
        print("===========================================\n")
        
        signInButton.isEnabled = false
        showLoadingIndicator()
        
        Task {
            do {
                // ✅ Verify admin credentials in Supabase
                let isValid = try await SupabaseManager.shared.verifyAdmin(email: email, password: password)
                
                guard isValid else {
                    await MainActor.run {
                        self.hideLoadingIndicator()
                        self.signInButton.isEnabled = true
                        self.showAlert(title: "Login Failed", message: "Invalid email or password")
                    }
                    return
                }
                
                print("✅ Admin credentials verified")
                
                // Get institute info
                if let institute = try await SupabaseManager.shared.getInstitute(byAdminEmail: email) {
                    print("✅ Institute found:", institute.name)
                    
                    // Store session
                    UserDefaults.standard.set(email, forKey: "admin_email")
                    UserDefaults.standard.set(institute.name, forKey: "admin_institute_name")
                    UserDefaults.standard.set(institute.domain, forKey: "admin_institute_domain")
                    UserDefaults.standard.set(true, forKey: "is_admin")
                }
                
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.signInButton.isEnabled = true
                    self.handleLoginSuccess()
                }
                
            } catch {
                print("❌ Login error:", error.localizedDescription)
                
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.signInButton.isEnabled = true
                    self.showAlert(title: "Login Failed", message: error.localizedDescription)
                }
            }
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
