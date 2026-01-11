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
    }
