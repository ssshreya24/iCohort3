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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    func setupUI() {
        passwordTextField.isSecureTextEntry = true
        passwordVisibilityToggle.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)
        rememberMeButton.configuration = nil
        rememberMeButton.backgroundColor = .clear
        rememberMeButton.tintColor = .clear
        rememberMeButton.layer.shadowOpacity = 0
        rememberMeButton.layer.masksToBounds = false
        rememberMeButton.contentEdgeInsets = .zero
        rememberMeButton.imageEdgeInsets = .zero
        rememberMeButton.adjustsImageWhenHighlighted = false
        rememberMeButton.showsTouchWhenHighlighted = false
        rememberMeButton.imageView?.contentMode = .scaleAspectFit
        rememberMeButton.setImage(makeRememberMeImage(selected: false), for: .normal)
        rememberMeButton.setImage(makeRememberMeImage(selected: true), for: .selected)
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
        performLogin(email: email, password: password)
    }
    
    // MARK: - Login Logic
    
    private func performLogin(email: String, password: String) {
        Task {
            do {
                print("📝 Verifying student credentials in Supabase...")
                
                // ✅ Verify password hash from student_profiles with 15s timeout
                let isValid = try await withLoginTimeout {
                    try await SupabaseManager.shared.verifyStudentFromProfiles(
                        email: email,
                        password: password
                    )
                }
                
                guard isValid else {
                    await finishLogin {
                        self.showAlert(title: "Login Failed", message: "Invalid email or password. Please try again.")
                    }
                    return
                }
                print("✅ Credentials verified")
                
                // ✅ Fetch person_id
                guard let personId = try await SupabaseManager.shared.fetchStudentId(srmMail: email) else {
                    throw SupabaseError.studentNotFound
                }
                print("✅ Person ID:", personId)
                
                // ✅ Fetch full name (non-fatal if missing)
                let fullName = (try? await SupabaseManager.shared.fetchStudentFullName(personIdString: personId)) ?? "Student"
                print("✅ Student name:", fullName)
                
                // ✅ Save session to UserDefaults
                UserDefaults.standard.set(personId,   forKey: "current_person_id")
                UserDefaults.standard.set(fullName,   forKey: "current_user_name")
                UserDefaults.standard.set(email,      forKey: "current_user_email")
                UserDefaults.standard.set("student",  forKey: "current_user_role")
                UserDefaults.standard.set(true,       forKey: "is_logged_in")
                
                if await rememberMeButton.isSelected {
                    UserDefaults.standard.set(true,  forKey: "remember_me")
                    UserDefaults.standard.set(email, forKey: "remembered_email")
                    UserDefaults.standard.set("student", forKey: "remembered_user_role")
                } else {
                    UserDefaults.standard.set(false, forKey: "remember_me")
                    UserDefaults.standard.removeObject(forKey: "remembered_email")
                    UserDefaults.standard.removeObject(forKey: "remembered_user_role")
                }
                
                print("✅ Student login success — navigating to home")
                await finishLogin { self.handleLoginSuccess() }
                
            } catch SupabaseError.notApproved {
                print("❌ Not approved")
                await finishLogin {
                    self.showAlert(
                        title: "Pending Approval",
                        message: "Your registration is pending admin approval. Please wait for confirmation."
                    )
                }
                
            } catch SupabaseError.studentNotFound {
                print("❌ Student not found")
                await finishLogin {
                    self.showAlert(
                        title: "Not Registered",
                        message: "No account found for this email. Please sign up first."
                    )
                }
                
            } catch let error as NSError where error.domain == "LoginTimeout" {
                print("❌ Login timed out")
                await finishLogin {
                    self.showAlert(
                        title: "Connection Timeout",
                        message: "Could not connect to the server. Please check your internet and try again."
                    )
                }
                
            } catch {
                print("❌ Login error:", error.localizedDescription)
                await finishLogin {
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
