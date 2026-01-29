//
//  AdminApprovalViewController.swift
//  iCohort3
//
//  Admin page to approve or decline student registrations
//

import UIKit
import FirebaseAuth

class AdminApprovalViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let greetingLabel = UILabel()
    private let nameLabel = UILabel()
    private let logoutButton = UIButton(type: .system)
    private let requestsHeaderLabel = UILabel()
    private let pendingBadge = UILabel()
    private let cardsStackView = UIStackView()
    private let refreshControl = UIRefreshControl()
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Data
    private var pendingStudents: [StudentRegistration] = []
    private var instituteDomain: String = "srmist.edu.in" // Default for SRM
    private var adminEmail: String = ""
    private var instituteName: String = "SRM University"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        getAdminInfo()
        loadPendingStudents()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 245/255, alpha: 1.0)
        
        // Hide navigation bar title since we have custom header
        navigationItem.title = ""
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        // Setup content view
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Setup greeting label
        greetingLabel.text = getGreeting()
        greetingLabel.font = .systemFont(ofSize: 16, weight: .regular)
        greetingLabel.textColor = .systemGray
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(greetingLabel)
        
        // Setup name label
        nameLabel.text = "Hello, Admin"
        nameLabel.font = .systemFont(ofSize: 34, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Setup logout button
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.setTitleColor(.systemBlue, for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        logoutButton.backgroundColor = .white
        logoutButton.layer.cornerRadius = 20
        logoutButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        
        // Setup requests header
        requestsHeaderLabel.text = "Requests"
        requestsHeaderLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        requestsHeaderLabel.textColor = .systemGray
        requestsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(requestsHeaderLabel)
        
        // Setup pending badge
        pendingBadge.text = "0 Pending"
        pendingBadge.font = .systemFont(ofSize: 14, weight: .semibold)
        pendingBadge.textColor = .systemBlue
        pendingBadge.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        pendingBadge.layer.cornerRadius = 12
        pendingBadge.clipsToBounds = true
        pendingBadge.textAlignment = .center
        pendingBadge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pendingBadge)
        
        // Setup cards stack view
        cardsStackView.axis = .vertical
        cardsStackView.spacing = 16
        cardsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardsStackView)
        
        // Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        
        // Layout constraints
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
            
            greetingLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            greetingLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            greetingLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            nameLabel.topAnchor.constraint(equalTo: greetingLabel.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -100),
            
            // Logout button positioned relative to view and nameLabel's top
            logoutButton.topAnchor.constraint(equalTo: nameLabel.topAnchor, constant: -4),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 40),
            
            requestsHeaderLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            requestsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            pendingBadge.centerYAnchor.constraint(equalTo: requestsHeaderLabel.centerYAnchor),
            pendingBadge.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            pendingBadge.heightAnchor.constraint(equalToConstant: 28),
            pendingBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 90),
            
            cardsStackView.topAnchor.constraint(equalTo: requestsHeaderLabel.bottomAnchor, constant: 20),
            cardsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            cardsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            cardsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func getGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:
            return "Good morning,"
        case 12..<17:
            return "Good afternoon,"
        case 17..<24:
            return "Good evening,"
        default:
            return "Hello,"
        }
    }
    
    private func getAdminInfo() {
        guard let user = Auth.auth().currentUser else {
            showAlert(title: "Error", message: "No admin logged in") {
                self.navigateToLogin()
            }
            return
        }
        
        adminEmail = user.email ?? ""
        
        // Get institute domain from Firebase
        Task {
            do {
                if let institute = try await FirebaseManager.shared.getInstitute(byAdminEmail: adminEmail) {
                    await MainActor.run {
                        self.instituteDomain = institute.domain
                        self.instituteName = institute.name
                        loadPendingStudents()
                    }
                }
            } catch {
                print("Error fetching institute:", error.localizedDescription)
            }
        }
    }
    
    // MARK: - Data Loading
    private func loadPendingStudents() {
        showLoadingIndicator()
        
        Task {
            do {
                let students = try await FirebaseManager.shared.getPendingStudents(forDomain: instituteDomain)
                
                await MainActor.run {
                    self.pendingStudents = students
                    self.updateUI()
                    self.hideLoadingIndicator()
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to load students: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateUI() {
        // Update pending badge
        let count = pendingStudents.count
        pendingBadge.text = "\(count) Pending"
        
        // Clear existing cards
        cardsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if pendingStudents.isEmpty {
            showEmptyState()
        } else {
            hideEmptyState()
            
            // Add cards for each student
            for (index, student) in pendingStudents.enumerated() {
                let card = createStudentCard(for: student, at: index)
                cardsStackView.addArrangedSubview(card)
            }
        }
    }
    
    private func createStudentCard(for student: StudentRegistration, at index: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 16
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 2)
        card.layer.shadowRadius = 8
        card.layer.shadowOpacity = 0.08
        card.translatesAutoresizingMaskIntoConstraints = false
        
        // Avatar circle
        let avatarView = UIView()
        avatarView.backgroundColor = getAvatarColor(for: student.fullName)
        avatarView.layer.cornerRadius = 30
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarLabel = UILabel()
        avatarLabel.text = String(student.fullName.prefix(1)).uppercased()
        avatarLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        avatarLabel.textColor = getAvatarTextColor(for: student.fullName)
        avatarLabel.textAlignment = .center
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarLabel)
        
        // Student name
        let nameLabel = UILabel()
        nameLabel.text = student.fullName
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Reg number and institute
        let regInstLabel = UILabel()
        regInstLabel.text = "\(student.regNumber) • \(instituteName)"
        regInstLabel.font = .systemFont(ofSize: 14, weight: .regular)
        regInstLabel.textColor = .systemGray
        regInstLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Email with icon
        let emailStack = UIStackView()
        emailStack.axis = .horizontal
        emailStack.spacing = 8
        emailStack.alignment = .center
        emailStack.translatesAutoresizingMaskIntoConstraints = false
        
        let emailIcon = UIImageView(image: UIImage(systemName: "envelope.fill"))
        emailIcon.tintColor = .systemGray2
        emailIcon.translatesAutoresizingMaskIntoConstraints = false
        emailIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        emailIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        let emailLabel = UILabel()
        emailLabel.text = student.email
        emailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emailLabel.textColor = .label
        
        emailStack.addArrangedSubview(emailIcon)
        emailStack.addArrangedSubview(emailLabel)
        
        // Date with icon
        let dateStack = UIStackView()
        dateStack.axis = .horizontal
        dateStack.spacing = 8
        dateStack.alignment = .center
        dateStack.translatesAutoresizingMaskIntoConstraints = false
        
        let clockIcon = UIImageView(image: UIImage(systemName: "clock"))
        clockIcon.tintColor = .systemGray2
        clockIcon.translatesAutoresizingMaskIntoConstraints = false
        clockIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        clockIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        let dateLabel = UILabel()
        if let date = student.createdAt {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM • h:mm a"
            dateLabel.text = "Applied \(formatter.string(from: date))"
        } else {
            dateLabel.text = "Applied recently"
        }
        dateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .systemGray
        
        dateStack.addArrangedSubview(clockIcon)
        dateStack.addArrangedSubview(dateLabel)
        
        // Buttons
        let approveButton = UIButton(type: .system)
        approveButton.setTitle("Approve", for: .normal)
        approveButton.setTitleColor(.systemGreen, for: .normal)
        approveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        approveButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        approveButton.layer.cornerRadius = 12
        approveButton.translatesAutoresizingMaskIntoConstraints = false
        approveButton.tag = index
        approveButton.addTarget(self, action: #selector(approveButtonTapped(_:)), for: .touchUpInside)
        
        let declineButton = UIButton(type: .system)
        declineButton.setTitle("Decline", for: .normal)
        declineButton.setTitleColor(.systemRed, for: .normal)
        declineButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        declineButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
        declineButton.layer.cornerRadius = 12
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        declineButton.tag = index
        declineButton.addTarget(self, action: #selector(declineButtonTapped(_:)), for: .touchUpInside)
        
        let buttonStack = UIStackView(arrangedSubviews: [approveButton, declineButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        // Add all subviews to card
        card.addSubview(avatarView)
        card.addSubview(avatarLabel)
        card.addSubview(nameLabel)
        card.addSubview(regInstLabel)
        card.addSubview(emailStack)
        card.addSubview(dateStack)
        card.addSubview(buttonStack)
        
        // Constraints
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            avatarView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),
            
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            
            regInstLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            regInstLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            regInstLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            
            emailStack.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 16),
            emailStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            emailStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -20),
            
            dateStack.topAnchor.constraint(equalTo: emailStack.bottomAnchor, constant: 8),
            dateStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            dateStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -20),
            
            buttonStack.topAnchor.constraint(equalTo: dateStack.bottomAnchor, constant: 20),
            buttonStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            buttonStack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            buttonStack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -20),
            buttonStack.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return card
    }
    
    private func getAvatarColor(for name: String) -> UIColor {
        let colors: [UIColor] = [
            UIColor.systemBlue.withAlphaComponent(0.15),
            UIColor.systemPurple.withAlphaComponent(0.15),
            UIColor.systemOrange.withAlphaComponent(0.15),
            UIColor.systemGreen.withAlphaComponent(0.15),
            UIColor.systemPink.withAlphaComponent(0.15),
            UIColor.systemTeal.withAlphaComponent(0.15)
        ]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
    
    private func getAvatarTextColor(for name: String) -> UIColor {
        let colors: [UIColor] = [
            .systemBlue,
            .systemPurple,
            .systemOrange,
            .systemGreen,
            .systemPink,
            .systemTeal
        ]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
    
    @objc private func refreshData() {
        Task {
            do {
                let students = try await FirebaseManager.shared.getPendingStudents(forDomain: instituteDomain)
                
                await MainActor.run {
                    self.pendingStudents = students
                    self.updateUI()
                    self.refreshControl.endRefreshing()
                }
            } catch {
                await MainActor.run {
                    self.refreshControl.endRefreshing()
                    self.showAlert(title: "Error", message: "Failed to refresh: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Actions
    @objc private func approveButtonTapped(_ sender: UIButton) {
        approveStudent(at: sender.tag)
    }
    
    @objc private func declineButtonTapped(_ sender: UIButton) {
        declineStudent(at: sender.tag)
    }
    
    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            do {
                try Auth.auth().signOut()
                self.navigateToLogin()
            } catch {
                self.showAlert(title: "Error", message: "Failed to logout: \(error.localizedDescription)")
            }
        })
        
        present(alert, animated: true)
    }
    
    private func approveStudent(at index: Int) {
        let student = pendingStudents[index]
        
        let alert = UIAlertController(
            title: "Approve Student",
            message: "Approve registration for \(student.fullName)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Approve", style: .default) { _ in
            self.performApproval(student: student, at: index)
        })
        
        present(alert, animated: true)
    }
    
    private func performApproval(student: StudentRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                try await FirebaseManager.shared.approveStudent(studentId: student.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingStudents.remove(at: index)
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Success", message: "\(student.fullName) has been approved and can now login.")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to approve student: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func declineStudent(at index: Int) {
        let student = pendingStudents[index]
        
        let alert = UIAlertController(
            title: "Decline Student",
            message: "Decline registration for \(student.fullName)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { _ in
            self.performDecline(student: student, at: index)
        })
        
        present(alert, animated: true)
    }
    
    private func performDecline(student: StudentRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                try await FirebaseManager.shared.declineStudent(studentId: student.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingStudents.remove(at: index)
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Declined", message: "\(student.fullName)'s registration has been declined.")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to decline student: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Navigation
    private func navigateToLogin() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let userSelection = storyboard.instantiateViewController(withIdentifier: "UserSelectionVC") as? UserSelectionViewController {
            let navRoot = UINavigationController(rootViewController: userSelection)
            navRoot.modalPresentationStyle = .fullScreen
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                window.rootViewController = navRoot
                window.makeKeyAndVisible()
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateLabel: UILabel?
    
    private func showEmptyState() {
        if emptyStateLabel == nil {
            let label = UILabel()
            label.text = "No pending approvals"
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            label.font = .systemFont(ofSize: 18, weight: .medium)
            label.translatesAutoresizingMaskIntoConstraints = false
            
            view.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            ])
            
            emptyStateLabel = label
        }
        
        emptyStateLabel?.isHidden = false
    }
    
    private func hideEmptyState() {
        emptyStateLabel?.isHidden = true
    }
    
    // MARK: - Loading Indicator
    private func showLoadingIndicator() {
        if loadingIndicator == nil {
            let indicator = UIActivityIndicatorView(style: .large)
            indicator.center = view.center
            indicator.hidesWhenStopped = true
            view.addSubview(indicator)
            loadingIndicator = indicator
        }
        loadingIndicator?.startAnimating()
        view.isUserInteractionEnabled = false
    }
    
    private func hideLoadingIndicator() {
        loadingIndicator?.stopAnimating()
        view.isUserInteractionEnabled = true
    }
    
    // MARK: - Alert Helper
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}
