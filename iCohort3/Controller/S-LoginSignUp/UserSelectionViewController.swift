//
//  UserSelectionViewController.swift
//  Login Screen
//
//  Created by user@51 on 03/11/25.
//

import UIKit

class UserSelectionViewController: UIViewController {

    @IBOutlet weak var studentCardView: UIView?
    @IBOutlet weak var facultyCardView: UIView?

    private enum UserRole {
        case admin, student, mentor

        var title: String {
            switch self {
            case .admin:   return "Admin"
            case .student: return "Student"
            case .mentor:  return "Mentor"
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

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        setupCards()
    }

    // MARK: - Cards

    private func setupCards() {
        // Bottom row: Student + Mentor (side by side)
        let bottomRow = UIStackView()
        bottomRow.translatesAutoresizingMaskIntoConstraints = false
        bottomRow.axis = .horizontal
        bottomRow.spacing = 20
        bottomRow.distribution = .fillEqually
        bottomRow.alignment = .fill

        bottomRow.addArrangedSubview(makeCard(for: .student))
        bottomRow.addArrangedSubview(makeCard(for: .mentor))

        // Top row: Admin centered (same card width as bottom cards)
        let adminCard = makeCard(for: .admin)
        adminCard.translatesAutoresizingMaskIntoConstraints = false

        // Outer stack: Admin on top, Student+Mentor on bottom
        let outerStack = UIStackView()
        outerStack.translatesAutoresizingMaskIntoConstraints = false
        outerStack.axis = .vertical
        outerStack.spacing = 20
        outerStack.alignment = .center

        outerStack.addArrangedSubview(adminCard)
        outerStack.addArrangedSubview(bottomRow)

        view.addSubview(outerStack)

        // Card size — matches the large square cards in the reference image
        let cardSize: CGFloat = 150

        NSLayoutConstraint.activate([
            // Admin card: same width as each bottom card
            adminCard.widthAnchor.constraint(equalToConstant: cardSize),
            adminCard.heightAnchor.constraint(equalToConstant: cardSize),

            // Bottom row: two cards + spacing
            bottomRow.widthAnchor.constraint(equalToConstant: cardSize * 2 + 24),
            bottomRow.heightAnchor.constraint(equalToConstant: cardSize),

            // Outer stack pinned to bottom of safe area
            outerStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            outerStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -36)
        ])
    }

    private func makeCard(for role: UserRole) -> UIButton {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor.white.withAlphaComponent(0.22)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true

        let icon = UIImageView()
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(systemName: role.symbolName)
        icon.tintColor = .white
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 44, weight: .medium)
        icon.isUserInteractionEnabled = false

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = role.title
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .white
        label.textAlignment = .center
        label.isUserInteractionEnabled = false

        button.addSubview(icon)
        button.addSubview(label)

        NSLayoutConstraint.activate([
            icon.centerXAnchor.constraint(equalTo: button.centerXAnchor),
            icon.centerYAnchor.constraint(equalTo: button.centerYAnchor, constant: -14),
            icon.widthAnchor.constraint(equalToConstant: 56),
            icon.heightAnchor.constraint(equalToConstant: 56),

            label.topAnchor.constraint(equalTo: icon.bottomAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 4),
            label.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -4)
        ])

        switch role {
        case .admin:   button.addTarget(self, action: #selector(adminRoleTapped),   for: .touchUpInside)
        case .student: button.addTarget(self, action: #selector(studentRoleTapped), for: .touchUpInside)
        case .mentor:  button.addTarget(self, action: #selector(mentorRoleTapped),  for: .touchUpInside)
        }

        button.addTarget(self, action: #selector(cardPressBegan(_:)), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(cardPressEnded(_:)), for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])

        return button
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

    // MARK: - IBActions (kept for storyboard compatibility)

    @IBAction func adminTapped(_ sender: Any)            { navigateToAdminLogin() }
    @IBAction func studentCardTapped(_ sender: UIButton) { navigateToStudentLogin() }
    @IBAction func facultyCardTapped(_ sender: UIButton) { navigateToFacultyLogin() }

    // MARK: - Objc targets

    @objc private func adminRoleTapped()   { navigateToAdminLogin() }
    @objc private func studentRoleTapped() { navigateToStudentLogin() }
    @objc private func mentorRoleTapped()  { navigateToFacultyLogin() }

    // MARK: - Press animations

    @objc private func cardPressBegan(_ sender: UIButton) {
        UIView.animate(withDuration: 0.14, delay: 0, options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = CGAffineTransform(scaleX: 0.94, y: 0.94)
            sender.alpha = 0.78
        }
    }

    @objc private func cardPressEnded(_ sender: UIButton) {
        UIView.animate(withDuration: 0.22, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5,
                       options: [.curveEaseOut, .allowUserInteraction]) {
            sender.transform = .identity
            sender.alpha = 1.0
        }
    }
}
