//
//  EmailVerificationViewController.swift
//  iCohort3
//
//  ✅ SUPABASE AUTH - Sends password reset email with OTP
//  ✅ Programmatic UI - No XIB needed
//  Maintains app consistency: Button #779CB3, BG #EFEFF5
//

import UIKit

class EmailVerificationViewController: UIViewController {
    
    // UI Elements
    private let backButton = UIButton(type: .system)
    private let logoImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let emailContainer = UIView()
    private let emailIcon = UIImageView()
    private let emailTextField = UITextField()
    private let sendOTPButton = UIButton(type: .system)
    
    private var loadingIndicator: UIActivityIndicatorView?
    private let requiredDomain = "srmist.edu.in"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    private func setupUI() {
        // Background color
        view.backgroundColor = UIColor(red: 0xEF/255, green: 0xEF/255, blue: 0xF5/255, alpha: 1)
        
        // Back Button
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let backImage = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(backImage, for: .normal)
        backButton.tintColor = .black
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 22
        backButton.layer.masksToBounds = true
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Logo ImageView
        logoImageView.image = UIImage(named: "logo")
        logoImageView.contentMode = .scaleAspectFit
        view.addSubview(logoImageView)
        
        // Title Label
        titleLabel.text = "Forgot Password?"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 26)
        titleLabel.textColor = .black
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        // Subtitle Label
        subtitleLabel.text = "Enter your registered email to receive OTP"
        subtitleLabel.font = UIFont.systemFont(ofSize: 15)
        subtitleLabel.textColor = UIColor(white: 0.33, alpha: 1)
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        view.addSubview(subtitleLabel)
        
        // Email Container
        emailContainer.backgroundColor = .white
        emailContainer.layer.cornerRadius = 20
        emailContainer.layer.masksToBounds = true
        view.addSubview(emailContainer)
        
        // Email Icon
        emailIcon.image = UIImage(systemName: "envelope")
        emailIcon.tintColor = UIColor(white: 0.33, alpha: 1)
        emailIcon.contentMode = .scaleAspectFit
        emailContainer.addSubview(emailIcon)
        
        // Email TextField
        emailTextField.placeholder = "Enter your registered email"
        emailTextField.textColor = .black
        emailTextField.font = UIFont.systemFont(ofSize: 16)
        emailTextField.keyboardType = .emailAddress
        emailTextField.autocapitalizationType = .none
        emailTextField.autocorrectionType = .no
        emailContainer.addSubview(emailTextField)
        
        // Send OTP Button
        sendOTPButton.setTitle("Send OTP", for: .normal)
        sendOTPButton.setTitleColor(.white, for: .normal)
        sendOTPButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        sendOTPButton.backgroundColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
        sendOTPButton.layer.cornerRadius = 20
        sendOTPButton.layer.masksToBounds = true
        sendOTPButton.addTarget(self, action: #selector(sendOTPTapped), for: .touchUpInside)
        view.addSubview(sendOTPButton)
        
        // Add shadow to button
        sendOTPButton.layer.shadowColor = UIColor.black.cgColor
        sendOTPButton.layer.shadowOpacity = 0.15
        sendOTPButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        sendOTPButton.layer.shadowRadius = 8
        sendOTPButton.layer.masksToBounds = false
    }
    
    private func setupConstraints() {
        backButton.translatesAutoresizingMaskIntoConstraints = false
        logoImageView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        emailContainer.translatesAutoresizingMaskIntoConstraints = false
        emailIcon.translatesAutoresizingMaskIntoConstraints = false
        emailTextField.translatesAutoresizingMaskIntoConstraints = false
        sendOTPButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            // Back Button
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Logo
            logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            logoImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 91),
            logoImageView.widthAnchor.constraint(equalToConstant: 200),
            logoImageView.heightAnchor.constraint(equalToConstant: 150),
            
            // Title
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            titleLabel.topAnchor.constraint(equalTo: logoImageView.bottomAnchor, constant: 30),
            
