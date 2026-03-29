//
//  ApprovedStudentsViewController.swift
//  iCohort3
//
//  ✅ FIXED: Uses Supabase instead of Firebase
//

import UIKit
import PostgREST
import Supabase

class ApprovedStudentsViewController: UIViewController {
    private struct StudentProfileDetail: Decodable {
        let first_name: String?
        let last_name: String?
        let department: String?
        let srm_mail: String?
        let reg_no: String?
        let personal_mail: String?
        let contact_number: String?
        let institute_domain: String?
        let approved_at: String?
        let is_profile_complete: Bool?
    }
    
    // MARK: - UI Components
    private let searchBar = UISearchBar()
    private let studentsTableView = UITableView()
    private let emptyStateLabel = UILabel()
    private let refreshControl = UIRefreshControl()
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Data
    private var allStudents: [ApprovedStudent] = []
    private var filteredStudents: [ApprovedStudent] = []
    private var isSearching = false
    private var instituteDomain: String
    
    // MARK: - Initialization
    init(instituteDomain: String) {
        self.instituteDomain = instituteDomain
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
        navigationItem.title = "Approved Students"
    }
    
    // MARK: - Setup
    private func setupUI() {
        AdminUIStyle.styleScreenBackground(view)
        
        searchBar.delegate = self
        searchBar.placeholder = "Search students..."
        AdminUIStyle.styleSearchBar(searchBar)
        
        studentsTableView.delegate = self
        studentsTableView.dataSource = self
        studentsTableView.register(BeautifulStudentCell.self, forCellReuseIdentifier: "BeautifulStudentCell")
        studentsTableView.separatorStyle = .none
        studentsTableView.backgroundColor = .clear
        studentsTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        studentsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(studentsTableView)
        studentsTableView.tableHeaderView = makeTableHeader()

        emptyStateLabel.text = "No approved students found"
        emptyStateLabel.font = .systemFont(ofSize: 17, weight: .medium)
        emptyStateLabel.textColor = .secondaryLabel
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        studentsTableView.refreshControl = refreshControl
        
        NSLayoutConstraint.activate([
            studentsTableView.topAnchor.constraint(equalTo: view.topAnchor),
            studentsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            studentsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            studentsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            emptyStateLabel.centerXAnchor.constraint(equalTo: studentsTableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: studentsTableView.centerYAnchor),
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
                let students = try await fetchApprovedStudents()
                
                await MainActor.run {
                    self.allStudents = students
                    self.filteredStudents = students
                    self.studentsTableView.reloadData()
                    self.updateEmptyState()
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
    
    // ✅ FIXED: Query Supabase instead of Firebase
    private func fetchApprovedStudents() async throws -> [ApprovedStudent] {
        struct StudentProfileDB: Codable {
            let person_id: String
            let first_name: String?
            let last_name: String?
            let srm_mail: String?
            let reg_no: String?
            let institute_domain: String?
            let approved_at: String?
        }
        
        let profiles: [StudentProfileDB] = try await SupabaseManager.shared.client
            .from("student_profiles")
            .select("person_id, first_name, last_name, srm_mail, reg_no, institute_domain, approved_at")
            .eq("institute_domain", value: instituteDomain)
            .execute()
            .value
        
        let isoFormatter = ISO8601DateFormatter()
        
        let students = profiles.compactMap { profile -> ApprovedStudent? in
            let fullName = [profile.first_name, profile.last_name]
                .compactMap { $0 }
                .joined(separator: " ")
            
            let approvedDate = profile.approved_at.flatMap { isoFormatter.date(from: $0) } ?? Date()
            
            return ApprovedStudent(
                id: profile.person_id,
                fullName: fullName.isEmpty ? (profile.srm_mail ?? "Unknown") : fullName,
                regNumber: profile.reg_no ?? "",
                email: profile.srm_mail ?? "",
                approvedAt: approvedDate
            )
        }.sorted { $0.approvedAt > $1.approvedAt }
        
        print("✅ Found \(students.count) approved students for domain: \(instituteDomain)")
        return students
    }
    
    @objc private func refreshData() {
        loadData()
        refreshControl.endRefreshing()
    }

    private func updateEmptyState() {
        let activeList = isSearching ? filteredStudents : allStudents
        let isEmpty = activeList.isEmpty
        emptyStateLabel.isHidden = !isEmpty
        studentsTableView.isHidden = isEmpty
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
extension ApprovedStudentsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredStudents.count : allStudents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BeautifulStudentCell", for: indexPath) as! BeautifulStudentCell
        let student = isSearching ? filteredStudents[indexPath.row] : allStudents[indexPath.row]
        cell.configure(with: student)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let student = isSearching ? filteredStudents[indexPath.row] : allStudents[indexPath.row]
        showStudentDetails(for: student)
    }
}

// MARK: - UISearchBarDelegate
extension ApprovedStudentsViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            isSearching = false
            filteredStudents = allStudents
        } else {
            isSearching = true
            filteredStudents = allStudents.filter { student in
                student.fullName.lowercased().contains(searchText.lowercased()) ||
                student.regNumber.lowercased().contains(searchText.lowercased()) ||
                student.email.lowercased().contains(searchText.lowercased())
            }
        }
        studentsTableView.reloadData()
        updateEmptyState()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        filteredStudents = allStudents
        studentsTableView.reloadData()
        updateEmptyState()
    }
}

private extension ApprovedStudentsViewController {
    func showStudentDetails(for student: ApprovedStudent) {
        showLoadingIndicator()

        Task {
            do {
                let details: [StudentProfileDetail] = try await SupabaseManager.shared.client
                    .from("student_profiles")
                    .select("first_name, last_name, department, srm_mail, reg_no, personal_mail, contact_number, institute_domain, approved_at, is_profile_complete")
                    .eq("person_id", value: student.id)
                    .limit(1)
                    .execute()
                    .value

                let detail = details.first
                let fullName = [detail?.first_name, detail?.last_name]
                    .compactMap { $0 }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                let fields: [(String, String)] = [
                    ("Full Name", fullName.isEmpty ? student.fullName : fullName),
                    ("Registration Number", detail?.reg_no ?? student.regNumber),
                    ("College Email", detail?.srm_mail ?? student.email),
                    ("Personal Email", detail?.personal_mail ?? "-"),
                    ("Department", detail?.department ?? "-"),
                    ("Contact Number", detail?.contact_number ?? "-"),
                    ("Institute Domain", detail?.institute_domain ?? instituteDomain),
                    ("Profile Complete", (detail?.is_profile_complete ?? false) ? "Yes" : "No"),
                    ("Approved At", detail?.approved_at ?? "-")
                ]

                await MainActor.run {
                    hideLoadingIndicator()
                    let detailVC = AdminProfileDetailViewController(profileTitle: "Student Details", fields: fields)
                    navigationController?.pushViewController(detailVC, animated: true)
                }
            } catch {
                await MainActor.run {
                    hideLoadingIndicator()
                    showAlert(title: "Error", message: "Failed to load student details: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Beautiful Student Cell
class BeautifulStudentCell: UITableViewCell {
    private let containerView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let regNumberLabel = UILabel()
    private let emailLabel = UILabel()
    
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
        profileImageView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        regNumberLabel.font = .systemFont(ofSize: 14, weight: .regular)
        regNumberLabel.textColor = .secondaryLabel
        regNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(regNumberLabel)
        
        emailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emailLabel.textColor = .tertiaryLabel
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(emailLabel)
        
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
            
            regNumberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            regNumberLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            regNumberLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            emailLabel.topAnchor.constraint(equalTo: regNumberLabel.bottomAnchor, constant: 2),
            emailLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16)
        ])
    }
    
    func configure(with student: ApprovedStudent) {
        nameLabel.text = student.fullName
        regNumberLabel.text = student.regNumber
        emailLabel.text = student.email
        
        let initial = String(student.fullName.prefix(1)).uppercased()
        profileImageView.image = generateProfileImage(initial: initial, name: student.fullName)
    }
    
    private func generateProfileImage(initial: String, name: String) -> UIImage {
        let size = CGSize(width: 60, height: 60)
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
struct ApprovedStudent {
    let id: String
    let fullName: String
    let regNumber: String
    let email: String
    let approvedAt: Date
}
