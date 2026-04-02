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

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        setupUI()
        setupPlaceholders()
        confirmButton.backgroundColor = UIColor(red: 0x77/255, green: 0x9C/255, blue: 0xB3/255, alpha: 1)
        confirmButton.setTitleColor(.white, for: .normal)
        backButton.tintColor = .white
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func setupPlaceholders() {
        newPasswordTextField.placeholder = "Enter the new password"
        confirmPasswordTextField.placeholder = "Confirm the new password"
        newPasswordTextField.textColor = .black
        confirmPasswordTextField.textColor = .black
        newPasswordTextField.isSecureTextEntry = true
        confirmPasswordTextField.isSecureTextEntry = true
    }

    private func setupUI() {
        passwordContainer.layer.cornerRadius = 20
        passwordContainer.layer.masksToBounds = true
        passwordContainer.backgroundColor = .white
        confirmPassword.layer.cornerRadius = 20
        confirmPassword.layer.masksToBounds = true
        confirmButton.layer.cornerRadius = 20
        confirmButton.layer.masksToBounds = true
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
