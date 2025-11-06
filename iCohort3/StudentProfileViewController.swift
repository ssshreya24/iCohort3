//
//  StudentProfileViewController.swift
//  iCohort3
//
//  Created by Shreya on 06/11/25.
//

import UIKit

class StudentProfileViewController: UIViewController {

   

        // MARK: - Outlets
        @IBOutlet weak var editButton: UIButton!

        @IBOutlet weak var firstNameField: UITextField!
        @IBOutlet weak var lastNameField: UITextField!
        @IBOutlet weak var departmentField: UITextField!
        @IBOutlet weak var srmMailField: UITextField!
        @IBOutlet weak var regNoField: UITextField!
        @IBOutlet weak var personalMailField: UITextField!
        @IBOutlet weak var contactNumberField: UITextField!

    @IBOutlet weak var profileCardView: UIView!
    @IBOutlet weak var academicCardView: UIView!
    @IBOutlet weak var personalCardView: UIView!

        private var isEditingProfile = false

        // Simple model to store data
        struct Profile {
            var firstName: String?
            var lastName: String?
            var department: String?
            var srmMail: String?
            var regNo: String?
            var personalMail: String?
            var contactNumber: String?
        }

        private var profile = Profile()

        override func viewDidLoad() {
            super.viewDidLoad()
            setupInitialState()
        }

        private func setupInitialState() {
            // Disable all textfields
            allTextFields.forEach { tf in
                tf.isEnabled = false
                tf.textColor = .systemBlue
                tf.placeholder = "Not Set"
            }
        }
    private func setupCardViews() {
        let cards = [profileCardView, academicCardView, personalCardView]

        for card in cards {
            guard let card = card else { continue }
            card.layer.cornerRadius = 16
            card.layer.masksToBounds = false
            card.layer.shadowColor = UIColor.black.withAlphaComponent(0.1).cgColor
            card.layer.shadowOffset = CGSize(width: 0, height: 3)
            card.layer.shadowOpacity = 0.3
            card.layer.shadowRadius = 6
        }
    }

        // MARK: - All Fields
        private var allTextFields: [UITextField] {
            [firstNameField, lastNameField, departmentField, srmMailField,
             regNoField, personalMailField, contactNumberField]
        }

        // MARK: - Edit/Save Button
        @IBAction func editButtonTapped(_ sender: UIButton) {
            isEditingProfile.toggle()

            if isEditingProfile {
                // Enable editing
                editButton.setTitle("Save", for: .normal)
                allTextFields.forEach { tf in
                    tf.isEnabled = true
                    tf.layer.borderWidth = 0.5
                    tf.layer.borderColor = UIColor.lightGray.cgColor
                    tf.layer.cornerRadius = 6
                    tf.backgroundColor = UIColor.systemGray6
                }
                firstNameField.becomeFirstResponder()

            } else {
                // Save data and disable editing
                editButton.setTitle("Edit", for: .normal)
                saveProfileData()
                allTextFields.forEach { tf in
                    tf.isEnabled = false
                    tf.layer.borderWidth = 0
                    tf.backgroundColor = .clear
                }
            }
        }

        // MARK: - Save Profile Data
        private func saveProfileData() {
            profile.firstName = firstNameField.text?.isEmpty == true ? nil : firstNameField.text
            profile.lastName = lastNameField.text?.isEmpty == true ? nil : lastNameField.text
            profile.department = departmentField.text?.isEmpty == true ? nil : departmentField.text
            profile.srmMail = srmMailField.text?.isEmpty == true ? nil : srmMailField.text
            profile.regNo = regNoField.text?.isEmpty == true ? nil : regNoField.text
            profile.personalMail = personalMailField.text?.isEmpty == true ? nil : personalMailField.text
            profile.contactNumber = contactNumberField.text?.isEmpty == true ? nil : contactNumberField.text

            // Update placeholders for empty fields
            allTextFields.forEach { tf in
                if tf.text?.isEmpty ?? true {
                    tf.placeholder = "Not Set"
                    tf.textColor = .systemBlue
                } else {
                    tf.textColor = .label
                }
            }
        }
    }

