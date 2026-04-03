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
    private let tableView = UITableView()
    private let refreshControl = UIRefreshControl()
    private var loadingIndicator: UIActivityIndicatorView?
    private let summaryCardView = UIView()
    private let summarySubtitleLabel = UILabel()
    
    // MARK: - Data
    private var teams: [TeamDisplayModel] = []
    private var approvedMentors: [ApprovedMentorForAssignment] = []
    private var instituteName: String
    private var instituteDomain: String
    
    // MARK: - Initialization
    init(instituteName: String, instituteDomain: String) {
        self.instituteName = instituteName
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
        applyTheme()
        loadData()
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
            tableView.reloadData()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationItem.title = "Teams Formed"
        navigationController?.navigationBar.tintColor = .label
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if isMovingFromParent || isBeingDismissed {
            navigationController?.navigationBar.prefersLargeTitles = false
        }
    }
    
    // MARK: - Setup
    private func setupUI() {
        AdminUIStyle.styleScreenBackground(view)
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(TeamCell.self, forCellReuseIdentifier: "TeamCell")
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        configureTableHeader()
        
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func applyTheme() {
        AdminUIStyle.styleScreenBackground(view)
        tableView.backgroundColor = .clear
        summarySubtitleLabel.textColor = .secondaryLabel
        AdminUIStyle.styleCard(summaryCardView, cornerRadius: 20)
        loadingIndicator?.color = AppTheme.accent
    }

    private func configureTableHeader() {
        let headerContainer = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 88))
        headerContainer.backgroundColor = .clear

        AdminUIStyle.styleCard(summaryCardView, cornerRadius: 20)
        summaryCardView.translatesAutoresizingMaskIntoConstraints = false
        headerContainer.addSubview(summaryCardView)

        summarySubtitleLabel.text = "Loading teams for \(instituteName)"
        summarySubtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        summarySubtitleLabel.textColor = UIColor(red: 0.31, green: 0.38, blue: 0.47, alpha: 1)
        summarySubtitleLabel.numberOfLines = 0
        summarySubtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        summaryCardView.addSubview(summarySubtitleLabel)

        NSLayoutConstraint.activate([
            summaryCardView.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 12),
            summaryCardView.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: 20),
            summaryCardView.trailingAnchor.constraint(equalTo: headerContainer.trailingAnchor, constant: -20),
            summaryCardView.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -16),

            summarySubtitleLabel.topAnchor.constraint(equalTo: summaryCardView.topAnchor, constant: 18),
            summarySubtitleLabel.leadingAnchor.constraint(equalTo: summaryCardView.leadingAnchor, constant: 18),
            summarySubtitleLabel.trailingAnchor.constraint(equalTo: summaryCardView.trailingAnchor, constant: -18),
            summarySubtitleLabel.bottomAnchor.constraint(equalTo: summaryCardView.bottomAnchor, constant: -18)
        ])

        tableView.tableHeaderView = headerContainer
    }
    
    // MARK: - Data Loading
    private func loadData() {
        showLoadingIndicator()
        
        Task {
            do {
                // ✅ FIXED: Fetch approved mentors from Supabase
                let mentors = try await fetchApprovedMentorsFromSupabase()
                
                // ✅ Fetch teams from Supabase
                let teamsData = try await SupabaseManager.shared.fetchAllTeamsWithDetails(forInstituteDomain: instituteDomain)
                
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
                        problemStatement: team.problemStatement,
                        memberNames: team.memberNames,
                        memberCount: team.memberCount
                    )
                }
                
                await MainActor.run {
                    self.approvedMentors = mentors
                    self.teams = displayTeams.sorted { $0.teamNo < $1.teamNo }
                    let count = self.teams.count
                    self.summarySubtitleLabel.text = count == 0
                        ? "No teams available for \(self.instituteName)"
                        : "\(count) active team\(count == 1 ? "" : "s") for \(self.instituteName)"
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
        let picker = MentorAssignmentSheetViewController(
            team: team,
            mentors: approvedMentors,
            onSelectMentor: { [weak self] mentor in
                self?.assignMentor(mentorId: mentor.personId, mentorName: mentor.fullName, to: team)
            },
            onRemoveMentor: team.mentorId != nil ? { [weak self] in
                self?.removeMentor(from: team)
            } : nil
        )

        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 28
        }

        present(picker, animated: true)
    }
    
    private func assignMentor(mentorId: String, mentorName: String, to team: TeamDisplayModel) {
        showLoadingIndicator()

        Task {
            do {
                // ✅ Must update BOTH mentor_id + mentor_name in new_teams
                try await SupabaseManager.shared.assignMentorToTeam(
                    teamId: team.id,
                    mentorId: mentorId
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let team = teams[indexPath.row]
        let detailVC = TeamDetailViewController(team: SupabaseManager.TeamWithDetails(
            id: team.id,
            teamNo: team.teamNo,
            mentorId: team.mentorId,
            mentorName: team.mentorName,
            problemStatement: team.problemStatement,
            memberNames: team.memberNames,
            memberCount: team.memberCount
        ))
        detailVC.modalPresentationStyle = .pageSheet

        if let sheet = detailVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
            sheet.preferredCornerRadius = 24
        }

        present(detailVC, animated: true)
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
        
        AdminUIStyle.styleCard(containerView, cornerRadius: 20)
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
        assignMentorButton.setTitleColor(.white, for: .normal)
        assignMentorButton.backgroundColor = AdminUIStyle.accentColor
        assignMentorButton.layer.cornerRadius = 12
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
            
            teamNumberLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            teamNumberLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            
            assignMentorButton.centerYAnchor.constraint(equalTo: teamNumberLabel.centerYAnchor),
            assignMentorButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            assignMentorButton.heightAnchor.constraint(equalToConstant: 36),
            assignMentorButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 132),
            
            mentorLabel.topAnchor.constraint(equalTo: teamNumberLabel.bottomAnchor, constant: 4),
            mentorLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            mentorLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            
            membersLabel.topAnchor.constraint(equalTo: mentorLabel.bottomAnchor, constant: 12),
            membersLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            membersLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            
            membersStackView.topAnchor.constraint(equalTo: membersLabel.bottomAnchor, constant: 8),
            membersStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            membersStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            membersStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -18)
        ])
        
        applyTheme()
    }
    
    func configure(with team: TeamDisplayModel) {
        applyTheme()
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
    
    private func applyTheme() {
        AdminUIStyle.styleCard(containerView, cornerRadius: 20)
        teamNumberLabel.textColor = .label
        membersLabel.textColor = .label
        membersStackView.arrangedSubviews.compactMap { $0 as? UILabel }.forEach { label in
            label.textColor = label.text == "No members yet" ? .secondaryLabel : .label
        }
        assignMentorButton.setTitleColor(.white, for: .normal)
        assignMentorButton.backgroundColor = AppTheme.accent
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
    let problemStatement: String?
    let memberNames: [String]
    let memberCount: Int
}

struct ApprovedMentorForAssignment {
    let personId: String
    let fullName: String
    let email: String
}

private final class MentorAssignmentSheetViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let team: TeamDisplayModel
    private let mentors: [ApprovedMentorForAssignment]
    private let onSelectMentor: (ApprovedMentorForAssignment) -> Void
    private let onRemoveMentor: (() -> Void)?

    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    init(
        team: TeamDisplayModel,
        mentors: [ApprovedMentorForAssignment],
        onSelectMentor: @escaping (ApprovedMentorForAssignment) -> Void,
        onRemoveMentor: (() -> Void)?
    ) {
        self.team = team
        self.mentors = mentors
        self.onSelectMentor = onSelectMentor
        self.onRemoveMentor = onRemoveMentor
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        AdminUIStyle.styleScreenBackground(view)

        titleLabel.text = "Change Mentor"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        subtitleLabel.text = "Select a mentor for Team \(team.teamNo)"
        subtitleLabel.font = .systemFont(ofSize: 14, weight: .medium)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MentorOptionCell")

        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        onRemoveMentor == nil ? 1 : 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 { return mentors.count }
        return 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 { return mentors.isEmpty ? "No approved mentors available" : "Approved Mentors" }
        return "Current Assignment"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MentorOptionCell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        cell.backgroundColor = AppTheme.cardBackground
        cell.contentView.backgroundColor = AppTheme.cardBackground

        if indexPath.section == 0 {
            let mentor = mentors[indexPath.row]
            content.text = mentor.fullName
            content.secondaryText = mentor.email.isEmpty ? nil : mentor.email
            content.textProperties.color = .label
            content.secondaryTextProperties.color = .secondaryLabel
            cell.accessoryType = .disclosureIndicator
            cell.tintColor = AdminUIStyle.accentColor
        } else {
            content.text = "Remove Mentor"
            content.textProperties.color = .systemRed
            cell.accessoryType = .none
        }

        cell.contentConfiguration = content
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            let mentor = mentors[indexPath.row]
            dismiss(animated: true) {
                self.onSelectMentor(mentor)
            }
        } else {
            dismiss(animated: true) {
                self.onRemoveMentor?()
            }
        }
    }
}
