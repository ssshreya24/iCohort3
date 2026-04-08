//
//  UserSelectionViewController.swift
//  Login Screen
//
//  Created by user@51 on 03/11/25.
//

import UIKit

private final class RoleSelectionControl: UIControl {
    private let role: UserSelectionViewController.UserRole
    private let tileView = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialLight))
    private let tapButton = UIButton(type: .custom)

    init(role: UserSelectionViewController.UserRole) {
        self.role = role
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        configure()
    }

    required init?(coder: NSCoder) {
        return nil
    }

    private var isPressed = false

    private func applyPressedState(animated: Bool) {
        let updates = {
            self.tileView.transform = self.isPressed ? CGAffineTransform(scaleX: 0.97, y: 0.97) : .identity
            self.alpha = self.isPressed ? 0.96 : 1.0
            self.tileView.layer.borderColor = (self.isPressed
                ? UIColor.white.withAlphaComponent(0.92)
                : UIColor.white.withAlphaComponent(0.55)).cgColor
            self.tileView.layer.shadowOpacity = self.isPressed ? 0.28 : 0.18
            self.tileView.backgroundColor = self.isPressed
                ? UIColor.white.withAlphaComponent(0.42)
                : UIColor.white.withAlphaComponent(0.28)
        }

        guard animated else {
            updates()
            return
        }

        UIView.animate(withDuration: 0.16, delay: 0, options: [.curveEaseOut, .allowUserInteraction], animations: updates)
    }

    private func configure() {
        tileView.translatesAutoresizingMaskIntoConstraints = false
        tileView.backgroundColor = UIColor.white.withAlphaComponent(0.28)
        tileView.layer.cornerRadius = 24
        tileView.layer.cornerCurve = .continuous
        tileView.layer.masksToBounds = false
        tileView.layer.borderWidth = 0.75
        tileView.layer.borderColor = UIColor.white.withAlphaComponent(0.55).cgColor
        tileView.layer.shadowColor = UIColor(red: 0.10, green: 0.20, blue: 0.34, alpha: 0.5).cgColor
        tileView.layer.shadowOffset = CGSize(width: 0, height: 8)
        tileView.layer.shadowRadius = 18
        tileView.layer.shadowOpacity = 0.18

        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 24
        blurView.layer.cornerCurve = .continuous
        blurView.isUserInteractionEnabled = false

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(systemName: role.symbolName)
        iconView.tintColor = UIColor(red: 0.18, green: 0.32, blue: 0.50, alpha: 1)
        iconView.contentMode = .scaleAspectFit
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 42, weight: .bold)
        iconView.isUserInteractionEnabled = false

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = role.title
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor(red: 0.18, green: 0.30, blue: 0.42, alpha: 1)
        titleLabel.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.85
        titleLabel.isUserInteractionEnabled = false

        tapButton.translatesAutoresizingMaskIntoConstraints = false
        tapButton.backgroundColor = .clear
        tapButton.addTarget(self, action: #selector(pressBegan), for: [.touchDown, .touchDragEnter])
        tapButton.addTarget(self, action: #selector(pressEnded), for: [.touchUpOutside, .touchCancel, .touchDragExit])
        tapButton.addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        addSubview(tileView)
        tileView.addSubview(blurView)
        tileView.addSubview(iconView)
        tileView.addSubview(titleLabel)
        addSubview(tapButton)

        NSLayoutConstraint.activate([
            tileView.topAnchor.constraint(equalTo: topAnchor),
            tileView.leadingAnchor.constraint(equalTo: leadingAnchor),
            tileView.trailingAnchor.constraint(equalTo: trailingAnchor),
            tileView.bottomAnchor.constraint(equalTo: bottomAnchor),

            tapButton.topAnchor.constraint(equalTo: topAnchor),
            tapButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            tapButton.trailingAnchor.constraint(equalTo: trailingAnchor),
            tapButton.bottomAnchor.constraint(equalTo: bottomAnchor),

            blurView.topAnchor.constraint(equalTo: tileView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: tileView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: tileView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: tileView.bottomAnchor),

            iconView.centerXAnchor.constraint(equalTo: tileView.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: tileView.centerYAnchor, constant: -18),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),

            titleLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 14),
            titleLabel.leadingAnchor.constraint(equalTo: tileView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: tileView.trailingAnchor, constant: -10),
            titleLabel.bottomAnchor.constraint(equalTo: tileView.bottomAnchor, constant: -18)
        ])
    }

    @objc private func pressBegan() {
        isPressed = true
        applyPressedState(animated: true)
    }

    @objc private func pressEnded() {
        isPressed = false
        applyPressedState(animated: true)
    }

    @objc private func handleTap() {
        isPressed = false
        applyPressedState(animated: true)
        sendActions(for: .primaryActionTriggered)
    }
}

class UserSelectionViewController: UIViewController {

    @IBOutlet weak var studentCardView: UIView?
    @IBOutlet weak var facultyCardView: UIView?

    enum UserRole {
        case admin, student, mentor

        var title: String {
            switch self {
            case .admin:    return "Admin"
            case .student:  return "Student"
            case .mentor:   return "Mentor"
            }
        }

        var symbolName: String {
            switch self {
            case .admin:   return "person.crop.rectangle.stack.fill"
            case .student: return "graduationcap.fill"
            case .mentor:  return "person.2.fill"
            }
        }
    }

