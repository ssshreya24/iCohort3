//
//  ProfileViewController.swift
//  iCohort3
//
//  Created by user@0 on 17/11/25.
//

import UIKit
import SafariServices
protocol ProfileViewControllerDelegate: AnyObject {
    func profileViewController(_ controller: ProfileViewController,
                               didUpdateAvatar image: UIImage)
}


class ProfileViewController: UIViewController, UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {
    weak var delegate: ProfileViewControllerDelegate?

    // MARK: - Top Back
    
        @IBOutlet weak var backButton: UIButton!
        @IBOutlet weak var editButton: UIButton!
        
        // MARK: - Avatar
        @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var avatarEditButton: UIButton!
        
        // MARK: - Cards
        @IBOutlet weak var profileCardView: UIView!    // First Name / Last Name
        @IBOutlet weak var academicCardView: UIView!   // Department / SRM Mail / Faculty Id
        @IBOutlet weak var personalCardView: UIView!   // Personal Mail / Contact Number
        @IBOutlet weak var featuresCardView: UIView!   // Personal Mail switch row
        
        // MARK: - Fields
        @IBOutlet weak var firstNameField: UITextField!
        @IBOutlet weak var lastNameField: UITextField!
        
        @IBOutlet weak var departmentField: UITextField!
        @IBOutlet weak var srmMailField: UITextField!
        @IBOutlet weak var facultyIdField: UITextField!
        
        @IBOutlet weak var personalMailField: UITextField!
        @IBOutlet weak var contactNumberField: UITextField!
        
        // MARK: - Features
        @IBOutlet weak var personalMailSwitch: UISwitch!
        
        // MARK: - Sign Out
        @IBOutlet weak var signOutButton: UIButton!
    
    
        
    // MARK: - State
       private var isEditingProfile = false

       struct Profile {
           var firstName: String?
           var lastName: String?
           var department: String?
           var srmMail: String?
           var facultyId: String?
           var personalMail: String?
           var contactNumber: String?
           var showPersonalMail: Bool
       }

       private var profile = Profile(
        firstName: "Arshad",
            lastName: "Shaikh",
            department: "Industry Mentor",
            srmMail: "as4371@srmist.edu.in",
            facultyId: "14368",
            personalMail: "arshad546@gmail.com",
            contactNumber: "9410670414",
            showPersonalMail: true
       )

       // MARK: - Convenience
       private var allTextFields: [UITextField?] {
           [
               firstNameField,
               lastNameField,
               departmentField,
               srmMailField,
               facultyIdField,
               personalMailField,
               contactNumberField
           ]
       }

       // MARK: - Lifecycle
       override func viewDidLoad() {
           super.viewDidLoad()
           setupUI()
           setupInitialState()
           avatarEditButton.isHidden = true
           if let img = UIImage(named: "ProfileImageMentor") {
                   let square = img.centerSquare()
                   avatarImageView.image = square
               }
       }

       override func viewDidLayoutSubviews() {
           super.viewDidLayoutSubviews()
           makeAvatarCircular()
           makeTopButtonsRounded()
           makeSignOutRounded()
           avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
                   avatarImageView.layer.masksToBounds = true
                   avatarEditButton.layer.cornerRadius = avatarEditButton.bounds.height / 2
                   avatarEditButton.layer.masksToBounds = true
       }

       // MARK: - Setup / Styling

       private func setupUI() {
           // Background like your screenshot (#EFEFF5)
           view.backgroundColor = UIColor(
               red: 0xEF/255.0,
               green: 0xEF/255.0,
               blue: 0xF5/255.0,
               alpha: 1.0
           )

           applyCardStyle(to: profileCardView)
           applyCardStyle(to: academicCardView)
           applyCardStyle(to: personalCardView)
           applyCardStyle(to: featuresCardView)

           editButton.setTitle("Edit", for: .normal)
           personalMailSwitch.isOn = profile.showPersonalMail
       }

