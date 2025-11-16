//
//  SProfileViewController.swift
//  iCohort3
//
//  Created by user@0 on 12/11/25.
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
    

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1)
            configureStaticUI()
            restoreSwitchState()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
        }

        private func configureStaticUI() {
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemGray3
            avatarImageView.contentMode = .scaleAspectFill
            avatarImageView.clipsToBounds = true
            [infoCardView, featuresCardView].forEach {
                $0?.backgroundColor = .white
                $0?.layer.cornerRadius = 16
                $0?.layer.masksToBounds = true
            }
            closeButton.layer.cornerRadius = closeButton.bounds.height / 2
            closeButton.clipsToBounds = true
           
        }

        private func addShadow(to view: UIView, radius: CGFloat, opacity: Float, y: CGFloat) {
            view.layer.shadowColor = UIColor.black.cgColor
            view.layer.shadowRadius = radius
            view.layer.shadowOpacity = opacity
            view.layer.shadowOffset = CGSize(width: 0, height: y)
        }



    

        @IBAction func myDetailsTapped(_ sender: Any) {
            print("My Details tapped")
            let vc = StudentProfileViewController(nibName: "StudentProfileViewController", bundle: nil)
                vc.modalPresentationStyle = .pageSheet
                vc.modalTransitionStyle = .coverVertical

                if let sheet = vc.sheetPresentationController {
                    let topGap: CGFloat = 0

                    sheet.detents = [
                        .custom(identifier: .init("almostFull")) { context in
                            context.maximumDetentValue - topGap
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
            print("My Team tapped")
                let sheet = UIAlertController(
                    title: "My Team",
                    message: "Choose an option",
                    preferredStyle: .actionSheet
                )

                // Option 1 – Create Team
                sheet.addAction(UIAlertAction(title: "Create Team", style: .default) { [weak self] _ in
                    self?.presentTeamVC(startMode: .create)
                })

                // Option 2 – Join Team
                sheet.addAction(UIAlertAction(title: "Join Team", style: .default) { [weak self] _ in
                    self?.presentJoinTeamsVC()
                })

                // Cancel
                sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

                // For iPad / large screens (to avoid crash)
                if let popover = sheet.popoverPresentationController {
                    if let view = sender as? UIView {
                        popover.sourceView = view
                        popover.sourceRect = view.bounds
                    } else {
                        popover.sourceView = self.view
                        popover.sourceRect = CGRect(
                            x: self.view.bounds.midX,
                            y: self.view.bounds.midY,
                            width: 0,
                            height: 0
                        )
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
            let topGap: CGFloat = 0
            sheet.detents = [
                .custom(identifier: .init("almostFull")) { context in
                    context.maximumDetentValue - topGap
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
            let topGap: CGFloat = 0
            sheet.detents = [
                .custom(identifier: .init("almostFull")) { context in
                    context.maximumDetentValue - topGap
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
