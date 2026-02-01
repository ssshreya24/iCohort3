//
//  ApprovedStudentsViewController.swift
//  iCohort3
//
//  Beautiful UI with profile avatars, styled cards, and chevron arrows
//  FIXED: Added chevron arrow and tap to view details
//

import UIKit
import FirebaseFirestore

class ApprovedStudentsViewController: UIViewController {
    
    // MARK: - UI Components
    private let backButton = UIButton(type: .system)
    private let searchBar = UISearchBar()
    private let studentsTableView = UITableView()
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
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor(red: 239/255, green: 239/255, blue: 245/255, alpha: 1.0) // #EFEFF5
        
        navigationItem.title = "Approved Students"
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
        searchBar.placeholder = "Search students..."
        searchBar.searchBarStyle = .minimal
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchBar)
        
        // Setup table view
        studentsTableView.delegate = self
        studentsTableView.dataSource = self
        studentsTableView.register(BeautifulStudentCell.self, forCellReuseIdentifier: "BeautifulStudentCell")
        studentsTableView.separatorStyle = .none
        studentsTableView.backgroundColor = .clear
        studentsTableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        studentsTableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(studentsTableView)
        
        // Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        studentsTableView.refreshControl = refreshControl
        
        // Layout
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            searchBar.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 12),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            
            studentsTableView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 8),
            studentsTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            studentsTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            studentsTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
                let students = try await fetchApprovedStudents()
                
                await MainActor.run {
                    self.allStudents = students
                    self.filteredStudents = students
                    self.studentsTableView.reloadData()
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
    
    private func fetchApprovedStudents() async throws -> [ApprovedStudent] {
        // Filter by instituteDomain (now properly saved during approval!)
        let query = FirebaseManager.shared.db.collection("approved_students")
            .whereField("instituteDomain", isEqualTo: instituteDomain)
        
        let snapshot = try await query.getDocuments()
        
        print("📊 Found \(snapshot.documents.count) approved students for domain: \(instituteDomain)")
        
        var students = snapshot.documents.compactMap { doc in
            let data = doc.data()
            return ApprovedStudent(
                id: doc.documentID,
                fullName: data["fullName"] as? String ?? "",
                regNumber: data["regNumber"] as? String ?? "",
                email: data["email"] as? String ?? "",
                approvedAt: (data["approvedAt"] as? Timestamp)?.dateValue() ?? Date()
            )
        }
        
        students.sort { $0.approvedAt > $1.approvedAt }
        
        return students
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
        let student = isSearching ? filteredStudents[indexPath.row] : allStudents[indexPath.row]
        
        let detailVC = StudentDetailViewController(
            email: student.email,
            name: student.fullName,
            regNo: student.regNumber
        )
        navigationController?.pushViewController(detailVC, animated: true)
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
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        isSearching = false
        filteredStudents = allStudents
        studentsTableView.reloadData()
    }
}

// MARK: - Beautiful Student Cell with Chevron
class BeautifulStudentCell: UITableViewCell {
    private let containerView = UIView()
    private let profileImageView = UIImageView()
    private let nameLabel = UILabel()
    private let regNumberLabel = UILabel()
    private let emailLabel = UILabel()
    private let chevronImageView = UIImageView()
    
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
        profileImageView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(profileImageView)
        
        // Name Label
        nameLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(nameLabel)
        
        // Reg Number Label
        regNumberLabel.font = .systemFont(ofSize: 14, weight: .regular)
        regNumberLabel.textColor = .secondaryLabel
        regNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(regNumberLabel)
        
        // Email Label
        emailLabel.font = .systemFont(ofSize: 14, weight: .regular)
        emailLabel.textColor = .tertiaryLabel
        emailLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(emailLabel)
        
        // Chevron Image View
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
        chevronImageView.image = UIImage(systemName: "chevron.right", withConfiguration: chevronConfig)
        chevronImageView.tintColor = .tertiaryLabel
        chevronImageView.contentMode = .scaleAspectFit
        chevronImageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(chevronImageView)
        
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
            nameLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            
            regNumberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            regNumberLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            regNumberLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            
            emailLabel.topAnchor.constraint(equalTo: regNumberLabel.bottomAnchor, constant: 2),
            emailLabel.leadingAnchor.constraint(equalTo: profileImageView.trailingAnchor, constant: 16),
            emailLabel.trailingAnchor.constraint(equalTo: chevronImageView.leadingAnchor, constant: -8),
            
            chevronImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            chevronImageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            chevronImageView.widthAnchor.constraint(equalToConstant: 14),
            chevronImageView.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    func configure(with student: ApprovedStudent) {
        nameLabel.text = student.fullName
        regNumberLabel.text = student.regNumber
        emailLabel.text = student.email
        
        // Set profile image with generated avatar
        let initial = String(student.fullName.prefix(1)).uppercased()
        profileImageView.image = generateProfileImage(initial: initial, name: student.fullName)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        UIView.animate(withDuration: 0.1) {
            self.containerView.alpha = highlighted ? 0.8 : 1.0
            self.containerView.transform = highlighted ? CGAffineTransform(scaleX: 0.98, y: 0.98) : .identity
        }
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
