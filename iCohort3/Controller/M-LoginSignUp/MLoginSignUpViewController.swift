//
//  MLoginSignUpViewController.swift
//  iCohort3
//

import UIKit
import FirebaseAuth

class MLoginSignUpViewController: UIViewController {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var containerView2: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var passwordVisibilityToggle: UIButton!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var rememberMeButton: UIButton!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        
        // Auto-login if user is already authenticated
        if Auth.auth().currentUser != nil {
            handleLoginSuccess()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // hide any system nav bar if design requires it
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    func setupUI() {
        passwordTextField.isSecureTextEntry = true
        passwordVisibilityToggle.setImage(UIImage(systemName: "eye.slash.fill"), for: .normal)

        rememberMeButton.isSelected = false
        rememberMeButton.setImage(UIImage(systemName: "square"), for: .normal)
        rememberMeButton.setImage(UIImage(systemName: "checkmark.square.fill"), for: .selected)

        signInButton.layer.cornerRadius = 20
        signInButton.layer.masksToBounds = true

        containerView.layer.cornerRadius = 23
        containerView.layer.masksToBounds = true

        containerView2.layer.cornerRadius = 23
        containerView2.layer.masksToBounds = true
    }

    @IBAction func togglePasswordVisibility(_ sender: UIButton) {
        passwordTextField.isSecureTextEntry.toggle()
        let imageName = passwordTextField.isSecureTextEntry ? "eye.slash.fill" : "eye.fill"
        (sender as AnyObject).setImage(UIImage(systemName: imageName), for: .normal)
    }

    @IBAction func rememberMeTapped(_ sender: UIButton) {
        sender.isSelected.toggle()
        print("Remember Me is now \(sender.isSelected ? "CHECKED" : "UNCHECKED")")
    }

    @IBAction func forgotPasswordTapped(_ sender: UIButton) {
        // push the XIB OTP VC so nav stack is preserved
        let otpVC = MOTPViewController(nibName: "MOTPViewController", bundle: nil)
        navigationController?.pushViewController(otpVC, animated: true)
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        // If there is somewhere to pop to — pop.
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            return
        }

        // If this is the root (no previous VC), navigate to UserSelection (initial screen).
        // Ensure your initial screen's storyboard ID is set to "UserSelectionVC"
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let userSelection = sb.instantiateViewController(withIdentifier: "UserSelectionVC") as? UserSelectionViewController {
            let navRoot = UINavigationController(rootViewController: userSelection)
            navRoot.modalPresentationStyle = .fullScreen

            // replace the window root safely
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                window.rootViewController = navRoot
                window.makeKeyAndVisible()
            } else if let window = view.window {
                window.rootViewController = navRoot
                window.makeKeyAndVisible()
            } else {
                // fallback: present modally
                present(navRoot, animated: true, completion: nil)
            }
        } else {
            // fallback: nothing found — print for debugging
            print("Could not find UserSelectionVC in Main.storyboard. Set the storyboard ID.")
        }
    }

    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let signUpVC = MSignUpViewController(nibName: "MSignUpViewController", bundle: nil)
        navigationController?.pushViewController(signUpVC, animated: true)
    }

    @IBAction func signInTapped(_ sender: UIButton) {
        print("Sign In button tapped")
        
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(title: "Error", message: "Email or password cannot be empty")
            return
        }
        
        signInButton.isEnabled = false
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            self?.signInButton.isEnabled = true
            
            if let error = error {
                self?.showAlert(title: "Login Failed", message: error.localizedDescription)
                return
            }
            
            print("✅ Firebase login success:", result?.user.email ?? "")
            
            if self?.rememberMeButton.isSelected == true {
                UserDefaults.standard.set(true, forKey: "isLoggedIn")
            }
            
            self?.handleLoginSuccess()
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
    
    // MARK: - Helper to show alerts
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
