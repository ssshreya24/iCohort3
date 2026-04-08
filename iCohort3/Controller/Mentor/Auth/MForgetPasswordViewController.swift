//
//  MForgetPasswordViewController.swift
//

import UIKit

class MForgetPasswordViewController: UIViewController {

    @IBOutlet weak var confirmButton: UIButton!
    @IBOutlet weak var confirmPassword: UIView!
    @IBOutlet weak var passwordContainer: UIView!

    @IBOutlet weak var confirmPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    private var didInstallAnimatedLogo = false

    override func viewDidLoad() {
        super.viewDidLoad()
        hideAnimatedAuthLogoPlaceholderIfNeeded()
        enableKeyboardDismissOnTap()
        setupUI()
        setupPlaceholders()
        confirmButton.setTitleColor(.white, for: .normal)
        applyAuthSymbolTint()
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
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

    private func setupPlaceholders() {
        let placeholderColor = UIColor.secondaryLabel
        newPasswordTextField.attributedPlaceholder = NSAttributedString(string: "Enter the new password", attributes: [.foregroundColor: placeholderColor])
        confirmPasswordTextField.attributedPlaceholder = NSAttributedString(string: "Confirm the new password", attributes: [.foregroundColor: placeholderColor])
        newPasswordTextField.textColor = .label
        confirmPasswordTextField.textColor = .label
        newPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
    }

    private func setupUI() {
        view.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.10, blue: 0.13, alpha: 1)
                : UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)
        }
        let containerBg = UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.12) : .white
        }
        passwordContainer.layer.cornerRadius = 20
        passwordContainer.layer.masksToBounds = true
        passwordContainer.backgroundColor = containerBg
        passwordContainer.layer.borderWidth = 0.5
        passwordContainer.layer.borderColor = UIColor.opaqueSeparator.cgColor
        confirmPassword.layer.cornerRadius = 20
        confirmPassword.layer.masksToBounds = true
        confirmPassword.backgroundColor = containerBg
        confirmPassword.layer.borderWidth = 0.5
        confirmPassword.layer.borderColor = UIColor.opaqueSeparator.cgColor
        confirmButton.layer.cornerRadius = 20
        confirmButton.layer.masksToBounds = true
        backButton.tintColor = UIColor { trait in trait.userInterfaceStyle == .dark ? .white : .black }
    }

    @IBAction func confirmButtonTapped(_ sender: UIButton) {
        print("Confirm button tapped")

        // If you want absolute navigation to MLogin (replacing root) — do it here.
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = storyboard.instantiateViewController(withIdentifier: "MLoginVC") as? MLoginSignUpViewController else {
            print("❌ Could not load MLoginVC")
            return
        }

        // Option A: Replace window root with login (like you had)
        // Wrap in nav controller so login has nav
        let nav = UINavigationController(rootViewController: loginVC)
        nav.modalPresentationStyle = .fullScreen

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            window.rootViewController = nav
            window.makeKeyAndVisible()
            return
        } else if let window = view.window {
            window.rootViewController = nav
            window.makeKeyAndVisible()
            return
        }

        // Option B (fallback): present login (should be avoided if you want clean root replacement)
        present(nav, animated: true, completion: nil)
    }

    // robust back: pop if possible; otherwise go to UserSelection as root
    @objc private func backTapped() {
        if let nav = navigationController, nav.viewControllers.count > 1 {
            nav.popViewController(animated: true)
            return
        }

        // If this VC is root (no previous controller), go to UserSelection (initial)
        let sb = UIStoryboard(name: "Main", bundle: nil)
        if let userSelection = sb.instantiateViewController(withIdentifier: "UserSelectionVC") as? UserSelectionViewController {
            let navRoot = UINavigationController(rootViewController: userSelection)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                window.rootViewController = navRoot
                window.makeKeyAndVisible()
                return
            } else if let window = view.window {
                window.rootViewController = navRoot
                window.makeKeyAndVisible()
                return
            } else {
                present(navRoot, animated: true, completion: nil)
                return
            }
        }

        // fallback
        dismiss(animated: true, completion: nil)
    }
}
