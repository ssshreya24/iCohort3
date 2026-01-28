//
//  MSignUpViewController.swift
//  iCohort3
//
//  Created by user@51 on 13/11/25.
//

import UIKit
import FirebaseAuth

class MSignUpViewController: UIViewController {

    @IBOutlet weak var fullNameContainer: UIView!
    @IBOutlet weak var emailContainer: UIView!
    @IBOutlet weak var employeeField: UITextField!
    @IBOutlet weak var employeeView: UIView!
    @IBOutlet weak var designationField: UITextField!
    @IBOutlet weak var designationView: UIView!
    @IBOutlet weak var passwordContainer: UIView!
    @IBOutlet weak var confirmContainer: UIView!
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var fullNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var departmentField: UITextField!
    @IBOutlet weak var departmentView: UIView!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmField: UITextField!
    @IBOutlet weak var instituteView: UIView!
    @IBOutlet weak var instituteField: UITextField!
    @IBOutlet weak var instituteButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBackButton()
        roundViews()
        setupInstituteDropdownTextField()
        setupPlaceholders()
    }
    
    private let institutes = [
        "SRM Institute of Science and Technology",
        "Maharashtra Institute of Technology World Peace University (MIT-WPU)",
        "Galgotias University",
        "Graphic Era University, Dehradun",
        "Chandigarh University",
    ]

    func setupPlaceholders() {
        fullNameField.placeholder = "Enter your full name"
        emailField.placeholder = "Enter your email address"
        employeeField.placeholder = "Enter your employee ID"
        designationField.placeholder = "Enter your designation"
        departmentField.placeholder = "Enter your department"
        passwordField.placeholder = "Enter your password"
        confirmField.placeholder = "Confirm your password"
    }
    
    func roundViews() {
        let containers = [fullNameContainer, emailContainer, designationView, employeeView, departmentView, passwordContainer, confirmContainer, instituteView]
        
        for view in containers {
            view?.layer.cornerRadius = 20
            view?.layer.borderWidth  = 0
            view?.layer.borderColor  = UIColor.systemGray4.cgColor
            view?.layer.masksToBounds = true
            view?.backgroundColor    = .white
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
    
    private func setupInstituteDropdownTextField() {
        instituteField.placeholder = "Select Institute"
        instituteField.textColor = .label

        // Disable typing & keyboard
        instituteField.tintColor = .clear
        instituteField.delegate = self

        // Container view for proper sizing & centering
        let rightContainer = UIView(frame: CGRect(x: 0, y: 0, width: 44, height: 44))

        // Chevron button
        let chevronButton = UIButton(type: .system)

        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .medium)
        let chevronImage = UIImage(systemName: "chevron.down", withConfiguration: config)

        chevronButton.setImage(chevronImage, for: .normal)
        chevronButton.tintColor = .gray
        chevronButton.frame = CGRect(x: 10, y: 10, width: 24, height: 24)

        // Dropdown menu
        let actions = institutes.map { institute in
            UIAction(title: institute) { _ in
                self.instituteField.text = institute
            }
        }

        chevronButton.menu = UIMenu(children: actions)
        chevronButton.showsMenuAsPrimaryAction = true

        rightContainer.addSubview(chevronButton)

        instituteField.rightView = rightContainer
        instituteField.rightViewMode = .always
    }

    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .regular)
        let image = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(image, for: .normal)
        
        backButton.tintColor = UIColor.black
        backButton.backgroundColor = UIColor.white
        backButton.layer.cornerRadius = 22
        backButton.layer.masksToBounds = true
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
    
    @objc private func backTapped() {
        if let navigationController = self.navigationController {
            navigationController.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func signUpTapped(_ sender: UIButton) {
        view.endEditing(true)
        
        guard let name = fullNameField.text, !name.isEmpty,
              let email = emailField.text, !email.isEmpty,
              let employeeID = employeeField.text, !employeeID.isEmpty,
              let designation = designationField.text, !designation.isEmpty,
              let department = departmentField.text, !department.isEmpty,
              let institute = instituteField.text, !institute.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let confirm = confirmField.text, !confirm.isEmpty else {
            showAlert(title: "Error", message: "All fields are required")
            return
        }
        
        guard password == confirm else {
            showAlert(title: "Error", message: "Passwords do not match")
            return
        }
        
        signUpButton.isEnabled = false
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            self?.signUpButton.isEnabled = true
            
            if let error = error {
                self?.showAlert(title: "Signup Failed", message: error.localizedDescription)
                return
            }
            
            print("🎉 Firebase mentor user created:", result?.user.uid ?? "")
            
            // Optional: send verification email
            result?.user.sendEmailVerification()
            
            // TODO: Store additional mentor data (name, employeeID, designation, department, institute)
            // in Firestore database when you implement it
            
            self?.showAlert(title: "Success", message: "Mentor account created. Please login.") {
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

extension MSignUpViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == instituteField { return false }
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == instituteField { return false } // prevents keyboard
        return true
    }
}
