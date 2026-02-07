//
//  SignUpViewController.swift
//  iCohort3
//
//  ✅ SUPABASE ONLY - No Firebase dependencies
//

import UIKit

class SignUpViewController: UIViewController {
    @IBOutlet weak var fullNameContainer: UIView!
    @IBOutlet weak var emailContainer: UIView!
    @IBOutlet weak var regContainer: UIView!
    @IBOutlet weak var passwordContainer: UIView!
    @IBOutlet weak var confirmContainer: UIView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var regField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!
    
    // Required domain for SRM students
    private let requiredDomain = "srmist.edu.in"
    
    private var loadingIndicator: UIActivityIndicatorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
        roundViews()
        setupPlaceholders()
    }
    
    func setupPlaceholders() {
        fullNameField.placeholder = "Enter your full name"
        emailField.placeholder = "Enter your email (@srmist.edu.in)"
        regField.placeholder = "Enter your registration number"
        passwordField.placeholder = "Enter your password"
        confirmField.placeholder = "Confirm your password"
        
        passwordField.isSecureTextEntry = true
        confirmField.isSecureTextEntry = true
    }
    
    func roundViews() {
        let containers = [fullNameContainer, emailContainer, regContainer, passwordContainer, confirmContainer]
        
        for view in containers {
            view?.layer.cornerRadius = 20
            view?.layer.borderWidth  = 0
            view?.layer.borderColor  = UIColor.systemGray4.cgColor
            view?.layer.masksToBounds = true
            view?.backgroundColor    = .white
        }
        
        signUpButton.layer.cornerRadius = 20
        signUpButton.layer.masksToBounds = true
        signUpButton.backgroundColor = UIColor(named: "Primary")
        
        signUpButton.layer.shadowColor = UIColor.black.cgColor
        signUpButton.layer.shadowOpacity = 0.15
        signUpButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        signUpButton.layer.shadowRadius = 8
        signUpButton.layer.masksToBounds = false
    }
    
    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(image, for: .normal)
        
        backButton.tintColor = UIColor.black
        backButton.backgroundColor = UIColor.white
        backButton.layer.cornerRadius = 22
        backButton.layer.masksToBounds = true
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    
    @objc private func backTapped() {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func signUpTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        // Validate all fields
        guard let name = fullNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert(title: "Error", message: "Please enter your full name")
            return
        }
        
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address")
            return
        }
        
        guard let reg = regField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !reg.isEmpty else {
            showAlert(title: "Error", message: "Please enter your registration number")
            return
        }
        
        guard let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Please enter a password")
            return
        }
        
        guard let confirm = confirmField.text, !confirm.isEmpty else {
            showAlert(title: "Error", message: "Please confirm your password")
            return
        }
        
        // Validate domain
        guard email.hasSuffix("@" + requiredDomain) else {
            showAlert(title: "Invalid Email", message: "Email must end with @\(requiredDomain)")
            return
        }
        
        // Validate password match
        guard password == confirm else {
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }
        
        // Validate password strength
        guard password.count >= 6 else {
            showAlert(title: "Weak Password", message: "Password must be at least 6 characters")
            return
        }
        
        // Disable button and show loading
        signUpButton.isEnabled = false
        showLoadingIndicator()
        
        // Extract domain from email
        let domain = email.components(separatedBy: "@").last ?? ""
        
        // Perform registration
        performRegistration(
            name: name,
            email: email,
            regNumber: reg,
            password: password,
            domain: domain
        )
    }
    
    private func performRegistration(
        name: String,
        email: String,
        regNumber: String,
        password: String,
        domain: String
    ) {
        Task {
            do {
                print("📝 Starting student registration in Supabase:", email)
                
                // ✅ Check if student already registered in Supabase
                let status = try? await SupabaseManager.shared.checkStudentApproval(email: email)
                
                if let status = status {
                    print("⚠️ Student already exists with status:", status)
                    
                    await MainActor.run {
                        hideLoadingIndicator()
                        signUpButton.isEnabled = true
                        
                        switch status {
                        case "pending":
                            showAlert(title: "Pending Approval", message: "Your registration is pending approval from your institute. Please wait for confirmation.")
                        case "approved":
                            showAlert(title: "Already Registered", message: "You are already registered and approved. Please login.")
                        case "declined":
                            showAlert(title: "Registration Declined", message: "Your registration was declined by the institute. Please contact your administrator.")
                        default:
                            showAlert(title: "Already Registered", message: "This email is already registered.")
                        }
                    }
                    return
                }
                
                print("✅ No existing registration found, proceeding with new registration")
                
                // ✅ Register in Supabase with pending status
                let studentId = try await SupabaseManager.shared.registerStudent(
                    fullName: name,
                    email: email,
                    regNumber: regNumber,
                    password: password,
                    instituteDomain: domain
                )
                
                print("✅ Student registered in Supabase with ID:", studentId)
                
                // Update UI on main thread
                await MainActor.run {
                    hideLoadingIndicator()
                    signUpButton.isEnabled = true
                    
                    showAlert(
                        title: "Registration Submitted",
                        message: "Your registration has been submitted for approval. You will be able to login once your institute (\(requiredDomain)) approves your registration."
                    ) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                
            } catch SupabaseError.alreadyRegistered {
                print("❌ Error: Already registered")
                await MainActor.run {
                    hideLoadingIndicator()
                    signUpButton.isEnabled = true
                    showAlert(title: "Already Registered", message: "This email is already registered. Please try logging in.")
                }
                
            } catch {
                print("❌ Registration error:", error.localizedDescription)
                await MainActor.run {
                    hideLoadingIndicator()
                    signUpButton.isEnabled = true
                    showAlert(title: "Registration Failed", message: "An error occurred: \(error.localizedDescription). Please try again.")
                }
            }
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
