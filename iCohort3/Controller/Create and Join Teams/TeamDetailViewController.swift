//
//  TeamDetailViewController.swift
//  iCohort3
//
//  Created by user@51 on 21/02/26.

import UIKit

final class TeamDetailViewController: UIViewController {

    // MARK: - Data

    private let teamInfo: SupabaseManager.StudentTeamInfo

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
    private let teamBadge     = UILabel()   // "Team 3"
    private let fullPill      = UILabel()   // "✓ Full"
    private let grabberBar    = UIView()

    // Members card
    private let membersCard       = UIView()
    private let membersTitleLabel = UILabel()
    private let membersStack      = UIStackView()

    // Mentor card
    private let mentorCard       = UIView()
    private let mentorTitleLabel = UILabel()
    private let mentorValueLabel = UILabel()

    // MARK: - Init

    init(teamInfo: SupabaseManager.StudentTeamInfo) {
        self.teamInfo = teamInfo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("Use init(teamInfo:)")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.94, green: 0.95, blue: 0.96, alpha: 1)
        buildUI()
        populateStaticInfo()
        Task { await loadMemberDetails() }
    }

    // MARK: - Build UI

    private func buildUI() {
        // Grabber
        grabberBar.backgroundColor  = UIColor.systemGray4
        grabberBar.layer.cornerRadius = 2.5
        grabberBar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(grabberBar)

        // ScrollView
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)

        // Content stack
        contentStack.axis    = .vertical
        contentStack.spacing = 16
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            grabberBar.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            grabberBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            grabberBar.widthAnchor.constraint(equalToConstant: 36),
            grabberBar.heightAnchor.constraint(equalToConstant: 5),

            scrollView.topAnchor.constraint(equalTo: grabberBar.bottomAnchor, constant: 8),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -32),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])

        buildHeaderCard()
        buildMembersCard()
        buildMentorCard()

        contentStack.addArrangedSubview(headerCard)
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

        // Full pill
        fullPill.text            = "✓ Full"
        fullPill.font            = .systemFont(ofSize: 13, weight: .semibold)
        fullPill.textColor       = .systemGreen
        fullPill.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.13)
        fullPill.layer.cornerRadius = 10
        fullPill.layer.masksToBounds = true
        fullPill.textAlignment   = .center
        fullPill.translatesAutoresizingMaskIntoConstraints = false

        // Subtitle
        let sub = UILabel()
        sub.text      = "3 / 3 members"
        sub.font      = .systemFont(ofSize: 14, weight: .regular)
        sub.textColor = .secondaryLabel
        sub.translatesAutoresizingMaskIntoConstraints = false

        headerCard.addSubview(teamBadge)
        headerCard.addSubview(fullPill)
        headerCard.addSubview(sub)

        NSLayoutConstraint.activate([
            teamBadge.topAnchor.constraint(equalTo: headerCard.topAnchor, constant: 20),
            teamBadge.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),

            fullPill.centerYAnchor.constraint(equalTo: teamBadge.centerYAnchor),
            fullPill.leadingAnchor.constraint(equalTo: teamBadge.trailingAnchor, constant: 12),
            fullPill.widthAnchor.constraint(equalToConstant: 68),
            fullPill.heightAnchor.constraint(equalToConstant: 26),

            sub.topAnchor.constraint(equalTo: teamBadge.bottomAnchor, constant: 4),
            sub.leadingAnchor.constraint(equalTo: headerCard.leadingAnchor, constant: 20),
            sub.bottomAnchor.constraint(equalTo: headerCard.bottomAnchor, constant: -20)
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
        teamBadge.text = "Team \(teamInfo.teamNumber)"

        // Mentor
        if let mentor = teamInfo.mentorName, !mentor.isEmpty {
            mentorValueLabel.text      = mentor
            mentorValueLabel.textColor = .label
        } else {
            mentorValueLabel.text      = "Not assigned yet"
            mentorValueLabel.textColor = .tertiaryLabel
        }
    }

    // MARK: - Load Member Names from new_teams

    private func loadMemberDetails() async {
        guard let personId = UserDefaults.standard.string(forKey: "current_person_id"),
              !personId.isEmpty else { return }

        // Fetch full team row so we have all member IDs + names
        guard let adminRow = try? await SupabaseManager.shared.fetchAdminTeamRowForUser(userId: personId) else {
            // Fallback — show team number only
            await MainActor.run { self.showFallbackMembers() }
            return
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
        card.backgroundColor      = .white
        card.layer.cornerRadius   = 16
        card.layer.masksToBounds  = true
        card.translatesAutoresizingMaskIntoConstraints = false
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
