//
//  OTPViewController.swift
//  iCohort3
//
//  ✅ Updated to verify OTP from custom password_reset_otps table
//  ✅ Works with custom OTP system (not Supabase Auth)
//  ✅ Beautiful, cute UI matching your design
//

import UIKit
import Supabase
import PostgREST

struct RegistrationVerificationContext {
    let role: SupabaseManager.LoginOTPUserRole
    let email: String
    let password: String
    let fullName: String?
    let regNumber: String?
    let employeeId: String?
    let designation: String?
    let department: String?
    let instituteName: String?
    let instituteDomain: String?
}

class OTPViewController: UIViewController {
    private struct LoginVerificationContext {
        let email: String
        let role: SupabaseManager.LoginOTPUserRole
        let shouldRemember: Bool
    }

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var otpStack: UIStackView!
    @IBOutlet weak var confirmButton: UIButton!
    
    private var otpTextFields: [UITextField] = []
    private var loadingIndicator: UIActivityIndicatorView?
    private let numberOfDigits = 6
    private let otpBoxSize: CGFloat = 54
    private var loginVerificationContext: LoginVerificationContext?
    private var registrationVerificationContext: RegistrationVerificationContext?

    func configureForLoginVerification(
        email: String,
        role: SupabaseManager.LoginOTPUserRole,
        shouldRemember: Bool
    ) {
        loginVerificationContext = LoginVerificationContext(
            email: email,
            role: role,
            shouldRemember: shouldRemember
        )
    }

