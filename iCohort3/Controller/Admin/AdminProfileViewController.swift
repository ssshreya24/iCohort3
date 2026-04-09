import UIKit

final class AdminProfileViewController: UIViewController {
    private var instituteName: String
    private var instituteDomain: String
    private var adminEmail: String

    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let stackView = UIStackView()

    private let headerView = UIView()
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let editButton = UIButton(type: .system)

    private let infoHeadingLabel = UILabel()
    private let infoCardView = UIView()
    private let infoCardStackView = UIStackView()

    private let collegeNameField = UITextField()
    private let collegeMailField = UITextField()
    private let adminMailField = UITextField()

    private let legalHeadingLabel = UILabel()
    private let legalCardView = UIView()
    private let legalCardStackView = UIStackView()
    private let privacyButton = UIButton(type: .system)
    private let deleteAccountButton = UIButton(type: .system)

    private let supportHeadingLabel = UILabel()
    private let supportCardView = UIView()
    private let supportCardStackView = UIStackView()
    private let supportButton = UIButton(type: .system)

    private let signOutButton = UIButton(type: .system)

    private var infoSeparators: [UIView] = []
    private var isEditingProfile = false
    private var isDeletingAccount = false

    init(instituteName: String, instituteDomain: String, adminEmail: String) {
        self.instituteName = instituteName
        self.instituteDomain = instituteDomain
        self.adminEmail = adminEmail
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applyProfileValues()
        applyEditingState()
        refreshTheme()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle else { return }
        refreshTheme()
    }

    private func setupUI() {
        view.backgroundColor = .clear

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = .clear
        scrollView.addSubview(contentView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.backgroundColor = .clear
        contentView.addSubview(stackView)

        buildHeader()
        buildInfoSection()
        buildLegalSection()
        buildSupportSection()
        buildSignOutButton()

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            contentView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor),

            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -24),