       private func applyCardStyle(to card: UIView?) {
           guard let card = card else { return }
           card.layer.cornerRadius = 12
           card.layer.masksToBounds = true
           card.layer.borderWidth = 0.5
           card.layer.borderColor = UIColor.systemGray5.cgColor
           card.backgroundColor = .white
       }

       private func makeAvatarCircular() {
           guard let avatar = avatarImageView else { return }
           avatar.layer.cornerRadius = avatar.bounds.width / 2
           avatar.layer.masksToBounds = true
           
       }

       private func makeTopButtonsRounded() {
           [backButton, editButton].forEach { button in
               guard let button = button else { return }
               button.layer.cornerRadius = button.bounds.height / 2
               button.layer.masksToBounds = true
               button.backgroundColor = .white
           }
       }

       private func makeSignOutRounded() {
           guard let btn = signOutButton else { return }
           btn.layer.cornerRadius = btn.bounds.height / 2
           btn.layer.masksToBounds = true
           btn.backgroundColor = UIColor.systemGray5
           btn.setTitleColor(.systemRed, for: .normal)
       }

    private func setupInitialState() {
        // All fields start as non-editable
        for tf in allTextFields.compactMap({ $0 }) {
            tf.isEnabled = false
        }

        // First Name
        if let value = profile.firstName, !value.isEmpty {
            firstNameField.text = value
            firstNameField.textColor = .label
        } else {
            firstNameField.text = "Not Set"
            firstNameField.textColor = .systemBlue
        }

        // Last Name
        if let value = profile.lastName, !value.isEmpty {
            lastNameField.text = value
            lastNameField.textColor = .label
        } else {
            lastNameField.text = "Not Set"
            lastNameField.textColor = .systemBlue
        }

        // Department
        if let value = profile.department, !value.isEmpty {
            departmentField.text = value
            departmentField.textColor = .label
        } else {
            departmentField.text = "Not Set"
            departmentField.textColor = .systemBlue
        }

        // SRM Mail
        if let value = profile.srmMail, !value.isEmpty {
            srmMailField.text = value
            srmMailField.textColor = .label
        } else {
            srmMailField.text = "Not Set"
            srmMailField.textColor = .systemBlue
        }

        // Faculty Id
        if let value = profile.facultyId, !value.isEmpty {
            facultyIdField.text = value
            facultyIdField.textColor = .label
        } else {
            facultyIdField.text = "Not Set"
            facultyIdField.textColor = .systemBlue
        }

        // Personal Mail
        if let value = profile.personalMail, !value.isEmpty {
            personalMailField.text = value
            personalMailField.textColor = .label
        } else {
            personalMailField.text = "Not Set"
            personalMailField.textColor = .systemBlue
        }

        // Contact Number
        if let value = profile.contactNumber, !value.isEmpty {
            contactNumberField.text = value
            contactNumberField.textColor = .label
        } else {
            contactNumberField.text = "Not Set"
            contactNumberField.textColor = .systemBlue
        }

        personalMailSwitch.isOn = profile.showPersonalMail
    }
       // MARK: - Actions

       @IBAction func backButtonTapped(_ sender: UIButton) {
           if let nav = navigationController {
               nav.popViewController(animated: true)
           } else {
               dismiss(animated: true, completion: nil)
           }
       }
    
