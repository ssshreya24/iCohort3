//
//  TeamDetailViewController.swift
//  iCohort3
//
//  Created by user@51 on 21/02/26.

import UIKit

final class TeamDetailViewController: UIViewController {

    struct ViewModel {
        let teamId: String
        let teamNumber: Int
        let mentorName: String?
        let problemStatement: String?
        let memberCount: Int
        let isCreator: Bool
        let isEditable: Bool
    }

    // MARK: - Data

    private var viewModel: ViewModel

    // Full member rows fetched from new_teams
    private var memberRows: [MemberRow] = []

    struct MemberRow {
        let name: String
        let role: String        // "Team Admin" or "Member"
        let regNo: String
        let dept: String
    }

    // MARK: - UI

    private let scrollView   = UIScrollView()
    private let contentStack = UIStackView()

    // Header card
    private let headerCard    = UIView()
    private let teamBadge     = UILabel()
    private let memberCountLabel = UILabel()
    private let teamOptionsButton = UIButton(type: .system)

    // Members card
    private let membersCard       = UIView()
    private let membersTitleLabel = UILabel()
    private let membersStack      = UIStackView()

    // Mentor card
    private let mentorCard       = UIView()
    private let mentorTitleLabel = UILabel()
    private let mentorValueLabel = UILabel()

    // Problem statement card
    private let problemCard = UIView()
    private let problemTitleLabel = UILabel()
    private let problemTextView = UITextView()
    private let saveProblemButton = UIButton(type: .system)
    private let problemPlaceholderLabel = UILabel()
    private var saveProblemButtonHeightConstraint: NSLayoutConstraint?
    private var isEditingProblemStatement = false

    // MARK: - Init

    init(teamInfo: SupabaseManager.StudentTeamInfo) {
        self.viewModel = ViewModel(
            teamId: teamInfo.teamId,
            teamNumber: teamInfo.teamNumber,
            mentorName: teamInfo.mentorName,
            problemStatement: teamInfo.problemStatement,
            memberCount: teamInfo.memberCount,
            isCreator: teamInfo.isCreator,
            isEditable: true
        )
        super.init(nibName: nil, bundle: nil)
    }

    init(team: SupabaseManager.TeamWithDetails) {
        self.viewModel = ViewModel(
            teamId: team.id,
            teamNumber: team.teamNo,
            mentorName: team.mentorName,
            problemStatement: team.problemStatement,
            memberCount: team.memberCount,
            isCreator: false,
            isEditable: false
        )
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(teamInfo:)")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        buildUI()
        populateStaticInfo()
        Task { await loadMemberDetails() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }

    // MARK: - Build UI

    private func buildUI() {
        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.backgroundColor = .clear
        view.addSubview(scrollView)

        // Content stack
        contentStack.axis    = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 18),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        buildHeaderCard()
        buildProblemCard()
        buildMembersCard()
        buildMentorCard()

        contentStack.addArrangedSubview(headerCard)
        contentStack.addArrangedSubview(problemCard)
        contentStack.addArrangedSubview(membersCard)
        contentStack.addArrangedSubview(mentorCard)
    }

    // ── Header card ──────────────────────────────────────────────────────────

