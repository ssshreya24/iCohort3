//
//  MentorDetailViewController.swift
//  iCohort3
//
//  Shows detailed mentor profile from both Firebase and Supabase
//

import UIKit
import FirebaseFirestore

class MentorDetailViewController: UIViewController {
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let backButton = UIButton(type: .system)
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // Sections
    private let personalDetailsLabel = UILabel()
    private let personalDetailsStack = UIStackView()
    
    private let professionalInfoLabel = UILabel()
    private let professionalInfoStack = UIStackView()
    
    private let teamInfoLabel = UILabel()
    private let teamInfoStack = UIStackView()
    
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Data
    private let mentorEmail: String
    private let mentorName: String
    private let mentorEmployeeId: String
    private let mentorDesignation: String
    private let mentorDepartment: String
    
    // MARK: - Initialization
    init(email: String, name: String, employeeId: String, designation: String, department: String) {
        self.mentorEmail = email
        self.mentorName = name
        self.mentorEmployeeId = employeeId
        self.mentorDesignation = designation
        self.mentorDepartment = department
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadMentorProfile()
    }
    
    // MARK: - Setup UI
    private func setupUI() {
        view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 245/255, alpha: 1.0)
        
        // Back button
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 22
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        backButton.layer.shadowRadius = 8
        backButton.layer.shadowOpacity = 0.1
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: chevronConfig), for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        view.addSubview(backButton)
        
        // Scroll view setup
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        
        // Profile image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 50
        profileImageView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Name label
        nameLabel.text = mentorName
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Subtitle
        subtitleLabel.text = "\(mentorDesignation) • \(mentorDepartment)"
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(subtitleLabel)
        
        // Personal Details Section
        personalDetailsLabel.text = "PERSONAL DETAILS"
        personalDetailsLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        personalDetailsLabel.textColor = .secondaryLabel
        personalDetailsLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(personalDetailsLabel)
        
        personalDetailsStack.axis = .vertical
        personalDetailsStack.spacing = 0
        personalDetailsStack.backgroundColor = .white
        personalDetailsStack.layer.cornerRadius = 12
        personalDetailsStack.clipsToBounds = true
        personalDetailsStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(personalDetailsStack)
        
        // Professional Info Section
        professionalInfoLabel.text = "PROFESSIONAL INFO"
        professionalInfoLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        professionalInfoLabel.textColor = .secondaryLabel
        professionalInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(professionalInfoLabel)
        
        professionalInfoStack.axis = .vertical
        professionalInfoStack.spacing = 0
        professionalInfoStack.backgroundColor = .white
        professionalInfoStack.layer.cornerRadius = 12
        professionalInfoStack.clipsToBounds = true
        professionalInfoStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(professionalInfoStack)
        
        // Team Info Section
        teamInfoLabel.text = "TEAM ASSIGNMENT"
        teamInfoLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        teamInfoLabel.textColor = .secondaryLabel
        teamInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(teamInfoLabel)
        
        teamInfoStack.axis = .vertical
        teamInfoStack.spacing = 0
        teamInfoStack.backgroundColor = .white
        teamInfoStack.layer.cornerRadius = 12
        teamInfoStack.clipsToBounds = true
        teamInfoStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(teamInfoStack)
        
        // Layout
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            scrollView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            profileImageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            profileImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            profileImageView.widthAnchor.constraint(equalToConstant: 100),
            profileImageView.heightAnchor.constraint(equalToConstant: 100),
            
            nameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            
            personalDetailsLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 32),
            personalDetailsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            personalDetailsStack.topAnchor.constraint(equalTo: personalDetailsLabel.bottomAnchor, constant: 8),
            personalDetailsStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            personalDetailsStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            professionalInfoLabel.topAnchor.constraint(equalTo: personalDetailsStack.bottomAnchor, constant: 24),
            professionalInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            professionalInfoStack.topAnchor.constraint(equalTo: professionalInfoLabel.bottomAnchor, constant: 8),
            professionalInfoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            professionalInfoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            teamInfoLabel.topAnchor.constraint(equalTo: professionalInfoStack.bottomAnchor, constant: 24),
            teamInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            teamInfoStack.topAnchor.constraint(equalTo: teamInfoLabel.bottomAnchor, constant: 8),
            teamInfoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            teamInfoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            teamInfoStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Set profile image
        let initial = String(mentorName.prefix(1)).uppercased()
        profileImageView.image = generateProfileImage(initial: initial, name: mentorName)
    }
    
    // MARK: - Load Profile Data
    private func loadMentorProfile() {
        showLoadingIndicator()
        
        Task {
            do {
                // Get person_id from Supabase using email
                let personId = try await SupabaseManager.shared.fetchMentorId(email: mentorEmail)
                
                if let personId = personId {
                    // Fetch complete profile from Supabase
                    let profile = try await SupabaseManager.shared.fetchMentorProfile(personId: personId)
                    
                    await MainActor.run {
                        self.populateProfile(with: profile)
                        self.hideLoadingIndicator()
                    }
                } else {
                    // No Supabase profile yet - show only Firebase data
                    await MainActor.run {
                        self.showFirebaseDataOnly()
                        self.hideLoadingIndicator()
                    }
                }
            } catch {
                await MainActor.run {
                    self.showFirebaseDataOnly()
                    self.hideLoadingIndicator()
                    print("Error loading mentor profile: \(error)")
                }
            }
        }
    }
    
    private func populateProfile(with profile: SupabaseManager.MentorProfileComplete?) {
        personalDetailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        professionalInfoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        teamInfoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let profile = profile {
            // Personal Details
            addDetailRow(to: personalDetailsStack, label: "Full Name", value: profile.full_name)
            addDetailRow(to: personalDetailsStack, label: "First Name", value: profile.first_name)
            addDetailRow(to: personalDetailsStack, label: "Last Name", value: profile.last_name)
            addDetailRow(to: personalDetailsStack, label: "Email ID", value: profile.email, isLink: true)
            addDetailRow(to: personalDetailsStack, label: "Personal Email", value: profile.personal_mail, isLink: true)
            addDetailRow(to: personalDetailsStack, label: "Phone", value: profile.contact_number)
            
            // Professional Info
            addDetailRow(to: professionalInfoStack, label: "Employee ID", value: profile.employee_id)
            addDetailRow(to: professionalInfoStack, label: "Designation", value: profile.designation)
            addDetailRow(to: professionalInfoStack, label: "Department", value: profile.department)
            
            // Team Assignment
            if let teamCount = profile.assigned_teams_count, teamCount > 0 {
                addDetailRow(to: teamInfoStack, label: "Assigned Teams", value: "\(teamCount) Team(s)", isStatus: true)
            } else {
                addDetailRow(to: teamInfoStack, label: "Assigned Teams", value: "No teams assigned", isStatus: false)
            }
        } else {
            showFirebaseDataOnly()
        }
    }
    
    private func showFirebaseDataOnly() {
        personalDetailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        professionalInfoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        teamInfoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Personal Details (from Firebase)
        addDetailRow(to: personalDetailsStack, label: "Full Name", value: mentorName)
        addDetailRow(to: personalDetailsStack, label: "Email ID", value: mentorEmail, isLink: true)
        addDetailRow(to: personalDetailsStack, label: "First Name", value: nil)
        addDetailRow(to: personalDetailsStack, label: "Last Name", value: nil)
        addDetailRow(to: personalDetailsStack, label: "Phone", value: nil)
        
        // Professional Info
        addDetailRow(to: professionalInfoStack, label: "Employee ID", value: mentorEmployeeId)
        addDetailRow(to: professionalInfoStack, label: "Designation", value: mentorDesignation)
        addDetailRow(to: professionalInfoStack, label: "Department", value: mentorDepartment)
        
        // Team Assignment
        addDetailRow(to: teamInfoStack, label: "Assigned Teams", value: "No teams assigned", isStatus: false)
    }
    
    private func addDetailRow(to stack: UIStackView, label: String, value: String?, isLink: Bool = false, isStatus: Bool? = nil) {
        let row = UIView()
        row.translatesAutoresizingMaskIntoConstraints = false
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = .systemFont(ofSize: 15, weight: .regular)
        labelView.textColor = .label
        labelView.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(labelView)
        
        let valueView = UILabel()
        valueView.text = value ?? "Not provided yet"
        valueView.font = .systemFont(ofSize: 15, weight: isLink ? .medium : .regular)
        valueView.textColor = value == nil ? .tertiaryLabel : (isLink ? .systemBlue : .secondaryLabel)
        valueView.textAlignment = .right
        valueView.numberOfLines = 0
        valueView.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(valueView)
        
        // Add status badge if needed
        if let isStatus = isStatus, value != nil {
            let badge = UIView()
            badge.backgroundColor = isStatus ? UIColor.systemGreen.withAlphaComponent(0.15) : UIColor.systemOrange.withAlphaComponent(0.15)
            badge.layer.cornerRadius = 4
            badge.translatesAutoresizingMaskIntoConstraints = false
            
            let badgeLabel = UILabel()
            badgeLabel.text = value
            badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
            badgeLabel.textColor = isStatus ? .systemGreen : .systemOrange
            badgeLabel.translatesAutoresizingMaskIntoConstraints = false
            badge.addSubview(badgeLabel)
            
            row.addSubview(badge)
            valueView.removeFromSuperview()
            
            NSLayoutConstraint.activate([
                badge.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
                badge.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 4),
                badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -4),
                badgeLabel.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 8),
                badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -8)
            ])
        } else {
            NSLayoutConstraint.activate([
                valueView.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
                valueView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                valueView.widthAnchor.constraint(lessThanOrEqualTo: row.widthAnchor, multiplier: 0.6)
            ])
        }
        
        NSLayoutConstraint.activate([
            labelView.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
            labelView.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            labelView.trailingAnchor.constraint(lessThanOrEqualTo: row.trailingAnchor, constant: -100),
            
            row.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        
        stack.addArrangedSubview(row)
        
        // Add separator
        if stack.arrangedSubviews.count > 1 {
            let separator = UIView()
            separator.backgroundColor = .separator
            separator.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(separator)
            
            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: row.trailingAnchor),
                separator.topAnchor.constraint(equalTo: row.topAnchor),
                separator.heightAnchor.constraint(equalToConstant: 0.5)
            ])
        }
    }
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    private func generateProfileImage(initial: String, name: String) -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let colors: [(UIColor, UIColor)] = [
            (UIColor(red: 0.98, green: 0.95, blue: 1.0, alpha: 1.0), UIColor(red: 0.6, green: 0.4, blue: 0.9, alpha: 1.0)),
            (UIColor(red: 0.95, green: 0.98, blue: 1.0, alpha: 1.0), UIColor(red: 0.3, green: 0.6, blue: 0.9, alpha: 1.0)),
            (UIColor(red: 1.0, green: 0.97, blue: 0.93, alpha: 1.0), UIColor(red: 0.9, green: 0.6, blue: 0.3, alpha: 1.0)),
            (UIColor(red: 0.95, green: 1.0, blue: 0.98, alpha: 1.0), UIColor(red: 0.3, green: 0.8, blue: 0.6, alpha: 1.0))
        ]
        
        let index = abs(name.hashValue) % colors.count
        let (bgColor, textColor) = colors[index]
        
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            bgColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 40, weight: .semibold),
                .foregroundColor: textColor
            ]
            
            let textSize = initial.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            initial.draw(in: textRect, withAttributes: attributes)
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
    }
    
    private func hideLoadingIndicator() {
        loadingIndicator?.stopAnimating()
    }
}