    @IBAction func avatarEditButtonTapped(_ sender: UIButton) {
      

        let sheet = UIAlertController(
            title: "Change Profile Picture",
            message: nil,
            preferredStyle: .actionSheet
        )

        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.presentImagePicker(source: .camera)
            })
        }

        sheet.addAction(UIAlertAction(title: "Upload from Photos", style: .default) { [weak self] _ in
            self?.presentImagePicker(source: .photoLibrary)
        })

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(sheet, animated: true)
    }
    private func presentImagePicker(source: UIImagePickerController.SourceType) {
            guard UIImagePickerController.isSourceTypeAvailable(source) else { return }
            let picker = UIImagePickerController()
            picker.sourceType = source
            picker.allowsEditing = true
            picker.delegate = self
            present(picker, animated: true)
        }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage
        if let img = image {
            let square = img.centerSquare()
            avatarImageView.image = square
            delegate?.profileViewController(self, didUpdateAvatar: square)
        }
        dismiss(animated: true)
    }


        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss(animated: true)
        }

       @IBAction func signOutButtonTapped(_ sender: UIButton) {
           DispatchQueue.main.async {
               guard let windowScene = UIApplication.shared.connectedScenes
                       .compactMap({ $0 as? UIWindowScene })
                       .first(where: { $0.activationState == .foregroundActive }),
                     let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                   print("⚠️ No key window found")
                   return
               }

               let sb = UIStoryboard(name: "Main", bundle: nil)
               guard let loginVC = sb.instantiateViewController(withIdentifier: "MLoginVC") as? MLoginSignUpViewController else {
                   print("⚠️ Couldn't instantiate MLoginVC")
                   return
               }

               let loginNav = UINavigationController(rootViewController: loginVC)
               loginNav.navigationBar.isTranslucent = false

               let transition = CATransition()
               transition.duration = 0.35
               transition.type = .push
               transition.subtype = .fromBottom
               transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

               window.layer.add(transition, forKey: kCATransition)
               window.rootViewController = loginNav
               window.makeKeyAndVisible()
           }
       }

       @IBAction func personalMailSwitchChanged(_ sender: UISwitch) {
           profile.showPersonalMail = sender.isOn
           // later you can use this flag to show/hide personal mail elsewhere
       }

    @IBAction func editButtonTapped(_ sender: UIButton) {

        isEditingProfile.toggle()
        avatarEditButton.isHidden = !isEditingProfile

        if isEditingProfile {
            // ENTER EDIT MODE
            editButton.setTitle("Save", for: .normal)

            for tf in allTextFields.compactMap({ $0 }) {
                tf.isEnabled = true

                let trimmed = tf.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if trimmed == "Not Set" || trimmed.isEmpty {
                    // Not set → keep BLUE, clear for typing
                    tf.textColor = .systemBlue
                    tf.text = ""
                } else {
                    // Has value → GREY while editing
                    tf.textColor = .systemGray
                }
            }

            firstNameField?.becomeFirstResponder()

        } else {
            // EXIT EDIT MODE (SAVE)
            editButton.setTitle("Edit", for: .normal)
            saveProfileData()

            for tf in allTextFields.compactMap({ $0 }) {
                tf.isEnabled = false

                let trimmed = tf.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if trimmed.isEmpty {
                    // Empty after save → Not Set in BLUE
                    tf.text = "Not Set"
                    tf.textColor = .systemBlue
                } else {
                    // Has value after save → BLACK
                    tf.textColor = .label
                }
            }
        }
    }


       // MARK: - Save

       private func saveProfileData() {
           profile.firstName = firstNameField?.text
           profile.lastName = lastNameField?.text
           profile.department = departmentField?.text
           profile.srmMail = srmMailField?.text
           profile.facultyId = facultyIdField?.text
           profile.personalMail = personalMailField?.text
           profile.contactNumber = contactNumberField?.text
           profile.showPersonalMail = personalMailSwitch.isOn
       }
   }
extension UIImage {
    func centerSquare() -> UIImage {
        let originalSize = self.size
        let side = min(originalSize.width, originalSize.height)
        let x = (originalSize.width  - side) / 2.0
        let y = (originalSize.height - side) / 2.0

        let cropRect = CGRect(x: x, y: y, width: side, height: side).integral

        guard let cg = self.cgImage?.cropping(to: cropRect) else { return self }
        return UIImage(cgImage: cg, scale: self.scale, orientation: self.imageOrientation)
    }
}
