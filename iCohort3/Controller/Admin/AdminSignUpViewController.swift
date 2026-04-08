//
//  AdminSignUpViewController.swift
//  iCohort3
//
//  ✅ FIXED: Uses Supabase instead of Firebase
//

import UIKit
import PostgREST
import Supabase

class AdminSignUpViewController: UIViewController {
    
    @IBOutlet weak var uniNameView: UIView!
    @IBOutlet weak var uniTextField: UITextField!
    @IBOutlet weak var mailView: UIView!
    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var domainView: UIView!
    @IBOutlet weak var domainTextField: UITextField!
    @IBOutlet weak var passView: UIView!
    @IBOutlet weak var passTextField: UITextField!
    @IBOutlet weak var confirmPassView: UIView!
    @IBOutlet weak var confirmPassTextField: UITextField!
    @IBOutlet weak var registerButtonOutlet: UIButton!
    @IBOutlet weak var backButtonOutlet: UIButton!
    
    private var isSubmitting = false
    private var didInstallAnimatedLogo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .fullScreen
        navigationController?.modalPresentationStyle = .fullScreen
        constrainLogoPlaceholderIfNeeded()
        hideAnimatedAuthLogoPlaceholderIfNeeded()
        enableKeyboardDismissOnTap()
        
        setupUI()
        setupPlaceholders()
        applyAuthSymbolTint()
        styleAuthBackButton(backButtonOutlet)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
        navigationController?.modalPresentationStyle = .fullScreen
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

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
    }
    
    // MARK: - UI Setup
    func setupUI() {
        let radius: CGFloat = 20
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1)
                : UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
        }
        let containerBg = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.12) : .white
        }
        
        // Apply corner radius to all views
        let views = [uniNameView, mailView, domainView, passView, confirmPassView]
        
        for view in views {
            view?.layer.cornerRadius = radius
            view?.clipsToBounds = true
            view?.backgroundColor = containerBg
            view?.layer.borderWidth = 0.5
            view?.layer.borderColor = UIColor.opaqueSeparator.cgColor
        }
        
        registerButtonOutlet.layer.cornerRadius = radius
        registerButtonOutlet.clipsToBounds = true
        
        // Setup text fields
        passTextField.isSecureTextEntry = true
        confirmPassTextField.isSecureTextEntry = true
        
        mailTextField.autocapitalizationType = .none
        mailTextField.keyboardType = .emailAddress
        [uniTextField, mailTextField, domainTextField, passTextField, confirmPassTextField].forEach { $0?.textColor = .label }
        
        domainTextField.autocapitalizationType = .none
        domainTextField.placeholder = "e.g., srmist.edu.in"
    }
    
    func setupPlaceholders() {
        let placeholderColor = UIColor.secondaryLabel
        uniTextField.attributedPlaceholder = NSAttributedString(string: "Institution Name", attributes: [.foregroundColor: placeholderColor])
        mailTextField.attributedPlaceholder = NSAttributedString(string: "Admin Email", attributes: [.foregroundColor: placeholderColor])
        domainTextField.attributedPlaceholder = NSAttributedString(string: "Email Domain (e.g., srmist.edu.in)", attributes: [.foregroundColor: placeholderColor])
        passTextField.attributedPlaceholder = NSAttributedString(string: "Password", attributes: [.foregroundColor: placeholderColor])
        confirmPassTextField.attributedPlaceholder = NSAttributedString(string: "Confirm Password", attributes: [.foregroundColor: placeholderColor])
    }

    private func constrainLogoPlaceholderIfNeeded() {
        guard let imageView = findLogoPlaceholderImageView() else { return }

        if let superview = imageView.superview {
            superview.constraints
                .filter { constraint in
                    let firstView = constraint.firstItem as? UIView
                    let secondView = constraint.secondItem as? UIView
                    let involvesImageView = firstView == imageView || secondView == imageView
                    let affectsHorizontalSize = [
                        constraint.firstAttribute,
                        constraint.secondAttribute
                    ].contains { attribute in
                        attribute == .leading || attribute == .trailing
                    }
                    return involvesImageView && affectsHorizontalSize
                }
                .forEach { $0.isActive = false }
        }

        let hasWidthConstraint = imageView.constraints.contains {
            $0.firstAttribute == .width && $0.relation == .equal
        }
        let hasHeightConstraint = imageView.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }

        if !hasWidthConstraint {
            imageView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        }
        if !hasHeightConstraint {
            imageView.heightAnchor.constraint(equalToConstant: 120).isActive = true
        }
        if let superview = imageView.superview,
           !superview.constraints.contains(where: {
               ($0.firstItem as? UIView == imageView || $0.secondItem as? UIView == imageView) &&
               ($0.firstAttribute == .centerX || $0.secondAttribute == .centerX)
           }) {
            imageView.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
        }
    }

    private func findLogoPlaceholderImageView() -> UIImageView? {
        allSubviews(in: view)
            .compactMap { $0 as? UIImageView }
            .filter { imageView in
                let frame = imageView.convert(imageView.bounds, to: view)
                return frame.minY < view.bounds.midY && frame.height >= 100
            }
            .sorted { lhs, rhs in
                let lhsFrame = lhs.convert(lhs.bounds, to: view)
                let rhsFrame = rhs.convert(rhs.bounds, to: view)
                return lhsFrame.minY < rhsFrame.minY
            }
            .first
    }

    private func allSubviews(in root: UIView) -> [UIView] {
        root.subviews + root.subviews.flatMap { allSubviews(in: $0) }
    }
    
    // MARK: - Validation
    
    private func validateInputs() -> (isValid: Bool, message: String?) {
        guard let institutionName = uniTextField.text?.trimmingCharacters(in: .whitespaces),
              !institutionName.isEmpty else {
            return (false, "Please enter institution name")
        }
        
        guard let email = mailTextField.text?.trimmingCharacters(in: .whitespaces),
              !email.isEmpty else {
            return (false, "Please enter admin email")
        }
        
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            return (false, "Please enter a valid email address")
        }
        
        // Auto-extract domain from email if domain field is empty
        var domain = domainTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        
        if domain.isEmpty {
            // Extract domain from email (everything after @)
            if let atIndex = email.firstIndex(of: "@") {
                let domainFromEmail = String(email[email.index(after: atIndex)...])
                domain = domainFromEmail.lowercased()
                
                // Update the text field with extracted domain
                domainTextField.text = domain
            } else {
                return (false, "Please enter email domain")
            }
        }
        
        // Basic domain validation - must contain at least one dot and valid characters
        // Accepts formats like: university.edu, srmist.edu.in, ox.ac.uk, etc.
        let domainComponents = domain.split(separator: ".")
        
        // Must have at least 2 parts (e.g., domain.com)
        guard domainComponents.count >= 2 else {
            return (false, "Please enter a valid domain (e.g. chitkara.edu.in)")
        }
        
        // Check each component is valid (alphanumeric and hyphens, but not starting/ending with hyphen)
        for component in domainComponents {
            let componentStr = String(component)
            
            // Must not be empty
            guard !componentStr.isEmpty else {
                return (false, "Please enter a valid domain (e.g. chitkara.edu.in)")
            }
            
            // Must start and end with alphanumeric
            guard let first = componentStr.first,
                  let last = componentStr.last,
                  first.isLetter || first.isNumber,
                  last.isLetter || last.isNumber else {
                return (false, "Please enter a valid domain (e.g. chitkara.edu.in)")
            }
            
            // Must contain only valid characters (alphanumeric and hyphen)
            let validCharacterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-"))
            guard componentStr.rangeOfCharacter(from: validCharacterSet.inverted) == nil else {
                return (false, "Please enter a valid domain (e.g. chitkara.edu.in)")
            }
        }
        
        // Last component should contain at least one letter (TLD requirement)
        guard let lastComponent = domainComponents.last,
              lastComponent.rangeOfCharacter(from: .letters) != nil else {
            return (false, "Please enter a valid domain (e.g. chitkara.edu.in)")
        }
        
        guard let password = passTextField.text,
              !password.isEmpty else {
            return (false, "Please enter a password")
        }
        
        guard password.count >= 6 else {
            return (false, "Password must be at least 6 characters")
        }
        
        guard let confirmPassword = confirmPassTextField.text,
              !confirmPassword.isEmpty else {
            return (false, "Please confirm your password")
        }
        
        guard password == confirmPassword else {
            return (false, "Passwords do not match")
        }
        
        return (true, nil)
    }
    
    // MARK: - Actions
    
    @IBAction func registerButton(_ sender: Any) {
        view.endEditing(true)
        
        guard !isSubmitting else { return }
        
        // Validate inputs
        let validation = validateInputs()
        guard validation.isValid else {
            showAlert(title: "Validation Error", message: validation.message ?? "Please check your inputs")
            return
        }
        
        guard let institutionName = uniTextField.text?.trimmingCharacters(in: .whitespaces),
              let email = mailTextField.text?.trimmingCharacters(in: .whitespaces),
              let domain = domainTextField.text?.trimmingCharacters(in: .whitespaces).lowercased(),
              let password = passTextField.text else {
            return
        }
        
        // Show loading
        isSubmitting = true
        registerButtonOutlet.isEnabled = false
        registerButtonOutlet.setTitle("Creating Account...", for: .normal)
        
        Task {
            do {
                let adminExists = try await SupabaseManager.shared.verifyAdminExists(email: email)
                if adminExists {
                    throw SupabaseError.alreadyRegistered
                }

                if let existingInstitute = try await SupabaseManager.shared.getInstitute(byDomain: domain),
                   !existingInstitute.id.isEmpty {
                    throw SupabaseError.instituteAlreadyExists
                }

                try await SupabaseManager.shared.sendPasswordResetEmail(email: email)

                await MainActor.run {
                    isSubmitting = false
                    registerButtonOutlet.isEnabled = true
                    registerButtonOutlet.setTitle("Register", for: .normal)

                    let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
                    otpVC.configureForRegistrationVerification(
                        RegistrationVerificationContext(
                            role: .admin,
                            email: email,
                            password: password,
                            fullName: nil,
                            regNumber: nil,
                            employeeId: nil,
                            designation: nil,
                            department: nil,
                            instituteName: institutionName,
                            instituteDomain: domain
                        )
                    )
                    self.navigationController?.pushViewController(otpVC, animated: true)
                }
                
            } catch let error as SupabaseError {
                await MainActor.run {
                    isSubmitting = false
                    registerButtonOutlet.isEnabled = true
                    registerButtonOutlet.setTitle("Register", for: .normal)
                    
                    showAlert(title: "Registration Failed", message: error.localizedDescription)
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    registerButtonOutlet.isEnabled = true
                    registerButtonOutlet.setTitle("Register", for: .normal)
                    
                    // Check if it's an "already registered" error
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("already registered") || errorMessage.contains("already exists") {
                        showAlert(title: "Registration Failed", message: "This email is already registered. Please use a different email.")
                    } else {
                        showAlert(title: "Registration Failed", message: "An error occurred: \(errorMessage)")
                    }
                }
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccessAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })
        present(alert, animated: true)
    }
}
