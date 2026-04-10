//
//  SignUpViewController.swift
//  iCohort3
//
//  ✅ SUPABASE ONLY - No Firebase dependencies
//

import UIKit

class SignUpViewController: UIViewController {
    @IBOutlet weak var collegeContainer: UIView!
    @IBOutlet weak var fullNameContainer: UIView!
    @IBOutlet weak var emailContainer: UIView!
    @IBOutlet weak var regContainer: UIView!
    @IBOutlet weak var passwordContainer: UIView!
    @IBOutlet weak var confirmContainer: UIView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var collegeField: UITextField!
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var regField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!

    private var selectedInstitute: SupabaseManager.Institute?
    private var availableInstitutes: [SupabaseManager.Institute] = []
    private var loadingIndicator: UIActivityIndicatorView?
    private var didInstallAnimatedLogo = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        constrainLogoPlaceholderIfNeeded()
        hideAnimatedAuthLogoPlaceholderIfNeeded()
        enableKeyboardDismissOnTap()
        setupBackButton()
        roundViews()
        setupPlaceholders()
        setupCollegePicker()
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

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
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

    private func allSubviews(in view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap { allSubviews(in: $0) }
    }
    
    func setupPlaceholders() {
        let placeholderColor = UIColor.secondaryLabel
        collegeField.attributedPlaceholder = NSAttributedString(string: "Select your college", attributes: [.foregroundColor: placeholderColor])
        fullNameField.attributedPlaceholder = NSAttributedString(string: "Enter your full name", attributes: [.foregroundColor: placeholderColor])
        emailField.attributedPlaceholder = NSAttributedString(string: "Enter your college email", attributes: [.foregroundColor: placeholderColor])
        regField.attributedPlaceholder = NSAttributedString(string: "Enter your registration number", attributes: [.foregroundColor: placeholderColor])
        passwordField.attributedPlaceholder = NSAttributedString(string: "Enter your password", attributes: [.foregroundColor: placeholderColor])
        confirmField.attributedPlaceholder = NSAttributedString(string: "Confirm your password", attributes: [.foregroundColor: placeholderColor])
        
        passwordField.isSecureTextEntry = true
        confirmField.isSecureTextEntry = true
        emailField.autocapitalizationType = .none
        emailField.keyboardType = .emailAddress
        [collegeField, fullNameField, emailField, regField, passwordField, confirmField].forEach { $0?.textColor = .label }
    }
    
    func roundViews() {
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1)
                : UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
        }
        let containers = [collegeContainer, fullNameContainer, emailContainer, regContainer, passwordContainer, confirmContainer]
        let containerBg = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.12) : .white
        }
        
        for view in containers {
            view?.layer.cornerRadius = 20
            view?.layer.borderWidth  = 0.5
            view?.layer.borderColor  = UIColor.opaqueSeparator.cgColor
            view?.layer.masksToBounds = true
            view?.backgroundColor    = containerBg
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
        
        backButton.tintColor = UIColor { trait in trait.userInterfaceStyle == .dark ? .white : .black }
        backButton.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.14) : .white
        }
        backButton.layer.cornerRadius = 22
        backButton.layer.masksToBounds = true
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
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

    private func setupCollegePicker() {
        collegeField.isUserInteractionEnabled = false

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showCollegePicker))
        collegeContainer.addGestureRecognizer(tapGesture)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.down"))
        chevron.tintColor = .systemGray
        chevron.contentMode = .scaleAspectFit
        chevron.frame = CGRect(x: 0, y: 0, width: 18, height: 18)

        let rightView = UIView(frame: CGRect(x: 0, y: 0, width: 34, height: 18))
        chevron.center = CGPoint(x: rightView.bounds.midX, y: rightView.bounds.midY)
        rightView.addSubview(chevron)
        collegeField.rightView = rightView
        collegeField.rightViewMode = .always
    }

    private func loadInstitutes() {
        Task {
            do {
                let institutes = try await SupabaseManager.shared.getAllInstitutes()
                await MainActor.run {
                    self.availableInstitutes = institutes
                    print("✅ Loaded \(institutes.count) colleges for student sign up")
                }
            } catch {
                print("❌ Error loading colleges:", error.localizedDescription)
                await MainActor.run {
                    self.showAlert(title: "Error", message: "Failed to load colleges. Please try again.")
                }
            }
        }
    }

    @objc private func showCollegePicker() {
        guard !availableInstitutes.isEmpty else {
            showAlert(title: "No Colleges", message: "No colleges are registered yet. Please contact support.")
            return
        }

        let alert = UIAlertController(title: "Select College", message: nil, preferredStyle: .actionSheet)

        for institute in availableInstitutes {
            let action = UIAlertAction(title: institute.name, style: .default) { [weak self] _ in
                self?.selectCollege(institute)
            }
            alert.addAction(action)
        }

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = collegeContainer
            popover.sourceRect = collegeContainer.bounds
        }

        present(alert, animated: true)
    }

    private func selectCollege(_ institute: SupabaseManager.Institute) {
        selectedInstitute = institute
        collegeField.text = institute.name
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
        guard let institute = selectedInstitute else {
            showAlert(title: "Error", message: "Please select your college")
            return
        }

        guard let name = fullNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert(title: "Error", message: "Please enter your full name")
            return
        }
        
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address")
            return
        }

        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: email) else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email address")
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
        
        guard email.hasSuffix("@\(institute.domain)") else {
            showAlert(title: "Invalid Email", message: "Email must end with @\(institute.domain) for \(institute.name)")
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
        
        performRegistration(
            institute: institute,
            name: name,
            email: email,
            regNumber: reg,
            password: password
        )
    }
    
    private func performRegistration(
        institute: SupabaseManager.Institute,
        name: String,
        email: String,
        regNumber: String,
        password: String
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
                            showAlert(title: "Pending Approval", message: "Your registration is pending approval from \(institute.name). Please wait for confirmation.")
                        case "approved":
                            showAlert(title: "Already Registered", message: "You are already registered and approved. Please login.")
                        case "declined":
                            showAlert(title: "Registration Declined", message: "Your registration was declined by \(institute.name). Please contact your administrator.")
                        default:
                            showAlert(title: "Already Registered", message: "This email is already registered.")
                        }
                    }
                    return
                }
                
                print("✅ No existing registration found, creating student registration...")
                _ = try await SupabaseManager.shared.registerStudent(
                    fullName: name,
                    email: email,
                    regNumber: regNumber,
                    password: password,
                    instituteDomain: institute.domain
                )
                
                // Update UI on main thread
                await MainActor.run {
                    hideLoadingIndicator()
                    signUpButton.isEnabled = true
                    self.showAlert(
                        title: "Registration Submitted",
                        message: "Your information has been submitted successfully. You can log in once your college approves your registration."
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
