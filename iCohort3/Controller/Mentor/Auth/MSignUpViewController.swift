//
//  MSignUpViewController.swift
//  iCohort3
//
//  ✅ ENHANCED: College selection with domain-based approval routing
//

import UIKit

class MSignUpViewController: UIViewController {
    
    @IBOutlet weak var fullNameContainer: UIView!
    @IBOutlet weak var emailContainer: UIView!
    @IBOutlet weak var employeeIdContainer: UIView!
    @IBOutlet weak var designationContainer: UIView!
    @IBOutlet weak var departmentContainer: UIView!
    @IBOutlet weak var instituteContainer: UIView!
    @IBOutlet weak var passwordContainer: UIView!
    @IBOutlet weak var confirmPasswordContainer: UIView!
    
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var employeeIdField: UITextField!
    @IBOutlet weak var designationField: UITextField!
    @IBOutlet weak var departmentField: UITextField!
    @IBOutlet weak var instituteField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    private var loadingIndicator: UIActivityIndicatorView?
    private var selectedInstitute: SupabaseManager.Institute?
    private var availableInstitutes: [SupabaseManager.Institute] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupPlaceholders()
        loadInstitutes()
    }
    
    // MARK: - Setup
    
    func setupUI() {
        let containers = [
            fullNameContainer, emailContainer, employeeIdContainer,
            designationContainer, departmentContainer, instituteContainer,
            passwordContainer, confirmPasswordContainer
        ]
        
        for container in containers {
            container?.layer.cornerRadius = 20
            container?.layer.masksToBounds = true
            container?.backgroundColor = .white
        }
        
        signUpButton.layer.cornerRadius = 20
        signUpButton.layer.masksToBounds = true
        
        passwordField.isSecureTextEntry = true
        confirmPasswordField.isSecureTextEntry = true
        
        // Setup college picker
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showInstitutePicker))
        instituteContainer.addGestureRecognizer(tapGesture)
        instituteField.isUserInteractionEnabled = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .systemGray
        chevron.contentMode = .scaleAspectFit
        chevron.frame = CGRect(x: 0, y: 0, width: 18, height: 18)

        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 18))
        chevron.center = CGPoint(x: rightView.bounds.midX, y: rightView.bounds.midY)
        rightView.addSubview(chevron)
        instituteField.rightView = rightView
        instituteField.rightViewMode = .always
    }
    
    func setupPlaceholders() {
        fullNameField.placeholder = "Enter your full name"
        emailField.placeholder = "Enter your college email"
        employeeIdField.placeholder = "Enter your employee ID"
        designationField.placeholder = "e.g., Assistant Professor"
        departmentField.placeholder = "e.g., Computer Science"
        instituteField.placeholder = "Select your college"
        passwordField.placeholder = "Enter your password"
        confirmPasswordField.placeholder = "Confirm your password"
        
        emailField.autocapitalizationType = .none
        emailField.keyboardType = .emailAddress
    }
    
    // MARK: - Load Institutes
    
    private func loadInstitutes() {
        Task {
            do {
                let institutes = try await SupabaseManager.shared.getAllInstitutes()
                await MainActor.run {
                    self.availableInstitutes = institutes
                    print("✅ Loaded \(institutes.count) colleges")
                }
            } catch {
                print("❌ Error loading colleges:", error.localizedDescription)
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to load colleges. Please try again.")
                }
            }
        }
    }
    
    @objc private func showInstitutePicker() {
        guard !availableInstitutes.isEmpty else {
            showAlert(title: "No Colleges", message: "No colleges are registered yet. Please contact support.")
            return
        }
        
        let alert = UIAlertController(title: "Select College", message: nil, preferredStyle: .actionSheet)
        
        for institute in availableInstitutes {
            let action = UIAlertAction(title: institute.name, style: .default) { [weak self] _ in
                self?.selectInstitute(institute)
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = instituteContainer
            popover.sourceRect = instituteContainer.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func selectInstitute(_ institute: SupabaseManager.Institute) {
        selectedInstitute = institute
        instituteField.text = institute.name
        print("✅ Selected college:", institute.name, "with domain:", institute.domain)
    }
    
    // MARK: - Validation
    
    private func validateInputs() -> (isValid: Bool, message: String?) {
        guard let fullName = fullNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !fullName.isEmpty else {
            return (false, "Please enter your full name")
        }
        
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !email.isEmpty else {
            return (false, "Please enter your email address")
        }
        
        // Email validation
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            return (false, "Please enter a valid email address")
        }
        
        // ✅ Validate email domain matches selected institute
        guard let institute = selectedInstitute else {
            return (false, "Please select your college")
        }
        
        guard email.hasSuffix("@\(institute.domain)") else {
            return (false, "Email must be from \(institute.domain) domain for \(institute.name)")
        }
        
        guard let employeeId = employeeIdField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !employeeId.isEmpty else {
            return (false, "Please enter your employee ID")
        }
        
        guard let designation = designationField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !designation.isEmpty else {
            return (false, "Please enter your designation")
        }
        
        guard let department = departmentField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !department.isEmpty else {
            return (false, "Please enter your department")
        }
        
        guard let password = passwordField.text, !password.isEmpty else {
            return (false, "Please enter a password")
        }
        
        guard password.count >= 6 else {
            return (false, "Password must be at least 6 characters")
        }
        
        guard let confirmPassword = confirmPasswordField.text, !confirmPassword.isEmpty else {
            return (false, "Please confirm your password")
        }
        
        guard password == confirmPassword else {
            return (false, "Passwords do not match")
        }
        
        return (true, nil)
    }
    
    // MARK: - Actions
    
    @IBAction func signUpTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        let validation = validateInputs()
        guard validation.isValid else {
            showAlert(title: "Validation Error", message: validation.message ?? "Please check your inputs")
            return
        }
        
        guard let fullName = fullNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              let employeeId = employeeIdField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let designation = designationField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let department = departmentField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              let password = passwordField.text,
              let institute = selectedInstitute else {
            return
        }
        
        signUpButton.isEnabled = false
        showLoadingIndicator()
        
        performRegistration(
            fullName: fullName,
            email: email,
            employeeId: employeeId,
            designation: designation,
            department: department,
            instituteName: institute.name,
            instituteDomain: institute.domain,
            password: password
        )
    }
    
    private func performRegistration(
        fullName: String,
        email: String,
        employeeId: String,
        designation: String,
        department: String,
        instituteName: String,
        instituteDomain: String,
        password: String
    ) {
        Task {
            do {
                print("📝 Starting mentor registration...")
                print("   Email:", email)
                print("   Institute:", instituteName)
                print("   Domain:", instituteDomain)
                
                // ✅ Check if mentor already registered
                let status = try? await SupabaseManager.shared.checkMentorApproval(email: email)
                
                if let status = status {
                    print("⚠️ Mentor already exists with status:", status)
                    
                    await MainActor.run {
                        hideLoadingIndicator()
                        signUpButton.isEnabled = true
                        
                        switch status {
                        case "pending":
                            showAlert(title: "Pending Approval", message: "Your registration is pending approval from \(instituteName). Please wait for confirmation.")
                        case "approved":
                            showAlert(title: "Already Registered", message: "You are already registered and approved. Please login.")
                        case "declined":
                            showAlert(title: "Registration Declined", message: "Your registration was declined. Please contact your administrator.")
                        default:
                            showAlert(title: "Already Registered", message: "This email is already registered.")
                        }
                    }
                    return
                }
                
                print("✅ No existing registration found, sending OTP...")
                try await SupabaseManager.shared.sendPasswordResetEmail(email: email)
                
                await MainActor.run {
                    hideLoadingIndicator()
                    signUpButton.isEnabled = true

                    let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
                    otpVC.configureForRegistrationVerification(
                        RegistrationVerificationContext(
                            role: .mentor,
                            email: email,
                            password: password,
                            fullName: fullName,
                            regNumber: nil,
                            employeeId: employeeId,
                            designation: designation,
                            department: department,
                            instituteName: instituteName,
                            instituteDomain: instituteDomain
                        )
                    )
                    self.navigationController?.pushViewController(otpVC, animated: true)
                }
                
            } catch SupabaseError.alreadyRegistered {
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
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func showLoadingIndicator() {
        hideLoadingIndicator()
        
        DispatchQueue.main.async {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.color = .systemBlue
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
