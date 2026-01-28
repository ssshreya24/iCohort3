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
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Data
    private var pendingStudents: [StudentRegistration] = []
    private var instituteDomain: String = "srmist.edu.in" // Default for SRM
    private var adminEmail: String = ""
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupTableView()
        getAdminInfo()
        loadPendingStudents()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = UIColor.systemGroupedBackground
        title = "Student Approvals"
        
        // Add logout button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Logout",
            style: .plain,
            target: self,
            action: #selector(logoutTapped)
        )
        
        // Setup table view
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(StudentApprovalCell.self, forCellReuseIdentifier: "StudentApprovalCell")
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 120
        tableView.separatorStyle = .singleLine
        
        // Add refresh control
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
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
                        self.title = "\(institute.name) - Approvals"
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
                    self.tableView.reloadData()
                    self.hideLoadingIndicator()
                    
                    if students.isEmpty {
                        self.showEmptyState()
                    } else {
                        self.hideEmptyState()
                    }
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to load students: \(error.localizedDescription)")
                }
            }
        }
    }
    
    @objc private func refreshData() {
        Task {
            do {
                let students = try await FirebaseManager.shared.getPendingStudents(forDomain: instituteDomain)
                
                await MainActor.run {
                    self.pendingStudents = students
                    self.tableView.reloadData()
                    self.refreshControl.endRefreshing()
                    
                    if students.isEmpty {
                        self.showEmptyState()
                    } else {
                        self.hideEmptyState()
                    }
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
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Success", message: "\(student.fullName) has been approved and can now login.")
                    
                    if self.pendingStudents.isEmpty {
                        self.showEmptyState()
                    }
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
                    self.tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .fade)
                    self.hideLoadingIndicator()
                    
                    self.showAlert(title: "Declined", message: "\(student.fullName)'s registration has been declined.")
                    
                    if self.pendingStudents.isEmpty {
                        self.showEmptyState()
                    }
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

// MARK: - UITableViewDataSource
extension AdminApprovalViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pendingStudents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StudentApprovalCell", for: indexPath) as! StudentApprovalCell
        
        let student = pendingStudents[indexPath.row]
        cell.configure(with: student)
        
        cell.onApprove = { [weak self] in
            self?.approveStudent(at: indexPath.row)
        }
        
        cell.onDecline = { [weak self] in
            self?.declineStudent(at: indexPath.row)
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension AdminApprovalViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

// MARK: - Custom Cell
class StudentApprovalCell: UITableViewCell {
    
    var onApprove: (() -> Void)?
    var onDecline: (() -> Void)?
    
    private let nameLabel = UILabel()
    private let emailLabel = UILabel()
    private let regNumberLabel = UILabel()
    private let dateLabel = UILabel()
    private let approveButton = UIButton(type: .system)
    private let declineButton = UIButton(type: .system)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // Name Label
        nameLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        nameLabel.textColor = .label
        
        // Email Label
        emailLabel.font = .systemFont(ofSize: 14)
        emailLabel.textColor = .secondaryLabel
        
        // Reg Number Label
        regNumberLabel.font = .systemFont(ofSize: 14, weight: .medium)
        regNumberLabel.textColor = .label
        
        // Date Label
        dateLabel.font = .systemFont(ofSize: 12)
        dateLabel.textColor = .tertiaryLabel
        
        // Approve Button
        approveButton.setTitle("Approve", for: .normal)
        approveButton.setTitleColor(.white, for: .normal)
        approveButton.backgroundColor = .systemGreen
        approveButton.layer.cornerRadius = 8
        approveButton.addTarget(self, action: #selector(approveTapped), for: .touchUpInside)
        
        // Decline Button
        declineButton.setTitle("Decline", for: .normal)
        declineButton.setTitleColor(.white, for: .normal)
        declineButton.backgroundColor = .systemRed
        declineButton.layer.cornerRadius = 8
        declineButton.addTarget(self, action: #selector(declineTapped), for: .touchUpInside)
        
        // Stack Views
        let infoStack = UIStackView(arrangedSubviews: [nameLabel, regNumberLabel, emailLabel, dateLabel])
        infoStack.axis = .vertical
        infoStack.spacing = 4
        
        let buttonStack = UIStackView(arrangedSubviews: [approveButton, declineButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually
        
        let mainStack = UIStackView(arrangedSubviews: [infoStack, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        contentView.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),
            
            approveButton.heightAnchor.constraint(equalToConstant: 40),
            declineButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    func configure(with student: StudentRegistration) {
        nameLabel.text = student.fullName
        emailLabel.text = student.email
        regNumberLabel.text = "Reg: \(student.regNumber)"
        
        if let date = student.createdAt {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            dateLabel.text = "Applied: \(formatter.string(from: date))"
        } else {
            dateLabel.text = ""
        }
    }
    
    @objc private func approveTapped() {
        onApprove?()
    }
    
    @objc private func declineTapped() {
        onDecline?()
    }
}
