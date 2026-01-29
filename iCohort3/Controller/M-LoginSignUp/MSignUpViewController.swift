//
//  MSignUpViewController.swift
//  iCohort3
//
//  Updated to register mentors with pending approval status (Firestore only, no Firebase Auth)
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
    
    private var loadingIndicator: UIActivityIndicatorView?

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
        
        passwordField.isSecureTextEntry = true
        confirmField.isSecureTextEntry = true
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
        
        // Validate all fields
        guard let name = fullNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty else {
            showAlert(title: "Error", message: "Please enter your full name")
            return
        }
        
        guard let email = emailField.text?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !email.isEmpty else {
            showAlert(title: "Error", message: "Please enter your email address")
            return
        }
        
        guard let employeeID = employeeField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !employeeID.isEmpty else {
            showAlert(title: "Error", message: "Please enter your employee ID")
            return
        }
        
        guard let designation = designationField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !designation.isEmpty else {
            showAlert(title: "Error", message: "Please enter your designation")
            return
        }
        
        guard let department = departmentField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !department.isEmpty else {
            showAlert(title: "Error", message: "Please enter your department")
            return
        }
        
        guard let institute = instituteField.text, !institute.isEmpty else {
            showAlert(title: "Error", message: "Please select your institute")
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
        
        // Perform registration
        performRegistration(
            name: name,
            email: email,
            employeeID: employeeID,
            designation: designation,
            department: department,
            institute: institute,
            password: password
        )
    }
    
    private func performRegistration(
        name: String,
        email: String,
        employeeID: String,
        designation: String,
        department: String,
        institute: String,
        password: String
    ) {
        Task {
            do {
                print("📝 Starting mentor registration for:", email)
                
                // Check if mentor already registered
                if let existingMentor = try await FirebaseManager.shared.getMentorRegistration(email: email) {
                    print("⚠️ Mentor already exists with status:", existingMentor.approvalStatus)
                    
                    await MainActor.run {
                        hideLoadingIndicator()
                        signUpButton.isEnabled = true
                        
                        switch existingMentor.approvalStatus {
                        case .pending:
                            showAlert(title: "Pending Approval", message: "Your registration is pending approval from the institute. Please wait for confirmation.")
                        case .approved:
                            showAlert(title: "Already Registered", message: "You are already registered and approved. Please login.")
                        case .declined:
                            showAlert(title: "Registration Declined", message: "Your registration was declined by the institute. Please contact your administrator.")
                        }
                    }
                    return
                }
                
                print("✅ No existing registration found, proceeding with new registration")
                
                // Register mentor in Firestore with pending status
                let mentorId = try await FirebaseManager.shared.registerMentor(
                    fullName: name,
                    email: email,
                    employeeId: employeeID,
                    designation: designation,
                    department: department,
                    instituteName: institute,
                    password: password
                )
                
                print("✅ Mentor registered in Firestore with ID:", mentorId)
                
                await MainActor.run {
                    hideLoadingIndicator()
                    signUpButton.isEnabled = true
                    
                    showAlert(
                        title: "Registration Submitted",
                        message: "Your mentor registration has been submitted for approval. You will be able to login once your institute (\(institute)) approves your registration."
                    ) {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
                
            } catch FirebaseManagerError.alreadyRegistered {
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
    
    private func hideLoadingIndicator() {
        DispatchQueue.main.async {
            self.view.viewWithTag(9999)?.removeFromSuperview()
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

extension MSignUpViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == instituteField { return false }
        return true
    }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField == instituteField { return false }
        return true
    }
}
