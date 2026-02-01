//
//  LoginViewController.swift
//  iCohort3
//
//  FIXED VERSION - Better error handling and loading states
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var containerView2: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var passwordVisibilityToggle: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var rememberMeButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    private var loadingIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func setupUI() {
        passwordTextField.isSecureTextEntry = true
        
        passwordVisibilityToggle.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        
        rememberMeButton.isSelected = false
        rememberMeButton.setImage(UIImage(systemName: "square"), for: .normal)
        rememberMeButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)
        
        signInButton.layer.cornerRadius = 20
        signInButton.layer.masksToBounds = true
        
        emailTextField.layer.cornerRadius = 0
        emailTextField.layer.masksToBounds = true
        
        passwordTextField.layer.cornerRadius = 0
        passwordTextField.layer.masksToBounds = true
        
        containerView.layer.cornerRadius = 23
        containerView.layer.masksToBounds = true
        
        containerView2.layer.cornerRadius = 23
        containerView2.layer.masksToBounds = true
    }
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
        
        if let nav = navigationController {
            nav.pushViewController(otpVC, animated: true)
        } else {
            otpVC.modalPresentationStyle = .fullScreen
            present(otpVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        
        if let nav = navigationController {
            nav.pushViewController(signUpVC, animated: true)
        } else {
            signUpVC.modalPresentationStyle = .fullScreen
            present(signUpVC, animated: true, completion: nil)
        }
    }
    
    @IBAction func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @IBAction func rememberMeTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
    }
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            return
        }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let userSelection = storyboard.instantiateViewController(withIdentifier: "UserSelectionVC") as? UserSelectionViewController {
            let navRoot = UINavigationController(rootViewController: userSelection)
            navRoot.modalPresentationStyle = .fullScreen
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                window.rootViewController = navRoot
                window.makeKeyAndVisible()
            } else if let window = view.window {
                window.rootViewController = navRoot
                window.makeKeyAndVisible()
            } else {
                present(navRoot, animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func signInTapped(_ sender: UIButton) {
        print("🔐 Sign In button tapped")
        
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address")
            return
        }
        
        guard let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter your password")
            return
        }
        
        signInButton.isEnabled = false
        showLoadingIndicator()
        
        performLogin(email: email, password: password)
    }
    
    private func performLogin(email: String, password: String) {
        Task {
            do {
                print("📝 Checking approval status for:", email)
                
                // First check if student is approved in Firestore
                let approvalStatus = try await FirebaseManager.shared.checkStudentApproval(email: email)
                
                print("📊 Approval status:", approvalStatus)
                
                switch approvalStatus {
                case .pending:
                    await MainActor.run {
                        hideLoadingIndicator()
                        signInButton.isEnabled = true
                        showAlert(title: "Pending Approval", message: "Your registration is still pending approval from your institute. Please wait for confirmation.")
                    }
                    return
                    
                case .declined:
                    await MainActor.run {
                        hideLoadingIndicator()
                        signInButton.isEnabled = true
                        showAlert(title: "Access Denied", message: "Your registration was declined by the institute. Please contact your administrator.")
                    }
                    return
                    
                case .approved:
                    print("✅ Student is approved, verifying password")
                    
                    // Verify password matches
                    let isValidPassword = try await FirebaseManager.shared.verifyApprovedStudent(email: email, password: password)
                    
                    guard isValidPassword else {
                        await MainActor.run {
                            hideLoadingIndicator()
                            signInButton.isEnabled = true
                            showAlert(title: "Login Failed", message: "Invalid email or password")
                        }
                        return
                    }
                    
                    print("✅ Password verified, logging in")
                    
                    await MainActor.run {
                        print("✅ Student login success (approved):", email)
                        
                        if rememberMeButton.isSelected {
                            UserDefaults.standard.set(true, forKey: "isLoggedIn")
                            UserDefaults.standard.set(email, forKey: "userEmail")
                        }
                        
                        hideLoadingIndicator()
                        signInButton.isEnabled = true
                        handleLoginSuccess()
                    }
                }
                
            } catch FirebaseManagerError.studentNotFound {
                print("❌ Error: Student not found")
                await MainActor.run {
                    hideLoadingIndicator()
                    signInButton.isEnabled = true
                    showAlert(title: "Not Registered", message: "This email is not registered. Please sign up first.")
                }
                
            } catch {
                print("❌ Login error:", error.localizedDescription)
                await MainActor.run {
                    hideLoadingIndicator()
                    signInButton.isEnabled = true
                    showAlert(title: "Login Failed", message: "An error occurred: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func handleLoginSuccess() {
        let tab = MainTabBarViewController()
        
        let win = view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        
        guard let window = win else { return }
        
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = tab
        }
    }
    
    // MARK: - Helper Methods
    
    private func showLoadingIndicator() {
        // Remove any existing indicator first
        hideLoadingIndicator()
        
        DispatchQueue.main.async {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .systemBlue
            indicator.center = self.view.center
            indicator.startAnimating()
            
            // Add backdrop
            let backdrop = UIView(frame: self.view.bounds)
            backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.3)
            backdrop.tag = 9999
            backdrop.addSubview(indicator)
            
            self.view.addSubview(backdrop)
            self.view.isUserInteractionEnabled = false
            
            self.loadingIndicator = indicator
            
            print("🔄 Loading indicator shown")
        }
    }
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            // Remove backdrop
            self.view.viewWithTag(9999)?.removeFromSuperview()
            
            // Remove indicator
            self.loadingIndicator?.stopAnimating()
            self.loadingIndicator?.removeFromSuperview()
            self.loadingIndicator = nil
            
            self.view.isUserInteractionEnabled = true
            
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