            signOutButton.heightAnchor.constraint(equalToConstant: 46)
        ])
    }

    private func buildHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = .clear

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Profile"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center

        editButton.translatesAutoresizingMaskIntoConstraints = false
        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)

        headerView.addSubview(closeButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(editButton)

        NSLayoutConstraint.activate([
            headerView.heightAnchor.constraint(equalToConstant: 52),
            closeButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),

            editButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            editButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            editButton.heightAnchor.constraint(equalToConstant: 38),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: closeButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: editButton.leadingAnchor, constant: -12)
        ])

        stackView.addArrangedSubview(headerView)
    }

    private func buildInfoSection() {
        infoHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        infoHeadingLabel.text = "Admin Information"
        infoHeadingLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        stackView.addArrangedSubview(infoHeadingLabel)

        infoCardView.translatesAutoresizingMaskIntoConstraints = false
        infoCardStackView.translatesAutoresizingMaskIntoConstraints = false
        infoCardStackView.axis = .vertical
        infoCardStackView.spacing = 0
        infoCardView.addSubview(infoCardStackView)

        NSLayoutConstraint.activate([
            infoCardStackView.topAnchor.constraint(equalTo: infoCardView.topAnchor, constant: 2),
            infoCardStackView.leadingAnchor.constraint(equalTo: infoCardView.leadingAnchor, constant: 16),
            infoCardStackView.trailingAnchor.constraint(equalTo: infoCardView.trailingAnchor, constant: -16),
            infoCardStackView.bottomAnchor.constraint(equalTo: infoCardView.bottomAnchor, constant: -2)
        ])

        addInfoRow(title: "College Name", field: collegeNameField)
        addInfoRow(title: "College Mail", field: collegeMailField)
        addInfoRow(title: "Admin Mail", field: adminMailField, includesSeparatorBelow: false)

        stackView.addArrangedSubview(infoCardView)
    }

    private func addInfoRow(title: String, field: UITextField, includesSeparatorBelow: Bool = true) {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = .label

        configureField(field)
        row.addSubview(titleLabel)
        row.addSubview(field)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 56),
            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            field.leadingAnchor.constraint(greaterThanOrEqualTo: titleLabel.trailingAnchor, constant: 16),
            field.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            field.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            field.topAnchor.constraint(equalTo: row.topAnchor, constant: 10),
            field.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -10)
        ])

        infoCardStackView.addArrangedSubview(row)

        if includesSeparatorBelow {
            let separator = makeSeparator()
            infoSeparators.append(separator)
            infoCardStackView.addArrangedSubview(separator)
        }
    }

    private func buildLegalSection() {
        legalHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        legalHeadingLabel.text = "Legal"
        legalHeadingLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        stackView.addArrangedSubview(legalHeadingLabel)

        legalCardView.translatesAutoresizingMaskIntoConstraints = false
        legalCardStackView.translatesAutoresizingMaskIntoConstraints = false
        legalCardStackView.axis = .vertical
        legalCardStackView.spacing = 10
        legalCardView.addSubview(legalCardStackView)

        NSLayoutConstraint.activate([
            legalCardStackView.topAnchor.constraint(equalTo: legalCardView.topAnchor, constant: 10),
            legalCardStackView.leadingAnchor.constraint(equalTo: legalCardView.leadingAnchor, constant: 10),
            legalCardStackView.trailingAnchor.constraint(equalTo: legalCardView.trailingAnchor, constant: -10),
            legalCardStackView.bottomAnchor.constraint(equalTo: legalCardView.bottomAnchor, constant: -10)
        ])

        configureActionButton(privacyButton, title: "Privacy & Policy", destructive: false)
        privacyButton.addTarget(self, action: #selector(openPrivacyPolicy), for: .touchUpInside)

        configureActionButton(deleteAccountButton, title: "Delete Your Account", destructive: true)
        deleteAccountButton.addTarget(self, action: #selector(confirmDeleteAccount), for: .touchUpInside)

        legalCardStackView.addArrangedSubview(privacyButton)
        legalCardStackView.addArrangedSubview(deleteAccountButton)

        NSLayoutConstraint.activate([
            privacyButton.heightAnchor.constraint(equalToConstant: 50),
            deleteAccountButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        stackView.addArrangedSubview(legalCardView)
    }

    private func buildSupportSection() {
        supportHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        supportHeadingLabel.text = "Support"
        supportHeadingLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        stackView.addArrangedSubview(supportHeadingLabel)

        supportCardView.translatesAutoresizingMaskIntoConstraints = false
        supportCardStackView.translatesAutoresizingMaskIntoConstraints = false
        supportCardStackView.axis = .vertical
        supportCardStackView.spacing = 10
        supportCardView.addSubview(supportCardStackView)

        NSLayoutConstraint.activate([
            supportCardStackView.topAnchor.constraint(equalTo: supportCardView.topAnchor, constant: 10),
            supportCardStackView.leadingAnchor.constraint(equalTo: supportCardView.leadingAnchor, constant: 10),
            supportCardStackView.trailingAnchor.constraint(equalTo: supportCardView.trailingAnchor, constant: -10),
            supportCardStackView.bottomAnchor.constraint(equalTo: supportCardView.bottomAnchor, constant: -10)
        ])

        configureActionButton(supportButton, title: "Support & Help", destructive: false)
        supportButton.addTarget(self, action: #selector(openSupportHelp), for: .touchUpInside)
        supportCardStackView.addArrangedSubview(supportButton)
        NSLayoutConstraint.activate([
            supportButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        stackView.addArrangedSubview(supportCardView)
    }

    private func buildSignOutButton() {
        signOutButton.translatesAutoresizingMaskIntoConstraints = false
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
        stackView.addArrangedSubview(signOutButton)
    }

    private func configureField(_ field: UITextField) {
        field.translatesAutoresizingMaskIntoConstraints = false
        field.borderStyle = .none
        field.font = .systemFont(ofSize: 17, weight: .regular)
        field.textAlignment = .right
        field.textColor = .secondaryLabel
        field.adjustsFontSizeToFitWidth = true
        field.minimumFontSize = 12
        field.clearButtonMode = .whileEditing
        field.autocorrectionType = .no
        field.autocapitalizationType = .words
        field.spellCheckingType = .no
    }

    private func configureActionButton(_ button: UIButton, title: String, destructive: Bool) {
        button.translatesAutoresizingMaskIntoConstraints = false
        var config = UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: "chevron.right")
        config.imagePlacement = .trailing
        config.imagePadding = 8
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 18, bottom: 0, trailing: 18)
        config.baseForegroundColor = destructive ? .systemRed : .label
        config.titleAlignment = .leading
        button.configuration = config
        button.contentHorizontalAlignment = .fill
        if destructive {
            button.tintColor = .systemRed
        }
    }

    private func makeSeparator() -> UIView {
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    private func applyProfileValues() {
        collegeNameField.text = instituteName
        collegeMailField.text = instituteDomain
        collegeMailField.keyboardType = .emailAddress
        collegeMailField.autocapitalizationType = .none
        adminMailField.text = adminEmail
        adminMailField.keyboardType = .emailAddress
        adminMailField.autocapitalizationType = .none
    }

    private func applyEditingState() {
        [collegeNameField, collegeMailField, adminMailField].forEach {
            $0.isUserInteractionEnabled = isEditingProfile
            $0.textColor = isEditingProfile ? .label : .secondaryLabel
        }
    }

    private func refreshTheme() {
        AppTheme.applyScreenBackground(to: view)
        titleLabel.textColor = .label
        infoHeadingLabel.textColor = .label
        legalHeadingLabel.textColor = .label
        supportHeadingLabel.textColor = .label

        var closeConfig = UIButton.Configuration.plain()
        closeConfig.image = UIImage(systemName: "xmark")
        closeConfig.baseForegroundColor = .label
        closeButton.configuration = closeConfig
        AppTheme.styleNativeFloatingControl(closeButton, cornerRadius: 22)

        var editConfig = UIButton.Configuration.plain()
        editConfig.title = isEditingProfile ? "Save" : "Edit"
        editConfig.baseForegroundColor = .label
        editButton.configuration = editConfig
        AppTheme.styleNativeFloatingControl(editButton, cornerRadius: 19)

        AppTheme.styleElevatedCard(infoCardView, cornerRadius: 20)
        AppTheme.styleElevatedCard(legalCardView, cornerRadius: 20)
        AppTheme.styleElevatedCard(supportCardView, cornerRadius: 20)

        infoSeparators.forEach {
            $0.backgroundColor = UIColor.separator.withAlphaComponent(traitCollection.userInterfaceStyle == .dark ? 0.4 : 0.2)
        }

        var signOutConfig = UIButton.Configuration.plain()
        signOutConfig.title = "Sign Out"
        signOutConfig.baseForegroundColor = .systemRed
        signOutConfig.cornerStyle = .capsule
        signOutButton.configuration = signOutConfig
        signOutButton.setTitleColor(.systemRed, for: .normal)
        signOutButton.tintColor = .systemRed
        AppTheme.styleNativeFloatingControl(signOutButton, cornerRadius: 23)
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func editTapped() {
        if isEditingProfile {
            saveProfile()
        } else {
            isEditingProfile = true
            applyEditingState()
            refreshTheme()
        }
    }

    private func saveProfile() {
        let updatedInstituteName = collegeNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let updatedInstituteDomain = collegeMailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let updatedAdminEmail = adminMailField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !updatedInstituteName.isEmpty, !updatedInstituteDomain.isEmpty, !updatedAdminEmail.isEmpty else {
            showAlert(title: "Missing Details", message: "Please fill in all admin profile fields before saving.")
            return
        }

        let previousAdminEmail = adminEmail

        Task { [weak self] in
            guard let self else { return }
            do {
                try await SupabaseManager.shared.updateAdminProfile(
                    currentAdminEmail: previousAdminEmail,
                    newAdminEmail: updatedAdminEmail,
                    instituteName: updatedInstituteName,
                    instituteDomain: updatedInstituteDomain
                )

                await MainActor.run {
                    self.instituteName = updatedInstituteName
                    self.instituteDomain = updatedInstituteDomain.lowercased()
                    self.adminEmail = updatedAdminEmail.lowercased()
                    self.applyProfileValues()
                    UserDefaults.standard.set(self.adminEmail, forKey: "admin_email")
                    UserDefaults.standard.set(self.adminEmail, forKey: "current_user_email")
                    UserDefaults.standard.set(self.instituteName, forKey: "admin_institute_name")
                    UserDefaults.standard.set(self.instituteDomain, forKey: "admin_institute_domain")
                    self.isEditingProfile = false
                    self.applyEditingState()
                    self.refreshTheme()
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Save Failed", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func openPrivacyPolicy() {
        PrivacyPolicySupport.present(from: self)
    }

    @objc private func openSupportHelp() {
        PrivacyPolicySupport.present(from: self)
    }

    @objc private func confirmDeleteAccount() {
        let alert = UIAlertController(
            title: "Delete Your Account",
            message: "This will permanently delete your admin account data from Supabase. This action cannot be undone.",
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
        let trimmedEmail = adminEmail.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty else { return }

        isDeletingAccount = true

        Task { [weak self] in
            guard let self else { return }
            do {
                try await SupabaseManager.shared.deleteAdminAccount(email: trimmedEmail)
                await MainActor.run {
                    self.isDeletingAccount = false
                    self.performSignOut()
                }
            } catch {
                await MainActor.run {
                    self.isDeletingAccount = false
                    self.showAlert(title: "Delete Failed", message: error.localizedDescription)
                }
            }
        }
    }

    @objc private func signOutTapped() {
        performSignOut()
    }

    private func performSignOut() {
        UserDefaults.standard.removeObject(forKey: "admin_email")
        UserDefaults.standard.removeObject(forKey: "admin_institute_name")
        UserDefaults.standard.removeObject(forKey: "admin_institute_domain")
        UserDefaults.standard.removeObject(forKey: "is_admin")
        UserDefaults.standard.removeObject(forKey: "current_user_email")
        UserDefaults.standard.removeObject(forKey: "current_person_id")
        UserDefaults.standard.removeObject(forKey: "current_user_role")
        UserDefaults.standard.removeObject(forKey: "remembered_email")
        UserDefaults.standard.removeObject(forKey: "remembered_user_role")
        UserDefaults.standard.removeObject(forKey: "remember_me")
        UserDefaults.standard.removeObject(forKey: "is_logged_in")

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let userSelection = storyboard.instantiateViewController(withIdentifier: "UserSelectionVC") as? UserSelectionViewController,
              let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            dismiss(animated: true)
            return
        }

        let navRoot = UINavigationController(rootViewController: userSelection)
        navRoot.modalPresentationStyle = .fullScreen
        window.rootViewController = navRoot
        window.makeKeyAndVisible()
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
