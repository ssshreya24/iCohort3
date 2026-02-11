//
//  AdminApprovalViewController.swift
//  iCohort3
//
//  ✅ FIXED: Uses Supabase instead of Firebase
//

import UIKit

class AdminApprovalViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let greetingLabel = UILabel()
    private let nameLabel = UILabel()
    private let logoutButton = UIButton(type: .system)
    private let segmentedControl = UISegmentedControl(items: ["Students", "Mentors"])
    private let requestsHeaderLabel = UILabel()
    private let pendingBadge = UILabel()
    private let cardsStackView = UIStackView()
    private let refreshControl = UIRefreshControl()
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Data
    private var pendingStudents: [SupabaseManager.StudentRegistration] = []
    private var pendingMentors: [SupabaseManager.MentorRegistration] = []
    private var instituteDomain: String = "srmist.edu.in"
    private var instituteName: String = "SRM University"
    private var adminEmail: String = ""
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        getAdminInfo()
        loadPendingData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 245/255, alpha: 1.0)
        
        navigationItem.title = ""
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        greetingLabel.text = "Welcome back,"
        greetingLabel.font = .systemFont(ofSize: 27, weight: .bold)
        greetingLabel.textColor = .black
        greetingLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(greetingLabel)
        
        nameLabel.text = "Admin"
        nameLabel.font = .systemFont(ofSize: 24, weight: .regular)
        nameLabel.textColor = .systemGray
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        logoutButton.setTitle("Logout", for: .normal)
        logoutButton.setTitleColor(.systemBlue, for: .normal)
        logoutButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        logoutButton.backgroundColor = .white
        logoutButton.layer.cornerRadius = 20
        logoutButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(logoutButton)
        
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        contentView.addSubview(segmentedControl)
        
        requestsHeaderLabel.text = "Requests"
        requestsHeaderLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        requestsHeaderLabel.textColor = .systemGray
        requestsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(requestsHeaderLabel)
        
        pendingBadge.text = "0 Pending"
        pendingBadge.font = .systemFont(ofSize: 14, weight: .semibold)
        pendingBadge.textColor = .systemBlue
        pendingBadge.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.15)
        pendingBadge.layer.cornerRadius = 12
        pendingBadge.clipsToBounds = true
        pendingBadge.textAlignment = .center
        pendingBadge.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pendingBadge)
        
        cardsStackView.axis = .vertical
        cardsStackView.spacing = 16
        cardsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(cardsStackView)
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        scrollView.refreshControl = refreshControl
        
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
            
            logoutButton.topAnchor.constraint(equalTo: greetingLabel.topAnchor, constant: -4),
            logoutButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logoutButton.heightAnchor.constraint(equalToConstant: 40),
            
            segmentedControl.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 24),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            requestsHeaderLabel.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 20),
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
    
    private func getAdminInfo() {
        // ✅ Use consistent key with AdminDashboardViewController
        adminEmail = UserDefaults.standard.string(forKey: "admin_email") ?? ""
        
        // Add debug logging
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔍 ADMIN APPROVAL - GET ADMIN INFO")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📧 Admin email from UserDefaults:", adminEmail)
        
        guard !adminEmail.isEmpty else {
            print("❌ ERROR: Admin email is EMPTY!")
            print("   UserDefaults keys:", UserDefaults.standard.dictionaryRepresentation().keys)
            return
        }
        
        Task {
            do {
                if let institute = try await SupabaseManager.shared.getInstitute(byAdminEmail: adminEmail) {
                    await MainActor.run {
                        self.instituteDomain = institute.domain
                        self.instituteName = institute.name
                        print("✅ Institute loaded:", institute.name)
                        loadPendingData()
                    }
                } else {
                    print("❌ No institute found for admin:", adminEmail)
                }
            } catch {
                print("❌ Error fetching institute:", error.localizedDescription)
            }
        }
    }
    
    @objc private func segmentChanged() {
        updateUI()
    }
    
    // In AdminApprovalViewController.swift

    private func loadPendingData() {
        showLoadingIndicator()
        
        Task {
            do {
                // ✅ Use institute-aware functions
                let students = try await SupabaseManager.shared.getPendingStudentsForAdmin(adminEmail: adminEmail)
                let mentors = try await SupabaseManager.shared.getPendingMentorsForAdmin(adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingStudents = students
                    self.pendingMentors = mentors
                    self.updateUI()
                    self.hideLoadingIndicator()
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to load data: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func updateUI() {
        let count = segmentedControl.selectedSegmentIndex == 0 ? pendingStudents.count : pendingMentors.count
        pendingBadge.text = "\(count) Pending"
        
        cardsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if count == 0 {
            showEmptyState()
        } else {
            hideEmptyState()
            
            if segmentedControl.selectedSegmentIndex == 0 {
                for (index, student) in pendingStudents.enumerated() {
                    let card = createStudentCard(for: student, at: index)
                    cardsStackView.addArrangedSubview(card)
                }
            } else {
                for (index, mentor) in pendingMentors.enumerated() {
                    let card = createMentorCard(for: mentor, at: index)
                    cardsStackView.addArrangedSubview(card)
                }
            }
        }
    }
    
    // MARK: - Student Card (adapted for Supabase model)
    private func createStudentCard(for student: SupabaseManager.StudentRegistration, at index: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 12
        card.layer.shadowOpacity = 0.06
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarView = UIView()
        avatarView.backgroundColor = getAvatarColor(for: student.full_name)
        avatarView.layer.cornerRadius = 30
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarLabel = UILabel()
        avatarLabel.text = String(student.full_name.prefix(1)).uppercased()
        avatarLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        avatarLabel.textColor = getAvatarTextColor(for: student.full_name)
        avatarLabel.textAlignment = .center
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarLabel)
        
        let nameLabel = UILabel()
        nameLabel.text = student.full_name
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let regInstLabel = UILabel()
        regInstLabel.text = "\(student.reg_number) • \(instituteName)"
        regInstLabel.font = .systemFont(ofSize: 14, weight: .regular)
        regInstLabel.textColor = .systemGray
        regInstLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let emailStack = createInfoStack(icon: "envelope.fill", text: student.email)
        
        // ✅ Parse created_at date from Supabase
        let dateStack: UIStackView
        if let createdAt = student.created_at {
            dateStack = createDateStackFromString(dateString: createdAt)
        } else {
            dateStack = createDateStack(date: nil)
        }
        
        let buttonStack = createButtonStack(approveTag: index, declineTag: index, type: .student)
        
        card.addSubview(avatarView)
        card.addSubview(avatarLabel)
        card.addSubview(nameLabel)
        card.addSubview(regInstLabel)
        card.addSubview(emailStack)
        card.addSubview(dateStack)
        card.addSubview(buttonStack)
        
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
    
    // MARK: - Mentor Card (adapted for Supabase model)
    private func createMentorCard(for mentor: SupabaseManager.MentorRegistration, at index: Int) -> UIView {
        let card = UIView()
        card.backgroundColor = .white
        card.layer.cornerRadius = 20
        card.layer.shadowColor = UIColor.black.cgColor
        card.layer.shadowOffset = CGSize(width: 0, height: 4)
        card.layer.shadowRadius = 12
        card.layer.shadowOpacity = 0.06
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarView = UIView()
        avatarView.backgroundColor = getAvatarColor(for: mentor.full_name)
        avatarView.layer.cornerRadius = 30
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        
        let avatarLabel = UILabel()
        avatarLabel.text = String(mentor.full_name.prefix(1)).uppercased()
        avatarLabel.font = .systemFont(ofSize: 24, weight: .semibold)
        avatarLabel.textColor = getAvatarTextColor(for: mentor.full_name)
        avatarLabel.textAlignment = .center
        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarView.addSubview(avatarLabel)
        
        let nameLabel = UILabel()
        nameLabel.text = mentor.full_name
        nameLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let empDesigLabel = UILabel()
        empDesigLabel.text = "\(mentor.employee_id) • \(mentor.designation)"
        empDesigLabel.font = .systemFont(ofSize: 14, weight: .regular)
        empDesigLabel.textColor = .systemGray
        empDesigLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let emailStack = createInfoStack(icon: "envelope.fill", text: mentor.email)
        let departmentStack = createInfoStack(icon: "building.2.fill", text: mentor.department)
        
        // ✅ Parse created_at date from Supabase
        let dateStack: UIStackView
        if let createdAt = mentor.created_at {
            dateStack = createDateStackFromString(dateString: createdAt)
        } else {
            dateStack = createDateStack(date: nil)
        }
        
        let buttonStack = createButtonStack(approveTag: index, declineTag: index, type: .mentor)
        
        card.addSubview(avatarView)
        card.addSubview(avatarLabel)
        card.addSubview(nameLabel)
        card.addSubview(empDesigLabel)
        card.addSubview(emailStack)
        card.addSubview(departmentStack)
        card.addSubview(dateStack)
        card.addSubview(buttonStack)
        
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
            
            empDesigLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            empDesigLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            empDesigLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            
            emailStack.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 16),
            emailStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            emailStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -20),
            
            departmentStack.topAnchor.constraint(equalTo: emailStack.bottomAnchor, constant: 8),
            departmentStack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            departmentStack.trailingAnchor.constraint(lessThanOrEqualTo: card.trailingAnchor, constant: -20),
            
            dateStack.topAnchor.constraint(equalTo: departmentStack.bottomAnchor, constant: 8),
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
    
    // MARK: - Helper Methods for Card Creation
    private func createInfoStack(icon: String, text: String) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView(image: UIImage(systemName: icon))
        iconView.tintColor = .systemGray2
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.widthAnchor.constraint(equalToConstant: 16).isActive = true
        iconView.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = .label
        
        stack.addArrangedSubview(iconView)
        stack.addArrangedSubview(label)
        
        return stack
    }
    
    private func createDateStack(date: Date?) -> UIStackView {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        let clockIcon = UIImageView(image: UIImage(systemName: "clock"))
        clockIcon.tintColor = .systemGray2
        clockIcon.translatesAutoresizingMaskIntoConstraints = false
        clockIcon.widthAnchor.constraint(equalToConstant: 16).isActive = true
        clockIcon.heightAnchor.constraint(equalToConstant: 16).isActive = true
        
        let dateLabel = UILabel()
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "d MMM • h:mm a"
            dateLabel.text = "Applied \(formatter.string(from: date))"
        } else {
            dateLabel.text = "Applied recently"
        }
        dateLabel.font = .systemFont(ofSize: 14, weight: .regular)
        dateLabel.textColor = .systemGray
        
        stack.addArrangedSubview(clockIcon)
        stack.addArrangedSubview(dateLabel)
        
        return stack
    }
    
    // ✅ NEW: Parse ISO date string from Supabase
    private func createDateStackFromString(dateString: String) -> UIStackView {
        let isoFormatter = ISO8601DateFormatter()
        let date = isoFormatter.date(from: dateString)
        return createDateStack(date: date)
    }
    
    enum CardType {
        case student
        case mentor
    }
    
    private func createButtonStack(approveTag: Int, declineTag: Int, type: CardType) -> UIStackView {
        let approveButton = UIButton(type: .system)
        approveButton.setTitle("Approve", for: .normal)
        approveButton.setTitleColor(.systemGreen, for: .normal)
        approveButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        approveButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        approveButton.layer.cornerRadius = 12
        approveButton.translatesAutoresizingMaskIntoConstraints = false
        approveButton.tag = approveTag
        
        let declineButton = UIButton(type: .system)
        declineButton.setTitle("Decline", for: .normal)
        declineButton.setTitleColor(.systemRed, for: .normal)
        declineButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        declineButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
        declineButton.layer.cornerRadius = 12
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        declineButton.tag = declineTag
        
        if type == .student {
            approveButton.addTarget(self, action: #selector(approveStudentButtonTapped(_:)), for: .touchUpInside)
            declineButton.addTarget(self, action: #selector(declineStudentButtonTapped(_:)), for: .touchUpInside)
        } else {
            approveButton.addTarget(self, action: #selector(approveMentorButtonTapped(_:)), for: .touchUpInside)
            declineButton.addTarget(self, action: #selector(declineMentorButtonTapped(_:)), for: .touchUpInside)
        }
        
        let buttonStack = UIStackView(arrangedSubviews: [approveButton, declineButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        
        return buttonStack
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
        loadPendingData()
        refreshControl.endRefreshing()
    }
    
    // MARK: - Actions - Students
    @objc private func approveStudentButtonTapped(_ sender: UIButton) {
        approveStudent(at: sender.tag)
    }
    
    @objc private func declineStudentButtonTapped(_ sender: UIButton) {
        declineStudent(at: sender.tag)
    }
    
    private func approveStudent(at index: Int) {
        let student = pendingStudents[index]
        
        let alert = UIAlertController(
            title: "Approve Student",
            message: "Approve registration for \(student.full_name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Approve", style: .default) { _ in
            self.performStudentApproval(student: student, at: index)
        })
        
        present(alert, animated: true)
    }
    
    private func performStudentApproval(student: SupabaseManager.StudentRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                // ✅ Approve in Supabase
                try await SupabaseManager.shared.approveStudent(studentId: student.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingStudents.remove(at: index)
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Success", message: "\(student.full_name) has been approved and can now login.")
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
            message: "Decline registration for \(student.full_name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { _ in
            self.performStudentDecline(student: student, at: index)
        })
        
        present(alert, animated: true)
    }
    
    private func performStudentDecline(student: SupabaseManager.StudentRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                // ✅ Decline in Supabase
                try await SupabaseManager.shared.declineStudent(studentId: student.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingStudents.remove(at: index)
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Declined", message: "\(student.full_name)'s registration has been declined.")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to decline student: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Actions - Mentors
    @objc private func approveMentorButtonTapped(_ sender: UIButton) {
        approveMentor(at: sender.tag)
    }
    
    @objc private func declineMentorButtonTapped(_ sender: UIButton) {
        declineMentor(at: sender.tag)
    }
    
    private func approveMentor(at index: Int) {
        let mentor = pendingMentors[index]
        
        let alert = UIAlertController(
            title: "Approve Mentor",
            message: "Approve registration for \(mentor.full_name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Approve", style: .default) { _ in
            self.performMentorApproval(mentor: mentor, at: index)
        })
        
        present(alert, animated: true)
    }
    
    private func performMentorApproval(mentor: SupabaseManager.MentorRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                // ✅ Approve in Supabase
                try await SupabaseManager.shared.approveMentor(mentorId: mentor.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingMentors.remove(at: index)
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Success", message: "\(mentor.full_name) has been approved and can now login.")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to approve mentor: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func declineMentor(at index: Int) {
        let mentor = pendingMentors[index]
        
        let alert = UIAlertController(
            title: "Decline Mentor",
            message: "Decline registration for \(mentor.full_name)?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { _ in
            self.performMentorDecline(mentor: mentor, at: index)
        })
        
        present(alert, animated: true)
    }
    
    private func performMentorDecline(mentor: SupabaseManager.MentorRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                // ✅ Decline in Supabase
                try await SupabaseManager.shared.declineMentor(mentorId: mentor.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingMentors.remove(at: index)
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Declined", message: "\(mentor.full_name)'s registration has been declined.")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to decline mentor: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            // ✅ Clear UserDefaults instead of Firebase Auth
            UserDefaults.standard.removeObject(forKey: "current_user_email")
            UserDefaults.standard.removeObject(forKey: "current_person_id")
            UserDefaults.standard.removeObject(forKey: "is_logged_in")
            
            self.navigateToLogin()
        })
        
        present(alert, animated: true)
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
