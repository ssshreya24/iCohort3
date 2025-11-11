//
//  StudentProfileViewController.swift
//  iCohort3
//
//  Created by Shreya on 06/11/25.
//

import UIKit

class StudentProfileViewController: UIViewController {

   

    @IBOutlet weak var logOut: UIButton!
    @IBOutlet weak var backButton: UIButton!
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

        // MARK: - Lifecycle
        override func viewDidLoad() {
            super.viewDidLoad()
            setupInitialState()
            applyRoundedCorners()
        }

    private func applyRoundedCorners() {
        let cardViews = [profileCardView, academicCardView, personalCardView]
        for view in cardViews.compactMap({ $0 }) {
            view.layer.cornerRadius = 16
            view.layer.masksToBounds = true
            view.layer.borderWidth = 0.5
            view.layer.borderColor = UIColor.systemGray5.cgColor
            view.backgroundColor = .systemBackground
        }
    }

        // MARK: - Setup
        private var allTextFields: [UITextField?] {
            [firstNameField, lastNameField, departmentField, srmMailField,
             regNoField, personalMailField, contactNumberField]
        }

        private func setupInitialState() {
            for tf in allTextFields.compactMap({ $0 }) {
                tf.isEnabled = false
                tf.placeholder = "Not Set"
                tf.textColor = .systemBlue
                tf.text = "Not Set"
            }
        }
    @IBAction func backButtonTapped(_ sender: UIButton) {
        if let nav = navigationController {
            // If this VC was pushed (via navigation)
            nav.popViewController(animated: true)
        } else {
            // If it was presented modally
            dismiss(animated: true, completion: nil)
        }
    
    }
    
    @IBAction func logOutButtonTapped(_ sender: Any) {
        view.endEditing(true)

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController {
                let transition = CATransition()
                transition.duration = 0.35
                transition.type = .push
                transition.subtype = .fromBottom
                transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                navigationController?.view.layer.add(transition, forKey: kCATransition)
                navigationController?.pushViewController(loginVC, animated: false)
            }
    }
    
        // MARK: - Edit/Save
        @IBAction func editButtonTapped(_ sender: UIButton) {
            isEditingProfile.toggle()

            if isEditingProfile {
                editButton.setTitle("Save", for: .normal)
                for tf in allTextFields.compactMap({ $0 }) {
                    tf.isEnabled = true
                    tf.textColor = .label
                    if tf.text == "Not Set" { tf.text = "" }
                }
                firstNameField?.becomeFirstResponder()
            } else {
                editButton.setTitle("Edit", for: .normal)
                saveProfileData()
                for tf in allTextFields.compactMap({ $0 }) {
                    tf.isEnabled = false
                    tf.textColor = tf.text?.isEmpty == true ? .systemBlue : .label
                    if tf.text?.isEmpty == true { tf.text = "Not Set" }
                }
            }
        }

        // MARK: - Save
        private func saveProfileData() {
            profile.firstName = firstNameField?.text
            profile.lastName = lastNameField?.text
            profile.department = departmentField?.text
            profile.srmMail = srmMailField?.text
            profile.regNo = regNoField?.text
            profile.personalMail = personalMailField?.text
            profile.contactNumber = contactNumberField?.text
        }
    }

extension UIStackView {
    func applyRoundedBackground(_ color: UIColor = .systemBackground) {
        // Remove old background if it exists (prevents duplicates)
        if let oldBg = subviews.first(where: { $0.tag == 999 }) {
            oldBg.removeFromSuperview()
        }

        let backgroundLayer = UIView(frame: bounds)
        backgroundLayer.backgroundColor = color
        backgroundLayer.layer.cornerRadius = 16
        backgroundLayer.layer.masksToBounds = true
        backgroundLayer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundLayer.tag = 999 // so we can identify it later
        insertSubview(backgroundLayer, at: 0)
    }
}

