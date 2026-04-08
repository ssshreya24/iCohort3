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
    private var didInstallAnimatedLogo = false
    private let privacyConsentContainer = UIStackView()
    private let privacyCheckboxButton = UIButton(type: .system)
    private let privacyPolicyButton = UIButton(type: .system)
    private var hasAcceptedPrivacyPolicy = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideAnimatedAuthLogoPlaceholderIfNeeded()
        enableKeyboardDismissOnTap()
        setupUI()
        setupPlaceholders()
        setupPrivacyConsentUI()
        loadInstitutes()
        applyAuthSymbolTint()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didInstallAnimatedLogo {
            didInstallAnimatedLogo = installAnimatedAuthLogoIfNeeded(sizeMultiplier: 0.72, verticalOffset: -8)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshAnimatedAuthLogoIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        applyTheme()
        setupPlaceholders()
        applyAuthSymbolTint()
        stylePrivacyConsentUI()
    }
    
    // MARK: - Setup
    
    func setupUI() {
        applyTheme()

        let containers = [
            fullNameContainer, emailContainer, employeeIdContainer,
            designationContainer, departmentContainer, instituteContainer,
            passwordContainer, confirmPasswordContainer
        ]
        let containerBg = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.12) : .white
        }
        
        for container in containers {
            container?.layer.cornerRadius = 20
            container?.layer.masksToBounds = true
            container?.backgroundColor = containerBg
            container?.layer.borderWidth = 0.5
            container?.layer.borderColor = UIColor.opaqueSeparator.cgColor
        }

        [fullNameField, emailField, employeeIdField, designationField, departmentField, instituteField, passwordField, confirmPasswordField].forEach {
            $0?.backgroundColor = .clear
            $0?.textColor = .label
            $0?.keyboardAppearance = traitCollection.userInterfaceStyle == .dark ? .dark : .default
        }
        
        signUpButton.layer.cornerRadius = 20
        signUpButton.layer.masksToBounds = true
        signUpButton.backgroundColor = UIColor(named: "Primary") ?? UIColor(named: "Button Color")
        signUpButton.setTitleColor(.white, for: .normal)
        if var config = signUpButton.configuration {
            config.baseBackgroundColor = UIColor(named: "Primary") ?? UIColor(named: "Button Color")
            config.baseForegroundColor = .white
            signUpButton.configuration = config
        }
        styleAuthBackButton(backButton)
        
        passwordField.isSecureTextEntry = true
        confirmPasswordField.isSecureTextEntry = true
        
        // Setup college picker
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showInstitutePicker))
        instituteContainer.addGestureRecognizer(tapGesture)
        instituteField.isUserInteractionEnabled = false

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .white : .systemGray
        }
        chevron.contentMode = .scaleAspectFit
        chevron.frame = CGRect(x: 0, y: 0, width: 18, height: 18)

        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 18))
        chevron.center = CGPoint(x: rightView.bounds.midX, y: rightView.bounds.midY)
        rightView.addSubview(chevron)
        instituteField.rightView = rightView
        instituteField.rightViewMode = .always
    }

    private func setupPrivacyConsentUI() {
        guard privacyConsentContainer.superview == nil else { return }
        guard let hostView = signUpButton.superview else { return }

        privacyConsentContainer.axis = .horizontal
        privacyConsentContainer.alignment = .center
        privacyConsentContainer.spacing = 10
        privacyConsentContainer.translatesAutoresizingMaskIntoConstraints = false

        privacyCheckboxButton.translatesAutoresizingMaskIntoConstraints = false
        privacyCheckboxButton.addTarget(self, action: #selector(togglePrivacyConsent), for: .touchUpInside)

        privacyPolicyButton.translatesAutoresizingMaskIntoConstraints = false
        privacyPolicyButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        privacyPolicyButton.titleLabel?.numberOfLines = 2
        privacyPolicyButton.addTarget(self, action: #selector(openPrivacyPolicy), for: .touchUpInside)

        privacyConsentContainer.addArrangedSubview(privacyCheckboxButton)
        privacyConsentContainer.addArrangedSubview(privacyPolicyButton)
        hostView.addSubview(privacyConsentContainer)

        NSLayoutConstraint.activate([
            privacyCheckboxButton.widthAnchor.constraint(equalToConstant: 24),
            privacyCheckboxButton.heightAnchor.constraint(equalToConstant: 24),
            privacyConsentContainer.leadingAnchor.constraint(equalTo: signUpButton.leadingAnchor),
            privacyConsentContainer.trailingAnchor.constraint(lessThanOrEqualTo: signUpButton.trailingAnchor),
            privacyConsentContainer.bottomAnchor.constraint(equalTo: signUpButton.topAnchor, constant: -14)
        ])

        stylePrivacyConsentUI()
    }

    private func stylePrivacyConsentUI() {
        PrivacyPolicySupport.styleConsentCheckbox(privacyCheckboxButton, isChecked: hasAcceptedPrivacyPolicy, traitCollection: traitCollection)
        PrivacyPolicySupport.stylePolicyButton(
            privacyPolicyButton,
            title: "I agree to the Privacy & Policy",
            traitCollection: traitCollection
        )
    }

    @objc private func togglePrivacyConsent() {
        hasAcceptedPrivacyPolicy.toggle()
        stylePrivacyConsentUI()
    }

    @objc private func openPrivacyPolicy() {
        PrivacyPolicySupport.present(from: self)
    }

    private func applyTheme() {
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1)
                : UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
        }

        view.subviews.compactMap { $0 as? UIScrollView }.forEach { scrollView in
            scrollView.backgroundColor = .clear
            scrollView.indicatorStyle = traitCollection.userInterfaceStyle == .dark ? .white : .black
            scrollView.subviews.first?.backgroundColor = .clear
        }

        allSubviews(in: view).forEach { subview in
            if let label = subview as? UILabel {
                label.textColor = .label
            }
        }
    }

    private func allSubviews(in root: UIView) -> [UIView] {
        root.subviews + root.subviews.flatMap { allSubviews(in: $0) }
    }
    
    func setupPlaceholders() {
        let placeholderColor = UIColor.secondaryLabel
        fullNameField.attributedPlaceholder = NSAttributedString(string: "Enter your full name", attributes: [.foregroundColor: placeholderColor])
        emailField.attributedPlaceholder = NSAttributedString(string: "Enter your college email", attributes: [.foregroundColor: placeholderColor])
        employeeIdField.attributedPlaceholder = NSAttributedString(string: "Enter your employee ID", attributes: [.foregroundColor: placeholderColor])
        designationField.attributedPlaceholder = NSAttributedString(string: "e.g., Assistant Professor", attributes: [.foregroundColor: placeholderColor])
        departmentField.attributedPlaceholder = NSAttributedString(string: "e.g., Computer Science", attributes: [.foregroundColor: placeholderColor])
        instituteField.attributedPlaceholder = NSAttributedString(string: "Select your college", attributes: [.foregroundColor: placeholderColor])
        passwordField.attributedPlaceholder = NSAttributedString(string: "Enter your password", attributes: [.foregroundColor: placeholderColor])
        confirmPasswordField.attributedPlaceholder = NSAttributedString(string: "Confirm your password", attributes: [.foregroundColor: placeholderColor])
        
        emailField.autocapitalizationType = .none
        emailField.keyboardType = .emailAddress
        [fullNameField, emailField, employeeIdField, designationField, departmentField, instituteField, passwordField, confirmPasswordField].forEach { $0?.textColor = .label }
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

        guard hasAcceptedPrivacyPolicy else {
            showAlert(title: "Privacy & Policy", message: "Please accept the Privacy & Policy to continue.")
            return
        }
        
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
