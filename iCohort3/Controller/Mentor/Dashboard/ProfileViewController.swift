//
//  ProfileViewController.swift
//  iCohort3
//
//  Updated with Supabase mentor profile integration
//

import UIKit
import SafariServices
import Supabase
import UserNotifications

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
    
    // MARK: - Greeting (NEW)
    @IBOutlet weak var greetingLabel: UILabel!
    
    // MARK: - Cards
    @IBOutlet weak var profileCardView: UIView!
    @IBOutlet weak var academicCardView: UIView!
    @IBOutlet weak var personalCardView: UIView!
    @IBOutlet weak var featuresCardView: UIView!
    
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
    
    // MARK: - Loading
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // MARK: - State
    private var isEditingProfile = false
    private var currentPersonId: String?
    private var currentProfile: SupabaseManager.MentorProfile?
    private var isShowingPlaceholderAvatar = true
    private let privacyPolicyButton = UIButton(type: .system)
    private let privacyHeadingLabel = UILabel()
    private let deleteAccountButton = UIButton(type: .system)
    private let supportButton = UIButton(type: .system)
    private let supportHeadingLabel = UILabel()
    private var isDeletingAccount = false

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
        enableKeyboardDismissOnTap()
        setupUI()
        setupProfileActionSections()
        setupAvatarPreviewTap()
        setupInitialState()
        setupLoadingIndicator()
        avatarEditButton.isHidden = true

        configureAvatarPlaceholder()
        
        // ✅ NEW: Get mentor person_id from UserDefaults
        getCurrentUserPersonId()
        restoreSwitchState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let personId = currentPersonId {
            loadProfileData(personId: personId)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        makeAvatarCircular()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
        avatarImageView.layer.masksToBounds = true
        avatarEditButton.layer.cornerRadius = avatarEditButton.bounds.height / 2
        avatarEditButton.layer.masksToBounds = true
        refreshTheme()
        if isShowingPlaceholderAvatar {
            configureAvatarPlaceholder()
        }
    }
    
    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            refreshTheme()
        }
    }

    // MARK: - Setup / Styling
    
    private func setupLoadingIndicator() {
        loadingIndicator?.hidesWhenStopped = true
        loadingIndicator?.style = .large
    }

    private func configureAvatarPlaceholder() {
        isShowingPlaceholderAvatar = true
        let name = UserDefaults.standard.string(forKey: "current_user_name") ?? "Mentor"
        let initial = String(name.first ?? "M")
        avatarImageView.image = UIImage.generateAvatar(initials: initial)
        avatarImageView.tintColor = nil
        avatarImageView.contentMode = .scaleAspectFill
    }
    
    private func getCurrentUserPersonId() {
        if let storedPersonId = UserDefaults.standard.string(forKey: "current_person_id") {
            currentPersonId = storedPersonId
            loadProfileData(personId: storedPersonId)
        } else {
            print("⚠️ No person ID found in UserDefaults")
            greetingLabel?.text = "Hi Mentor"
        }
    }
    
    // ✅ NEW: Load profile data from Supabase
    private func loadProfileData(personId: String) {
        loadingIndicator?.startAnimating()
        
        Task {
            do {
                // Fetch greeting
                let greeting = try await SupabaseManager.shared.getMentorGreeting(personId: personId)
                
                // Fetch profile
                let profile = try await SupabaseManager.shared.fetchBasicMentorProfile(personId: personId)
                
                await MainActor.run {
                    self.currentProfile = profile
                    self.updateUIWithProfile(profile, greeting: greeting)
                    self.loadingIndicator?.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    print("Error loading mentor profile:", error)
                    self.loadingIndicator?.stopAnimating()
                    
                    // Show empty state
                    if error.localizedDescription.contains("not found") {
                        self.greetingLabel?.text = "Hi Mentor"
                    } else {
                        self.showError("Failed to load profile")
                    }
                }
            }
        }
    }
    
    private func updateUIWithProfile(_ profile: SupabaseManager.MentorProfile?, greeting: String) {
        greetingLabel?.text = greeting

        // Fast path: use locally cached photo
        if let personId = currentPersonId,
           let cachedAvatar = SupabaseManager.shared.cachedProfilePhotoBase64(personId: personId, role: "mentor"),
           let image = SupabaseManager.shared.base64ToImage(base64String: cachedAvatar) {
            avatarImageView.image = image
            avatarImageView.tintColor = nil
            avatarImageView.contentMode = .scaleAspectFill
            isShowingPlaceholderAvatar = false
        } else if let personId = currentPersonId {
            // Slow path: fetch from Supabase backend
            Task { [weak self] in
                guard let self else { return }
                if let base64 = await SupabaseManager.shared.fetchProfilePhoto(personId: personId, role: "mentor"),
                   let image = SupabaseManager.shared.base64ToImage(base64String: base64) {
                    SupabaseManager.shared.cacheProfilePhotoBase64(base64, personId: personId, role: "mentor")
                    await MainActor.run {
                        self.avatarImageView.image = image
                        self.avatarImageView.tintColor = nil
                        self.avatarImageView.contentMode = .scaleAspectFill
                        self.isShowingPlaceholderAvatar = false
                    }
                }
            }
        }
        
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
        srmMailField?.text = profile.email ?? ""
        facultyIdField?.text = profile.employee_id ?? ""
        personalMailField?.text = profile.personal_mail ?? ""
        contactNumberField?.text = profile.contact_number ?? ""
        
        // Update text colors based on content
        for tf in allTextFields.compactMap({ $0 }) {
            if tf.text?.isEmpty == true {
                tf.textColor = .systemBlue
                tf.text = "Not Set"
            } else {
                tf.textColor = .label
            }
        }
    }

    private func setupUI() {
        AppTheme.applyScreenBackground(to: view)

        applyCardStyle(to: profileCardView)
        applyCardStyle(to: academicCardView)
        applyCardStyle(to: personalCardView)
        applyCardStyle(to: featuresCardView)

        editButton.setTitle("Edit", for: .normal)
        
        // ✅ NEW: Configure greeting label
        if greetingLabel != nil {
            greetingLabel.font = .systemFont(ofSize: 24, weight: .bold)
            greetingLabel.textColor = .label
            greetingLabel.text = "Hi Mentor" // Default
        }

        if avatarEditButton != nil {
            var config = UIButton.Configuration.filled()
            config.title = nil
            config.image = UIImage(systemName: "camera.fill")
            config.baseBackgroundColor = .white
            config.baseForegroundColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
            config.cornerStyle = .capsule
            avatarEditButton.configuration = config
        }
        
        refreshTheme()
    }

    private func setupProfileActionSections() {
        guard privacyPolicyButton.superview == nil,
              supportButton.superview == nil,
              let container = signOutButton.superview else { return }

        if let legacyTopConstraint = container.constraints.first(where: { constraint in
            (constraint.firstItem as? UIButton) === signOutButton &&
            (constraint.secondItem as? UIView) === featuresCardView &&
            constraint.firstAttribute == .top &&
            constraint.secondAttribute == .bottom
        }) {
            legacyTopConstraint.isActive = false
        }

        privacyHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        privacyHeadingLabel.text = "Legal"
        privacyHeadingLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        privacyPolicyButton.translatesAutoresizingMaskIntoConstraints = false
        privacyPolicyButton.addTarget(self, action: #selector(openPrivacyPolicy), for: .touchUpInside)

        deleteAccountButton.translatesAutoresizingMaskIntoConstraints = false
        deleteAccountButton.addTarget(self, action: #selector(confirmDeleteAccount), for: .touchUpInside)

        supportHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        supportHeadingLabel.text = "Support"
        supportHeadingLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        supportButton.translatesAutoresizingMaskIntoConstraints = false
        supportButton.addTarget(self, action: #selector(openSupportHelp), for: .touchUpInside)

        container.addSubview(privacyHeadingLabel)
        container.addSubview(privacyPolicyButton)
        container.addSubview(deleteAccountButton)
        container.addSubview(supportHeadingLabel)
        container.addSubview(supportButton)

        NSLayoutConstraint.activate([
            privacyHeadingLabel.leadingAnchor.constraint(equalTo: featuresCardView.leadingAnchor),
            privacyHeadingLabel.trailingAnchor.constraint(equalTo: featuresCardView.trailingAnchor),
            privacyHeadingLabel.topAnchor.constraint(equalTo: featuresCardView.bottomAnchor, constant: 18),
            privacyPolicyButton.leadingAnchor.constraint(equalTo: signOutButton.leadingAnchor),
            privacyPolicyButton.trailingAnchor.constraint(equalTo: signOutButton.trailingAnchor),
            privacyPolicyButton.topAnchor.constraint(equalTo: privacyHeadingLabel.bottomAnchor, constant: 8),
            privacyPolicyButton.heightAnchor.constraint(equalToConstant: 50),
            deleteAccountButton.leadingAnchor.constraint(equalTo: privacyPolicyButton.leadingAnchor),
            deleteAccountButton.trailingAnchor.constraint(equalTo: privacyPolicyButton.trailingAnchor),
            deleteAccountButton.topAnchor.constraint(equalTo: privacyPolicyButton.bottomAnchor, constant: 10),
            deleteAccountButton.heightAnchor.constraint(equalToConstant: 50),
            supportHeadingLabel.leadingAnchor.constraint(equalTo: privacyHeadingLabel.leadingAnchor),
            supportHeadingLabel.trailingAnchor.constraint(equalTo: privacyHeadingLabel.trailingAnchor),
            supportHeadingLabel.topAnchor.constraint(equalTo: deleteAccountButton.bottomAnchor, constant: 18),
            supportButton.leadingAnchor.constraint(equalTo: privacyPolicyButton.leadingAnchor),
            supportButton.trailingAnchor.constraint(equalTo: privacyPolicyButton.trailingAnchor),
            supportButton.topAnchor.constraint(equalTo: supportHeadingLabel.bottomAnchor, constant: 8),
            supportButton.heightAnchor.constraint(equalToConstant: 50),
            signOutButton.topAnchor.constraint(equalTo: supportButton.bottomAnchor, constant: 18)
        ])

        stylePrivacyPolicyButton()
        styleDeleteAccountButton()
        styleSupportButton()
    }

    private func applyCardStyle(to card: UIView?) {
        guard let card = card else { return }
        AppTheme.styleElevatedCard(card, cornerRadius: 20)
        card.layer.cornerCurve = .continuous
    }

    private func makeAvatarCircular() {
        guard let avatar = avatarImageView else { return }
        avatar.layer.cornerRadius = avatar.bounds.width / 2
        avatar.layer.masksToBounds = true
    }

    private func setupInitialState() {
        for tf in allTextFields.compactMap({ $0 }) {
            tf.isEnabled = false
            tf.placeholder = "Not Set"
            tf.textColor = .systemGray
            tf.text = ""
            tf.borderStyle = .none
            tf.backgroundColor = .clear
            tf.background = nil
            tf.disabledBackground = nil
        }
        
        greetingLabel?.text = "Hi Mentor"
        greetingLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        personalMailSwitch?.isOn = false
    }

    private func setupAvatarPreviewTap() {
        avatarImageView.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(showAvatarPreview))
        avatarImageView.addGestureRecognizer(tap)
    }
    
    private func refreshTheme() {
        AppTheme.applyScreenBackground(to: view)
        [profileCardView, academicCardView, personalCardView, featuresCardView].forEach { card in
            applyCardStyle(to: card)
        }
        styleOuterHierarchy(in: view)
        styleCardContent(profileCardView)
        styleCardContent(academicCardView)
        styleCardContent(personalCardView)
        styleCardContent(featuresCardView)
        styleBackButton()
        styleEditButton()
        styleAvatarEditButton()
        styleSignOutButton()
        privacyHeadingLabel.textColor = .label
        supportHeadingLabel.textColor = .label
        stylePrivacyPolicyButton()
        styleDeleteAccountButton()
        styleSupportButton()
        styleNotificationSwitch()
        loadingIndicator?.color = AppTheme.accent
        greetingLabel?.textColor = .label
    }
    
    private func styleBackButton() {
        let foreground = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.left")
        config.baseForegroundColor = foreground
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        backButton.configuration = config
        AppTheme.styleNativeFloatingControl(backButton, cornerRadius: backButton.bounds.height / 2)
        backButton.backgroundColor = .clear
        backButton.tintColor = foreground
    }
    
    private func styleEditButton() {
        let title = isEditingProfile ? "Save" : "Edit"
        let foreground = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = foreground
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([.foregroundColor: foreground])
        )
        editButton.configuration = config
        AppTheme.styleNativeFloatingControl(editButton, cornerRadius: editButton.bounds.height / 2)
        editButton.backgroundColor = .clear
        editButton.tintColor = foreground
        editButton.setTitleColor(foreground, for: .normal)
    }
    
    private func styleAvatarEditButton() {
        var config = UIButton.Configuration.plain()
        config.title = nil
        config.image = UIImage(systemName: "camera.fill")
        config.baseForegroundColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        avatarEditButton.configuration = config
        AppTheme.styleNativeFloatingControl(avatarEditButton, cornerRadius: avatarEditButton.bounds.height / 2)
        avatarEditButton.backgroundColor = .clear
    }
    
    private func styleSignOutButton() {
        var config = UIButton.Configuration.plain()
        config.title = "Sign Out"
        config.baseForegroundColor = .systemRed
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString(
            "Sign Out",
            attributes: AttributeContainer([.foregroundColor: UIColor.systemRed])
        )
        signOutButton.configuration = config
        AppTheme.styleNativeFloatingControl(signOutButton, cornerRadius: signOutButton.bounds.height / 2)
        signOutButton.backgroundColor = .clear
        signOutButton.tintColor = .systemRed
        signOutButton.setTitleColor(.systemRed, for: .normal)
    }

    private func stylePrivacyPolicyButton() {
        AppTheme.styleCard(privacyPolicyButton, cornerRadius: 18)
        var config = UIButton.Configuration.plain()
        config.title = "Privacy & Policy"
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 10
        config.baseForegroundColor = .label
        config.background.backgroundColor = .clear
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        config.titleAlignment = .leading
        privacyPolicyButton.configuration = config
        privacyPolicyButton.contentHorizontalAlignment = .fill
        privacyPolicyButton.tintColor = .secondaryLabel
    }

    private func styleSupportButton() {
        AppTheme.styleCard(supportButton, cornerRadius: 18)
        var config = UIButton.Configuration.plain()
        config.title = "Support & Help"
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 10
        config.baseForegroundColor = .label
        config.background.backgroundColor = .clear
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        config.titleAlignment = .leading
        supportButton.configuration = config
        supportButton.contentHorizontalAlignment = .fill
        supportButton.tintColor = .secondaryLabel
    }

    private func styleDeleteAccountButton() {
        AppTheme.styleCard(deleteAccountButton, cornerRadius: 18)
        var config = UIButton.Configuration.plain()
        config.title = "Delete Your Account"
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 10
        config.baseForegroundColor = .systemRed
        config.background.backgroundColor = .clear
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        config.titleAlignment = .leading
        deleteAccountButton.configuration = config
        deleteAccountButton.contentHorizontalAlignment = .fill
        deleteAccountButton.tintColor = .systemRed
    }
    
    private func styleNotificationSwitch() {
        let offTrackColor: UIColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.18)
            : UIColor(red: 0.21, green: 0.33, blue: 0.49, alpha: 0.24)
        personalMailSwitch?.onTintColor = AppTheme.accent
        personalMailSwitch?.tintColor = offTrackColor
        personalMailSwitch?.backgroundColor = offTrackColor
        personalMailSwitch?.thumbTintColor = .white
        personalMailSwitch?.layer.cornerRadius = (personalMailSwitch?.bounds.height ?? 0) / 2
        personalMailSwitch?.layer.masksToBounds = true
    }
    
    private func styleCardContent(_ root: UIView?) {
        guard let root else { return }
        for subview in root.subviews {
            if subview is UISwitch {
                continue
            }
            if shouldStyleAsSeparator(subview) {
                subview.backgroundColor = UIColor.separator.withAlphaComponent(
                    traitCollection.userInterfaceStyle == .dark ? 0.42 : 0.18
                )
                continue
            }
            switch subview {
            case let label as UILabel:
                label.textColor = .label
                label.backgroundColor = .clear
            case let textField as UITextField:
                textField.borderStyle = .none
                textField.backgroundColor = .clear
                textField.background = nil
                textField.disabledBackground = nil
                textField.textColor = textField.isEnabled ? .label : (textField.text == "Not Set" ? .secondaryLabel : .label)
                textField.tintColor = AppTheme.accent
                if let placeholder = textField.placeholder {
                    textField.attributedPlaceholder = NSAttributedString(
                        string: placeholder,
                        attributes: [.foregroundColor: UIColor.secondaryLabel]
                    )
                }
            case let button as UIButton:
                if button !== backButton && button !== editButton && button !== signOutButton && button !== avatarEditButton {
                    button.backgroundColor = .clear
                    button.tintColor = .secondaryLabel
                    button.setTitleColor(.label, for: .normal)
                }
            default:
                subview.backgroundColor = .clear
            }
            styleCardContent(subview)
        }
    }
    
    private func styleOuterHierarchy(in root: UIView) {
        for subview in root.subviews {
            if subview is UISwitch {
                continue
            }
            switch subview {
            case profileCardView, academicCardView, personalCardView, featuresCardView, backButton, editButton, signOutButton, avatarEditButton, avatarImageView:
                break
            case is UILabel, is UIStackView, is UIScrollView, is UIImageView, is UITextField:
                subview.backgroundColor = .clear
            default:
                subview.backgroundColor = .clear
            }
            styleOuterHierarchy(in: subview)
        }
    }
    
    private func shouldStyleAsSeparator(_ view: UIView) -> Bool {
        let constraintHeight = view.constraints
            .filter { $0.firstAttribute == .height }
            .map(\.constant)
            .min() ?? .greatestFiniteMagnitude
        let effectiveHeight = min(view.bounds.height, constraintHeight)
        return effectiveHeight <= 1.5
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

    @objc private func showAvatarPreview() {
        guard let image = avatarImageView.image else { return }
        present(ProfileImagePreviewViewController(image: image), animated: true)
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
            avatarImageView.tintColor = nil
            avatarImageView.contentMode = .scaleAspectFill
            isShowingPlaceholderAvatar = false
            if let personId = currentPersonId,
               let base64 = SupabaseManager.shared.imageToBase64(image: square) {
                // 1. Cache locally for instant display next launch
                SupabaseManager.shared.cacheProfilePhotoBase64(base64, personId: personId, role: "mentor")
                // 2. Persist to Supabase so it survives reinstalls
                Task { await SupabaseManager.shared.saveProfilePhoto(base64, personId: personId, role: "mentor") }
            }
            delegate?.profileViewController(self, didUpdateAvatar: square)
        }
        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    @IBAction func signOutButtonTapped(_ sender: UIButton) {
        Task {
            try? await SupabaseManager.shared.client.auth.signOut()
        }
        // ✅ Clear stored data
        UserDefaults.standard.removeObject(forKey: "current_person_id")
        UserDefaults.standard.removeObject(forKey: "current_user_name")
        UserDefaults.standard.removeObject(forKey: "current_user_email")
        UserDefaults.standard.removeObject(forKey: "current_user_role")
        UserDefaults.standard.set(false, forKey: "is_logged_in")
        UserDefaults.standard.removeObject(forKey: "current_user_name")
        UserDefaults.standard.removeObject(forKey: "mentorEmail")
        
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

    @objc private func openPrivacyPolicy() {
        PrivacyPolicySupport.present(from: self)
    }

    @objc private func openSupportHelp() {
        presentAsProfileSheet(SupportHelpViewController())
    }

    @objc private func confirmDeleteAccount() {
        let alert = UIAlertController(
            title: "Delete Your Account",
            message: "This will permanently delete your account data from Supabase. This action cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Not Now", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete Account", style: .destructive) { [weak self] _ in
            self?.deleteAccount()
        })
        present(alert, animated: true)
    }

    private func deleteAccount() {
        guard !isDeletingAccount else { return }
        guard let personId = currentPersonId, !personId.isEmpty else { return }

        isDeletingAccount = true
        let email = UserDefaults.standard.string(forKey: "current_user_email")

        Task { [weak self] in
            guard let self else { return }
            do {
                try await SupabaseManager.shared.deleteAccount(role: "mentor", personId: personId, email: email)
                await MainActor.run {
                    self.isDeletingAccount = false
                    self.signOutButtonTapped(self.signOutButton)
                }
            } catch {
                await MainActor.run {
                    self.isDeletingAccount = false
                    self.showDeletionError(message: error.localizedDescription)
                }
            }
        }
    }

    private func showDeletionError(message: String) {
        let alert = UIAlertController(title: "Delete Failed", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @IBAction func personalMailSwitchChanged(_ sender: UISwitch) {
        let isOn = sender.isOn
        
        if isOn {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .notDetermined {
                        // Ask once
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                            DispatchQueue.main.async {
                                sender.setOn(granted, animated: true)
                                UserDefaults.standard.set(granted, forKey: "profile_notifications_enabled")
                            }
                        }
                    } else if settings.authorizationStatus == .denied {
                        // Already denied
                        sender.setOn(false, animated: true)
                        self.showSettingsAlert()
                    } else {
                        // Already authorized
                        UserDefaults.standard.set(true, forKey: "profile_notifications_enabled")
                    }
                }
            }
        } else {
            UserDefaults.standard.set(false, forKey: "profile_notifications_enabled")
        }
    }
    
    private func showSettingsAlert() {
        let alert = UIAlertController(
            title: "Notifications Disabled",
            message: "Please enable notifications in Settings to receive alerts.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        }))
        present(alert, animated: true)
    }

    @IBAction func editButtonTapped(_ sender: UIButton) {
        isEditingProfile.toggle()
        avatarEditButton.isHidden = !isEditingProfile

        if isEditingProfile {
            // ENTER EDIT MODE
            for tf in allTextFields.compactMap({ $0 }) {
                tf.isEnabled = true
                tf.borderStyle = .none
                tf.backgroundColor = .clear
                tf.textColor = .label
                if tf.text == "Not Set" || tf.text?.isEmpty == true {
                    tf.text = ""
                }
            }

            firstNameField?.becomeFirstResponder()

        } else {
            // EXIT EDIT MODE (SAVE)
            view.endEditing(true)
            saveProfileToSupabase()

            for tf in allTextFields.compactMap({ $0 }) {
                tf.isEnabled = false
                tf.borderStyle = .none
                tf.backgroundColor = .clear
            }
        }
        
        refreshTheme()
    }

    // ✅ NEW: Save to Supabase
    private func saveProfileToSupabase() {
        guard let personId = currentPersonId else {
            showError("User not found. Please log in again.")
            return
        }
        
        print("🔄 Starting mentor profile save for person_id: \(personId)")
        
        // Get field values
        let firstName = firstNameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let lastName = lastNameField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let department = departmentField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let email = srmMailField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let employeeId = facultyIdField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
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
                print("🔄 Upserting mentor profile...")
                
                // Upsert profile to Supabase
                struct MentorProfileUpsert: Encodable {
                    let person_id: String
                    let first_name: String
                    let last_name: String
                    let email: String?
                    let employee_id: String?
                    let department: String?
                    let designation: String?
                    let personal_mail: String?
                    let contact_number: String?
                    let is_profile_complete: Bool
                }
                
                let isComplete = !firstName.isEmpty && !lastName.isEmpty
                
                let profile = MentorProfileUpsert(
                    person_id: personId,
                    first_name: firstName,
                    last_name: lastName,
                    email: email?.isEmpty == true ? nil : email,
                    employee_id: employeeId?.isEmpty == true ? nil : employeeId,
                    department: department?.isEmpty == true ? nil : department,
                    designation: currentProfile?.designation,
                    personal_mail: personalMail?.isEmpty == true ? nil : personalMail,
                    contact_number: contactNumber?.isEmpty == true ? nil : contactNumber,
                    is_profile_complete: isComplete
                )
                
                struct ProfileResponse: Codable {
                    let id: String
                }
                
                let _: [ProfileResponse] = try await SupabaseManager.shared.client
                    .from("mentor_profiles")
                    .upsert(profile, onConflict: "person_id")
                    .select("id")
                    .execute()
                    .value
                
                print("✅ Mentor profile saved")
                
                await MainActor.run {
                    self.loadingIndicator?.stopAnimating()
                    
                    // Reload to get updated greeting
                    Task {
                        self.loadProfileData(personId: personId)
                    }
                }
                
            } catch let error as NSError {
                await MainActor.run {
                    self.loadingIndicator?.stopAnimating()
                    print("❌ Error saving mentor profile:", error)
                    
                    let errorMessage = error.localizedDescription
                    self.showError("Failed to save profile: \(errorMessage)")
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator?.stopAnimating()
                    print("❌ Unknown error saving mentor profile:", error)
                    self.showError("Failed to save profile: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func restoreSwitchState() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
                
                if !isAuthorized {
                    self.personalMailSwitch?.setOn(false, animated: false)
                    UserDefaults.standard.set(false, forKey: "profile_notifications_enabled")
                } else {
                    if UserDefaults.standard.object(forKey: "profile_notifications_enabled") == nil {
                        UserDefaults.standard.set(true, forKey: "profile_notifications_enabled")
                    }
                    let on = UserDefaults.standard.bool(forKey: "profile_notifications_enabled")
                    self.personalMailSwitch?.setOn(on, animated: false)
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
