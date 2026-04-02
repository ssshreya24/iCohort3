//
//  StudentProfileViewController.swift
//  iCohort3
//
//  ✅ CLEANED: Removed Team 9 auto-assignment and dummy data
//

import UIKit
import Supabase

class StudentProfileViewController: UIViewController, UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate {

    @IBOutlet weak var logOut: UIButton?
    @IBOutlet weak var backButton: UIButton?
    @IBOutlet weak var editButton: UIButton?
    @IBOutlet weak var greetingLabel: UILabel?
    @IBOutlet weak var uploadButton: UIButton?
    @IBOutlet weak var avatarImageView: UIImageView?

    @IBOutlet weak var firstNameField: UITextField?
    @IBOutlet weak var lastNameField: UITextField?
    @IBOutlet weak var departmentField: UITextField?
    @IBOutlet weak var srmMailField: UITextField?
    @IBOutlet weak var regNoField: UITextField?
    @IBOutlet weak var personalMailField: UITextField?
    @IBOutlet weak var contactNumberField: UITextField?

    @IBOutlet weak var profileCardView: UIView?
    @IBOutlet weak var academicCardView: UIView?
    @IBOutlet weak var personalCardView: UIView?
    
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView?

    private var isEditingProfile = false
    private var currentPersonId: String?
    private var currentProfile: SupabaseManager.StudentProfile?
    private var headingLabels: [UILabel] = []
    private var fieldTitleLabels: [UILabel] = []

