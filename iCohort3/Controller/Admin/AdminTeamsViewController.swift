//
//  AdminTeamsViewController.swift
//  iCohort3
//
//  ✅ FIXED: Uses Supabase for approved mentors
//

import UIKit
import PostgREST
import Supabase

class AdminTeamsViewController: UIViewController {
    
    // MARK: - UI Components
    private let backButton = UIButton(type: .system)
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private var loadingIndicator: UIActivityIndicatorView?
    
    // MARK: - Data
    private var teams: [TeamDisplayModel] = []
    private var approvedMentors: [ApprovedMentorForAssignment] = []
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
        view.backgroundColor = UIColor(red: 0.78, green: 0.88, blue: 0.95, alpha: 1)
        
        navigationItem.title = "Teams"
        navigationItem.largeTitleDisplayMode = .never
        
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
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TeamCell.self, forCellReuseIdentifier: "TeamCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            tableView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 12),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
                // ✅ FIXED: Fetch approved mentors from Supabase
                let mentors = try await fetchApprovedMentorsFromSupabase()
                
                // ✅ Fetch teams from Supabase
                let teamsData = try await SupabaseManager.shared.fetchAllTeamsWithDetails()
                
                // ✅ Map to display models with mentor names
                let displayTeams = teamsData.map { team in
                    let mentorName = team.mentorId != nil ?
                        (mentors.first(where: { $0.personId == team.mentorId })?.fullName ?? "Unknown Mentor") :
                        nil
                    
                    return TeamDisplayModel(
                        id: team.id,
                        teamNo: team.teamNo,
                        mentorId: team.mentorId,
                        mentorName: mentorName,
                        memberNames: team.memberNames,
                        memberCount: team.memberCount
                    )
                }
                
