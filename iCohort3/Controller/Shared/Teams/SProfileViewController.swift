//
//  SProfileViewController.swift
//  iCohort3
//
//  Based on the original XIB-driven profile layout, with added Legal/Support
//  sections and the same near-full sheet presentation used elsewhere.
//

import UIKit
import UserNotifications

final class SProfileViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton?
    @IBOutlet weak var avatarImageView: UIImageView?
    @IBOutlet weak var infoCardView: UIView?
    @IBOutlet weak var notificationSwitch: UISwitch?
    @IBOutlet weak var myDetailsTapArea: UIButton?
    @IBOutlet weak var myTeamTapArea: UIButton?
    @IBOutlet weak var featuresCardView: UIView?

    private var cachedTeamInfo: SupabaseManager.StudentTeamInfo?
    private var teamStatusTask: Task<Void, Never>?
    private var teamStatusRevision: Int = 0

    private let legalHeadingLabel = UILabel()
    private let legalCardView = UIView()
    private let legalButton = UIButton(type: .system)
    private let deleteAccountButton = UIButton(type: .system)

    private let supportHeadingLabel = UILabel()
    private let supportCardView = UIView()
    private let supportButton = UIButton(type: .system)

    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    private var isDeletingAccount = false

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStaticUI()
        restoreSwitchState()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTeamMembershipDidChange),
            name: .teamMembershipDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAvatarUpdated),
            name: NSNotification.Name("ProfileAvatarUpdated"),
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCachedAvatar()
        loadTeamStatus()
        refreshTheme()
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            refreshTheme()
            applyTeamButtonStyle(teamInfo: cachedTeamInfo)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView?.layer.cornerRadius = (avatarImageView?.bounds.width ?? 0) / 2
        refreshTheme()
    }

    private func configureStaticUI() {
        configureDefaultAvatar()
        avatarImageView?.clipsToBounds = true
        installAdditionalSections()
        styleNotificationSwitch()
        refreshTheme()
    }

    @objc private func handleAvatarUpdated() {
        loadCachedAvatar()
    }

    private func configureDefaultAvatar() {
        guard let avatarImageView else { return }

        let name = UserDefaults.standard.string(forKey: "current_user_name") ?? "Student"
        let initial = String(name.first ?? "S")

        avatarImageView.image = UIImage.generateAvatar(initials: initial)
        avatarImageView.tintColor = nil
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.clipsToBounds = true
        avatarImageView.backgroundColor = .clear
    }

    private func loadCachedAvatar() {
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              let cachedAvatar = SupabaseManager.shared.cachedProfilePhotoBase64(personId: personId, role: "student"),
              let image = SupabaseManager.shared.base64ToImage(base64String: cachedAvatar) else {
            configureDefaultAvatar()
            return
        }

        avatarImageView?.image = image
        avatarImageView?.tintColor = nil
        avatarImageView?.contentMode = .scaleAspectFill
    }

    private func loadTeamStatus() {
        teamStatusRevision += 1
        let revision = teamStatusRevision
        teamStatusTask?.cancel()

        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              !personId.isEmpty else {
            cachedTeamInfo = nil
            applyTeamButtonStyle(teamInfo: nil)
            return
        }

        teamStatusTask = Task { [weak self] in
            guard let self else { return }
            let teamInfo = try? await SupabaseManager.shared.fetchTeamInfoForStudent(personId: personId)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard self.teamStatusRevision == revision else { return }
                self.cachedTeamInfo = teamInfo
                self.applyTeamButtonStyle(teamInfo: teamInfo)
            }
        }
    }

    private func applyTeamButtonStyle(teamInfo: SupabaseManager.StudentTeamInfo?) {
        guard let btn = myTeamTapArea else { return }

        var title = "Not Set"
        var color = UIColor.secondaryLabel
        var weight = UIFont.Weight.regular

        if let info = teamInfo {
            if info.isFull {
                title = "Team \(info.teamNumber)"
                color = .systemGreen
                weight = .semibold
            } else {
                title = "Team \(info.teamNumber)  ·  \(info.memberCount)/3"
                color = AppTheme.accent
                weight = .medium
            }
        }

        btn.titleLabel?.font = .systemFont(ofSize: 15, weight: weight)
        btn.setTitleColor(color, for: .normal)
        btn.tintColor = color

        var config = btn.configuration ?? UIButton.Configuration.plain()
        config.title = title
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 6
        config.baseForegroundColor = color
        config.contentInsets = .zero
        btn.configuration = config
    }

    @IBAction func myDetailsTapped(_ sender: Any) {
        let vc = StudentProfileViewController(nibName: "StudentProfileViewController", bundle: nil)
        presentAsProfileSheet(vc)
    }

    @IBAction func myTeamTapped(_ sender: Any) {
        if let info = cachedTeamInfo, info.isFull {
            let detailVC = TeamDetailViewController(teamInfo: info)
            presentAsProfileSheet(detailVC)
            return
        }

        presentTeamVC(startMode: .create)
    }

    @IBAction func notificationChanged(_ sender: UISwitch) {
        let isOn = sender.isOn

        if isOn {
            UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
                guard let self else { return }
                DispatchQueue.main.async {
                    if settings.authorizationStatus == .notDetermined {
                        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                            DispatchQueue.main.async {
                                sender.setOn(granted, animated: true)
                                UserDefaults.standard.set(granted, forKey: "profile_notifications_enabled")
                            }
                        }
                    } else if settings.authorizationStatus == .denied {
                        sender.setOn(false, animated: true)
                        self.showSettingsAlert()
                    } else {
                        UserDefaults.standard.set(true, forKey: "profile_notifications_enabled")
                    }
                }
            }
        } else {
            UserDefaults.standard.set(false, forKey: "profile_notifications_enabled")
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
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              !personId.isEmpty else { return }

        isDeletingAccount = true
        let email = UserDefaults.standard.string(forKey: "current_user_email")

        Task { [weak self] in
            guard let self else { return }
            do {
                try await SupabaseManager.shared.deleteAccount(role: "student", personId: personId, email: email)
                await MainActor.run {
                    self.isDeletingAccount = false
                    self.signOutTapped()
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

    private func showSettingsAlert() {
        let alert = UIAlertController(
            title: "Notifications Disabled",
            message: "Please enable notifications in Settings to receive alerts.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        present(alert, animated: true)
    }

    @IBAction func closeTapped(_ sender: Any) {
        if let nav = navigationController, nav.viewControllers.first != self {
            nav.popViewController(animated: true)
        } else if presentingViewController != nil {
            dismiss(animated: true)
        } else {
            view.endEditing(true)
        }
    }

    @objc private func signOutTapped() {
        UserDefaults.standard.removeObject(forKey: "current_person_id")
        UserDefaults.standard.removeObject(forKey: "current_user_name")
        UserDefaults.standard.removeObject(forKey: "current_user_email")
        UserDefaults.standard.removeObject(forKey: "current_user_role")
        UserDefaults.standard.set(false, forKey: "is_logged_in")

        guard let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            return
        }

        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = storyboard.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController else {
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

    @objc private func handleTeamMembershipDidChange() {
        teamStatusRevision += 1
        teamStatusTask?.cancel()
        cachedTeamInfo = nil
        applyTeamButtonStyle(teamInfo: nil)
        Task { [weak self] in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard let self else { return }
            await MainActor.run {
                self.loadTeamStatus()
            }
        }
    }

    deinit {
        teamStatusTask?.cancel()
        NotificationCenter.default.removeObserver(self)
    }

    private func restoreSwitchState() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let isAuthorized = settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional

                if !isAuthorized {
                    self.notificationSwitch?.setOn(false, animated: false)
                    UserDefaults.standard.set(false, forKey: "profile_notifications_enabled")
                } else {
                    if UserDefaults.standard.object(forKey: "profile_notifications_enabled") == nil {
                        UserDefaults.standard.set(true, forKey: "profile_notifications_enabled")
                    }
                    self.notificationSwitch?.setOn(UserDefaults.standard.bool(forKey: "profile_notifications_enabled"), animated: false)
                }
            }
        }
    }

    private func installAdditionalSections() {
        guard legalHeadingLabel.superview == nil,
              let featuresCardView,
              let container = featuresCardView.superview else { return }

        let legalRow = makeStandaloneActionRow(title: "Privacy & Policy", button: legalButton)
        let deleteRow = makeStandaloneActionRow(title: "Delete Your Account", button: deleteAccountButton)
        let supportRow = makeStandaloneActionRow(title: "Support & Help", button: supportButton)

        legalHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        legalCardView.translatesAutoresizingMaskIntoConstraints = false
        supportHeadingLabel.translatesAutoresizingMaskIntoConstraints = false
        supportCardView.translatesAutoresizingMaskIntoConstraints = false

        legalHeadingLabel.text = "Legal"
        legalHeadingLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        supportHeadingLabel.text = "Support"
        supportHeadingLabel.font = .systemFont(ofSize: 22, weight: .semibold)

        legalButton.addTarget(self, action: #selector(openPrivacyPolicy), for: .touchUpInside)
        deleteAccountButton.addTarget(self, action: #selector(confirmDeleteAccount), for: .touchUpInside)
        supportButton.addTarget(self, action: #selector(openSupportHelp), for: .touchUpInside)
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)

        legalCardView.addSubview(legalRow)
        legalCardView.addSubview(deleteRow)
        supportCardView.addSubview(supportRow)

        legalRow.translatesAutoresizingMaskIntoConstraints = false
        deleteRow.translatesAutoresizingMaskIntoConstraints = false
        supportRow.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(legalHeadingLabel)
        container.addSubview(legalCardView)
        container.addSubview(supportHeadingLabel)
        container.addSubview(supportCardView)
        container.addSubview(signOutButton)

        if let oldSignOutConstraints = container.constraints.filter({
            ($0.firstItem as? UIButton) === signOutButton || ($0.secondItem as? UIButton) === signOutButton
        }) as [NSLayoutConstraint]? {
            oldSignOutConstraints.forEach { $0.isActive = false }
        }

        NSLayoutConstraint.activate([
            legalRow.topAnchor.constraint(equalTo: legalCardView.topAnchor),
            legalRow.leadingAnchor.constraint(equalTo: legalCardView.leadingAnchor),
            legalRow.trailingAnchor.constraint(equalTo: legalCardView.trailingAnchor),

            deleteRow.topAnchor.constraint(equalTo: legalRow.bottomAnchor),
            deleteRow.leadingAnchor.constraint(equalTo: legalCardView.leadingAnchor),
            deleteRow.trailingAnchor.constraint(equalTo: legalCardView.trailingAnchor),
            deleteRow.bottomAnchor.constraint(equalTo: legalCardView.bottomAnchor),

            supportRow.topAnchor.constraint(equalTo: supportCardView.topAnchor),
            supportRow.leadingAnchor.constraint(equalTo: supportCardView.leadingAnchor),
            supportRow.trailingAnchor.constraint(equalTo: supportCardView.trailingAnchor),
            supportRow.bottomAnchor.constraint(equalTo: supportCardView.bottomAnchor),

            legalHeadingLabel.topAnchor.constraint(equalTo: featuresCardView.bottomAnchor, constant: 18),
            legalHeadingLabel.leadingAnchor.constraint(equalTo: featuresCardView.leadingAnchor),
            legalHeadingLabel.trailingAnchor.constraint(equalTo: featuresCardView.trailingAnchor),

            legalCardView.topAnchor.constraint(equalTo: legalHeadingLabel.bottomAnchor, constant: 8),
            legalCardView.leadingAnchor.constraint(equalTo: featuresCardView.leadingAnchor),
            legalCardView.trailingAnchor.constraint(equalTo: featuresCardView.trailingAnchor),
            legalCardView.heightAnchor.constraint(equalToConstant: 100),

            supportHeadingLabel.topAnchor.constraint(equalTo: legalCardView.bottomAnchor, constant: 18),
            supportHeadingLabel.leadingAnchor.constraint(equalTo: legalHeadingLabel.leadingAnchor),
            supportHeadingLabel.trailingAnchor.constraint(equalTo: legalHeadingLabel.trailingAnchor),

            supportCardView.topAnchor.constraint(equalTo: supportHeadingLabel.bottomAnchor, constant: 8),
            supportCardView.leadingAnchor.constraint(equalTo: legalCardView.leadingAnchor),
            supportCardView.trailingAnchor.constraint(equalTo: legalCardView.trailingAnchor),
            supportCardView.heightAnchor.constraint(equalToConstant: 50),

            signOutButton.topAnchor.constraint(equalTo: supportCardView.bottomAnchor, constant: 18),
            signOutButton.leadingAnchor.constraint(equalTo: featuresCardView.leadingAnchor),
            signOutButton.trailingAnchor.constraint(equalTo: featuresCardView.trailingAnchor),
            signOutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    private func makeStandaloneActionRow(title: String, button: UIButton) -> UIView {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        titleLabel.textColor = .label

        var config = UIButton.Configuration.plain()
        config.title = nil
        config.image = UIImage(systemName: "chevron.right")
        config.baseForegroundColor = title == "Delete Your Account" ? .systemRed : .secondaryLabel
        config.contentInsets = .zero
        button.configuration = config
        button.translatesAutoresizingMaskIntoConstraints = false

        row.addSubview(titleLabel)
        row.addSubview(button)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 50),

            titleLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            titleLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            button.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
            button.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 28),
            button.heightAnchor.constraint(equalToConstant: 28)
        ])

        return row
    }

    private func applyThemeToHierarchy() {
        styleViewHierarchy(view)

        [infoCardView, featuresCardView, legalCardView, supportCardView].forEach { card in
            guard let card else { return }
            AppTheme.styleElevatedCard(card, cornerRadius: 20)
            card.layer.cornerCurve = .continuous
            styleCardContent(in: card)
        }
    }

    private func refreshTheme() {
        AppTheme.applyScreenBackground(to: view)
        styleCloseButton()
        styleNotificationSwitch()
        styleSignOutButton()
        applyThemeToHierarchy()
        styleOuterHierarchy(in: view)
        legalHeadingLabel.textColor = .label
        supportHeadingLabel.textColor = .label
    }

    private func styleNotificationSwitch() {
        guard let notificationSwitch else { return }

        let offTrackColor: UIColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.18)
            : UIColor(red: 0.21, green: 0.33, blue: 0.49, alpha: 0.24)

        notificationSwitch.onTintColor = AppTheme.accent
        notificationSwitch.tintColor = offTrackColor
        notificationSwitch.backgroundColor = offTrackColor
        notificationSwitch.thumbTintColor = .white
        notificationSwitch.layer.cornerRadius = notificationSwitch.bounds.height / 2
        notificationSwitch.layer.masksToBounds = true
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
        AppTheme.styleNativeFloatingControl(signOutButton, cornerRadius: 22)
        signOutButton.backgroundColor = .clear
        signOutButton.setTitleColor(.systemRed, for: .normal)
        signOutButton.tintColor = .systemRed
    }

    private func styleCloseButton() {
        let foreground = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "xmark")
        config.baseForegroundColor = foreground
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        closeButton?.configuration = config

        if let closeButton {
            AppTheme.styleNativeFloatingControl(closeButton, cornerRadius: 22)
            closeButton.backgroundColor = .clear
            closeButton.tintColor = foreground
            closeButton.setTitleColor(foreground, for: .normal)
        }
    }

    private func styleViewHierarchy(_ root: UIView) {
        for subview in root.subviews {
            if subview is UISwitch {
                continue
            }

            if shouldStyleAsSeparator(subview) {
                subview.backgroundColor = UIColor.separator.withAlphaComponent(
                    traitCollection.userInterfaceStyle == .dark ? 0.46 : 0.22
                )
                continue
            }

            switch subview {
            case let label as UILabel:
                label.textColor = .label
            case let button as UIButton:
                if button === closeButton {
                    button.tintColor = .label
                } else {
                    button.backgroundColor = .clear
                    if button !== myTeamTapArea {
                        button.tintColor = .secondaryLabel
                    }
                }
            case let imageView as UIImageView:
                if imageView !== avatarImageView {
                    imageView.tintColor = .secondaryLabel
                }
                imageView.backgroundColor = .clear
            case is UIStackView, is UIScrollView:
                subview.backgroundColor = .clear
            default:
                if subview !== infoCardView && subview !== featuresCardView && subview !== legalCardView && subview !== supportCardView {
                    subview.backgroundColor = .clear
                }
            }

            styleViewHierarchy(subview)
        }
    }

    private func styleCardContent(in root: UIView) {
        for subview in root.subviews {
            if subview is UISwitch {
                continue
            }

            if shouldStyleAsSeparator(subview) {
                subview.backgroundColor = UIColor.separator.withAlphaComponent(
                    traitCollection.userInterfaceStyle == .dark ? 0.46 : 0.18
                )
                continue
            }

            if let label = subview as? UILabel {
                label.backgroundColor = .clear
                if label.text == "Delete Your Account" {
                    label.textColor = .systemRed
                }
            } else if subview is UIStackView || subview is UIImageView || subview is UIScrollView {
                subview.backgroundColor = .clear
            } else if let button = subview as? UIButton, button !== closeButton {
                button.backgroundColor = .clear
            } else if subview !== infoCardView && subview !== featuresCardView && subview !== legalCardView && subview !== supportCardView {
                subview.backgroundColor = .clear
            }

            styleCardContent(in: subview)
        }
    }

    private func styleOuterHierarchy(in root: UIView) {
        for subview in root.subviews {
            if subview is UISwitch {
                continue
            }

            switch subview {
            case infoCardView, featuresCardView, legalCardView, supportCardView, closeButton, avatarImageView:
                break
            case is UILabel, is UIStackView, is UIScrollView, is UIImageView:
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

    private func presentTeamVC(startMode: TeamStartMode) {
        let vc = TeamViewController(nibName: "TeamViewController", bundle: nil)
        vc.startMode = startMode
        presentAsProfileSheet(vc)
    }
}
