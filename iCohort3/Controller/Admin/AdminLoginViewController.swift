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
    private let rememberMeButton = UIButton(type: .system)
    private let rememberMeLabel = UILabel()
    private let forgotPasswordButton = UIButton(type: .system)
    private let rememberRowStack = UIStackView()
    private let passwordVisibilityButton = UIButton(type: .system)
    private var didConfigureAuxiliaryControls = false
    private var didConfigurePasswordToggle = false
    
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
        styleStaticText()

        rememberMeButton.configuration = nil
        rememberMeButton.backgroundColor = .clear
        rememberMeButton.tintColor = .clear
        rememberMeButton.layer.shadowOpacity = 0
        rememberMeButton.contentEdgeInsets = .zero
        rememberMeButton.imageEdgeInsets = .zero
        rememberMeButton.adjustsImageWhenHighlighted = false
        rememberMeButton.imageView?.contentMode = .scaleAspectFit
        rememberMeButton.setImage(makeRememberMeImage(selected: false), for: .normal)
        rememberMeButton.setImage(makeRememberMeImage(selected: true), for: .selected)

        let shouldRemember = UserDefaults.standard.bool(forKey: "remember_me")
            && UserDefaults.standard.string(forKey: "remembered_user_role") == "admin"
        rememberMeButton.isSelected = shouldRemember
        if shouldRemember {
            emailTextField.text = UserDefaults.standard.string(forKey: "remembered_email")
        }

        rememberMeLabel.text = "Remember Me"
        rememberMeLabel.font = .systemFont(ofSize: 12, weight: .regular)
        rememberMeLabel.textColor = .label

        forgotPasswordButton.setTitle("Forgot Password?", for: .normal)
        forgotPasswordButton.setTitleColor(.systemRed, for: .normal)
        forgotPasswordButton.titleLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        forgotPasswordButton.addTarget(self, action: #selector(forgotPasswordTapped), for: .touchUpInside)

        rememberMeButton.addTarget(self, action: #selector(rememberMeTapped), for: .touchUpInside)
        installAuxiliaryControlsIfNeeded()
        installPasswordVisibilityToggleIfNeeded()
    }

    private func styleStaticText() {
        emailTextField.placeholder = "Enter Admin Email ID"
        passwordTextField.placeholder = "Enter Password"

        signInButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .medium)
        registerButton.setTitle("Sign Up", for: .normal)
        registerButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .regular)

        for case let label as UILabel in view.allDescendantSubviews() {
            switch label.text?.trimmingCharacters(in: .whitespacesAndNewlines) {
            case "SRM Mail ID", "Admin Email ID":
                label.text = "Admin Email ID"
                label.font = .systemFont(ofSize: 17, weight: .semibold)
            case "Password", "Admin Password":
                label.text = "Password"
                label.font = .systemFont(ofSize: 17, weight: .semibold)
            case "New University?", "Dont have an account?", "Don't have an account?":
                label.text = "Dont have an account?"
                label.font = .systemFont(ofSize: 17, weight: .regular)
                label.adjustsFontSizeToFitWidth = true
                label.minimumScaleFactor = 0.82
            default:
                continue
            }
        }
    }

    private func installAuxiliaryControlsIfNeeded() {
        guard !didConfigureAuxiliaryControls else { return }
        didConfigureAuxiliaryControls = true

        let leftStack = UIStackView(arrangedSubviews: [rememberMeButton, rememberMeLabel])
        leftStack.axis = .horizontal
        leftStack.alignment = .center
        leftStack.spacing = 4

        rememberRowStack.axis = .horizontal
        rememberRowStack.alignment = .center
        rememberRowStack.distribution = .equalSpacing
        rememberRowStack.translatesAutoresizingMaskIntoConstraints = false
        rememberRowStack.addArrangedSubview(leftStack)
        rememberRowStack.addArrangedSubview(forgotPasswordButton)
        view.addSubview(rememberRowStack)

        if let topConstraint = view.constraints.first(where: { constraint in
            let firstView = constraint.firstItem as? UIView
            let secondView = constraint.secondItem as? UIView
            return ((firstView == signInButton && secondView == passwordView) ||
                    (firstView == passwordView && secondView == signInButton)) &&
                   (constraint.firstAttribute == .top || constraint.secondAttribute == .top)
        }) {
            topConstraint.isActive = false
        }

        NSLayoutConstraint.activate([
            rememberMeButton.widthAnchor.constraint(equalToConstant: 30),
            rememberMeButton.heightAnchor.constraint(equalToConstant: 24),

            rememberRowStack.topAnchor.constraint(equalTo: passwordView.bottomAnchor, constant: 14),
            rememberRowStack.leadingAnchor.constraint(equalTo: emailView.leadingAnchor),
            rememberRowStack.trailingAnchor.constraint(equalTo: emailView.trailingAnchor),

            signInButton.topAnchor.constraint(equalTo: rememberRowStack.bottomAnchor, constant: 18)
        ])
    }

    private func installPasswordVisibilityToggleIfNeeded() {
        guard !didConfigurePasswordToggle else { return }
        didConfigurePasswordToggle = true

        passwordVisibilityButton.translatesAutoresizingMaskIntoConstraints = false
        passwordVisibilityButton.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        passwordVisibilityButton.tintColor = .label
        passwordVisibilityButton.addTarget(self, action: #selector(togglePasswordVisibility), for: .touchUpInside)
        passwordView.addSubview(passwordVisibilityButton)

        if let trailingConstraint = passwordView.constraints.first(where: { constraint in
            let firstView = constraint.firstItem as? UIView
            let secondView = constraint.secondItem as? UIView
            return ((firstView == passwordTextField && secondView == passwordView) ||
                    (firstView == passwordView && secondView == passwordTextField)) &&
                   (constraint.firstAttribute == .trailing || constraint.secondAttribute == .trailing)
        }) {
            trailingConstraint.isActive = false
        }

        NSLayoutConstraint.activate([
            passwordVisibilityButton.centerYAnchor.constraint(equalTo: passwordView.centerYAnchor),
            passwordVisibilityButton.trailingAnchor.constraint(equalTo: passwordView.trailingAnchor, constant: -14),
            passwordVisibilityButton.widthAnchor.constraint(equalToConstant: 24),
            passwordVisibilityButton.heightAnchor.constraint(equalToConstant: 24),
            passwordTextField.trailingAnchor.constraint(equalTo: passwordVisibilityButton.leadingAnchor, constant: -12)
        ])
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
                try await SupabaseManager.shared.startLoginOTP(email: email, password: password, role: .admin)
                print("✅ Admin verification code sent")
                
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.signInButton.isEnabled = true
                    self.navigateToOTPVerification(email: email, shouldRemember: self.rememberMeButton.isSelected)
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

    private func navigateToOTPVerification(email: String, shouldRemember: Bool) {
        let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
        otpVC.configureForLoginVerification(email: email, role: .admin, shouldRemember: shouldRemember)
        navigationController?.pushViewController(otpVC, animated: true)
    }

    @objc private func rememberMeTapped() {
        rememberMeButton.isSelected.toggle()
    }

    @objc private func forgotPasswordTapped() {
        let emailVerificationVC = EmailVerificationViewController(role: .admin)
        navigationController?.pushViewController(emailVerificationVC, animated: true)
    }

    @objc private func togglePasswordVisibility() {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        passwordVisibilityButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    @IBAction func registerTapped(_ sender: Any) {
        print("Register button tapped. Navigating to AdminSignUpViewController.")
        navigateToSignUp()
    }
    
    @IBAction func backButton(_ sender: Any) {
        if let navigationController = navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
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
                    present(navRoot, animated: true)
                }
            }
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

    private func makeRememberMeImage(selected: Bool) -> UIImage? {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let rounded = UIBezierPath(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: 5)

            if selected {
                UIColor.black.setFill()
                rounded.fill()

                let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
                let check = UIImage(systemName: "checkmark", withConfiguration: config)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal)
                check?.draw(in: CGRect(x: 5.5, y: 5.5, width: 13, height: 13))
            } else {
                UIColor.clear.setFill()
                rounded.fill()
                UIColor.black.setStroke()
                rounded.lineWidth = 1.6
                rounded.stroke()
            }
        }.withRenderingMode(.alwaysOriginal)
    }
}

private extension UIView {
    func allDescendantSubviews() -> [UIView] {
        subviews + subviews.flatMap { $0.allDescendantSubviews() }
    }
}
