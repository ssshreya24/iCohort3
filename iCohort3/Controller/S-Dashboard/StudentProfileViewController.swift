//
//  StudentProfileViewController.swift
//  iCohort3
//
//  ✅ CLEANED: Removed Team 9 auto-assignment and dummy data
//

import UIKit
import Supabase

class StudentProfileViewController: UIViewController {

    @IBOutlet weak var logOut: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var greetingLabel: UILabel!
    @IBOutlet weak var uploadButton: UIButton!

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
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!

    private var isEditingProfile = false
    private var currentPersonId: String?
    private var currentProfile: SupabaseManager.StudentProfile?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupInitialState()
        applyRoundedCorners()
        setupLoadingIndicator()
        getCurrentUserPersonId()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let personId = currentPersonId {
            loadProfileData(personId: personId)
        }
    }

    // MARK: - Setup
    
    private func setupLoadingIndicator() {
        loadingIndicator?.hidesWhenStopped = true
        loadingIndicator?.style = .large
    }
    
    private func getCurrentUserPersonId() {
        if let storedPersonId = UserDefaults.standard.string(forKey: "current_person_id") {
            currentPersonId = storedPersonId
        } else {
            // Show error - user needs to login
            showError("Please login to view your profile")
        }
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

    private var allTextFields: [UITextField?] {
        [firstNameField, lastNameField, departmentField, srmMailField,
         regNoField, personalMailField, contactNumberField]
    }

    private func setupInitialState() {
        for tf in allTextFields.compactMap({ $0 }) {
            tf.isEnabled = false
            tf.placeholder = "Not Set"
            tf.textColor = .systemGray
            tf.text = ""
        }
        
        greetingLabel?.text = "Hi User"
        greetingLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        uploadButton.isHidden = true
        uploadButton.alpha = 1.0
        uploadButton.isUserInteractionEnabled = true
        view.bringSubviewToFront(uploadButton)
    }
    
    // MARK: - Load Data from Supabase
    
    private func loadProfileData(personId: String) {
        loadingIndicator?.startAnimating()
        
        Task {
            do {
                // Fetch greeting
                let greeting = try await SupabaseManager.shared.getStudentGreeting(personId: personId)
                
                // Fetch profile
                let profile = try await SupabaseManager.shared.fetchBasicStudentProfile(personId: personId)
                
                await MainActor.run {
                    self.currentProfile = profile
                    self.updateUIWithProfile(profile, greeting: greeting)
                    self.loadingIndicator?.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    print("Error loading profile: \(error)")
                    self.loadingIndicator?.stopAnimating()
                    
                    // If no profile exists, show empty state
                    if error.localizedDescription.contains("not found") {
                        self.greetingLabel?.text = "Hi User"
                    } else {
                        self.showError("Failed to load profile")
                    }
                }
            }
        }
    }
    
    private func updateUIWithProfile(_ profile: SupabaseManager.StudentProfile?, greeting: String) {
        greetingLabel?.text = greeting
        
        guard let profile = profile else {
            // New user - show empty fields
            for tf in allTextFields.compactMap({ $0 }) {
                tf.text = ""
                tf.textColor = .systemGray
            }
            return
        }
        
        // Populate fields
        firstNameField?.text = profile.first_name ?? ""
        lastNameField?.text = profile.last_name ?? ""
        departmentField?.text = profile.department ?? ""
        srmMailField?.text = profile.srm_mail ?? ""
        regNoField?.text = profile.reg_no ?? ""
        personalMailField?.text = profile.personal_mail ?? ""
        contactNumberField?.text = profile.contact_number ?? ""
        
        // Update text colors based on content
        for tf in allTextFields.compactMap({ $0 }) {
            if tf.text?.isEmpty == true {
                tf.textColor = .systemGray
            } else {
                tf.textColor = .label
            }
        }
    }

    // MARK: - Actions
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func logOutButtonTapped(_ sender: Any) {
        // Clear stored person_id
        UserDefaults.standard.removeObject(forKey: "current_person_id")
        
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes
                    .compactMap({ $0 as? UIWindowScene })
                    .first(where: { $0.activationState == .foregroundActive }),
                  let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
                print("⚠️ No key window found")
                return
            }
            
            let sb = UIStoryboard(name: "Main", bundle: nil)
            guard let loginVC = sb.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController else {
                print("⚠️ Couldn't instantiate SLoginVC")
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
    
    // MARK: - Edit/Save
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        isEditingProfile.toggle()

        uploadButton.isHidden = false
        uploadButton.alpha = 1.0
        uploadButton.isUserInteractionEnabled = true
        view.bringSubviewToFront(uploadButton)

        if isEditingProfile {
            editButton.setTitle("Save", for: .normal)
            editButton.backgroundColor = .systemGreen

            for tf in allTextFields.compactMap({ $0 }) {
                tf.isEnabled = true
                tf.textColor = .label
                if tf.text?.isEmpty == true { tf.text = "" }
            }
            firstNameField?.becomeFirstResponder()
        } else {
            editButton.setTitle("Edit", for: .normal)
            editButton.backgroundColor = .systemBlue

            view.endEditing(true)
            saveProfileToSupabase()

            for tf in allTextFields.compactMap({ $0 }) {
                tf.isEnabled = false
            }
        }
    }

    // MARK: - Save to Supabase
    
    private func saveProfileToSupabase() {
        guard let personId = currentPersonId else {
            showError("User not found. Please log in again.")
            return
        }
        
        print("🔄 Starting profile save for person_id: \(personId)")
        
        // Get field values
        let firstName = firstNameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = lastNameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let department = departmentField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let srmMail = srmMailField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let regNo = regNoField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let personalMail = personalMailField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let contactNumber = contactNumberField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Validate required fields
        guard let firstName = firstName, !firstName.isEmpty else {
            showError("First name is required")
            return
        }
        
        guard let lastName = lastName, !lastName.isEmpty else {
            showError("Last name is required")
            return
        }
        
        loadingIndicator?.startAnimating()
        
        Task {
            do {
                print("🔄 Calling upsertStudentProfile...")
                
                // ✅ CLEANED: Just save profile, no Team 9 assignment
                let profileId = try await SupabaseManager.shared.upsertStudentProfile(
                    personId: personId,
                    firstName: firstName,
                    lastName: lastName,
                    department: department?.isEmpty == true ? nil : department,
                    srmMail: srmMail?.isEmpty == true ? nil : srmMail,
                    regNo: regNo?.isEmpty == true ? nil : regNo,
                    personalMail: personalMail?.isEmpty == true ? nil : personalMail,
                    contactNumber: contactNumber?.isEmpty == true ? nil : contactNumber
                )
                
                print("✅ Profile saved with ID: \(profileId)")
                
                await MainActor.run {
                    self.loadingIndicator?.stopAnimating()
                    self.showSuccess("Profile saved successfully!")
                    
                    // Reload to get updated greeting
                    Task {
                        await self.loadProfileData(personId: personId)
                    }
                }
            } catch let error as NSError {
                await MainActor.run {
                    self.loadingIndicator?.stopAnimating()
                    print("❌ Error saving profile: \(error)")
                    
                    let errorMessage = error.localizedDescription
                    self.showError("Failed to save profile: \(errorMessage)")
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator?.stopAnimating()
                    print("❌ Unknown error saving profile: \(error)")
                    self.showError("Failed to save profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showError(_ message: String) async {
        await MainActor.run {
            let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccess(_ message: String) {
        let alert = UIAlertController(title: "Success", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension UIStackView {
    func applyRoundedBackground(_ color: UIColor = .systemBackground) {
        if let oldBg = subviews.first(where: { $0.tag == 999 }) {
            oldBg.removeFromSuperview()
        }

        let backgroundLayer = UIView(frame: bounds)
        backgroundLayer.backgroundColor = color
        backgroundLayer.layer.cornerRadius = 16
        backgroundLayer.layer.masksToBounds = true
        backgroundLayer.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundLayer.tag = 999
        insertSubview(backgroundLayer, at: 0)
    }
}