            // Subtitle
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            
            // Email Container
            emailContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            emailContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            emailContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 30),
            emailContainer.heightAnchor.constraint(equalToConstant: 56),
            
            // Email Icon
            emailIcon.leadingAnchor.constraint(equalTo: emailContainer.leadingAnchor, constant: 20),
            emailIcon.centerYAnchor.constraint(equalTo: emailContainer.centerYAnchor),
            emailIcon.widthAnchor.constraint(equalToConstant: 24),
            emailIcon.heightAnchor.constraint(equalToConstant: 24),
            
            // Email TextField
            emailTextField.leadingAnchor.constraint(equalTo: emailIcon.trailingAnchor, constant: 10),
            emailTextField.trailingAnchor.constraint(equalTo: emailContainer.trailingAnchor, constant: -10),
            emailTextField.centerYAnchor.constraint(equalTo: emailContainer.centerYAnchor),
            emailTextField.heightAnchor.constraint(equalToConstant: 40),
            
            // Send OTP Button
            sendOTPButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            sendOTPButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            sendOTPButton.topAnchor.constraint(equalTo: emailContainer.bottomAnchor, constant: 40),
            sendOTPButton.heightAnchor.constraint(equalToConstant: 54)
        ])
    }
    
    @objc private func backButtonTapped() {
        print("Email verification back tapped")
        
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func sendOTPTapped() {
        view.endEditing(true)
        
        // Validate email
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address")
            return
        }
        
        // Validate email format
        guard email.contains("@"), email.contains(".") else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address")
            return
        }
        
        // Validate domain
        guard email.hasSuffix("@" + requiredDomain) else {
            showAlert(title: "Invalid Email", message: "Email must end with @\(requiredDomain)")
            return
        }
        
        // Disable button and show loading
        sendOTPButton.isEnabled = false
        showLoadingIndicator()
        
        // Verify email exists and send OTP
        verifyEmailAndSendOTP(email: email)
    }
    
    private func verifyEmailAndSendOTP(email: String) {
        Task {
            do {
                print("📝 Verifying email in Supabase:", email)
                
                // ✅ Check if student exists in Supabase student_profiles table
                let studentExists = try await SupabaseManager.shared.verifyStudentExists(email: email)
                
                guard studentExists else {
                    await MainActor.run {
                        hideLoadingIndicator()
                        sendOTPButton.isEnabled = true
                        showAlert(title: "Email Not Found", message: "This email is not registered. Please sign up first or check your email address.")
                    }
                    return
                }
                
                print("✅ Email found in student_profiles")
                
                // ✅ Send password reset email using Supabase Auth
                try await SupabaseManager.shared.sendPasswordResetEmail(email: email)
                
                print("✅ Password reset email sent successfully")
                
                // Store email for later use
                UserDefaults.standard.set(email, forKey: "forgot_password_email")
                
                await MainActor.run {
                    hideLoadingIndicator()
                    sendOTPButton.isEnabled = true
                    
                    // Navigate to OTP screen
                    let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
                    
                    if let nav = navigationController {
                        nav.pushViewController(otpVC, animated: true)
                    } else {
                        otpVC.modalPresentationStyle = .fullScreen
                        present(otpVC, animated: true)
                    }
                    
                    // Show success message
                    showAlert(title: "OTP Sent", message: "A 6-digit OTP has been sent to your email. Please check your inbox.")
                }
                
            } catch {
                print("❌ Email verification error:", error.localizedDescription)
                await MainActor.run {
                    hideLoadingIndicator()
                    sendOTPButton.isEnabled = true
                    showAlert(title: "Error", message: "Failed to send OTP. Please try again.")
                }
            }
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
            
            print("🔄 Loading indicator shown")
        }
    }
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.view.viewWithTag(9999)?.removeFromSuperview()
            
            self.loadingIndicator?.stopAnimating()
            self.loadingIndicator?.removeFromSuperview()
            self.loadingIndicator = nil
            
            self.view.isUserInteractionEnabled = true
            
            print("✋ Loading indicator hidden")
        }
    }
    
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
}