    private let contentView    = UIView()
    private let footerLabel    = UILabel()
    private let cardsContainer = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        buildInterface()
    }

    private func buildInterface() {
        view.subviews.forEach { $0.removeFromSuperview() }
        configureBackground()
        configureContent()
    }

    // MARK: - Background

    private func configureBackground() {
        view.backgroundColor = UIColor(named: "Background Color")
            ?? UIColor(red: 0.91, green: 0.93, blue: 0.96, alpha: 1)

        let backgroundImageView = UIImageView(image: UIImage(named: "Backgrround"))
        backgroundImageView.translatesAutoresizingMaskIntoConstraints = false
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.isUserInteractionEnabled = false
        view.addSubview(backgroundImageView)
        view.sendSubviewToBack(backgroundImageView)

        NSLayoutConstraint.activate([
            backgroundImageView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Content

    private func configureContent() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(contentView)

        // Role cards
        let studentControl = makeRoleControl(for: .student, action: #selector(studentRoleTapped))
        let mentorControl  = makeRoleControl(for: .mentor,  action: #selector(mentorRoleTapped))
        let adminControl   = makeRoleControl(for: .admin,   action: #selector(adminRoleTapped))

        cardsContainer.translatesAutoresizingMaskIntoConstraints = false
        cardsContainer.addSubview(studentControl)
        cardsContainer.addSubview(mentorControl)
        cardsContainer.addSubview(adminControl)

        // Footer
        footerLabel.translatesAutoresizingMaskIntoConstraints = false
        footerLabel.text = "Tap a card to continue"
        footerLabel.textAlignment = .center
        footerLabel.textColor = UIColor.white.withAlphaComponent(0.85)
        footerLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)

        contentView.addSubview(cardsContainer)
        contentView.addSubview(footerLabel)

        NSLayoutConstraint.activate([
            contentView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            contentView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            contentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0),

            // Fix the cards entirely to the lower half by anchoring from the bottom footer
            cardsContainer.bottomAnchor.constraint(equalTo: footerLabel.topAnchor, constant: -12),
            cardsContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            cardsContainer.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            cardsContainer.heightAnchor.constraint(equalToConstant: 332),

            // Student – left
            studentControl.leadingAnchor.constraint(equalTo: cardsContainer.leadingAnchor, constant: 8),
            studentControl.topAnchor.constraint(equalTo: cardsContainer.topAnchor),
            studentControl.widthAnchor.constraint(equalToConstant: 132),
            studentControl.heightAnchor.constraint(equalToConstant: 148),

            // Mentor – right
            mentorControl.trailingAnchor.constraint(equalTo: cardsContainer.trailingAnchor, constant: -8),
            mentorControl.topAnchor.constraint(equalTo: cardsContainer.topAnchor),
            mentorControl.widthAnchor.constraint(equalToConstant: 132),
            mentorControl.heightAnchor.constraint(equalToConstant: 148),

            // Admin – centre, below the first row
            adminControl.centerXAnchor.constraint(equalTo: cardsContainer.centerXAnchor),
            adminControl.topAnchor.constraint(equalTo: studentControl.bottomAnchor, constant: 36),
            adminControl.widthAnchor.constraint(equalToConstant: 132),
            adminControl.heightAnchor.constraint(equalToConstant: 148),

            footerLabel.topAnchor.constraint(equalTo: cardsContainer.bottomAnchor, constant: 18),
            footerLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            footerLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            footerLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }

    // MARK: - Helpers

    private func makeRoleControl(for role: UserRole, action: Selector) -> UIControl {
        let control = RoleSelectionControl(role: role)
        control.addTarget(self, action: action, for: .primaryActionTriggered)
        return control
    }

    // MARK: - Navigation

    private func navigateToStudentLogin() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = sb.instantiateViewController(withIdentifier: "SLoginVC") as? LoginViewController else {
            print("ERROR: Couldn't instantiate LoginViewController with Storyboard ID 'SLoginVC'.")
            return
        }
        push(loginVC)
    }

    private func navigateToFacultyLogin() {
        let sb = UIStoryboard(name: "Main", bundle: nil)
        guard let loginVC = sb.instantiateViewController(withIdentifier: "MLoginVC") as? MLoginSignUpViewController else {
            print("ERROR: Couldn't instantiate MLoginViewController with Storyboard ID 'MLoginVC'.")
            return
        }
        push(loginVC)
    }

    private func navigateToAdminLogin() {
        let adminLoginVC = AdminLoginViewController(nibName: "AdminLoginViewController", bundle: nil)
        push(adminLoginVC)
    }

    private func push(_ vc: UIViewController) {
        if let nav = navigationController {
            nav.pushViewController(vc, animated: true)
        } else {
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true)
        }
    }

    // MARK: - IBActions (storyboard compatibility)

    @IBAction func adminTapped(_ sender: Any)              { navigateToAdminLogin() }
    @IBAction func studentCardTapped(_ sender: UIButton)   { navigateToStudentLogin() }
    @IBAction func facultyCardTapped(_ sender: UIButton)   { navigateToFacultyLogin() }

    // MARK: - Programmatic actions

    @objc private func adminRoleTapped()   { navigateToAdminLogin() }
    @objc private func studentRoleTapped() { navigateToStudentLogin() }
    @objc private func mentorRoleTapped()  { navigateToFacultyLogin() }
}