    private func buildHeaderCard() {
        styleCard(headerCard)

        // Team number
        teamBadge.font      = .systemFont(ofSize: 34, weight: .bold)
        teamBadge.textColor = .label
        teamBadge.translatesAutoresizingMaskIntoConstraints = false

        memberCountLabel.font      = .systemFont(ofSize: 15, weight: .medium)
        memberCountLabel.textColor = .secondaryLabel
        memberCountLabel.translatesAutoresizingMaskIntoConstraints = false

        teamOptionsButton.tintColor = UIColor(red: 0x77/255.0, green: 0x9C/255.0, blue: 0xB3/255.0, alpha: 1)
        teamOptionsButton.backgroundColor = .clear
        teamOptionsButton.layer.cornerRadius = 0
        teamOptionsButton.setImage(UIImage(systemName: "info.circle"), for: .normal)
        teamOptionsButton.translatesAutoresizingMaskIntoConstraints = false

        headerCard.addSubview(teamBadge)
        headerCard.addSubview(memberCountLabel)
        headerCard.addSubview(teamOptionsButton)

        NSLayoutConstraint.activate([
            teamBadge.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 20),
            teamBadge.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            teamBadge.trailingAnchor.constraint(lessThanOrEqualTo: teamOptionsButton.leadingAnchor, constant: -12),

            teamOptionsButton.centerYAnchor.constraint(equalTo: teamBadge.centerYAnchor),
            teamOptionsButton.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20),
            teamOptionsButton.widthAnchor.constraint(equalToConstant: 32),
            teamOptionsButton.heightAnchor.constraint(equalToConstant: 32),

            memberCountLabel.topAnchor.constraint(equalTo: teamBadge.bottomAnchor, constant: 6),
            memberCountLabel.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            memberCountLabel.trailingAnchor.constraint(equalTo: headerCard.trailingAnchor, constant: -20),
            memberCountLabel.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -20)
        ])
    }

    private func buildProblemCard() {
        styleCard(problemCard)

        problemTitleLabel.text = "Problem Statement"
        problemTitleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        problemTitleLabel.textColor = .secondaryLabel
        problemTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        problemTextView.font = .systemFont(ofSize: 15, weight: .regular)
        problemTextView.textColor = .label
        problemTextView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.55)
        problemTextView.layer.cornerRadius = 14
        problemTextView.textContainerInset = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        problemTextView.isScrollEnabled = false
        problemTextView.delegate = self
        problemTextView.translatesAutoresizingMaskIntoConstraints = false

        problemPlaceholderLabel.font = .systemFont(ofSize: 15, weight: .regular)
        problemPlaceholderLabel.textColor = .tertiaryLabel
        problemPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = false

        saveProblemButton.setTitle("Save", for: .normal)
        saveProblemButton.setTitleColor(.white, for: .normal)
        saveProblemButton.backgroundColor = UIColor(red: 0x77/255.0, green: 0x9C/255.0, blue: 0xB3/255.0, alpha: 1)
        saveProblemButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        saveProblemButton.layer.cornerRadius = 12
        saveProblemButton.addTarget(self, action: #selector(saveProblemStatementTapped), for: .touchUpInside)
        saveProblemButton.translatesAutoresizingMaskIntoConstraints = false

        problemCard.addSubview(problemTitleLabel)
        problemCard.addSubview(problemTextView)
        problemTextView.addSubview(problemPlaceholderLabel)
        problemCard.addSubview(saveProblemButton)

        let saveHeightConstraint = saveProblemButton.heightAnchor.constraint(equalToConstant: 46)
        saveProblemButtonHeightConstraint = saveHeightConstraint

        NSLayoutConstraint.activate([
            problemTitleLabel.topAnchor.constraint(equalTo: problemCard.topAnchor, constant: 16),
            problemTitleLabel.leadingAnchor.constraint(equalTo: problemCard.leadingAnchor, constant: 20),
            problemTitleLabel.trailingAnchor.constraint(equalTo: problemCard.trailingAnchor, constant: -20),

            problemTextView.topAnchor.constraint(equalTo: problemTitleLabel.bottomAnchor, constant: 10),
            problemTextView.leadingAnchor.constraint(equalTo: problemCard.leadingAnchor, constant: 20),
            problemTextView.trailingAnchor.constraint(equalTo: problemCard.trailingAnchor, constant: -20),
            problemTextView.heightAnchor.constraint(greaterThanOrEqualToConstant: 112),

            problemPlaceholderLabel.topAnchor.constraint(equalTo: problemTextView.topAnchor, constant: 14),
            problemPlaceholderLabel.leadingAnchor.constraint(equalTo: problemTextView.leadingAnchor, constant: 17),
            problemPlaceholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: problemTextView.trailingAnchor, constant: -17),

            saveProblemButton.topAnchor.constraint(equalTo: problemTextView.bottomAnchor, constant: 12),
            saveProblemButton.leadingAnchor.constraint(equalTo: problemCard.leadingAnchor, constant: 20),
            saveProblemButton.trailingAnchor.constraint(equalTo: problemCard.trailingAnchor, constant: -20),
            saveHeightConstraint,
            saveProblemButton.bottomAnchor.constraint(equalTo: problemCard.bottomAnchor, constant: -18)
        ])
    }

    // ── Members card ─────────────────────────────────────────────────────────

    private func buildMembersCard() {
        styleCard(membersCard)

        membersTitleLabel.text      = "Members"
        membersTitleLabel.font      = .systemFont(ofSize: 13, weight: .semibold)
        membersTitleLabel.textColor = .secondaryLabel
        membersTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        membersStack.axis    = .vertical
        membersStack.spacing = 0
        membersStack.translatesAutoresizingMaskIntoConstraints = false

        membersCard.addSubview(membersTitleLabel)
        membersCard.addSubview(membersStack)

        NSLayoutConstraint.activate([
            membersTitleLabel.topAnchor.constraint(equalTo: membersCard.topAnchor, constant: 16),
            membersTitleLabel.leadingAnchor.constraint(equalTo: membersCard.leadingAnchor, constant: 20),
            membersTitleLabel.trailingAnchor.constraint(equalTo: membersCard.trailingAnchor, constant: -20),

            membersStack.topAnchor.constraint(equalTo: membersTitleLabel.bottomAnchor, constant: 10),
            membersStack.leadingAnchor.constraint(equalTo: membersCard.leadingAnchor),
            membersStack.trailingAnchor.constraint(equalTo: membersCard.trailingAnchor),
            membersStack.bottomAnchor.constraint(equalTo: membersCard.bottomAnchor, constant: -4)
        ])
    }

    // ── Mentor card ──────────────────────────────────────────────────────────

    private func buildMentorCard() {
        styleCard(mentorCard)

        mentorTitleLabel.text      = "Mentor"
        mentorTitleLabel.font      = .systemFont(ofSize: 13, weight: .semibold)
        mentorTitleLabel.textColor = .secondaryLabel
        mentorTitleLabel.translatesAutoresizingMaskIntoConstraints = false

        mentorValueLabel.font      = .systemFont(ofSize: 16, weight: .medium)
        mentorValueLabel.textColor = .label
        mentorValueLabel.numberOfLines = 1
        mentorValueLabel.translatesAutoresizingMaskIntoConstraints = false

        mentorCard.addSubview(mentorTitleLabel)
        mentorCard.addSubview(mentorValueLabel)

        NSLayoutConstraint.activate([
            mentorTitleLabel.topAnchor.constraint(equalTo: mentorCard.topAnchor, constant: 16),
            mentorTitleLabel.leadingAnchor.constraint(equalTo: mentorCard.leadingAnchor, constant: 20),
            mentorTitleLabel.trailingAnchor.constraint(equalTo: mentorCard.trailingAnchor, constant: -20),

            mentorValueLabel.topAnchor.constraint(equalTo: mentorTitleLabel.bottomAnchor, constant: 6),
            mentorValueLabel.leadingAnchor.constraint(equalTo: mentorCard.leadingAnchor, constant: 20),
            mentorValueLabel.trailingAnchor.constraint(equalTo: mentorCard.trailingAnchor, constant: -20),
            mentorValueLabel.bottomAnchor.constraint(equalTo: mentorCard.bottomAnchor, constant: -16)
        ])
    }

    // MARK: - Populate Static Info (from teamInfo)

    private func populateStaticInfo() {
        teamBadge.text = "Team \(viewModel.teamNumber)"
        memberCountLabel.text = "\(viewModel.memberCount) / 3 members"

        // Mentor
        if let mentor = viewModel.mentorName, !mentor.isEmpty {
            mentorValueLabel.text      = mentor
            mentorValueLabel.textColor = .label
        } else {
            mentorValueLabel.text      = "Not assigned yet"
            mentorValueLabel.textColor = .tertiaryLabel
        }

        problemTextView.text = viewModel.problemStatement
        problemPlaceholderLabel.text = viewModel.isEditable ? "Add your team problem statement" : "No problem statement added yet"
        let hasProblemStatement = !(viewModel.problemStatement?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        problemPlaceholderLabel.isHidden = hasProblemStatement || isEditingProblemStatement
        let shouldAllowEditing = viewModel.isEditable && (!hasProblemStatement || isEditingProblemStatement)
        problemTextView.isEditable = shouldAllowEditing
        saveProblemButton.isHidden = !shouldAllowEditing
        saveProblemButtonHeightConstraint?.constant = shouldAllowEditing ? 46 : 0
        teamOptionsButton.isHidden = !viewModel.isEditable
        configureTeamOptionsMenu()
    }

    // MARK: - Load Member Names from new_teams

    private func loadMemberDetails() async {
        guard let adminRow = try? await SupabaseManager.shared.fetchAdminTeamRow(teamId: viewModel.teamId) else {
            // Fallback — show team number only
            await MainActor.run { self.showFallbackMembers() }
            return
        }

        await MainActor.run {
            self.viewModel = ViewModel(
                teamId: adminRow.id,
                teamNumber: adminRow.team_number,
                mentorName: adminRow.mentor_name,
                problemStatement: adminRow.problem_statement,
                memberCount: [adminRow.created_by_id, adminRow.member2_id, adminRow.member3_id].compactMap { $0 }.count,
                isCreator: self.viewModel.isCreator,
                isEditable: self.viewModel.isEditable
            )
            self.populateStaticInfo()
        }

        var rows: [MemberRow] = []

        // Helper: resolve display name from picker info or fall back to stored name
        func resolvedName(personId: String, storedName: String) async -> (name: String, reg: String, dept: String) {
            if let info = try? await SupabaseManager.shared.fetchStudentPickerInfo(personId: personId) {
                return (info.displayName, info.reg_no ?? "", info.department ?? "")
            }
            return (storedName, "", "")
        }

        // Creator — always present
        let creator = await resolvedName(personId: adminRow.created_by_id,
                                         storedName: adminRow.created_by_name)
        rows.append(MemberRow(name: creator.name, role: "Team Admin",
                              regNo: creator.reg, dept: creator.dept))

        // Member 2
        if let id2 = adminRow.member2_id {
            let m2 = await resolvedName(personId: id2,
                                        storedName: adminRow.member2_name ?? "Member")
            rows.append(MemberRow(name: m2.name, role: "Member",
                                  regNo: m2.reg, dept: m2.dept))
        }

        // Member 3
        if let id3 = adminRow.member3_id {
            let m3 = await resolvedName(personId: id3,
                                        storedName: adminRow.member3_name ?? "Member")
            rows.append(MemberRow(name: m3.name, role: "Member",
                                  regNo: m3.reg, dept: m3.dept))
        }

        memberRows = rows

        await MainActor.run { self.renderMemberRows() }
    }

    private func renderMemberRows() {
        membersStack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for (i, row) in memberRows.enumerated() {
            let rowView = makeMemberRowView(row, showDivider: i < memberRows.count - 1)
            membersStack.addArrangedSubview(rowView)
        }
    }

    private func showFallbackMembers() {
        membersStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let lbl = UILabel()
        lbl.text      = "Could not load member details."
        lbl.font      = .systemFont(ofSize: 14)
        lbl.textColor = .secondaryLabel
        lbl.textAlignment = .center
        membersStack.addArrangedSubview(lbl)
    }

    // MARK: - Member Row View

    private func makeMemberRowView(_ row: MemberRow, showDivider: Bool) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        // ── Avatar ───────────────────────────────────────────────────────────
        let avatarSize: CGFloat = 40
        let avatar = UIView()
        avatar.translatesAutoresizingMaskIntoConstraints = false
        avatar.backgroundColor    = avatarColor(for: row.name)
        avatar.layer.cornerRadius = avatarSize / 2
        avatar.clipsToBounds      = true

        let initial = UILabel()
        initial.text          = String(row.name.prefix(1).uppercased())
        initial.font          = .systemFont(ofSize: 16, weight: .bold)
        initial.textColor     = avatarTextColor(for: row.name)
        initial.textAlignment = .center
        initial.translatesAutoresizingMaskIntoConstraints = false
        avatar.addSubview(initial)

        // ── Name ─────────────────────────────────────────────────────────────
        let nameLabel = UILabel()
        nameLabel.text      = row.name
        nameLabel.font      = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.setContentHuggingPriority(.required, for: .vertical)

        // ── Role pill (intrinsic width only) ──────────────────────────────────
        let rolePill = makePill(
            text: row.role,
            color: row.role == "Team Admin" ? .systemBlue : UIColor.systemGray2
        )
        // Do NOT stretch pill — hug its content
        rolePill.setContentHuggingPriority(.required, for: .horizontal)
        rolePill.setContentCompressionResistancePriority(.required, for: .horizontal)

        // ── Reg label ─────────────────────────────────────────────────────────
        let regLabel = UILabel()
        regLabel.text      = row.regNo.isEmpty ? "" : row.regNo
        regLabel.font      = .systemFont(ofSize: 12, weight: .regular)
        regLabel.textColor = .secondaryLabel
        regLabel.setContentHuggingPriority(.required, for: .horizontal)

        // ── Sub-row: pill + reg + spacer ──────────────────────────────────────
        // Using a spacer view at the end prevents the stack from stretching pill
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        var subItems: [UIView] = [rolePill]
        if !row.regNo.isEmpty { subItems.append(regLabel) }
        subItems.append(spacer)

        let subRow = UIStackView(arrangedSubviews: subItems)
        subRow.axis      = .horizontal
        subRow.spacing   = 8
        subRow.alignment = .center
        subRow.setContentHuggingPriority(.required, for: .vertical)

        // ── Text stack ────────────────────────────────────────────────────────
        let textStack = UIStackView(arrangedSubviews: [nameLabel, subRow])
        textStack.axis    = .vertical
        textStack.spacing = 4
        textStack.alignment = .fill   // subRow fills width — spacer absorbs extra
        textStack.translatesAutoresizingMaskIntoConstraints = false

        // ── Divider ───────────────────────────────────────────────────────────
        let divider = UIView()
        divider.backgroundColor = UIColor.separator
        divider.translatesAutoresizingMaskIntoConstraints = false
        divider.isHidden = !showDivider

        container.addSubview(avatar)
        container.addSubview(textStack)
        container.addSubview(divider)

        NSLayoutConstraint.activate([
            // Row height
            container.heightAnchor.constraint(greaterThanOrEqualToConstant: 60),

            // Initial inside avatar
            initial.centerXAnchor.constraint(equalTo: avatar.centerXAnchor),
            initial.centerYAnchor.constraint(equalTo: avatar.centerYAnchor),

            // Avatar — fixed size, vertically centred
            avatar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            avatar.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: avatarSize),
            avatar.heightAnchor.constraint(equalToConstant: avatarSize),

            // Text stack — next to avatar, fills remaining width
            textStack.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            // Divider — hairline at bottom, inset from leading avatar
            divider.leadingAnchor.constraint(equalTo: avatar.leadingAnchor),
            divider.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            divider.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            divider.heightAnchor.constraint(equalToConstant: 0.5)
        ])

        return container
    }

    private func makePill(text: String, color: UIColor) -> UIView {
        let bg = UIView()
        bg.translatesAutoresizingMaskIntoConstraints = false
        bg.backgroundColor    = color.withAlphaComponent(0.12)
        bg.layer.cornerRadius = 8
        bg.clipsToBounds      = true

        let lbl = UILabel()
        lbl.text      = text
        lbl.font      = .systemFont(ofSize: 11, weight: .semibold)
        lbl.textColor = color
        lbl.translatesAutoresizingMaskIntoConstraints = false
        bg.addSubview(lbl)

        // Pill sizes itself to label — no stretching
        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: bg.topAnchor, constant: 4),
            lbl.bottomAnchor.constraint(equalTo: bg.bottomAnchor, constant: -4),
            lbl.leadingAnchor.constraint(equalTo: bg.leadingAnchor, constant: 9),
            lbl.trailingAnchor.constraint(equalTo: bg.trailingAnchor, constant: -9)
        ])
        return bg
    }

    // MARK: - Helpers

    private func styleCard(_ card: UIView) {
        AppTheme.styleElevatedCard(card, cornerRadius: 16)
        card.translatesAutoresizingMaskIntoConstraints = false
    }

    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        view.tintColor = AppTheme.accent
        scrollView.backgroundColor = .clear
        contentStack.backgroundColor = .clear
        problemTextView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(
            traitCollection.userInterfaceStyle == .dark ? 0.72 : 0.9
        )
    }

    @objc private func saveProblemStatementTapped() {
        let text = problemTextView.text ?? ""

        Task {
            do {
                guard let teamId = UUID(uuidString: viewModel.teamId) else { return }
                try await SupabaseManager.shared.updateTeamProblemStatement(teamId: teamId, problemStatement: text)
                await MainActor.run {
                    self.isEditingProblemStatement = false
                    self.viewModel = ViewModel(
                        teamId: self.viewModel.teamId,
                        teamNumber: self.viewModel.teamNumber,
                        mentorName: self.viewModel.mentorName,
                        problemStatement: text,
                        memberCount: self.viewModel.memberCount,
                        isCreator: self.viewModel.isCreator,
                        isEditable: self.viewModel.isEditable
                    )
                    self.populateStaticInfo()
                    self.showAlert(title: "Saved", message: "Problem statement updated.")
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func configureTeamOptionsMenu() {
        guard viewModel.isEditable else {
            teamOptionsButton.menu = nil
            return
        }

        let hasProblemStatement = !(viewModel.problemStatement?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
        var actions: [UIAction] = []

        if hasProblemStatement {
            let editAction = UIAction(
                title: "Edit Problem Statement",
                image: UIImage(systemName: "pencil")
            ) { [weak self] _ in
                guard let self else { return }
                self.isEditingProblemStatement = true
                self.populateStaticInfo()
                self.problemTextView.becomeFirstResponder()
            }
            actions.append(editAction)
        }

        let destructiveAction = UIAction(
            title: viewModel.isCreator ? "Delete Team" : "Leave Team",
            image: UIImage(systemName: viewModel.isCreator ? "trash" : "rectangle.portrait.and.arrow.right"),
            attributes: .destructive
        ) { [weak self] _ in
            guard let self else { return }
            self.viewModel.isCreator ? self.presentDeleteTeamAlert() : self.presentLeaveTeamAlert()
        }
        actions.append(destructiveAction)

        teamOptionsButton.showsMenuAsPrimaryAction = true
        teamOptionsButton.menu = UIMenu(title: "Team Actions", children: actions)
    }

    private func presentDeleteTeamAlert() {
        let alert = UIAlertController(title: "Delete Team?", message: "This will permanently delete the team.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            Task {
                do {
                    guard let teamId = UUID(uuidString: self.viewModel.teamId),
                          let personId = UserDefaults.standard.string(forKey: "current_person_id") else { return }
                    try await SupabaseManager.shared.deleteTeam(teamId: teamId, creatorId: personId)
                    await MainActor.run {
                        self.dismiss(animated: true)
                    }
                } catch {
                    await MainActor.run {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func presentLeaveTeamAlert() {
        let alert = UIAlertController(title: "Leave Team?", message: "You will be removed from this team.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            Task {
                do {
                    guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
                          let team = try await SupabaseManager.shared.fetchActiveTeamForUser(userId: personId) else { return }
                    try await SupabaseManager.shared.leaveTeam(team: team, userId: personId)
                    await MainActor.run {
                        self.dismiss(animated: true)
                    }
                } catch {
                    await MainActor.run {
                        self.showAlert(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func avatarColor(for name: String) -> UIColor {
        let palette: [UIColor] = [
            UIColor.systemBlue.withAlphaComponent(0.15),
            UIColor.systemPurple.withAlphaComponent(0.15),
            UIColor.systemOrange.withAlphaComponent(0.15),
            UIColor.systemGreen.withAlphaComponent(0.15),
            UIColor.systemPink.withAlphaComponent(0.15),
            UIColor.systemTeal.withAlphaComponent(0.15)
        ]
        return palette[abs(name.hashValue) % palette.count]
    }

    private func avatarTextColor(for name: String) -> UIColor {
        let palette: [UIColor] = [.systemBlue, .systemPurple, .systemOrange,
                                   .systemGreen, .systemPink, .systemTeal]
        return palette[abs(name.hashValue) % palette.count]
    }
}

extension TeamDetailViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        problemPlaceholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
