//
//  StudentProfileViewController.swift
//  iCohort3
//

import UIKit
import Supabase

final class StudentProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let titleLabel = UILabel()
    private let mainStack = UIStackView()
    private let academicHeadingLabel = UILabel()
    private let personalHeadingLabel = UILabel()

    private var rowTitleLabels: [UILabel] = []
    private var rowSeparators: [UIView] = []
    private var allFields: [UITextField] = []

    private var isEditingProfile = false
    private var currentPersonId: String?
    private var currentProfile: SupabaseManager.StudentProfile?

    private var resolvedPersonId: String? {
        currentPersonId ?? UserDefaults.standard.string(forKey: "current_person_id")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        rebuildScreen()
        enableKeyboardDismissOnTap()
        setupAvatarPreviewTap()
        setupInitialState()
        configureAvatarPlaceholder()
        configureAvatarEditButton()
        getCurrentUserPersonId()
        loadCachedAvatar()
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            refreshTheme()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
        avatarImageView?.layer.cornerRadius = (avatarImageView?.bounds.width ?? 0) / 2
        uploadButton?.layer.cornerRadius = (uploadButton?.bounds.height ?? 0) / 2
        loadingIndicator?.layer.cornerRadius = (loadingIndicator?.bounds.width ?? 0) / 2
        if avatarImageView?.image == nil {
            configureAvatarPlaceholder()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshTheme()
        loadCachedAvatar()
        if let personId = currentPersonId {
            loadProfileData(personId: personId)
        }
    }

    private func rebuildScreen() {
        view.subviews.forEach { $0.removeFromSuperview() }

        rowTitleLabels.removeAll()
        rowSeparators.removeAll()
        allFields.removeAll()

        let backButton = UIButton(type: .system)
        let editButton = UIButton(type: .system)
        let avatarImageView = UIImageView()
        let uploadButton = UIButton(type: .system)
        let loadingIndicator = UIActivityIndicatorView(style: .large)

        let firstNameField = makeValueField()
        let lastNameField = makeValueField()
        let departmentField = makeValueField()
        let srmMailField = makeValueField()
        let regNoField = makeValueField()
        let personalMailField = makeValueField()
        let contactNumberField = makeValueField()

        let profileCardView = makeCard()
        let academicCardView = makeCard()
        let personalCardView = makeCard()

        self.backButton = backButton
        self.editButton = editButton
        self.greetingLabel = titleLabel
        self.avatarImageView = avatarImageView
        self.uploadButton = uploadButton
        self.loadingIndicator = loadingIndicator

        self.firstNameField = firstNameField
        self.lastNameField = lastNameField
        self.departmentField = departmentField
        self.srmMailField = srmMailField
        self.regNoField = regNoField
        self.personalMailField = personalMailField
        self.contactNumberField = contactNumberField

        self.profileCardView = profileCardView
        self.academicCardView = academicCardView
        self.personalCardView = personalCardView
        self.logOut = nil

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true

        contentView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Profile"
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textAlignment = .center

        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.addTarget(self, action: #selector(backButtonTapped(_:)), for: .touchUpInside)

        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editButtonTapped(_:)), for: .touchUpInside)

        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.isUserInteractionEnabled = true

        uploadButton.translatesAutoresizingMaskIntoConstraints = false
        uploadButton.addTarget(self, action: #selector(uploadButtonTapped(_:)), for: .touchUpInside)

        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.hidesWhenStopped = true

        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.alignment = .fill
        mainStack.distribution = .fill
        mainStack.spacing = 16

        academicHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        academicHeadingLabel.text = "Academic Information"
        academicHeadingLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        personalHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        personalHeadingLabel.text = "Personal Details"
        personalHeadingLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        allFields = [
            firstNameField, lastNameField, departmentField, srmMailField,
            regNoField, personalMailField, contactNumberField
        ]

        configureFieldInputBehavior()

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(backButton)
        contentView.addSubview(editButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(avatarImageView)
        contentView.addSubview(uploadButton)
        contentView.addSubview(loadingIndicator)
        contentView.addSubview(mainStack)

        let profileRows = [
            makeRow(title: "First Name", field: firstNameField, showsSeparator: true),
            makeRow(title: "Last Name", field: lastNameField, showsSeparator: false)
        ]
        let academicRows = [
            makeRow(title: "Department", field: departmentField, showsSeparator: true),
            makeRow(title: "SRM Mail", field: srmMailField, showsSeparator: true),
            makeRow(title: "Registration Number", field: regNoField, showsSeparator: false)
        ]
        let personalRows = [
            makeRow(title: "Personal Mail", field: personalMailField, showsSeparator: true),
            makeRow(title: "Contact Number", field: contactNumberField, showsSeparator: false)
        ]

        populateCard(profileCardView, rows: profileRows)
        populateCard(academicCardView, rows: academicRows)
        populateCard(personalCardView, rows: personalRows)

        mainStack.addArrangedSubview(profileCardView)
        mainStack.addArrangedSubview(academicHeadingLabel)
        mainStack.addArrangedSubview(academicCardView)
        mainStack.addArrangedSubview(personalHeadingLabel)
        mainStack.addArrangedSubview(personalCardView)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            backButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            editButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            editButton.widthAnchor.constraint(equalToConstant: 64),
            editButton.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            avatarImageView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 96),
            avatarImageView.heightAnchor.constraint(equalToConstant: 96),

            uploadButton.widthAnchor.constraint(equalToConstant: 38),
            uploadButton.heightAnchor.constraint(equalToConstant: 38),
            uploadButton.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            uploadButton.bottomAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: -4),

            loadingIndicator.centerXAnchor.constraint(equalTo: avatarImageView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: avatarImageView.centerYAnchor),

            mainStack.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 24),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])

        mainStack.setCustomSpacing(12, after: academicHeadingLabel)
        mainStack.setCustomSpacing(16, after: academicCardView)
        mainStack.setCustomSpacing(12, after: personalHeadingLabel)

        refreshTheme()
    }

    private func makeCard() -> UIView {
        let card = UIView()
        card.translatesAutoresizingMaskIntoConstraints = false
        return card
    }

    private func populateCard(_ card: UIView, rows: [UIView]) {
        let stack = UIStackView(arrangedSubviews: rows)
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.alignment = .fill
        stack.distribution = .fill
        stack.spacing = 0
        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor)
        ])
    }

    private func makeRow(title: String, field: UITextField, showsSeparator: Bool) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)

        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.isHidden = !showsSeparator

        rowTitleLabels.append(titleLabel)
        rowSeparators.append(separator)

        row.addSubview(titleLabel)
        row.addSubview(field)
        row.addSubview(separator)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 50),

            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            field.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 12),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            separator.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            separator.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            separator.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            separator.heightAnchor.constraint(equalToConstant: 1)
        ])

        return row
    }

    private func makeValueField() -> UITextField {
        let field = UITextField()
        field.translatesAutoresizingMaskIntoConstraints = false
        field.textAlignment = .right
        field.font = .systemFont(ofSize: 17, weight: .regular)
        field.borderStyle = .none
        field.backgroundColor = .clear
        field.adjustsFontSizeToFitWidth = false
        field.clearButtonMode = .never
        field.placeholder = "Not Set"
        field.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return field
    }

    private func configureFieldInputBehavior() {
        firstNameField?.autocapitalizationType = .words
        lastNameField?.autocapitalizationType = .words
        departmentField?.autocapitalizationType = .words
        srmMailField?.autocapitalizationType = .none
        regNoField?.autocapitalizationType = .allCharacters
        personalMailField?.autocapitalizationType = .none
        contactNumberField?.autocapitalizationType = .none

        firstNameField?.keyboardType = .default
        lastNameField?.keyboardType = .default
        departmentField?.keyboardType = .default
        srmMailField?.keyboardType = .emailAddress
        regNoField?.keyboardType = .asciiCapable
        personalMailField?.keyboardType = .emailAddress
        contactNumberField?.keyboardType = .phonePad

        srmMailField?.autocorrectionType = .no
        personalMailField?.autocorrectionType = .no
        regNoField?.autocorrectionType = .no

        [firstNameField, lastNameField, departmentField].forEach {
            $0?.addTarget(self, action: #selector(capitalizeProfileField(_:)), for: .editingChanged)
        }
    }

    private var editableFields: [UITextField] {
        allFields
    }

    private func setupInitialState() {
        editableFields.forEach {
            $0.isEnabled = false
            $0.text = ""
            $0.placeholder = "Not Set"
        }
        uploadButton?.isHidden = true
        uploadButton?.isUserInteractionEnabled = false
        loadingIndicator?.hidesWhenStopped = true
        loadingIndicator?.stopAnimating()
        titleLabel.text = "Profile"
        refreshTheme()
    }

    private func configureAvatarPlaceholder() {
        guard let avatarImageView else { return }
        let name = UserDefaults.standard.string(forKey: "current_user_name") ?? "Student"
        let initial = String(name.first ?? "S")
        avatarImageView.image = UIImage.generateAvatar(initials: initial)
        avatarImageView.tintColor = nil
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.backgroundColor = .clear
    }

    private func configureAvatarEditButton() {
        guard let uploadButton else { return }
        var config = UIButton.Configuration.plain()
        config.title = nil
        config.image = UIImage(systemName: "camera.fill")
        config.baseForegroundColor = traitCollection.userInterfaceStyle == .dark ? .white : .black
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        uploadButton.configuration = config
        AppTheme.styleNativeFloatingControl(uploadButton, cornerRadius: 19)
    }

    private func setupAvatarPreviewTap() {
        avatarImageView?.isUserInteractionEnabled = true
        avatarImageView?.gestureRecognizers?.forEach { avatarImageView?.removeGestureRecognizer($0) }
        let tap = UITapGestureRecognizer(target: self, action: #selector(showAvatarPreview))
        avatarImageView?.addGestureRecognizer(tap)
    }

    @objc private func showAvatarPreview() {
        guard let image = avatarImageView?.image else { return }
        present(ProfileImagePreviewViewController(image: image), animated: true)
    }

    private func refreshTheme() {
        AppTheme.applyScreenBackground(to: view)
        view.tintColor = AppTheme.accent
        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear
        mainStack.backgroundColor = .clear

        titleLabel.textColor = .label
        academicHeadingLabel.textColor = .label
        personalHeadingLabel.textColor = .label

        if let backButton {
            styleFloatingButton(backButton, title: nil, foregroundColor: traitCollection.userInterfaceStyle == .dark ? .white : .black)
        }
        if let editButton {
            styleFloatingButton(editButton, title: isEditingProfile ? "Save" : "Edit", foregroundColor: traitCollection.userInterfaceStyle == .dark ? .white : .black)
        }

        configureAvatarEditButton()
        [profileCardView, academicCardView, personalCardView].compactMap { $0 }.forEach {
            AppTheme.styleElevatedCard($0, cornerRadius: 18)
        }

        rowTitleLabels.forEach {
            $0.textColor = .label
            $0.backgroundColor = .clear
        }
        rowSeparators.forEach {
            $0.backgroundColor = UIColor.separator.withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.42 : 0.20)
        }

        let filledColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        let emptyColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white.withAlphaComponent(0.78) : UIColor.black.withAlphaComponent(0.62)
        editableFields.forEach { field in
            field.textColor = (field.text?.isEmpty == false) ? filledColor : emptyColor
            field.font = .systemFont(ofSize: 17, weight: .regular)
            field.attributedPlaceholder = NSAttributedString(
                string: field.placeholder ?? "",
                attributes: [.foregroundColor: emptyColor]
            )
            field.tintColor = AppTheme.accent
        }
    }

    private func styleFloatingButton(_ button: UIButton, title: String?, foregroundColor: UIColor, cornerRadius: CGFloat = 22) {
        let existingImage = button.configuration?.image
        let image = existingImage ?? (title == nil ? UIImage(systemName: "chevron.left") : nil)
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

    private func getCurrentUserPersonId() {
        if let storedPersonId = resolvedPersonId {
            currentPersonId = storedPersonId
        } else {
            showError("Please login to view your profile")
        }
    }

    private func loadCachedAvatar() {
        guard let personId = resolvedPersonId else {
            configureAvatarPlaceholder()
            return
        }
        currentPersonId = personId

        if let cached = SupabaseManager.shared.cachedProfilePhotoBase64(personId: personId, role: "student"),
           let image = SupabaseManager.shared.base64ToImage(base64String: cached) {
            avatarImageView?.image = image
            avatarImageView?.tintColor = nil
            avatarImageView?.contentMode = .scaleAspectFill
            return
        }

        Task { [weak self] in
            guard let self else { return }
            if let base64 = await SupabaseManager.shared.fetchProfilePhoto(personId: personId, role: "student"),
               let image = SupabaseManager.shared.base64ToImage(base64String: base64) {
                SupabaseManager.shared.cacheProfilePhotoBase64(base64, personId: personId, role: "student")
                await MainActor.run {
                    self.avatarImageView?.image = image
                    self.avatarImageView?.tintColor = nil
                    self.avatarImageView?.contentMode = .scaleAspectFill
                }
            } else {
                await MainActor.run {
                    self.configureAvatarPlaceholder()
                }
            }
        }
    }

    private func loadProfileData(personId: String) {
        loadingIndicator?.startAnimating()

        Task {
            do {
                let _ = try await SupabaseManager.shared.getStudentGreeting(personId: personId)
                let profile = try await SupabaseManager.shared.fetchBasicStudentProfile(personId: personId)

                await MainActor.run {
                    self.currentProfile = profile
                    self.updateUIWithProfile(profile)
                    self.loadingIndicator?.stopAnimating()
                }
            } catch {
                await MainActor.run {
                    self.loadingIndicator?.stopAnimating()
                    if error.localizedDescription.contains("not found") {
                        self.updateUIWithProfile(nil)
                    } else {
                        self.showError("Failed to load profile")
                    }
                }
            }
        }
    }

    private func updateUIWithProfile(_ profile: SupabaseManager.StudentProfile?) {
        loadCachedAvatar()

        guard let profile else {
            editableFields.forEach {
                $0.text = ""
                $0.textColor = .systemGray
            }
            refreshTheme()
            return
        }

        firstNameField?.text = normalizedCapitalizedValue(profile.first_name)
        lastNameField?.text = normalizedCapitalizedValue(profile.last_name)
        departmentField?.text = normalizedCapitalizedValue(profile.department)
        srmMailField?.text = profile.srm_mail ?? ""
        regNoField?.text = profile.reg_no ?? ""
        personalMailField?.text = profile.personal_mail ?? ""
        contactNumberField?.text = profile.contact_number ?? ""

        refreshTheme()
    }

    @IBAction func backButtonTapped(_ sender: UIButton) {
        if let nav = navigationController {
            nav.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @IBAction func logOutButtonTapped(_ sender: Any) {
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
                return
            }

            let sb = UIStoryboard(name: "Main", bundle: nil)
            guard let loginVC = sb.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController else {
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
        let sheet = UIAlertController(title: "Change Profile Picture", message: nil, preferredStyle: .actionSheet)

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

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
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
                Task {
                    await SupabaseManager.shared.saveProfilePhoto(base64, personId: personId, role: "student")
                }
                NotificationCenter.default.post(name: NSNotification.Name("ProfileAvatarUpdated"), object: nil)
            }
        }
        dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true)
    }

    @IBAction func editButtonTapped(_ sender: UIButton) {
        isEditingProfile.toggle()
        uploadButton?.isHidden = !isEditingProfile
        uploadButton?.isUserInteractionEnabled = isEditingProfile

        if isEditingProfile {
            editableFields.forEach {
                $0.isEnabled = true
                if $0.text?.isEmpty == true { $0.text = "" }
            }
            firstNameField?.text = normalizedCapitalizedValue(firstNameField?.text)
            lastNameField?.text = normalizedCapitalizedValue(lastNameField?.text)
            departmentField?.text = normalizedCapitalizedValue(departmentField?.text)
            refreshTheme()
            firstNameField?.becomeFirstResponder()
        } else {
            view.endEditing(true)
            editableFields.forEach { $0.isEnabled = false }
            refreshTheme()
            saveProfileToSupabase()
        }
    }

    private func saveProfileToSupabase() {
        guard let personId = currentPersonId else {
            showError("User not found. Please log in again.")
            return
        }

        let firstName = normalizedCapitalizedValue(firstNameField?.text)
        let lastName = normalizedCapitalizedValue(lastNameField?.text)
        let department = normalizedCapitalizedValue(departmentField?.text)
        let srmMail = srmMailField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let regNo = regNoField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let personalMail = personalMailField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let contactNumber = contactNumberField?.text?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let firstName, !firstName.isEmpty else {
            showError("First name is required")
            return
        }

        guard let lastName, !lastName.isEmpty else {
            showError("Last name is required")
            return
        }

        loadingIndicator?.startAnimating()

        Task {
            do {
                _ = try await SupabaseManager.shared.upsertStudentProfile(
                    personId: personId,
                    firstName: firstName,
                    lastName: lastName,
                    department: department?.isEmpty == true ? nil : department,
                    srmMail: srmMail?.isEmpty == true ? nil : srmMail,
                    regNo: regNo?.isEmpty == true ? nil : regNo,
                    personalMail: personalMail?.isEmpty == true ? nil : personalMail,
                    contactNumber: contactNumber?.isEmpty == true ? nil : contactNumber
                )

                await MainActor.run {
                    self.loadingIndicator?.stopAnimating()
                }
                self.loadProfileData(personId: personId)
            } catch {
                await MainActor.run {
                    self.loadingIndicator?.stopAnimating()
                    self.showError("Failed to save profile: \(error.localizedDescription)")
                }
            }
        }
    }

    private func showError(_ message: String) async {
        await MainActor.run {
            self.showError(message)
        }
    }

    private func showError(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @objc private func capitalizeProfileField(_ sender: UITextField) {
        let currentCursorOffset = sender.offset(from: sender.beginningOfDocument, to: sender.selectedTextRange?.start ?? sender.endOfDocument)
        let normalizedText = normalizedCapitalizedValue(sender.text) ?? ""
        if sender.text != normalizedText {
            sender.text = normalizedText
            if let newPosition = sender.position(from: sender.beginningOfDocument, offset: min(currentCursorOffset, normalizedText.count)) {
                sender.selectedTextRange = sender.textRange(from: newPosition, to: newPosition)
            }
        }
    }

    private func normalizedCapitalizedValue(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }

        return trimmed
            .split(separator: " ")
            .map { word in
                let lowercased = word.lowercased()
                guard let firstCharacter = lowercased.first else { return "" }
                return String(firstCharacter).uppercased() + lowercased.dropFirst()
            }
            .joined(separator: " ")
    }
}
