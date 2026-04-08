//
//  SProfileViewController.swift
//  iCohort3
//
//  ✅ UPDATED: My Team button title updates to reflect team status.
//              Tapping when full navigates to TeamDetailViewController.
//

import UIKit
import UserNotifications

class SProfileViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton?
    @IBOutlet weak var avatarImageView: UIImageView?
    @IBOutlet weak var infoCardView: UIView?
    @IBOutlet weak var notificationSwitch: UISwitch?
    @IBOutlet weak var myDetailsTapArea: UIButton?
    @IBOutlet weak var myTeamTapArea: UIButton?
    @IBOutlet weak var featuresCardView: UIView?

    // Cached so myTeamTapped knows whether to show sheet or go to detail
    private var cachedTeamInfo: SupabaseManager.StudentTeamInfo?
    private var teamStatusTask: Task<Void, Never>?
    private var teamStatusRevision: Int = 0
    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // MARK: - Lifecycle

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

    // MARK: - Static UI

    private func configureStaticUI() {
        configureDefaultAvatar()
        avatarImageView?.clipsToBounds = true
        installSignOutButton()
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

    // MARK: - Team Status

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

    /// Updates myTeamTapArea title and tint to reflect current team state.
    /// No separate badge view — the button itself carries the status.
    private func applyTeamButtonStyle(teamInfo: SupabaseManager.StudentTeamInfo?) {
        guard let btn = myTeamTapArea else { return }

        guard let info = teamInfo else {
            // No team yet — right side says "Not Set"
            btn.setTitle("Not Set", for: .normal)
            btn.setTitleColor(.secondaryLabel, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .regular)
            return
        }

        // Has team — show team info on button
        if info.isFull {
            // ✅ Green text: "Team 3  ·  Full ✓"
            let title = "Team \(info.teamNumber) "
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.systemGreen, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        } else {
            // Blue text: "Team 3  ·  2/3"
            let title = "Team \(info.teamNumber)  ·  \(info.memberCount)/3"
            btn.setTitle(title, for: .normal)
            btn.setTitleColor(.systemBlue, for: .normal)
            btn.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        }
    }

    // MARK: - Actions

    @IBAction func myDetailsTapped(_ sender: Any) {
        let vc = StudentProfileViewController(nibName: "StudentProfileViewController", bundle: nil)
        vc.modalPresentationStyle = .pageSheet
        vc.modalTransitionStyle = .coverVertical

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [
                .custom(identifier: .init("almostFull")) { context in
                    context.maximumDetentValue
                }
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(vc, animated: true)
    }

    @IBAction func myTeamTapped(_ sender: Any) {
        // ✅ If team is full — navigate straight to TeamDetailViewController
        if let info = cachedTeamInfo, info.isFull {
            let detailVC = TeamDetailViewController(teamInfo: info)
            detailVC.modalPresentationStyle = .pageSheet
            detailVC.modalTransitionStyle = .coverVertical

            if let sheet = detailVC.sheetPresentationController {
                sheet.detents = [
                    .custom(identifier: .init("almostFull")) { context in
                        context.maximumDetentValue
                    }
                ]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
            present(detailVC, animated: true)
            return
        }

        // Not full — go directly to TeamViewController (handles both create and join)
        presentTeamVC(startMode: .create)
    }

    @IBAction func notificationChanged(_ sender: UISwitch) {
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

    // MARK: - Helpers

    private func restoreSwitchState() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self = self else { return }
                let isAuthorized = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
                
                if !isAuthorized {
                    self.notificationSwitch?.setOn(false, animated: false)
                    UserDefaults.standard.set(false, forKey: "profile_notifications_enabled")
                } else {
                    if UserDefaults.standard.object(forKey: "profile_notifications_enabled") == nil {
                        UserDefaults.standard.set(true, forKey: "profile_notifications_enabled")
                    }
                    let on = UserDefaults.standard.bool(forKey: "profile_notifications_enabled")
                    self.notificationSwitch?.setOn(on, animated: false)
                }
            }
        }
    }

    private func applyThemeToHierarchy() {
        styleViewHierarchy(view)
        [infoCardView, featuresCardView].forEach { card in
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

    private func installSignOutButton() {
        guard signOutButton.superview == nil,
              let featuresCardView,
              let container = featuresCardView.superview else { return }
        container.addSubview(signOutButton)
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            signOutButton.topAnchor.constraint(equalTo: featuresCardView.bottomAnchor, constant: 20),
            signOutButton.leadingAnchor.constraint(equalTo: featuresCardView.leadingAnchor),
            signOutButton.trailingAnchor.constraint(equalTo: featuresCardView.trailingAnchor),
            signOutButton.heightAnchor.constraint(equalToConstant: 44)
        ])
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
                    button.tintColor = .secondaryLabel
                    button.setTitleColor(.label, for: .normal)
                    if let config = button.configuration {
                        var updated = config
                        if button === myTeamTapArea {
                            // Team status tint is applied separately.
                        } else {
                            updated.baseForegroundColor = .secondaryLabel
                        }
                        button.configuration = updated
                    }
                }
                button.backgroundColor = .clear
            case let imageView as UIImageView:
                if imageView !== avatarImageView {
                    imageView.tintColor = .secondaryLabel
                }
                imageView.backgroundColor = .clear
            case let stack as UIStackView:
                stack.backgroundColor = .clear
            case let scroll as UIScrollView:
                scroll.backgroundColor = .clear
            default:
                if subview !== infoCardView && subview !== featuresCardView {
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

            if subview is UILabel || subview is UIStackView || subview is UIImageView || subview is UIScrollView {
                subview.backgroundColor = .clear
            } else if subview is UISwitch {
                // Keep system switch rendering.
            } else if let button = subview as? UIButton, button !== closeButton {
                button.backgroundColor = .clear
            } else if subview !== infoCardView && subview !== featuresCardView {
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
            case infoCardView, featuresCardView, closeButton, avatarImageView:
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
        vc.modalPresentationStyle = .pageSheet
        vc.modalTransitionStyle = .coverVertical

        if let sheet = vc.sheetPresentationController {
            sheet.detents = [
                .custom(identifier: .init("almostFull")) { context in
                    context.maximumDetentValue
                }
            ]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(vc, animated: true)
    }

}
