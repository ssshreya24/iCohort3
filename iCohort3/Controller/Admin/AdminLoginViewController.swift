//
//  AdminLoginViewController.swift
//  iCohort3
//
//  Created by user@56 on 11/01/26.
//

import UIKit

class AdminLoginViewController: UIViewController,
                                UIPickerViewDelegate,
                                UIPickerViewDataSource{
    
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var dropdownButton: UIButton!
    @IBOutlet weak var universityTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var signInButton: UIButton!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    // MARK: - Data
    let universities = [
        "SRM Institute of Science and Technology",
        "Graphic Era",
        "Galgotias",
        "Chitkara"
    ]
    
    let universityPicker = UIPickerView()
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupUniversityDropdown()
    }
    
    // MARK: - UI Setup
    func setupUI() {
        let radius: CGFloat = 23
        
        universityTextField.layer.cornerRadius = radius
        emailTextField.layer.cornerRadius = radius
        passwordTextField.layer.cornerRadius = radius
        confirmPasswordTextField.layer.cornerRadius = radius
        signInButton.layer.cornerRadius = radius
        
        universityTextField.clipsToBounds = true
        emailTextField.clipsToBounds = true
        passwordTextField.clipsToBounds = true
        confirmPasswordTextField.clipsToBounds = true
        signInButton.clipsToBounds = true
        
        // Disable typing cursor for dropdown field
        universityTextField.tintColor = .clear
    }
    
    // MARK: - Dropdown Setup
    func setupUniversityDropdown() {
        universityPicker.delegate = self
        universityPicker.dataSource = self
        
        universityTextField.inputView = universityPicker
        
        // Toolbar with Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let space = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .prominent,
            target: self,
            action: #selector(doneTapped)
        )
        
        toolbar.items = [space, doneButton]
        universityTextField.inputAccessoryView = toolbar
    }
    
    // MARK: - Navigation
    private func navigateToSignUp() {
        // Check if AdminSignUpViewController is XIB-based or Storyboard-based
        
        // For XIB-based (most likely based on your setup)
        let signUpVC = AdminSignUpViewController(nibName: "AdminSignUpViewController", bundle: nil)
        navigationController?.pushViewController(signUpVC, animated: true)
        
        // For Storyboard-based (uncomment if using storyboard)
        // let sb = UIStoryboard(name: "Main", bundle: nil)
        // guard let signUpVC = sb.instantiateViewController(withIdentifier: "AdminSignUpVC") as? AdminSignUpViewController else {
        //     print("ERROR: Couldn't instantiate AdminSignUpViewController")
        //     return
        // }
        // navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    // MARK: - Picker View DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return universities.count
    }

    // MARK: - Picker View Delegate
    func pickerView(_ pickerView: UIPickerView,
                    titleForRow row: Int,
                    forComponent component: Int) -> String? {
        return universities[row]
    }

    func pickerView(_ pickerView: UIPickerView,
                    didSelectRow row: Int,
                    inComponent component: Int) {
        universityTextField.text = universities[row]
    }

    // MARK: - Actions
    @objc func doneTapped() {
        universityTextField.resignFirstResponder()
    }
    
    
    @IBAction func registerTapped(_ sender: Any) {
        print("Register button tapped. Navigating to AdminSignUpViewController.")
        navigateToSignUp()
    }
    
    @IBAction func backButton(_ sender: Any) {
        // Navigate back to UserSelectionViewController
        if let navigationController = navigationController {
            // Pop back to previous view controller (UserSelectionViewController)
            navigationController.popViewController(animated: true)
        } else {
            // Dismiss if presented modally
            dismiss(animated: true, completion: nil)
        }
    }
    
    
    
}
