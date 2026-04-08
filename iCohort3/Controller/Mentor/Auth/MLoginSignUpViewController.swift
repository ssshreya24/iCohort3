//
//  MLoginSignUpViewController.swift
//  iCohort3
//
//  ✅ SUPABASE ONLY - No Firebase dependencies
//

import UIKit

class MLoginSignUpViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var containerView2: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var passwordVisibilityToggle: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var rememberMeButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    private var loadingIndicator: UIActivityIndicatorView?
    private var didInstallAnimatedLogo = false
    private var pendingLoginNavigation: (() -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        hideAnimatedAuthLogoPlaceholderIfNeeded()
        enableKeyboardDismissOnTap()
        setupUI()
        applyAuthSymbolTint()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        refreshAnimatedAuthLogoIfNeeded()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        updateRememberMeAppearance()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if !didInstallAnimatedLogo {
            didInstallAnimatedLogo = installAnimatedAuthLogoIfNeeded()
        }
    }

    func setupUI() {
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1)
                : UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
        }

        passwordTextField.isSecureTextEntry = true
        passwordVisibilityToggle.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        passwordVisibilityToggle.tintColor = .label

        rememberMeButton.configuration = nil
        rememberMeButton.backgroundColor = .clear
        rememberMeButton.tintColor = .clear
        rememberMeButton.layer.shadowOpacity = 0
        rememberMeButton.layer.masksToBounds = false
        rememberMeButton.imageView?.contentMode = .scaleAspectFit
        updateRememberMeAppearance()
        let shouldRemember = UserDefaults.standard.bool(forKey: "remember_me")
            && UserDefaults.standard.string(forKey: "remembered_user_role") == "mentor"
        rememberMeButton.isSelected = shouldRemember
        if shouldRemember {
            emailTextField.text = UserDefaults.standard.string(forKey: "remembered_email")
        }

        signInButton.layer.cornerRadius = 20
        signInButton.layer.masksToBounds = true

        containerView.layer.cornerRadius = 23
        containerView.layer.masksToBounds = true
        containerView2.layer.cornerRadius = 23
        containerView2.layer.masksToBounds = true

        let containerBg = UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark 
                ? UIColor.white.withAlphaComponent(0.12) 
                : UIColor.white
        }
        containerView.backgroundColor = containerBg
        containerView2.backgroundColor = containerBg
        containerView.layer.borderWidth = 0.5
        containerView2.layer.borderWidth = 0.5
        containerView.layer.borderColor = UIColor.opaqueSeparator.cgColor
        containerView2.layer.borderColor = UIColor.opaqueSeparator.cgColor
        
        emailTextField.textColor = .label
        passwordTextField.textColor = .label
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter SRM Mail ID",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Enter Password",
            attributes: [.foregroundColor: UIColor.secondaryLabel]
        )

        styleAuthBackButton(backButton)
    }

    @IBAction func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        sender.setImage(UIImage(systemName: imageName), for: .normal)
    }

    @IBAction func rememberMeTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        print("Remember Me is now \(sender.isSelected ? "CHECKED" : "UNCHECKED")")
    }

    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let emailVerificationVC = EmailVerificationViewController(role: .mentor)
        navigationController?.pushViewController(emailVerificationVC, animated: true)
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            return
        }

        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let userSelection = sb.instantiateViewController(withIdentifier: "UserSelectionVC") as? UserSelectionViewController {
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

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let signUpVC = MSignUpViewController(nibName: "MSignUpViewController", bundle: nil)
        navigationController?.pushViewController(signUpVC, animated: true)
    }

    @IBAction func signInTapped(_ sender: UIButton) {
        print("\n===========================================")
        print("🔐 MENTOR LOGIN STARTED (SUPABASE)")
        print("===========================================")
        
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
        
        performLogin(email: email, password: password, shouldRemember: rememberMeButton.isSelected)
    }
    
    private func performLogin(email: String, password: String, shouldRemember: Bool) {
        Task {
            do {
                if let debugSession = try await TestingPurpose.attemptDebugLogin(
                    email: email,
                    password: password,
                    role: .mentor
                ) {
                    print("🧪 Using DEBUG mentor test login")
                    await MainActor.run {
                        hideLoadingIndicator()
                        signInButton.isEnabled = true
                        self.handlePrivacyConsentIfNeeded(email: email, role: .mentor) {
                            TestingPurpose.completeDebugLogin(debugSession, shouldRemember: shouldRemember, from: self)
                        }
                    }
                    return
                }

                print("📝 Starting mentor login OTP flow...")
                
                try await SupabaseManager.shared.startLoginOTP(email: email, password: password, role: .mentor)
                print("✅ Verification code sent")
                
                await MainActor.run {
                    hideLoadingIndicator()
                    signInButton.isEnabled = true
                    self.handlePrivacyConsentIfNeeded(email: email, role: .mentor) {
                        self.navigateToOTPVerification(email: email, role: .mentor, shouldRemember: shouldRemember)
                    }
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

    private func navigateToOTPVerification(
        email: String,
        role: SupabaseManager.LoginOTPUserRole,
        shouldRemember: Bool
    ) {
        let otpVC = OTPViewController(nibName: "OTPViewController", bundle: nil)
        otpVC.configureForLoginVerification(email: email, role: role, shouldRemember: shouldRemember)
        navigationController?.pushViewController(otpVC, animated: true)
    }

    @MainActor
    private func handlePrivacyConsentIfNeeded(
        email: String,
        role: SupabaseManager.LoginOTPUserRole,
        onAccepted: @escaping () -> Void
    ) {
        guard !PrivacyPolicySupport.hasAcceptedConsent(email: email, role: role.rawValue) else {
            onAccepted()
            return
        }

        pendingLoginNavigation = onAccepted
        PrivacyPolicySupport.presentConsent(from: self, email: email, role: role.rawValue) { [weak self] in
            let action = self?.pendingLoginNavigation
            self?.pendingLoginNavigation = nil
            action?()
        }
    }

    func handleLoginSuccess() {
        let tab = MentorMainTabBarViewController()

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
    
    func showLoadingIndicator() {
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
            
            print("🔄 Loading indicator shown")
        }
    }
    
    func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.view.viewWithTag(9999)?.removeFromSuperview()
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

    private func updateRememberMeAppearance() {
        rememberMeButton.setImage(makeRememberMeImage(selected: false), for: .normal)
        rememberMeButton.setImage(makeRememberMeImage(selected: true), for: .selected)
    }

    private func makeRememberMeImage(selected: Bool) -> UIImage? {
        let size = CGSize(width: 24, height: 24)
        let renderer = UIGraphicsImageRenderer(size: size)
        let strokeColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black

        return renderer.image { _ in
            let rect = CGRect(origin: .zero, size: size)
            let rounded = UIBezierPath(roundedRect: rect.insetBy(dx: 1.5, dy: 1.5), cornerRadius: 5)

            if selected {
                strokeColor.setFill()
                rounded.fill()

                let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
                let check = UIImage(systemName: "checkmark", withConfiguration: config)?
                    .withTintColor(.white, renderingMode: .alwaysOriginal)
                check?.draw(in: CGRect(x: 5.5, y: 5.5, width: 13, height: 13))
            } else {
                UIColor.clear.setFill()
                rounded.fill()
                strokeColor.setStroke()
                rounded.lineWidth = 1.6
                rounded.stroke()
            }
        }.withRenderingMode(.alwaysOriginal)
    }
}
