//
//  StudentDetailViewController.swift
//  iCohort3
//
//  Shows detailed student profile from both Firebase and Supabase
//

import UIKit
import FirebaseFirestore

class StudentDetailViewController: UIViewController {
    
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
    
    private let academicInfoLabel = UILabel()
    private let academicInfoStack = UIStackView()
    
    private let mentorTeamLabel = UILabel()
    private let mentorTeamStack = UIStackView()
    
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Data
    private let studentEmail: String
    private let studentName: String
    private let studentRegNo: String
    
    // MARK: - Initialization
    init(email: String, name: String, regNo: String) {
        self.studentEmail = email
        self.studentName = name
        self.studentRegNo = regNo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadStudentProfile()
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
        profileImageView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(profileImageView)
        
        // Name label
        nameLabel.text = studentName
        nameLabel.font = .systemFont(ofSize: 28, weight: .bold)
        nameLabel.textColor = .label
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(nameLabel)
        
        // Subtitle
        subtitleLabel.text = studentRegNo
        subtitleLabel.font = .systemFont(ofSize: 17, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.textAlignment = .center
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
        
        // Academic Info Section
        academicInfoLabel.text = "ACADEMIC INFO"
        academicInfoLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        academicInfoLabel.textColor = .secondaryLabel
        academicInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(academicInfoLabel)
        
        academicInfoStack.axis = .vertical
        academicInfoStack.spacing = 0
        academicInfoStack.backgroundColor = .white
        academicInfoStack.layer.cornerRadius = 12
        academicInfoStack.clipsToBounds = true
        academicInfoStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(academicInfoStack)
        
        // Mentor & Team Section
        mentorTeamLabel.text = "MENTOR & TEAM STATUS"
        mentorTeamLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        mentorTeamLabel.textColor = .secondaryLabel
        mentorTeamLabel.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mentorTeamLabel)
        
        mentorTeamStack.axis = .vertical
        mentorTeamStack.spacing = 0
        mentorTeamStack.backgroundColor = .white
        mentorTeamStack.layer.cornerRadius = 12
        mentorTeamStack.clipsToBounds = true
        mentorTeamStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mentorTeamStack)
        
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
            
            academicInfoLabel.topAnchor.constraint(equalTo: personalDetailsStack.bottomAnchor, constant: 24),
            academicInfoLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            academicInfoStack.topAnchor.constraint(equalTo: academicInfoLabel.bottomAnchor, constant: 8),
            academicInfoStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            academicInfoStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            
            mentorTeamLabel.topAnchor.constraint(equalTo: academicInfoStack.bottomAnchor, constant: 24),
            mentorTeamLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            
            mentorTeamStack.topAnchor.constraint(equalTo: mentorTeamLabel.bottomAnchor, constant: 8),
            mentorTeamStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mentorTeamStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mentorTeamStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
        
        // Set profile image
        let initial = String(studentName.prefix(1)).uppercased()
        profileImageView.image = generateProfileImage(initial: initial, name: studentName)
    }
    
    // MARK: - Load Profile Data
    private func loadStudentProfile() {
        showLoadingIndicator()
        
        Task {
            do {
                // First, get person_id from Supabase using email
                let personId = try await SupabaseManager.shared.fetchStudentId(srmMail: studentEmail)
                
                if let personId = personId {
                    // Fetch complete profile from Supabase
                    let profile = try await SupabaseManager.shared.fetchStudentProfile(personId: personId)
                    
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
                    print("Error loading profile: \(error)")
                }
            }
        }
    }
    
    private func populateProfile(with profile: SupabaseManager.StudentProfileComplete?) {
        personalDetailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        academicInfoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        mentorTeamStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if let profile = profile {
            // Personal Details
            addDetailRow(to: personalDetailsStack, label: "Full Name", value: profile.full_name)
            addDetailRow(to: personalDetailsStack, label: "First Name", value: profile.first_name)
            addDetailRow(to: personalDetailsStack, label: "Last Name", value: profile.last_name)
            addDetailRow(to: personalDetailsStack, label: "Email ID", value: profile.srm_mail, isLink: true)
            addDetailRow(to: personalDetailsStack, label: "Personal Email", value: profile.personal_mail, isLink: true)
            addDetailRow(to: personalDetailsStack, label: "Phone", value: profile.contact_number)
            
            // Academic Info
            addDetailRow(to: academicInfoStack, label: "Registration No.", value: profile.reg_no)
            addDetailRow(to: academicInfoStack, label: "Department", value: profile.department)
            
            // Mentor & Team
            if let teamNo = profile.team_no {
                addDetailRow(to: mentorTeamStack, label: "Team Status", value: "ASSIGNED", isStatus: true)
                addDetailRow(to: mentorTeamStack, label: "Team Number", value: "Team \(teamNo)")
            } else {
                addDetailRow(to: mentorTeamStack, label: "Team Status", value: "NOT ASSIGNED", isStatus: false)
            }
            
            if let mentorName = profile.mentor_name {
                addDetailRow(to: mentorTeamStack, label: "Assigned Mentor", value: mentorName)
            } else {
                addDetailRow(to: mentorTeamStack, label: "Assigned Mentor", value: nil)
            }
        } else {
            showFirebaseDataOnly()
        }
    }
    
    private func showFirebaseDataOnly() {
        personalDetailsStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        academicInfoStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        mentorTeamStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        // Personal Details (from Firebase)
        addDetailRow(to: personalDetailsStack, label: "Full Name", value: studentName)
        addDetailRow(to: personalDetailsStack, label: "Email ID", value: studentEmail, isLink: true)
        addDetailRow(to: personalDetailsStack, label: "First Name", value: nil)
        addDetailRow(to: personalDetailsStack, label: "Last Name", value: nil)
        addDetailRow(to: personalDetailsStack, label: "Phone", value: nil)
        
        // Academic Info
        addDetailRow(to: academicInfoStack, label: "Registration No.", value: studentRegNo)
        addDetailRow(to: academicInfoStack, label: "Department", value: nil)
        
        // Mentor & Team
        addDetailRow(to: mentorTeamStack, label: "Team Status", value: "NOT ASSIGNED", isStatus: false)
        addDetailRow(to: mentorTeamStack, label: "Assigned Mentor", value: nil)
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
            (UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1.0), UIColor(red: 0.4, green: 0.4, blue: 0.9, alpha: 1.0)),
            (UIColor(red: 1.0, green: 0.95, blue: 0.95, alpha: 1.0), UIColor(red: 0.9, green: 0.4, blue: 0.4, alpha: 1.0)),
            (UIColor(red: 0.95, green: 1.0, blue: 0.95, alpha: 1.0), UIColor(red: 0.4, green: 0.9, blue: 0.4, alpha: 1.0)),
            (UIColor(red: 1.0, green: 0.97, blue: 0.9, alpha: 1.0), UIColor(red: 0.9, green: 0.7, blue: 0.3, alpha: 1.0))
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
