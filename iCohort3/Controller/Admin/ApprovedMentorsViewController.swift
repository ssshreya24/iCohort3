//
//  ApprovedMentorsViewController.swift
//  iCohort3
//
//  Beautiful UI with profile avatars and styled cards
//  FIXED: Removed sorting to work without Firebase index
//

import UIKit
import FirebaseFirestore

class ApprovedMentorsViewController: UIViewController {
    
    // MARK: - UI Components
    private let backButton = UIButton(type: .system)
    private let searchBar = UISearchBar()
    private let mentorsTableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Data
    private var allMentors: [ApprovedMentor] = []
    private var filteredMentors: [ApprovedMentor] = []
    private var isSearching = false
    private var instituteName: String
    
    // MARK: - Initialization
    init(instituteName: String) {
        self.instituteName = instituteName
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        loadData()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 245/255, alpha: 1.0) // #EFEFF5
        
        navigationItem.title = "Approved Mentors"
        navigationItem.largeTitleDisplayMode = .never
        
        // Setup custom back button
        backButton.backgroundColor = .white
        backButton.layer.cornerRadius = 22
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        backButton.layer.shadowRadius = 8
        backButton.layer.shadowOpacity = 0.1
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let chevronImage = UIImage(systemName: "chevron.left", withConfiguration: chevronConfig)
        backButton.setImage(chevronImage, for: .normal)
        backButton.tintColor = .label
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        view.addSubview(backButton)
        
        // Setup search bar
        searchBar.delegate = self
        searchBar.placeholder = "Search mentors..."
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Setup table view
        mentorsTableView.delegate = self
        mentorsTableView.dataSource = self
        mentorsTableView.register(BeautifulMentorCell.self, forCellReuseIdentifier: "BeautifulMentorCell")
        mentorsTableView.separatorStyle = .none
        mentorsTableView.backgroundColor = .clear
        mentorsTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        mentorsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mentorsTableView)
        
        // Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        mentorsTableView.refreshControl = refreshControl
        
        // Layout
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            searchBar.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            
            mentorsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            mentorsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mentorsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mentorsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Data Loading
    private func loadData() {
        showLoadingIndicator()
        
        Task {
            do {
                let mentors = try await fetchApprovedMentors()
                
                await MainActor.run {
                    self.allMentors = mentors
                    self.filteredMentors = mentors
                    self.mentorsTableView.reloadData()
                    self.hideLoadingIndicator()
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to load mentors: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func fetchApprovedMentors() async throws -> [ApprovedMentor] {
        // Filter by instituteName (now properly saved during approval!)
        let query = FirebaseManager.shared.db.collection("approved_mentors")
            .whereField("instituteName", isEqualTo: instituteName)
        
        let snapshot = try await query.getDocuments()
        
        print("📊 Found \(snapshot.documents.count) approved mentors for institute: \(instituteName)")
        
        var mentors = snapshot.documents.compactMap { doc in
            let data = doc.data()
            return ApprovedMentor(
                id: doc.documentID,
                fullName: data["fullName"] as? String ?? "",
                employeeId: data["employeeId"] as? String ?? "",
                designation: data["designation"] as? String ?? "",
                department: data["department"] as? String ?? "",
                email: data["email"] as? String ?? "",
                approvedAt: (data["approvedAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
        
        mentors.sort { $0.approvedAt > $1.approvedAt }
        
        return mentors
    }
    
    @objc private func refreshData() {
        loadData()
        refreshControl.endRefreshing()
    }
    
    // MARK: - Helper Methods
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
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDelegate & DataSource
extension ApprovedMentorsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredMentors.count : allMentors.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeautifulMentorCell", for: indexPath) as! BeautifulMentorCell
        let mentor = isSearching ? filteredMentors[indexPath.row] : allMentors[indexPath.row]
        cell.configure(with: mentor)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 110
    }
}

// MARK: - UISearchBarDelegate
extension ApprovedMentorsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredMentors = allMentors
        } else {
            isSearching = true
            filteredMentors = allMentors.filter { mentor in
                mentor.fullName.lowercased().contains(searchText.lowercased()) ||
                mentor.employeeId.lowercased().contains(searchText.lowercased()) ||
                mentor.designation.lowercased().contains(searchText.lowercased()) ||
                mentor.department.lowercased().contains(searchText.lowercased()) ||
                mentor.email.lowercased().contains(searchText.lowercased())
            }
        }
        mentorsTableView.reloadData()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        filteredMentors = allMentors
        mentorsTableView.reloadData()
    }
}

// MARK: - Beautiful Mentor Cell
class BeautifulMentorCell: UITableViewCell {
    private let containerView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let departmentBadge = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        // Container
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.08
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        // Profile Image
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 30
        profileImageView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        // Name Label
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Email Label
        emailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emailLabel.textColor = .secondaryLabel
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(emailLabel)
        
        // Department Badge
        departmentBadge.font = .systemFont(ofSize: 13, weight: .medium)
        departmentBadge.textColor = .systemBlue
        departmentBadge.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        departmentBadge.layer.cornerRadius = 12
        departmentBadge.clipsToBounds = true
        departmentBadge.textAlignment = .center
        departmentBadge.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(departmentBadge)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            
            profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            profileImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            profileImageView.widthAnchor.constraint(equalToConstant: 60),
            profileImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            nameLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            nameLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            departmentBadge.topAnchor.constraint(equalTo: emailLabel.bottomAnchor, constant: 8),
            departmentBadge.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            departmentBadge.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with mentor: ApprovedMentor) {
        nameLabel.text = mentor.fullName
        emailLabel.text = mentor.email
        departmentBadge.text = "  \(mentor.department)  "
        
        // Set profile image with generated avatar
        let initial = String(mentor.fullName.prefix(1)).uppercased()
        profileImageView.image = generateProfileImage(initial: initial, name: mentor.fullName)
    }
    
    private func generateProfileImage(initial: String, name: String) -> UIImage {
        let size = CGSize(width: 60, height: 60)
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
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
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
}

// MARK: - Supporting Types
struct ApprovedMentor {
    let id: String
    let fullName: String
    let employeeId: String
    let designation: String
    let department: String
    let email: String
    let approvedAt: Date
}