    func configureForRegistrationVerification(_ context: RegistrationVerificationContext) {
        registrationVerificationContext = context
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupOTPFields()
        backButton.tintColor = .white
        if loginVerificationContext != nil {
            confirmButton.setTitle("Verify Code", for: .normal)
        } else if registrationVerificationContext != nil {
            confirmButton.setTitle("Verify Email", for: .normal)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupUI() {
        // Set button color to match app theme
        confirmButton.backgroundColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
        confirmButton.layer.cornerRadius = 20
        confirmButton.layer.masksToBounds = true
        
        // Add shadow to button
        confirmButton.layer.shadowColor = UIColor.black.cgColor
        confirmButton.layer.shadowOpacity = 0.15
        confirmButton.layer.shadowOffset = CGSize(width: 0, height: 4)
        confirmButton.layer.shadowRadius = 8
        confirmButton.layer.masksToBounds = false
    }
    
    private func setupOTPFields() {
        // Clear existing array
        otpTextFields.removeAll()
        
        print("📝 Setting up OTP fields...")
        
        // Remove all existing subviews from stack
        otpStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Configure stack view
        otpStack.axis = .horizontal
        otpStack.distribution = .fillEqually
        otpStack.spacing = 10
        otpStack.alignment = .center
        
        // Create text fields (cute small boxes like in your image)
        for i in 0..<numberOfDigits {
            let containerView = UIView()
            containerView.backgroundColor = .white
            containerView.layer.cornerRadius = 14
            containerView.layer.borderWidth = 1.5
            containerView.layer.borderColor = UIColor(red: 0xD1/255, green: 0xD5/255, blue: 0xDB/255, alpha: 1).cgColor
            containerView.layer.shadowColor = UIColor.black.cgColor
            containerView.layer.shadowOpacity = 0.05
            containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
            containerView.layer.shadowRadius = 5
            
            let textField = UITextField()
            configureTextField(textField)
            
            containerView.addSubview(textField)
            textField.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                textField.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
                textField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                textField.widthAnchor.constraint(equalTo: containerView.widthAnchor),
                textField.heightAnchor.constraint(equalTo: containerView.heightAnchor)
            ])
            
            otpStack.addArrangedSubview(containerView)
            otpTextFields.append(textField)
            
            // Larger boxes improve tap accuracy and make correction easier.
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.widthAnchor.constraint(equalToConstant: otpBoxSize).isActive = true
            containerView.heightAnchor.constraint(equalToConstant: otpBoxSize).isActive = true
            
            print("✅ Created text field \(i + 1)")
        }
        
        print("📝 Total OTP text fields configured: \(otpTextFields.count)")
        
        // Focus on first field
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.otpTextFields.first?.becomeFirstResponder()
        }
    }
    
    private func configureTextField(_ textField: UITextField) {
        textField.delegate = self
        textField.keyboardType = .numberPad
        textField.textAlignment = .center
        textField.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        textField.text = ""
        textField.backgroundColor = .clear
        textField.textColor = UIColor(red: 0x1F/255, green: 0x29/255, blue: 0x37/255, alpha: 1)
        textField.tintColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
        textField.clearButtonMode = .never
        textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        // Move to next field when a digit is entered
        if let text = textField.text, text.count == 1 {
            if let index = otpTextFields.firstIndex(of: textField), index < otpTextFields.count - 1 {
                otpTextFields[index + 1].becomeFirstResponder()
            } else {
                textField.resignFirstResponder()
            }
        }
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        print("OTP back tapped")
        
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        print("Confirm button tapped")
        
        // Collect OTP from text fields
        var enteredOTP = ""
        for textField in otpTextFields {
            if let text = textField.text, !text.isEmpty {
                enteredOTP += text
            }
        }
        
        print("📝 Collected OTP: '\(enteredOTP)'")
        
        // Validate OTP length
        guard enteredOTP.count == numberOfDigits else {
            showAlert(title: "Invalid OTP", message: "Please enter the complete \(numberOfDigits)-digit OTP.")
            return
        }
        
        // Validate OTP contains only numbers
        guard enteredOTP.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil else {
            showAlert(title: "Invalid OTP", message: "OTP should contain only numbers")
            return
        }
        
        // Disable button and show loading
        confirmButton.isEnabled = false
        showLoadingIndicator()

        if let context = loginVerificationContext {
            verifyLoginOTPAndNavigate(context: context, otp: enteredOTP)
        } else if let context = registrationVerificationContext {
            verifyRegistrationOTPAndComplete(context: context, otp: enteredOTP)
        } else {
            guard let email = UserDefaults.standard.string(forKey: "forgot_password_email") else {
                hideLoadingIndicator()
                confirmButton.isEnabled = true
                showAlert(title: "Error", message: "Session expired. Please start the process again.")
                return
            }

            verifyPasswordResetOTPAndNavigate(email: email, otp: enteredOTP)
        }
    }
    
    private func verifyPasswordResetOTPAndNavigate(email: String, otp: String) {
        Task {
            do {
                try await SupabaseManager.shared.verifyOTPForPasswordReset(email: email, otp: otp)
                
                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    
                    let forgotVC = forgotPasswordViewController(nibName: "forgotPasswordViewController", bundle: nil)
                    let roleString = UserDefaults.standard.string(forKey: "forgot_password_role")
                    let role = SupabaseManager.PasswordResetUserRole(rawValue: roleString ?? "") ?? .student
                    forgotVC.configure(role: role)
                    
                    if let nav = navigationController {
                        nav.pushViewController(forgotVC, animated: true)
                    } else {
                        forgotVC.modalPresentationStyle = .fullScreen
                        present(forgotVC, animated: true, completion: nil)
                    }
                }
                
            } catch {
                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    
                    let errorMessage: String
                    if error.localizedDescription.contains("expired") {
                        errorMessage = "The OTP has expired. Please request a new one."
                    } else if error.localizedDescription.contains("Invalid") {
                        errorMessage = "Invalid OTP. Please check and try again."
                    } else {
                        errorMessage = "OTP verification failed. Please try again."
                    }
                    
                    showAlert(title: "Verification Failed", message: errorMessage)
                    
                    // Clear text fields
                    for textField in otpTextFields {
                        textField.text = ""
                    }
                    otpTextFields.first?.becomeFirstResponder()
                }
            }
        }
    }

    private func verifyLoginOTPAndNavigate(context: LoginVerificationContext, otp: String) {
        Task {
            do {
                let session = try await SupabaseManager.shared.verifyLoginOTP(
                    email: context.email,
                    otp: otp,
                    role: context.role
                )

                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    finalizeLogin(session: session, shouldRemember: context.shouldRemember)
                }
            } catch {
                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    showAlert(title: "Verification Failed", message: error.localizedDescription)

                    for textField in otpTextFields {
                        textField.text = ""
                    }
                    otpTextFields.first?.becomeFirstResponder()
                }
            }
        }
    }

    private func verifyRegistrationOTPAndComplete(context: RegistrationVerificationContext, otp: String) {
        Task {
            do {
                try await SupabaseManager.shared.verifyOTPForPasswordReset(email: context.email, otp: otp)
                try await completeRegistration(context: context)
                try? await SupabaseManager.shared.deleteOTP(email: context.email)

                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    showAlert(
                        title: "Verification Complete",
                        message: registrationSuccessMessage(for: context)
                    ) { [weak self] in
                        self?.navigateToLoginAfterRegistration(role: context.role)
                    }
                }
            } catch {
                await MainActor.run {
                    hideLoadingIndicator()
                    confirmButton.isEnabled = true
                    showAlert(title: "Verification Failed", message: error.localizedDescription)

                    for textField in otpTextFields {
                        textField.text = ""
                    }
                    otpTextFields.first?.becomeFirstResponder()
                }
            }
        }
    }

    private func completeRegistration(context: RegistrationVerificationContext) async throws {
        switch context.role {
        case .student:
            guard
                let fullName = context.fullName,
                let regNumber = context.regNumber,
                let instituteDomain = context.instituteDomain
            else {
                throw NSError(domain: "RegistrationOTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Student registration details are incomplete."])
            }

            _ = try await SupabaseManager.shared.registerStudent(
                fullName: fullName,
                email: context.email,
                regNumber: regNumber,
                password: context.password,
                instituteDomain: instituteDomain
            )

        case .mentor:
            guard
                let fullName = context.fullName,
                let employeeId = context.employeeId,
                let designation = context.designation,
                let department = context.department,
                let instituteName = context.instituteName,
                let instituteDomain = context.instituteDomain
            else {
                throw NSError(domain: "RegistrationOTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mentor registration details are incomplete."])
            }

            _ = try await SupabaseManager.shared.registerMentorWithDomain(
                fullName: fullName,
                email: context.email,
                employeeId: employeeId,
                designation: designation,
                department: department,
                instituteName: instituteName,
                instituteDomain: instituteDomain,
                password: context.password
            )

        case .admin:
            guard
                let instituteName = context.instituteName,
                let instituteDomain = context.instituteDomain
            else {
                throw NSError(domain: "RegistrationOTP", code: -1, userInfo: [NSLocalizedDescriptionKey: "Institute registration details are incomplete."])
            }

            try await SupabaseManager.shared.registerAdmin(
                email: context.email,
                password: context.password,
                instituteId: nil
            )

            struct AdminAccountResponse: Codable {
                let id: String
            }

            let adminAccounts: [AdminAccountResponse] = try await SupabaseManager.shared.client
                .from("admin_accounts")
                .select("id")
                .eq("email", value: context.email)
                .limit(1)
                .execute()
                .value

            guard let adminId = adminAccounts.first?.id else {
                throw NSError(domain: "RegistrationOTP", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to retrieve admin account after verification."])
            }

            try await SupabaseManager.shared.registerInstitute(
                name: instituteName,
                domain: instituteDomain,
                adminEmail: context.email,
                adminId: adminId
            )
        }
    }

    @MainActor
    private func navigateToLoginAfterRegistration(role: SupabaseManager.LoginOTPUserRole) {
        guard let nav = navigationController else {
            dismiss(animated: true)
            return
        }

        let target: UIViewController?
        switch role {
        case .student:
            target = nav.viewControllers.first { $0 is LoginViewController }
        case .mentor:
            target = nav.viewControllers.first { $0 is MLoginSignUpViewController }
        case .admin:
            target = nav.viewControllers.first { $0 is AdminLoginViewController }
        }

        if let target {
            nav.popToViewController(target, animated: true)
        } else {
            nav.popToRootViewController(animated: true)
        }
    }

    private func registrationSuccessMessage(for context: RegistrationVerificationContext) -> String {
        switch context.role {
        case .student, .mentor:
            return "Your information has been submitted successfully. You can log in once your college approves your registration."
        case .admin:
            return "Your institute and admin account have been created successfully. You can now sign in."
        }
    }

    @MainActor
    private func finalizeLogin(session: SupabaseManager.LoginOTPSession, shouldRemember: Bool) {
        guard let role = SupabaseManager.LoginOTPUserRole(rawValue: session.role) else {
            showAlert(title: "Login Failed", message: "Unknown role returned by server.")
            return
        }

        switch role {
        case .student:
            guard let personId = session.person_id, !personId.isEmpty else {
                showAlert(title: "Login Failed", message: "Student session is missing person id.")
                return
            }

            UserDefaults.standard.set(personId, forKey: "current_person_id")
            UserDefaults.standard.set(session.display_name ?? "Student", forKey: "current_user_name")
            UserDefaults.standard.set(session.email, forKey: "current_user_email")
            UserDefaults.standard.set(role.rawValue, forKey: "current_user_role")
            UserDefaults.standard.set(true, forKey: "is_logged_in")

            applyRememberMePreference(shouldRemember, email: session.email, role: role.rawValue)
            transitionToRootViewController(MainTabBarViewController())

        case .mentor:
            guard let personId = session.person_id, !personId.isEmpty else {
                showAlert(title: "Login Failed", message: "Mentor session is missing person id.")
                return
            }

            UserDefaults.standard.set(personId, forKey: "current_person_id")
            UserDefaults.standard.set(session.display_name ?? "Mentor", forKey: "current_user_name")
            UserDefaults.standard.set(session.email, forKey: "current_user_email")
            UserDefaults.standard.set(role.rawValue, forKey: "current_user_role")
            UserDefaults.standard.set(true, forKey: "is_logged_in")

            applyRememberMePreference(shouldRemember, email: session.email, role: role.rawValue)
            transitionToRootViewController(MentorMainTabBarViewController())

        case .admin:
            UserDefaults.standard.removeObject(forKey: "current_person_id")
            UserDefaults.standard.set(session.display_name ?? "Admin", forKey: "current_user_name")
            UserDefaults.standard.set(session.email, forKey: "admin_email")
            UserDefaults.standard.set(session.email, forKey: "current_user_email")
            UserDefaults.standard.set(role.rawValue, forKey: "current_user_role")
            UserDefaults.standard.set(true, forKey: "is_logged_in")
            UserDefaults.standard.set(session.institute_name, forKey: "admin_institute_name")
            UserDefaults.standard.set(session.institute_domain, forKey: "admin_institute_domain")
            UserDefaults.standard.set(true, forKey: "is_admin")
            applyRememberMePreference(shouldRemember, email: session.email, role: role.rawValue)

            let dashboardVC = AdminDashboardViewController()
            if let nav = navigationController {
                nav.setViewControllers([dashboardVC], animated: true)
            } else {
                let nav = UINavigationController(rootViewController: dashboardVC)
                nav.modalPresentationStyle = .fullScreen
                present(nav, animated: true)
            }
        }
    }

    @MainActor
    private func transitionToRootViewController(_ viewController: UIViewController) {
        let window = view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }

        guard let window else { return }

        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = viewController
        }
    }

    private func applyRememberMePreference(_ shouldRemember: Bool, email: String, role: String) {
        if shouldRemember {
            UserDefaults.standard.set(true, forKey: "remember_me")
            UserDefaults.standard.set(email, forKey: "remembered_email")
            UserDefaults.standard.set(role, forKey: "remembered_user_role")
        } else {
            UserDefaults.standard.set(false, forKey: "remember_me")
            UserDefaults.standard.removeObject(forKey: "remembered_email")
            UserDefaults.standard.removeObject(forKey: "remembered_user_role")
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

// MARK: - UITextFieldDelegate
extension OTPViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else { return false }
        let updatedText = currentText.replacingCharacters(in: stringRange, with: string)
        
        // Only allow numbers and max 1 character
        if updatedText.count > 1 {
            return false
        }
        
        if !string.isEmpty && !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: string)) {
            return false
        }
        
        // Handle backspace - move to previous field
        if string.isEmpty && currentText.isEmpty {
            if let index = otpTextFields.firstIndex(of: textField), index > 0 {
                otpTextFields[index - 1].becomeFirstResponder()
            }
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        // Highlight the active field with nice animation
        if let containerView = textField.superview {
            UIView.animate(withDuration: 0.2) {
                containerView.layer.borderColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1).cgColor
                containerView.layer.borderWidth = 2
            }
        }
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        // Reset border when field loses focus
        if let containerView = textField.superview {
            UIView.animate(withDuration: 0.2) {
                containerView.layer.borderColor = UIColor(red: 0xD1/255, green: 0xD5/255, blue: 0xDB/255, alpha: 1).cgColor
                containerView.layer.borderWidth = 1.5
            }
        }
    }
}
