//
//  ApprovedMentorsViewController.swift
//  iCohort3
//
//  ✅ FIXED: Uses Supabase instead of Firebase
//

import UIKit
import PostgREST
import Supabase

class ApprovedMentorsViewController: UIViewController {
    private struct MentorProfileDetail: Decodable {
        let first_name: String?
        let last_name: String?
        let email: String?
        let employee_id: String?
        let designation: String?
        let department: String?
        let personal_mail: String?
        let contact_number: String?
        let institute_name: String?
        let approved_at: String?
        let is_profile_complete: Bool?
    }
    
    // MARK: - UI Components
    private let searchBar = UISearchBar()
    private let mentorsTableView = UITableView()
    private let emptyStateLabel = UILabel()
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AdminUIStyle.updateScreenBackgroundLayout(for: view)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Approved Mentors"
    }
    
    // MARK: - Setup
    private func setupUI() {
        AdminUIStyle.styleScreenBackground(view)
        
        searchBar.delegate = self
        searchBar.placeholder = "Search mentors..."
        AdminUIStyle.styleSearchBar(searchBar)
        
        mentorsTableView.delegate = self
        mentorsTableView.dataSource = self
        mentorsTableView.register(BeautifulMentorCell.self, forCellReuseIdentifier: "BeautifulMentorCell")
        mentorsTableView.separatorStyle = .none
        mentorsTableView.backgroundColor = .clear
        mentorsTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        mentorsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(mentorsTableView)
        mentorsTableView.tableHeaderView = makeTableHeader()

        emptyStateLabel.text = "No approved mentors found"
        emptyStateLabel.font = .systemFont(ofSize: 17, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        mentorsTableView.refreshControl = refreshControl
        
        NSLayoutConstraint.activate([
            mentorsTableView.topAnchor.constraint(equalTo: view.topAnchor),
            mentorsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mentorsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mentorsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: mentorsTableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: mentorsTableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 32),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -32)
        ])
    }

    private func makeTableHeader() -> UIView {
        let header = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 72))
        header.backgroundColor = .clear
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        header.addSubview(searchBar)

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: header.topAnchor, constant: 8),
            searchBar.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -8),
            searchBar.bottomAnchor.constraint(equalTo: header.bottomAnchor, constant: -8)
        ])

        return header
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
                    self.updateEmptyState()
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
    
    // ✅ FIXED: Query Supabase instead of Firebase
    private func fetchApprovedMentors() async throws -> [ApprovedMentor] {
        struct MentorProfileDB: Codable {
            let person_id: String
            let first_name: String?
            let last_name: String?
            let email: String?
            let employee_id: String?
            let designation: String?
            let department: String?
            let institute_name: String?
            let approved_at: String?
        }
        
        let profiles: [MentorProfileDB] = try await SupabaseManager.shared.client
            .from("mentor_profiles")
            .select("person_id, first_name, last_name, email, employee_id, designation, department, institute_name, approved_at")
            .eq("institute_name", value: instituteName)
            .execute()
            .value
        
        let isoFormatter = ISO8601DateFormatter()
        
        let mentors = profiles.compactMap { profile -> ApprovedMentor? in
            let fullName = [profile.first_name, profile.last_name]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let approvedDate = profile.approved_at.flatMap { isoFormatter.date(from: $0) } ?? Date()
            
            return ApprovedMentor(
                id: profile.person_id,
                fullName: fullName.isEmpty ? (profile.email ?? "Unknown") : fullName,
                employeeId: profile.employee_id ?? "",
                designation: profile.designation ?? "",
                department: profile.department ?? "",
                email: profile.email ?? "",
                approvedAt: approvedDate
            )
        }.sorted { $0.approvedAt > $1.approvedAt }
        
        print("✅ Found \(mentors.count) approved mentors for institute: \(instituteName)")
        return mentors
    }
    
    @objc private func refreshData() {
        loadData()
        refreshControl.endRefreshing()
    }

    private func updateEmptyState() {
        let activeList = isSearching ? filteredMentors : allMentors
        let isEmpty = activeList.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        mentorsTableView.isHidden = isEmpty
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let mentor = isSearching ? filteredMentors[indexPath.row] : allMentors[indexPath.row]
        showMentorDetails(for: mentor)
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
        updateEmptyState()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        filteredMentors = allMentors
        mentorsTableView.reloadData()
        updateEmptyState()
    }
}

private extension ApprovedMentorsViewController {
    func showMentorDetails(for mentor: ApprovedMentor) {
        showLoadingIndicator()

        Task {
            do {
                let details: [MentorProfileDetail] = try await SupabaseManager.shared.client
                    .from("mentor_profiles")
                    .select("first_name, last_name, email, employee_id, designation, department, personal_mail, contact_number, institute_name, approved_at, is_profile_complete")
                    .eq("person_id", value: mentor.id)
                    .limit(1)
                    .execute()
                    .value

                let detail = details.first
                let fullName = [detail?.first_name, detail?.last_name]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let fields: [(String, String)] = [
                    ("Full Name", fullName.isEmpty ? mentor.fullName : fullName),
                    ("Employee ID", detail?.employee_id ?? mentor.employeeId),
                    ("College Email", detail?.email ?? mentor.email),
                    ("Personal Email", detail?.personal_mail ?? "-"),
                    ("Designation", detail?.designation ?? mentor.designation),
                    ("Department", detail?.department ?? mentor.department),
                    ("Contact Number", detail?.contact_number ?? "-"),
                    ("Institute", detail?.institute_name ?? instituteName),
                    ("Profile Complete", (detail?.is_profile_complete ?? false) ? "Yes" : "No"),
                    ("Approved At", detail?.approved_at ?? "-")
                ]

                await MainActor.run {
                    hideLoadingIndicator()
                    let detailVC = AdminProfileDetailViewController(profileTitle: "Mentor Details", fields: fields)
                    navigationController?.pushViewController(detailVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    hideLoadingIndicator()
                    showAlert(title: "Error", message: "Failed to load mentor details: \(error.localizedDescription)")
                }
            }
        }
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
        
        AdminUIStyle.styleCard(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.clipsToBounds = true
        profileImageView.layer.cornerRadius = 30
        profileImageView.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.1)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        emailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emailLabel.textColor = .secondaryLabel
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(emailLabel)
        
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