    private var resolvedPersonId: String? {
        currentPersonId ?? UserDefaults.standard.string(forKey: "current_person_id")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        setupInitialState()
        applyRoundedCorners()
        setupLoadingIndicator()
        configureAvatarEditButton()
        configureAvatarPlaceholder()
        getCurrentUserPersonId()
        loadCachedAvatar()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            refreshTheme()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
        applyRoundedCorners()
        styleOuterHierarchy(in: view)
        styleCardContentHierarchy()
        if let avatarImageView = avatarImageView {
            avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
            avatarImageView.layer.masksToBounds = true
        }
        if let uploadButton = uploadButton {
            uploadButton.layer.cornerRadius = uploadButton.bounds.height / 2
            uploadButton.layer.masksToBounds = true
        }
        if avatarImageView?.image == nil {
            configureAvatarPlaceholder()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCachedAvatar()
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
        if let storedPersonId = resolvedPersonId {
            currentPersonId = storedPersonId
        } else {
            // Show error - user needs to login
            showError("Please login to view your profile")
        }
    }

    private func applyRoundedCorners() {
        let cardViews = [profileCardView, academicCardView, personalCardView]
        for view in cardViews.compactMap({ $0 }) {
            AppTheme.styleElevatedCard(view, cornerRadius: 18)
        }
    }

    private var allTextFields: [UITextField?] {
        [firstNameField, lastNameField, departmentField, srmMailField,
         regNoField, personalMailField, contactNumberField]
    }

    private func setupInitialState() {
        logOut?.removeFromSuperview()
        for tf in allTextFields.compactMap({ $0 }) {
            tf.isEnabled = false
            tf.placeholder = "Not Set"
            tf.textColor = .systemGray
            tf.text = ""
        }
        
        greetingLabel?.text = "Hi Student"
        greetingLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        uploadButton?.isHidden = true
        uploadButton?.alpha = 1.0
        uploadButton?.isUserInteractionEnabled = true
        if let uploadButton = uploadButton {
            view.bringSubviewToFront(uploadButton)
        }
        discoverStaticLabels()
        refreshTheme()
    }

    private func configureAvatarPlaceholder() {
        guard let avatarImageView = avatarImageView else { return }
        if let logo = UIImage(named: "logo") {
            avatarImageView.image = logo
            avatarImageView.tintColor = nil
            avatarImageView.contentMode = .scaleAspectFill
        } else {
            let pointSize = max(42, avatarImageView.bounds.width * 0.72)
            let placeholderConfig = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
            avatarImageView.image = UIImage(systemName: "person.circle.fill", withConfiguration: placeholderConfig)
            avatarImageView.tintColor = .systemGray3
            avatarImageView.contentMode = .center
        }
        avatarImageView.clipsToBounds = true
    }

    private func configureAvatarEditButton() {
        guard let uploadButton = uploadButton else { return }
        var config = UIButton.Configuration.plain()
        config.title = nil
        config.image = UIImage(systemName: "camera.fill")
        config.baseForegroundColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        uploadButton.configuration = config
        AppTheme.styleNativeFloatingControl(uploadButton, cornerRadius: max(18, uploadButton.bounds.height / 2))
    }

    private func refreshTheme() {
        AppTheme.applyScreenBackground(to: view)
        view.tintColor = AppTheme.accent
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let headingColor: UIColor = isDarkMode ? .white : .black
        let bodyColor: UIColor = isDarkMode ? .white : .black
        let secondaryColor: UIColor = isDarkMode ? UIColor.white.withAlphaComponent(0.88) : UIColor.black.withAlphaComponent(0.78)

        headingLabels.forEach { $0.textColor = headingColor }
        fieldTitleLabels.forEach { $0.textColor = bodyColor }

        if let backButton = backButton {
            let foreground = isDarkMode ? UIColor.white : UIColor.black
            styleFloatingButton(backButton, title: nil, foregroundColor: foreground)
        }

        if let logOut = logOut, logOut.superview != nil {
            styleFloatingButton(logOut, title: "Sign Out", foregroundColor: .systemPink, cornerRadius: 18)
        }

        if let editButton = editButton {
            styleFloatingButton(editButton, title: isEditingProfile ? "Save" : "Edit", foregroundColor: .black)
        }

        configureAvatarEditButton()
        styleOuterHierarchy(in: view)
        styleCardContentHierarchy()
        styleTextFields(isEditing: isEditingProfile, primaryTextColor: bodyColor, secondaryTextColor: secondaryColor)
    }

    private func styleTextFields(isEditing: Bool, primaryTextColor: UIColor, secondaryTextColor: UIColor) {
        for textField in allTextFields.compactMap({ $0 }) {
            textField.backgroundColor = .clear
            textField.textColor = (textField.text?.isEmpty == false) ? primaryTextColor : secondaryTextColor
            textField.attributedPlaceholder = NSAttributedString(
                string: textField.placeholder ?? "",
                attributes: [.foregroundColor: secondaryTextColor]
            )
            textField.layer.cornerRadius = 0
            textField.layer.masksToBounds = true
            textField.borderStyle = .none
        }
    }

    private func styleFloatingButton(_ button: UIButton,
                                     title: String?,
                                     foregroundColor: UIColor,
                                     cornerRadius: CGFloat = 22) {
        let image = button.configuration?.image
        var config = UIButton.Configuration.plain()
        config.image = image
        config.baseForegroundColor = foregroundColor
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        if let title {
            config.title = title
            config.attributedTitle = AttributedString(
                title,
                attributes: AttributeContainer([.foregroundColor: foregroundColor])
            )
        }
        button.configuration = config

        AppTheme.styleNativeFloatingControl(button, cornerRadius: cornerRadius)
        button.backgroundColor = .clear
        button.tintColor = foregroundColor
        button.setTitleColor(foregroundColor, for: .normal)
    }

    private func styleCardContentHierarchy() {
        [profileCardView, academicCardView, personalCardView].compactMap { $0 }.forEach { card in
            AppTheme.styleElevatedCard(card, cornerRadius: 18)
            clearNestedBackgrounds(in: card)
        }
    }

    private func clearNestedBackgrounds(in root: UIView) {
        for subview in root.subviews {
            if shouldStyleAsSeparator(subview) {
                subview.backgroundColor = UIColor.separator.withAlphaComponent(
                    traitCollection.userInterfaceStyle == .dark ? 0.42 : 0.20
                )
                continue
            }

            switch subview {
            case is UILabel, is UIStackView:
                subview.backgroundColor = .clear
            case is UITextField:
                break
            default:
                subview.backgroundColor = .clear
            }

            clearNestedBackgrounds(in: subview)
        }
    }

    private func styleOuterHierarchy(in root: UIView) {
        for subview in root.subviews {
            switch subview {
            case profileCardView, academicCardView, personalCardView,
                 backButton, editButton, uploadButton, avatarImageView:
                break
            case is UILabel, is UIStackView, is UIScrollView, is UIImageView:
                subview.backgroundColor = .clear
            case is UITextField:
                break
            default:
                subview.backgroundColor = .clear
            }

            styleOuterHierarchy(in: subview)
        }
    }

    private func shouldStyleAsSeparator(_ view: UIView) -> Bool {
        let heightConstraint = view.constraints
            .filter { $0.firstAttribute == .height }
            .map(\.constant)
            .min() ?? .greatestFiniteMagnitude
        let measuredHeight = view.bounds.height > 0 ? view.bounds.height : heightConstraint
        return measuredHeight <= 1.5
    }

    private func discoverStaticLabels() {
        let labels = collectLabels(in: view)
        headingLabels = labels.filter { $0.font.pointSize >= 20 }
        fieldTitleLabels = labels.filter { label in
            label.font.pointSize < 20 && !headingLabels.contains(label)
        }
    }

    private func collectLabels(in root: UIView) -> [UILabel] {
        var labels: [UILabel] = []
        for subview in root.subviews {
            if let label = subview as? UILabel {
                labels.append(label)
            }
            labels.append(contentsOf: collectLabels(in: subview))
        }
        return labels
    }

    private func loadCachedAvatar() {
        guard let personId = resolvedPersonId,
              let cachedAvatar = SupabaseManager.shared.cachedProfilePhotoBase64(personId: personId, role: "student"),
              let image = SupabaseManager.shared.base64ToImage(base64String: cachedAvatar) else {
            configureAvatarPlaceholder()
            return
        }

        currentPersonId = personId
        avatarImageView?.image = image
        avatarImageView?.tintColor = nil
        avatarImageView?.contentMode = .scaleAspectFill
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
                        self.greetingLabel?.text = "Hi Student"
                    } else {
                        self.showError("Failed to load profile")
                    }
                }
            }
        }
    }
    
    private func updateUIWithProfile(_ profile: SupabaseManager.StudentProfile?, greeting: String) {
        greetingLabel?.text = greeting
        loadCachedAvatar()
        
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
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let primaryTextColor: UIColor = isDarkMode ? .white : .black
        let secondaryTextColor: UIColor = isDarkMode ? UIColor.white.withAlphaComponent(0.88) : UIColor.black.withAlphaComponent(0.78)
        styleTextFields(isEditing: isEditingProfile, primaryTextColor: primaryTextColor, secondaryTextColor: secondaryTextColor)
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
        UserDefaults.standard.removeObject(forKey: "current_user_name")
        UserDefaults.standard.removeObject(forKey: "current_user_email")
        UserDefaults.standard.removeObject(forKey: "current_user_role")
        UserDefaults.standard.set(false, forKey: "is_logged_in")
        
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

    @IBAction func uploadButtonTapped(_ sender: UIButton) {
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

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
            popover.permittedArrowDirections = .up
        }

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
        if let image {
            let square = image.centerSquare()
            avatarImageView?.image = square
            avatarImageView?.tintColor = nil
            avatarImageView?.contentMode = .scaleAspectFill

            if let personId = resolvedPersonId,
               let base64 = SupabaseManager.shared.imageToBase64(image: square) {
                currentPersonId = personId
                SupabaseManager.shared.cacheProfilePhotoBase64(base64, personId: personId, role: "student")
            }
        }
        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }
    
    // MARK: - Edit/Save
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        isEditingProfile.toggle()
        uploadButton?.isHidden = !isEditingProfile
        uploadButton?.alpha = 1.0
        uploadButton?.isUserInteractionEnabled = true
        if let uploadButton = uploadButton {
            view.bringSubviewToFront(uploadButton)
        }

        if isEditingProfile {
            for tf in allTextFields.compactMap({ $0 }) {
                tf.isEnabled = true
                tf.textColor = .label
                if tf.text?.isEmpty == true { tf.text = "" }
            }
            refreshTheme()
            firstNameField?.becomeFirstResponder()
        } else {
            view.endEditing(true)
            saveProfileToSupabase()

            for tf in allTextFields.compactMap({ $0 }) {
                tf.isEnabled = false
            }
            refreshTheme()
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
