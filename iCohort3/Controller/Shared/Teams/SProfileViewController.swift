//
//  SProfileViewController.swift
//  iCohort3
//
//  ✅ UPDATED: My Team button title updates to reflect team status.
//              Tapping when full navigates to TeamDetailViewController.
//

import UIKit

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
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCachedAvatar()
        loadTeamStatus()
        refreshTheme()
    }

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

    private func configureDefaultAvatar() {
        guard let avatarImageView else { return }

        if let logo = UIImage(named: "logo") {
            avatarImageView.image = logo
            avatarImageView.tintColor = nil
            avatarImageView.contentMode = .scaleAspectFill
        } else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemGray3
            avatarImageView.contentMode = .center
        }
        avatarImageView.clipsToBounds = true
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
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              !personId.isEmpty else {
            applyTeamButtonStyle(teamInfo: nil)
            return
        }

        Task {
            let teamInfo = try? await SupabaseManager.shared.fetchTeamInfoForStudent(personId: personId)
            cachedTeamInfo = teamInfo
            await MainActor.run {
                self.applyTeamButtonStyle(teamInfo: teamInfo)
            }
        }
    }

    /// Updates myTeamTapArea title and tint to reflect current team state.
    /// No separate badge view — the button itself carries the status.
    private func applyTeamButtonStyle(teamInfo: SupabaseManager.StudentTeamInfo?) {
        guard let btn = myTeamTapArea else { return }

        // Reset to plain style first
        btn.setTitleColor(.label, for: .normal)
        btn.backgroundColor = .clear

        guard let info = teamInfo else {
            // No team yet — leave the button as-is (storyboard title like "My Team")
            return
        }

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

        // Not full — show Create / Join sheet as before
        let sheet = UIAlertController(
            title: "My Team",
            message: "Choose an option",
            preferredStyle: .actionSheet
        )
        sheet.addAction(UIAlertAction(title: "Create Team", style: .default) { [weak self] _ in
            self?.presentTeamVC(startMode: .create)
        })
        sheet.addAction(UIAlertAction(title: "Join Team", style: .default) { [weak self] _ in
            self?.presentJoinTeamsVC()
        })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = sheet.popoverPresentationController {
            if let view = sender as? UIView {
                popover.sourceView = view
                popover.sourceRect = view.bounds
            } else {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY,
                                            width: 0, height: 0)
            }
            popover.permittedArrowDirections = .up
        }
        present(sheet, animated: true)
    }

    @IBAction func notificationChanged(_ sender: UISwitch) {
        UserDefaults.standard.set(sender.isOn, forKey: "profile_notifications_enabled")
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

    // MARK: - Helpers

    private func restoreSwitchState() {
        let on = UserDefaults.standard.bool(forKey: "profile_notifications_enabled")
        notificationSwitch?.setOn(on, animated: false)
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

    private func presentJoinTeamsVC() {
        let vc = JoinTeamsViewController(nibName: "JoinTeamsViewController", bundle: nil)
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
