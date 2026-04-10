//
//  LoginViewController.swift
//  iCohort3
//
//  ✅ SUPABASE ONLY - No Firebase dependencies
//  ✅ Fixed: login hang, loading indicator race condition, 15s timeout added
//

import UIKit

class LoginViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var containerView2: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var passwordVisibilityToggle: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var rememberMeButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    
    private var backdropView: UIView?
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

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
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
            && UserDefaults.standard.string(forKey: "remembered_user_role") == "student"
        rememberMeButton.isSelected = shouldRemember
        if shouldRemember {
            emailTextField.text = UserDefaults.standard.string(forKey: "remembered_email")
        }
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
    
    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        let emailVerificationVC = EmailVerificationViewController()
        if let nav = navigationController {
            nav.pushViewController(emailVerificationVC, animated: true)
        } else {
            emailVerificationVC.modalPresentationStyle = .fullScreen
            present(emailVerificationVC, animated: true)
        }
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let signUpVC = SignUpViewController(nibName: "SignUpViewController", bundle: nil)
        if let nav = navigationController {
            nav.pushViewController(signUpVC, animated: true)
        } else {
            signUpVC.modalPresentationStyle = .fullScreen
            present(signUpVC, animated: true)
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
                present(navRoot, animated: true)
            }
        }
    }
    
    @IBAction func signInTapped(_ sender: UIButton) {
        print("\n===========================================")
        print("🔐 STUDENT LOGIN STARTED (SUPABASE)")
        print("===========================================")
        
        guard let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
              !email.isEmpty else {
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
    
    // MARK: - Login Logic
    
    private func performLogin(email: String, password: String, shouldRemember: Bool) {
        Task {
            do {
                print("📝 Starting direct student login...")

                let session = try await withLoginTimeout {
                    try await SupabaseManager.shared.loginDirect(
                        email: email,
                        password: password,
                        role: .student
                    )
                }
                print("✅ Student login verified")

                finishLogin {
                    self.handlePrivacyConsentIfNeeded(email: email, role: .student) {
                        self.finalizeDirectLogin(session: session, shouldRemember: shouldRemember)
                    }
                }
                
            } catch let error as NSError where error.domain == "LoginTimeout" {
                print("❌ Login timed out")
                finishLogin {
                    self.showAlert(
                        title: "Connection Timeout",
                        message: "Could not connect to the server. Please check your internet and try again."
                    )
                }
                
            } catch {
                print("❌ Login error:", error.localizedDescription)
                finishLogin {
                    self.showAlert(title: "Login Failed", message: error.localizedDescription)
                }
            }
        }
    }

    /// Always called at end of login — hides loader, re-enables button, runs optional UI block.
    /// Marked @MainActor so it's always safe to update UI directly — no DispatchQueue needed.
    @MainActor
    private func finishLogin(action: (() -> Void)? = nil) {
        hideLoadingIndicator()
        signInButton.isEnabled = true
        action?()
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
    
    /// Races the login operation against a 15-second timeout.
    private func withLoginTimeout<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask { try await operation() }
            group.addTask {
                try await Task.sleep(nanoseconds: 15_000_000_000)
                throw NSError(
                    domain: "LoginTimeout",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
                )
            }
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    // MARK: - Navigation
    
    func handleLoginSuccess() {
        let tab = MainTabBarViewController()
        let window = view.window ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        guard let window else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            window.rootViewController = tab
        }
    }

    @MainActor
    private func finalizeDirectLogin(
        session: SupabaseManager.LoginOTPSession,
        shouldRemember: Bool
    ) {
        guard let personId = session.person_id, !personId.isEmpty else {
            showAlert(title: "Login Failed", message: "Student session is missing person id.")
            return
        }

        UserDefaults.standard.set(personId, forKey: "current_person_id")
        UserDefaults.standard.set(session.display_name ?? "Student", forKey: "current_user_name")
        UserDefaults.standard.set(session.email, forKey: "current_user_email")
        UserDefaults.standard.set("student", forKey: "current_user_role")
        UserDefaults.standard.set(true, forKey: "is_logged_in")

        applyRememberMePreference(shouldRemember: shouldRemember, email: session.email, role: "student")
        handleLoginSuccess()
    }

    private func applyRememberMePreference(shouldRemember: Bool, email: String, role: String) {
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
    
    // MARK: - Loading Indicator
    // ✅ @MainActor eliminates the need for DispatchQueue.main.async wrappers,
    //    which caused race conditions with the previous implementation.
    
    @MainActor
    func showLoadingIndicator() {
        hideLoadingIndicator() // clear stale state first
        
        let backdrop = UIView(frame: view.bounds)
        backdrop.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        backdrop.tag = 9999
        
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        indicator.center = CGPoint(x: backdrop.bounds.midX, y: backdrop.bounds.midY)
        indicator.startAnimating()
        
        backdrop.addSubview(indicator)
        view.addSubview(backdrop)
        view.isUserInteractionEnabled = false
        
        backdropView = backdrop
        loadingIndicator = indicator
        print("🔄 Loading indicator shown")
    }
    
    @MainActor
    func hideLoadingIndicator() {
        backdropView?.removeFromSuperview()
        backdropView = nil
        loadingIndicator?.stopAnimating()
        loadingIndicator?.removeFromSuperview()
        loadingIndicator = nil
        view.isUserInteractionEnabled = true
        print("✋ Loading indicator hidden")
    }
    
    // MARK: - Alert
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