                await MainActor.run {
                    self.approvedMentors = mentors
                    self.teams = displayTeams.sorted { $0.teamNo < $1.teamNo }
                    self.tableView.reloadData()
                    self.hideLoadingIndicator()
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to load teams: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // ✅ FIXED: Fetch approved mentors from Supabase
    // ✅ Fetch mentors from mentor_profile_complete (as per your screenshot)
    private func fetchApprovedMentorsFromSupabase() async throws -> [ApprovedMentorForAssignment] {

        struct MentorProfileCompleteDB: Decodable {
            let person_id: String       // UUID stored, decode as String
            let full_name: String?
            let first_name: String?
            let last_name: String?
        }

        let profiles: [MentorProfileCompleteDB] = try await SupabaseManager.shared.client
            .from("mentor_profile_complete")
            .select("person_id, full_name, first_name, last_name")
            .execute()
            .value

        return profiles.map { p in
            let fallback = [p.first_name, p.last_name]
                .compactMap { $0 }
                .joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let name = (p.full_name?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "")
            let finalName = !name.isEmpty ? name : (!fallback.isEmpty ? fallback : "Unknown Mentor")

            return ApprovedMentorForAssignment(
                personId: p.person_id,
                fullName: finalName,
                email: "" // mentor_profile_complete screenshot doesn't show email column
            )
        }
    }

    
    @objc private func refreshData() {
        loadData()
        refreshControl.endRefreshing()
    }
    
    // MARK: - Mentor Assignment
    private func showMentorAssignmentSheet(for team: TeamDisplayModel) {
        let alert = UIAlertController(
            title: "Assign Mentor",
            message: "Select a mentor for Team \(team.teamNo)",
            preferredStyle: .actionSheet
        )
        
        for mentor in approvedMentors {
            let action = UIAlertAction(title: mentor.fullName, style: .default) { _ in
                self.assignMentor(mentorId: mentor.personId, mentorName: mentor.fullName, to: team)
            }
            alert.addAction(action)
        }
        
        if team.mentorId != nil {
            let removeAction = UIAlertAction(title: "Remove Mentor", style: .destructive) { _ in
                self.removeMentor(from: team)
            }
            alert.addAction(removeAction)
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(alert, animated: true)
    }
    
    private func assignMentor(mentorId: String, mentorName: String, to team: TeamDisplayModel) {
        showLoadingIndicator()

        Task {
            do {
                // ✅ Must update BOTH mentor_id + mentor_name in new_teams
                try await SupabaseManager.shared.assignMentorToTeam(
                    teamId: team.id,
                    mentorId: mentorId,
                    mentorName: mentorName
                )

                await MainActor.run {
                    if let index = self.teams.firstIndex(where: { $0.id == team.id }) {
                        self.teams[index].mentorId = mentorId
                        self.teams[index].mentorName = mentorName
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Success", message: "\(mentorName) assigned to Team \(team.teamNo)")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to assign mentor: \(error.localizedDescription)")
                }
            }
        }
    }

    
    private func removeMentor(from team: TeamDisplayModel) {
        showLoadingIndicator()
        
        Task {
            do {
                try await SupabaseManager.shared.removeMentorFromTeam(teamId: team.id)
                
                await MainActor.run {
                    if let index = self.teams.firstIndex(where: { $0.id == team.id }) {
                        self.teams[index].mentorId = nil
                        self.teams[index].mentorName = nil
                        self.tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                    }
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Success", message: "Mentor removed from Team \(team.teamNo)")
                }
            } catch {
                await MainActor.run {
                    self.hideLoadingIndicator()
                    self.showAlert(title: "Error", message: "Failed to remove mentor: \(error.localizedDescription)")
                }
            }
        }
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
extension AdminTeamsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return teams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TeamCell", for: indexPath) as! TeamCell
        let team = teams[indexPath.row]
        cell.configure(with: team)
        cell.onAssignMentor = { [weak self] in
            self?.showMentorAssignmentSheet(for: team)
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
}

// MARK: - Team Cell
class TeamCell: UITableViewCell {
    private let containerView = UIView()
    private let teamNumberLabel = UILabel()
    private let mentorLabel = UILabel()
    private let assignMentorButton = UIButton(type: .system)
    private let membersLabel = UILabel()
    private let membersStackView = UIStackView()
    
    var onAssignMentor: (() -> Void)?
    
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
        
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        containerView.layer.shadowRadius = 8
        containerView.layer.shadowOpacity = 0.08
        containerView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(containerView)
        
        teamNumberLabel.font = .systemFont(ofSize: 24, weight: .bold)
        teamNumberLabel.textColor = .label
        teamNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(teamNumberLabel)
        
        mentorLabel.font = .systemFont(ofSize: 15, weight: .medium)
        mentorLabel.textColor = .secondaryLabel
        mentorLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(mentorLabel)
        
        assignMentorButton.setTitle("Assign Mentor", for: .normal)
        assignMentorButton.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        assignMentorButton.setTitleColor(.systemBlue, for: .normal)
        assignMentorButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        assignMentorButton.layer.cornerRadius = 8
        assignMentorButton.addTarget(self, action: #selector(assignMentorTapped), for: .touchUpInside)
        assignMentorButton.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(assignMentorButton)
        
        membersLabel.text = "Members:"
        membersLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        membersLabel.textColor = .label
        membersLabel.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(membersLabel)
        
        membersStackView.axis = .vertical
        membersStackView.spacing = 4
        membersStackView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(membersStackView)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            containerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            containerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            containerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            teamNumberLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 16),
            teamNumberLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            
            assignMentorButton.centerYAnchor.constraint(equalTo: teamNumberLabel.centerYAnchor),
            assignMentorButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            assignMentorButton.heightAnchor.constraint(equalToConstant: 32),
            assignMentorButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
            
            mentorLabel.topAnchor.constraint(equalTo: teamNumberLabel.bottomAnchor, constant: 4),
            mentorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            mentorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            membersLabel.topAnchor.constraint(equalTo: mentorLabel.bottomAnchor, constant: 12),
            membersLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            membersLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            
            membersStackView.topAnchor.constraint(equalTo: membersLabel.bottomAnchor, constant: 8),
            membersStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            membersStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            membersStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ])
    }
    
    func configure(with team: TeamDisplayModel) {
        teamNumberLabel.text = "Team \(team.teamNo)"
        
        if let mentorName = team.mentorName {
            mentorLabel.text = "Mentor: \(mentorName)"
            mentorLabel.textColor = .systemGreen
            assignMentorButton.setTitle("Change Mentor", for: .normal)
        } else {
            mentorLabel.text = "No mentor assigned"
            mentorLabel.textColor = .systemOrange
            assignMentorButton.setTitle("Assign Mentor", for: .normal)
        }
        
        membersStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for memberName in team.memberNames {
            let memberLabel = UILabel()
            memberLabel.text = "• \(memberName)"
            memberLabel.font = .systemFont(ofSize: 14, weight: .regular)
            memberLabel.textColor = .label
            membersStackView.addArrangedSubview(memberLabel)
        }
        
        if team.memberNames.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "No members yet"
            emptyLabel.font = .systemFont(ofSize: 14, weight: .regular)
            emptyLabel.textColor = .secondaryLabel
            membersStackView.addArrangedSubview(emptyLabel)
        }
    }
    
    @objc private func assignMentorTapped() {
        onAssignMentor?()
    }
}

// MARK: - Supporting Models
struct TeamDisplayModel {
    let id: String
    let teamNo: Int
    var mentorId: String?
    var mentorName: String?
    let memberNames: [String]
    let memberCount: Int
}

struct ApprovedMentorForAssignment {
    let personId: String
    let fullName: String
    let email: String
}
