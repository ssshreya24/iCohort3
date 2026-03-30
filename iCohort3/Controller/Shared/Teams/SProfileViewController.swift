//
//  SProfileViewController.swift
//  iCohort3
//
//  ✅ UPDATED: My Team button title updates to reflect team status.
//              Tapping when full navigates to TeamDetailViewController.
//

import UIKit

class SProfileViewController: UIViewController {

    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var infoCardView: UIView!
    @IBOutlet weak var notificationSwitch: UISwitch!
    @IBOutlet weak var myDetailsTapArea: UIButton?
    @IBOutlet weak var myTeamTapArea: UIButton?
    @IBOutlet weak var featuresCardView: UIView!

    // Cached so myTeamTapped knows whether to show sheet or go to detail
    private var cachedTeamInfo: SupabaseManager.StudentTeamInfo?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1)
        configureStaticUI()
        restoreSwitchState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadCachedAvatar()
        loadTeamStatus()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }

    // MARK: - Static UI

    private func configureStaticUI() {
        avatarImageView.image = UIImage(systemName: "person.circle.fill")
        avatarImageView.tintColor = .systemGray3
        avatarImageView.contentMode = .center
        avatarImageView.clipsToBounds = true

        [infoCardView, featuresCardView].forEach {
            $0?.backgroundColor = .white
            $0?.layer.cornerRadius = 16
            $0?.layer.masksToBounds = true
        }

        closeButton.layer.cornerRadius = closeButton.bounds.height / 2
        closeButton.clipsToBounds = true
    }

    private func loadCachedAvatar() {
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              let cachedAvatar = SupabaseManager.shared.cachedProfilePhotoBase64(personId: personId, role: "student"),
              let image = SupabaseManager.shared.base64ToImage(base64String: cachedAvatar) else {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemGray3
            avatarImageView.contentMode = .center
            return
        }

        avatarImageView.image = image
        avatarImageView.tintColor = nil
        avatarImageView.contentMode = .scaleAspectFill
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
            sheet.largestUndimmedDetentIdentifier = .init("almostFull")
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
                sheet.largestUndimmedDetentIdentifier = .init("almostFull")
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

    // MARK: - Helpers

    private func restoreSwitchState() {
        let on = UserDefaults.standard.bool(forKey: "profile_notifications_enabled")
        notificationSwitch.setOn(on, animated: false)
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
            sheet.largestUndimmedDetentIdentifier = .init("almostFull")
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
            sheet.largestUndimmedDetentIdentifier = .init("almostFull")
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
        }
        present(vc, animated: true)
    }
}
