//
//  AdminDashboardViewController.swift
//  iCohort3
//
//  ✅ FIXED: Uses correct UserDefaults key "admin_email" instead of "current_user_email"
//

import UIKit

class AdminDashboardViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let headerContainerView = UIView()
    private let titleLabel = UILabel()
    private let institutionLabel = UILabel()
    private let logoutButton = UIButton(type: .system)
    private var gradientLayer: CAGradientLayer!
    
    // Statistics Cards
    private let statisticsStackView = UIStackView()
    private var approvedStudentsCard: StatisticCardView!
    private var approvedMentorsCard: StatisticCardView!
    
    // Teams Section
    private let teamsHeaderLabel = UILabel()
    private let viewAllTeamsButton = UIButton(type: .system)
    private let teamsContainerView = UIView()
    
    // Pending Requests Section
    private let pendingRequestsLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["Students", "Mentors"])
    private let requestsStackView = UIStackView()
    
    private let refreshControl = UIRefreshControl()
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Data
    private var instituteName: String = ""
    private var instituteDomain: String = ""
    private var adminEmail: String = ""
    
    private var approvedStudentsCount: Int = 0
    private var approvedMentorsCount: Int = 0
    private var teamsCount: Int = 0
    private var pendingStudents: [SupabaseManager.StudentRegistration] = []
    private var pendingMentors: [SupabaseManager.MentorRegistration] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        applyTheme()
        getAdminInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        if !instituteDomain.isEmpty {
            loadAllData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AdminUIStyle.updateScreenBackgroundLayout(for: view)
    }
    
    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
            updateUI()
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        AdminUIStyle.styleScreenBackground(view)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = true
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(headerContainerView)
        
        titleLabel.text = "Admin"
        titleLabel.font = .systemFont(ofSize: 32, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(titleLabel)
        
        institutionLabel.text = "Loading..."
        institutionLabel.font = .systemFont(ofSize: 17, weight: .regular)
        institutionLabel.textColor = .secondaryLabel
        institutionLabel.numberOfLines = 0
        institutionLabel.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(institutionLabel)
        
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        AdminUIStyle.styleCompactActionButton(logoutButton, systemImage: "rectangle.portrait.and.arrow.right")
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        headerContainerView.addSubview(logoutButton)
        
        statisticsStackView.axis = .horizontal
        statisticsStackView.spacing = 16
        statisticsStackView.distribution = .fillEqually
        statisticsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(statisticsStackView)
        
        approvedStudentsCard = StatisticCardView(
            icon: UIImage(systemName: "person.2.fill")!,
            iconColor: .systemBlue,
            count: "0",
            title: "Approved Students"
        )
        approvedStudentsCard.addTarget(self, action: #selector(viewApprovedStudents), for: .touchUpInside)
        
        approvedMentorsCard = StatisticCardView(
            icon: UIImage(systemName: "person.badge.shield.checkmark.fill")!,
            iconColor: .systemOrange,
            count: "0",
            title: "Approved Mentors"
        )
        approvedMentorsCard.addTarget(self, action: #selector(viewApprovedMentors), for: .touchUpInside)
        
        statisticsStackView.addArrangedSubview(approvedStudentsCard)
        statisticsStackView.addArrangedSubview(approvedMentorsCard)
        
        teamsHeaderLabel.text = "Teams Formed"
        teamsHeaderLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        teamsHeaderLabel.textColor = .label
        teamsHeaderLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(teamsHeaderLabel)
        
        viewAllTeamsButton.setTitle("View All", for: .normal)
        viewAllTeamsButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        viewAllTeamsButton.setTitleColor(.label, for: .normal)
        viewAllTeamsButton.addTarget(self, action: #selector(viewAllTeamsTapped), for: .touchUpInside)
        viewAllTeamsButton.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(viewAllTeamsButton)
        
        AdminUIStyle.styleCard(teamsContainerView)
        teamsContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(teamsContainerView)
        
        pendingRequestsLabel.text = "Pending Requests"
        pendingRequestsLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        pendingRequestsLabel.textColor = .label
        pendingRequestsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(pendingRequestsLabel)
        
        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(segmentChanged), for: .valueChanged)
        contentView.addSubview(segmentedControl)
        
        requestsStackView.axis = .vertical
        requestsStackView.spacing = 12
        requestsStackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(requestsStackView)
        
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
            
            headerContainerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            headerContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            headerContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            titleLabel.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 2),
            titleLabel.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: logoutButton.leadingAnchor, constant: -12),
            
            logoutButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            logoutButton.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor),
            logoutButton.widthAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            
            institutionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            institutionLabel.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor),
            institutionLabel.trailingAnchor.constraint(equalTo: logoutButton.leadingAnchor, constant: -12),
            institutionLabel.bottomAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            
            statisticsStackView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor, constant: 24),
            statisticsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            statisticsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            statisticsStackView.heightAnchor.constraint(equalToConstant: 136),
            
            teamsHeaderLabel.topAnchor.constraint(equalTo: statisticsStackView.bottomAnchor, constant: 32),
            teamsHeaderLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            viewAllTeamsButton.centerYAnchor.constraint(equalTo: teamsHeaderLabel.centerYAnchor),
            viewAllTeamsButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            teamsContainerView.topAnchor.constraint(equalTo: teamsHeaderLabel.bottomAnchor, constant: 16),
            teamsContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            teamsContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            teamsContainerView.heightAnchor.constraint(equalToConstant: 100),
            
            pendingRequestsLabel.topAnchor.constraint(equalTo: teamsContainerView.bottomAnchor, constant: 32),
            pendingRequestsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            pendingRequestsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            segmentedControl.topAnchor.constraint(equalTo: pendingRequestsLabel.bottomAnchor, constant: 20),
            segmentedControl.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            segmentedControl.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            segmentedControl.heightAnchor.constraint(equalToConstant: 32),
            
            requestsStackView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 24),
            requestsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            requestsStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            requestsStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    private func applyTheme() {
        AdminUIStyle.styleScreenBackground(view)
        scrollView.backgroundColor = .clear
        contentView.backgroundColor = .clear
        headerContainerView.backgroundColor = .clear
        titleLabel.textColor = .label
        institutionLabel.textColor = .secondaryLabel
        teamsHeaderLabel.textColor = .label
        pendingRequestsLabel.textColor = .label
        viewAllTeamsButton.setTitleColor(traitCollection.userInterfaceStyle == .dark ? .white : .black, for: .normal)
        AdminUIStyle.styleCard(teamsContainerView)
        styleSegmentedControl()
        loadingIndicator?.color = AppTheme.accent
        approvedStudentsCard?.applyTheme()
        approvedMentorsCard?.applyTheme()
    }
    
    private func styleSegmentedControl() {
        let selectedTextColor = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        let normalTextColor = UIColor.secondaryLabel
        segmentedControl.backgroundColor = AppTheme.floatingBackground
        segmentedControl.selectedSegmentTintColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.12)
            : UIColor.white.withAlphaComponent(0.72)
        segmentedControl.setTitleTextAttributes([.foregroundColor: normalTextColor], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: selectedTextColor], for: .selected)
        segmentedControl.layer.cornerRadius = 16
        segmentedControl.layer.masksToBounds = true
    }
    
    // MARK: - Data Loading
    private func getAdminInfo() {
        // ✅ FIXED: Changed from "current_user_email" to "admin_email"
        adminEmail = UserDefaults.standard.string(forKey: "admin_email") ?? ""
        
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔍 ADMIN DASHBOARD - GET ADMIN INFO")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📧 Admin email from UserDefaults:", adminEmail)
        
        guard !adminEmail.isEmpty else {
            print("❌ ERROR: Admin email is EMPTY!")
            print("   UserDefaults keys:", UserDefaults.standard.dictionaryRepresentation().keys)
            print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            DispatchQueue.main.async {
                self.institutionLabel.text = "Error: No admin email found"
                self.showAlert(title: "Error", message: "Admin session not found. Please login again.")
            }
            return
        }
        
        Task {
            do {
                print("🔍 Fetching institute for admin email:", adminEmail)
                
                if let institute = try await SupabaseManager.shared.getInstitute(byAdminEmail: adminEmail) {
                    print("✅ INSTITUTE FOUND!")
                    print("   ID:", institute.id)
                    print("   Name:", institute.name)
                    print("   Domain:", institute.domain)
                    print("   Admin Email:", institute.admin_email)
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    
                    await MainActor.run {
                        self.instituteName = institute.name
                        self.instituteDomain = institute.domain
                        self.institutionLabel.text = institute.name
                        
                        print("✅ Updated UI with institute name:", institute.name)
                        print("🔄 Now loading pending data...")
                        
                        self.loadAllData()
                    }
                } else {
                    print("❌ ERROR: No institute found for admin:", adminEmail)
                    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    
                    await MainActor.run {
                        self.institutionLabel.text = "Institute not found"
                        self.showAlert(title: "Error", message: "No institute found for admin email: \(self.adminEmail)\n\nPlease register your institute first.")
                    }
                }
            } catch {
                print("❌ EXCEPTION fetching institute:", error.localizedDescription)
                print("   Error type:", type(of: error))
                print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                
                await MainActor.run {
                    self.institutionLabel.text = "Error loading institute"
                    self.showAlert(title: "Error", message: "Failed to load institute: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // In AdminDashboardViewController.swift

    private func loadAllData() {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🔄 LOAD ALL DATA (INSTITUTE-FILTERED)")
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("📧 Admin Email:", adminEmail)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        guard !adminEmail.isEmpty else {
            print("❌ ERROR: Admin email is EMPTY")
            return
        }
        
        showLoadingIndicator()
        
        Task {
            do {
                // ✅ Use new institute-aware function
                let stats = try await SupabaseManager.shared.getInstituteStatistics(adminEmail: adminEmail)
                
                print("✅ STATISTICS LOADED:")
                print("   Institute: \(stats.instituteName)")
                print("   Domain: \(stats.instituteDomain)")
                print("   Pending Students: \(stats.pendingStudents)")
                print("   Pending Mentors: \(stats.pendingMentors)")
                print("   Approved Students: \(stats.approvedStudents)")
                print("   Approved Mentors: \(stats.approvedMentors)")
                print("   Teams: \(stats.totalTeams)")
                
                // Get detailed pending lists
                let students = try await SupabaseManager.shared.getPendingStudentsForAdmin(adminEmail: adminEmail)
                let mentors = try await SupabaseManager.shared.getPendingMentorsForAdmin(adminEmail: adminEmail)
                
                await MainActor.run {
                    self.instituteName = stats.instituteName
                    self.instituteDomain = stats.instituteDomain
                    self.pendingStudents = students
                    self.pendingMentors = mentors
                    self.approvedStudentsCount = stats.approvedStudents
                    self.approvedMentorsCount = stats.approvedMentors
                    self.teamsCount = stats.totalTeams
                    
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    print("✅ UI UPDATED with institute-filtered data")
                }
                
            } catch {
                print("❌ ERROR loading data:", error.localizedDescription)
                
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to load data: \(error.localizedDescription)")
                }
            }
        }
    }
    private func updateUI() {
        approvedStudentsCard.updateCount("\(approvedStudentsCount)")
        approvedMentorsCard.updateCount("\(approvedMentorsCount)")
        
        updateTeamsPreview()
        updatePendingRequests()
    }
    
    private func updateTeamsPreview() {
        teamsContainerView.subviews.forEach { $0.removeFromSuperview() }
        
        let teamsLabel = UILabel()
        teamsLabel.text = "\(teamsCount) Teams"
        teamsLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        teamsLabel.textColor = .label
        teamsLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let statusLabel = UILabel()
        statusLabel.text = "Currently active"
        statusLabel.font = .systemFont(ofSize: 14, weight: .regular)
        statusLabel.textColor = .secondaryLabel
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        
        teamsContainerView.addSubview(teamsLabel)
        teamsContainerView.addSubview(statusLabel)
        
        NSLayoutConstraint.activate([
            teamsLabel.centerYAnchor.constraint(equalTo: teamsContainerView.centerYAnchor, constant: -10),
            teamsLabel.leadingAnchor.constraint(equalTo: teamsContainerView.leadingAnchor, constant: 20),
            
            statusLabel.topAnchor.constraint(equalTo: teamsLabel.bottomAnchor, constant: 4),
            statusLabel.leadingAnchor.constraint(equalTo: teamsContainerView.leadingAnchor, constant: 20)
        ])
    }
    
    @objc private func segmentChanged() {
        updatePendingRequests()
    }
    
    private func updatePendingRequests() {
        requestsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        if segmentedControl.selectedSegmentIndex == 0 {
            if pendingStudents.isEmpty {
                let emptyLabel = UILabel()
                emptyLabel.text = "No pending requests"
                emptyLabel.textAlignment = .center
                emptyLabel.textColor = .secondaryLabel
                emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
                emptyLabel.translatesAutoresizingMaskIntoConstraints = false
                requestsStackView.addArrangedSubview(emptyLabel)
                
                NSLayoutConstraint.activate([
                    emptyLabel.heightAnchor.constraint(equalToConstant: 100)
                ])
            } else {
                let maxToShow = min(3, pendingStudents.count)
                for i in 0..<maxToShow {
                    let card = createPendingStudentCard(for: pendingStudents[i], index: i)
                    requestsStackView.addArrangedSubview(card)
                }

                if pendingStudents.count > 3 {
                    let viewAllButton = UIButton(type: .system)
                    viewAllButton.setTitle("View all pending requests (\(pendingStudents.count))", for: .normal)
                    viewAllButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
                    viewAllButton.setTitleColor(AppTheme.accent, for: .normal)
                    viewAllButton.addTarget(self, action: #selector(viewAllPendingRequests), for: .touchUpInside)
                    requestsStackView.addArrangedSubview(viewAllButton)
                }
            }
        } else {
            if pendingMentors.isEmpty {
                let emptyLabel = UILabel()
                emptyLabel.text = "No pending requests"
                emptyLabel.textAlignment = .center
                emptyLabel.textColor = .secondaryLabel
                emptyLabel.font = .systemFont(ofSize: 16, weight: .medium)
                emptyLabel.translatesAutoresizingMaskIntoConstraints = false
                requestsStackView.addArrangedSubview(emptyLabel)
                
                NSLayoutConstraint.activate([
                    emptyLabel.heightAnchor.constraint(equalToConstant: 100)
                ])
            } else {
                let maxToShow = min(3, pendingMentors.count)
                for i in 0..<maxToShow {
                    let card = createPendingMentorCard(for: pendingMentors[i], index: i)
                    requestsStackView.addArrangedSubview(card)
                }

                if pendingMentors.count > 3 {
                    let viewAllButton = UIButton(type: .system)
                    viewAllButton.setTitle("View all pending requests (\(pendingMentors.count))", for: .normal)
                    viewAllButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
                    viewAllButton.setTitleColor(AppTheme.accent, for: .normal)
                    viewAllButton.addTarget(self, action: #selector(viewAllPendingRequests), for: .touchUpInside)
                    requestsStackView.addArrangedSubview(viewAllButton)
                }
            }
        }
    }

    private func createPendingStudentCard(for student: SupabaseManager.StudentRegistration, index: Int) -> UIView {
        let card = UIView()
        AdminUIStyle.styleCard(card)
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
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let infoLabel = UILabel()
        infoLabel.text = student.reg_number
        infoLabel.font = .systemFont(ofSize: 14, weight: .regular)
        infoLabel.textColor = .secondaryLabel
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let instituteLabel = UILabel()
        instituteLabel.text = instituteName
        instituteLabel.font = .systemFont(ofSize: 13, weight: .regular)
        instituteLabel.textColor = .tertiaryLabel
        instituteLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let emailLabel = UILabel()
        emailLabel.text = student.email
        emailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        emailLabel.textColor = .secondaryLabel
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let requestLabel = UILabel()
        if let dateString = student.created_at {
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: dateString) {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM yyyy"
                requestLabel.text = "Requested • \(formatter.string(from: date))"
            } else {
                requestLabel.text = "Requested recently"
            }
        } else {
            requestLabel.text = "Requested recently"
        }
        requestLabel.font = .systemFont(ofSize: 13, weight: .regular)
        requestLabel.textColor = .tertiaryLabel
        requestLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let approveButton = UIButton(type: .system)
        approveButton.setTitle("Approve", for: .normal)
        approveButton.setTitleColor(.systemGreen, for: .normal)
        approveButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        approveButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        approveButton.layer.cornerRadius = 10
        approveButton.tag = index
        approveButton.addTarget(self, action: #selector(approveStudentButtonTapped(_:)), for: .touchUpInside)
        approveButton.translatesAutoresizingMaskIntoConstraints = false
        
        let declineButton = UIButton(type: .system)
        declineButton.setTitle("Decline", for: .normal)
        declineButton.setTitleColor(.systemRed, for: .normal)
        declineButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        declineButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
        declineButton.layer.cornerRadius = 10
        declineButton.tag = index
        declineButton.addTarget(self, action: #selector(declineStudentButtonTapped(_:)), for: .touchUpInside)
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(avatarView)
        card.addSubview(nameLabel)
        card.addSubview(infoLabel)
        card.addSubview(instituteLabel)
        card.addSubview(emailLabel)
        card.addSubview(requestLabel)
        card.addSubview(approveButton)
        card.addSubview(declineButton)
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 180),
            
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            avatarView.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            avatarView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            infoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            infoLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            instituteLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 16),
            instituteLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            instituteLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            emailLabel.topAnchor.constraint(equalTo: instituteLabel.bottomAnchor, constant: 6),
            emailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            requestLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 4),
            requestLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            requestLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            approveButton.topAnchor.constraint(equalTo: requestLabel.bottomAnchor, constant: 16),
            approveButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            approveButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            approveButton.heightAnchor.constraint(equalToConstant: 44),
            approveButton.widthAnchor.constraint(equalTo: declineButton.widthAnchor),
            
            declineButton.topAnchor.constraint(equalTo: requestLabel.bottomAnchor, constant: 16),
            declineButton.leadingAnchor.constraint(equalTo: approveButton.trailingAnchor, constant: 12),
            declineButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            declineButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            declineButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return card
    }
    
    private func createPendingMentorCard(for mentor: SupabaseManager.MentorRegistration, index: Int) -> UIView {
        let card = UIView()
        AdminUIStyle.styleCard(card)
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
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let infoLabel = UILabel()
        infoLabel.text = "\(mentor.employee_id) • \(mentor.designation)"
        infoLabel.font = .systemFont(ofSize: 14, weight: .regular)
        infoLabel.textColor = .secondaryLabel
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let instituteLabel = UILabel()
        instituteLabel.text = instituteName
        instituteLabel.font = .systemFont(ofSize: 13, weight: .regular)
        instituteLabel.textColor = .tertiaryLabel
        instituteLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let emailLabel = UILabel()
        emailLabel.text = mentor.email
        emailLabel.font = .systemFont(ofSize: 13, weight: .regular)
        emailLabel.textColor = .secondaryLabel
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let requestLabel = UILabel()
        if let dateString = mentor.created_at {
            let isoFormatter = ISO8601DateFormatter()
            if let date = isoFormatter.date(from: dateString) {
                let formatter = DateFormatter()
                formatter.dateFormat = "d MMM yyyy"
                requestLabel.text = "Requested • \(formatter.string(from: date))"
            } else {
                requestLabel.text = "Requested recently"
            }
        } else {
            requestLabel.text = "Requested recently"
        }
        requestLabel.font = .systemFont(ofSize: 13, weight: .regular)
        requestLabel.textColor = .tertiaryLabel
        requestLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let approveButton = UIButton(type: .system)
        approveButton.setTitle("Approve", for: .normal)
        approveButton.setTitleColor(.systemGreen, for: .normal)
        approveButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        approveButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.15)
        approveButton.layer.cornerRadius = 10
        approveButton.tag = index
        approveButton.addTarget(self, action: #selector(approveMentorButtonTapped(_:)), for: .touchUpInside)
        approveButton.translatesAutoresizingMaskIntoConstraints = false
        
        let declineButton = UIButton(type: .system)
        declineButton.setTitle("Decline", for: .normal)
        declineButton.setTitleColor(.systemRed, for: .normal)
        declineButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        declineButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.15)
        declineButton.layer.cornerRadius = 10
        declineButton.tag = index
        declineButton.addTarget(self, action: #selector(declineMentorButtonTapped(_:)), for: .touchUpInside)
        declineButton.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(avatarView)
        card.addSubview(nameLabel)
        card.addSubview(infoLabel)
        card.addSubview(instituteLabel)
        card.addSubview(emailLabel)
        card.addSubview(requestLabel)
        card.addSubview(approveButton)
        card.addSubview(declineButton)
        
        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 180),
            
            avatarLabel.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            avatarLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
            
            avatarView.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            avatarView.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            avatarView.widthAnchor.constraint(equalToConstant: 60),
            avatarView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 20),
            nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            infoLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            infoLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 16),
            infoLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            instituteLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 16),
            instituteLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            instituteLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            emailLabel.topAnchor.constraint(equalTo: instituteLabel.bottomAnchor, constant: 6),
            emailLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            requestLabel.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 4),
            requestLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            requestLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            
            approveButton.topAnchor.constraint(equalTo: requestLabel.bottomAnchor, constant: 16),
            approveButton.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            approveButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            approveButton.heightAnchor.constraint(equalToConstant: 44),
            approveButton.widthAnchor.constraint(equalTo: declineButton.widthAnchor),
            
            declineButton.topAnchor.constraint(equalTo: requestLabel.bottomAnchor, constant: 16),
            declineButton.leadingAnchor.constraint(equalTo: approveButton.trailingAnchor, constant: 12),
            declineButton.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            declineButton.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16),
            declineButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        return card
    }
    
    // MARK: - Actions
    @objc private func logoutTapped() {
        let alert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Logout", style: .destructive) { _ in
            // ✅ Clear all admin-related UserDefaults keys
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
            
            self.navigateToLogin()
        })
        
        present(alert, animated: true)
    }
    
    @objc private func viewApprovedStudents() {
        let approvedStudentsVC = ApprovedStudentsViewController(instituteDomain: instituteDomain)
        navigationController?.pushViewController(approvedStudentsVC, animated: true)
    }
    
    @objc private func viewApprovedMentors() {
        let approvedMentorsVC = ApprovedMentorsViewController(instituteName: instituteName)
        navigationController?.pushViewController(approvedMentorsVC, animated: true)
    }
    
    @objc private func viewAllTeamsTapped() {
        let teamsVC = AdminTeamsViewController(instituteName: instituteName, instituteDomain: instituteDomain)
        navigationController?.pushViewController(teamsVC, animated: true)
    }
    
    @objc private func viewAllPendingRequests() {
        let approvalVC = AdminApprovalViewController()
        navigationController?.pushViewController(approvalVC, animated: true)
    }
    
    @objc private func refreshData() {
        loadAllData()
        refreshControl.endRefreshing()
    }
    
    // MARK: - Student Actions
    @objc private func approveStudentButtonTapped(_ sender: UIButton) {
        let student = pendingStudents[sender.tag]
        
        let alert = UIAlertController(
            title: "Approve Request",
            message: "Request will be approved for \(student.full_name)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Approve", style: .default) { _ in
            self.performStudentApproval(student: student, at: sender.tag)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func declineStudentButtonTapped(_ sender: UIButton) {
        let student = pendingStudents[sender.tag]
        
        let alert = UIAlertController(
            title: "Decline Request",
            message: "Request will be declined for \(student.full_name)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { _ in
            self.performStudentDecline(student: student, at: sender.tag)
        })
        
        present(alert, animated: true)
    }
    
    private func performStudentApproval(student: SupabaseManager.StudentRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                try await SupabaseManager.shared.approveStudent(studentId: student.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingStudents.remove(at: index)
                    self.approvedStudentsCount += 1
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Request Approved", message: "\(student.full_name)'s request has been approved")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to approve: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func performStudentDecline(student: SupabaseManager.StudentRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                try await SupabaseManager.shared.declineStudent(studentId: student.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingStudents.remove(at: index)
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Request Declined", message: "\(student.full_name)'s request has been declined")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to decline: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Mentor Actions
    @objc private func approveMentorButtonTapped(_ sender: UIButton) {
        let mentor = pendingMentors[sender.tag]
        
        let alert = UIAlertController(
            title: "Approve Request",
            message: "Request will be approved for \(mentor.full_name)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Approve", style: .default) { _ in
            self.performMentorApproval(mentor: mentor, at: sender.tag)
        })
        
        present(alert, animated: true)
    }
    
    @objc private func declineMentorButtonTapped(_ sender: UIButton) {
        let mentor = pendingMentors[sender.tag]
        
        let alert = UIAlertController(
            title: "Decline Request",
            message: "Request will be declined for \(mentor.full_name)",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Decline", style: .destructive) { _ in
            self.performMentorDecline(mentor: mentor, at: sender.tag)
        })
        
        present(alert, animated: true)
    }
    
    private func performMentorApproval(mentor: SupabaseManager.MentorRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                try await SupabaseManager.shared.approveMentor(mentorId: mentor.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingMentors.remove(at: index)
                    self.approvedMentorsCount += 1
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Request Approved", message: "\(mentor.full_name)'s request has been approved")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to approve: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func performMentorDecline(mentor: SupabaseManager.MentorRegistration, at index: Int) {
        showLoadingIndicator()
        
        Task {
            do {
                try await SupabaseManager.shared.declineMentor(mentorId: mentor.id, adminEmail: adminEmail)
                
                await MainActor.run {
                    self.pendingMentors.remove(at: index)
                    self.updateUI()
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Request Declined", message: "\(mentor.full_name)'s request has been declined")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to decline: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - Helper Methods
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
    
    private func showAlert(title: String, message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
}

// MARK: - Statistic Card View
class StatisticCardView: UIControl {
    private let iconImageView = UIImageView()
    private let countLabel = UILabel()
    private let titleLabel = UILabel()
    
    init(icon: UIImage, iconColor: UIColor, count: String, title: String) {
        super.init(frame: .zero)

        AdminUIStyle.styleCard(self)

        iconImageView.image = icon
        iconImageView.tintColor = iconColor
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(iconImageView)
        
        countLabel.text = count
        countLabel.font = .systemFont(ofSize: 30, weight: .bold)
        countLabel.textColor = .label
        countLabel.textAlignment = .left
        countLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(countLabel)
        
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = UIColor(red: 0.31, green: 0.38, blue: 0.47, alpha: 1)
        titleLabel.numberOfLines = 0
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            iconImageView.topAnchor.constraint(equalTo: topAnchor, constant: 18),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            
            countLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 10),
            countLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            countLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            
            titleLabel.topAnchor.constraint(equalTo: countLabel.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -18)
        ])
        
        applyTheme()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateCount(_ count: String) {
        countLabel.text = count
    }
    
    func applyTheme() {
        AdminUIStyle.styleCard(self)
        countLabel.textColor = .label
        titleLabel.textColor = .secondaryLabel
    }
    
    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.1) {
                self.alpha = self.isHighlighted ? 0.7 : 1.0
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
            }
        }
    }
}
