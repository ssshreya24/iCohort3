import UIKit
import Supabase

enum TeamStartMode {
    case create
    case join
}

final class TeamViewController: UIViewController {

    private enum TeamCacheKeys {
        static let currentTeamId = "current_team_id"
        static let currentTeamNumber = "current_team_number"
    }

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!

    enum Section: Int, CaseIterable {
        case summary
        case members
        case createCTA
        case requestSwitcher
        case search
        case requests
    }

    var startMode: TeamStartMode = .create
    /// 0 = Send Invites, 1 = Received Invites, 2 = Join a Team
    private var requestSegment: Int = 0

    private var currentTeam: SupabaseManager.NewTeamRow?

    // Identity
    private var myUserId: String = ""   // people.id (person_id uuidString)
    private var myName: String = "Student"

    // fetched from public.student_profile_complete
    private var myRegNo: String = ""
    private var myDept: String = ""

    // ✅ Member info with names
    private var memberInfos: [MemberInfo] = []
    
    struct MemberInfo {
        let personId: String
        let name: String
        let regNo: String
        let dept: String
        let slot: MemberSlot
    }

    // ✅ Send Requests tab = student list
    private var eligibleStudents: [SupabaseManager.StudentPickerRow] = []

    // ✅ Used only to enforce max-2 invites
    private var sentInvites: [SupabaseManager.TeamInviteRow] = []

    // ✅ Received Requests tab = received invites
    enum ReceivedItem {
        case invite(SupabaseManager.TeamInviteRow)
        case joinRequest(SupabaseManager.TeamJoinRequestRow)
    }
    private var receivedItems: [ReceivedItem] = []
    
    // ✅ Join a Team tab = other teams to join
    private var availableTeams: [(team: SupabaseManager.NewTeamRow, creator: SupabaseManager.StudentPickerRow)] = []
    private var sentJoinRequests: [SupabaseManager.TeamJoinRequestRow] = []
    private var incomingJoinRequests: [SupabaseManager.TeamJoinRequestRow] = []
    private var mySrmMail: String = ""

    private var searchQuery: String = ""

    private var filteredEligibleStudents: [SupabaseManager.StudentPickerRow] {
        if searchQuery.isEmpty { return eligibleStudents }
        return eligibleStudents.filter { $0.displayName.lowercased().contains(searchQuery.lowercased()) }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        setupTitle()
        setupCollection()
        setupCloseButton()
        setupOptionsButton()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleTeamMembershipDidChange),
            name: .teamMembershipDidChange,
            object: nil
        )
        Task { await bootstrapIdentityAndLoad() }
    }

    /// Finds the xmark close button from XIB and wires it to dismiss
    private func setupCloseButton() {
        // The XIB close button is a direct subview of the main view
        for subview in view.subviews {
            if let btn = subview as? UIButton {
                // It's the only UIButton that is not the collectionView or titleLabel
                btn.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
                // Style it properly
                AppTheme.styleFloatingControl(btn, cornerRadius: btn.bounds.height / 2)
                btn.tintColor = .label
                break
            }
        }
    }

    @objc private func didTapClose() {
        dismiss(animated: true)
    }

    /// Adds a top-right options button since there is no UINavigationBar
    private func setupOptionsButton() {
        let btn = UIButton(type: .system)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.setImage(UIImage(systemName: "ellipsis"), for: .normal)
        btn.addTarget(self, action: #selector(didTapOptions), for: .touchUpInside)
        
        AppTheme.styleFloatingControl(btn, cornerRadius: 22) // 44/2
        btn.tintColor = .label
        
        view.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            btn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -31),
            btn.widthAnchor.constraint(equalToConstant: 44),
            btn.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func didTapOptions() {
        let sheet = UIAlertController(title: "Team Options", message: nil, preferredStyle: .actionSheet)
        
        if let team = currentTeam {
            if team.createdById == myUserId {
                sheet.addAction(UIAlertAction(title: "Delete Team", style: .destructive) { [weak self] _ in
                    self?.didTapDeleteTeam()
                })
            } else {
                sheet.addAction(UIAlertAction(title: "Leave Team", style: .destructive) { [weak self] _ in
                    self?.didTapLeaveTeam()
                })
            }
        } else {
            sheet.addAction(UIAlertAction(title: "Create Team", style: .default) { [weak self] _ in
                self?.didTapCreateTeamAuth()
            })
        }
        
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.width - 40, y: 40, width: 1, height: 1)
        }
        
        present(sheet, animated: true)
    }

    // Wrapper to match selector if needed, or simply re-use existing
    @objc private func didTapCreateTeamAuth() {
        didTapCreateTeam()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        Task {
            await loadSendAndReceivedLists()
            // ✅ Refresh team data
            await loadExistingTeam(personIdString: myUserId)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
    }

    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
            collectionView.reloadData()
        }
    }

    private func setupTitle() {
        titleLabel.text = "My Team"
        titleLabel.textColor = .label
    }

    private func setupCollection() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.collectionViewLayout = makeLayout()

        collectionView.register(UINib(nibName: "TeamSummaryCell", bundle: nil),
                                forCellWithReuseIdentifier: "TeamSummaryCell")

        collectionView.register(MemberAvatarCell.self,
                                forCellWithReuseIdentifier: "MemberAvatarCell")

        collectionView.register(UINib(nibName: "RequestSwitcherCell", bundle: nil),
                                forCellWithReuseIdentifier: "RequestSwitcherCell")

        collectionView.register(RequestItemCell.self,
                                forCellWithReuseIdentifier: "RequestItemCell")

        collectionView.register(UICollectionViewCell.self,
                                forCellWithReuseIdentifier: "EmptyStateCell")
        
        collectionView.register(SearchCell.self,
                                forCellWithReuseIdentifier: "SearchCell")
        collectionView.register(CreateTeamCTACollectionViewCell.self,
                                forCellWithReuseIdentifier: "CreateTeamCTACollectionViewCell")
    }

    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        view.tintColor = AppTheme.accent
        collectionView?.backgroundColor = .clear
        titleLabel?.textColor = .label
        styleButtons(in: view)
    }

    private func reloadRequestSections() {
        let sections = IndexSet([
            Section.search.rawValue,
            Section.requests.rawValue
        ])

        UIView.performWithoutAnimation {
            collectionView.performBatchUpdates({
                collectionView.reloadSections(sections)
            })
        }
    }

    private func styleButtons(in root: UIView) {
        for subview in root.subviews {
            if let button = subview as? UIButton {
                AppTheme.styleFloatingControl(button, cornerRadius: 22)
                button.tintColor = .label
                button.setTitleColor(.label, for: .normal)
            }
            styleButtons(in: subview)
        }
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            guard let section = Section(rawValue: sectionIndex) else { return nil }

            switch section {
            case .summary:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(180))
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(180)),
                    subitems: [item]
                )
                let s = NSCollectionLayoutSection(group: group)
                s.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
                return s

            case .members:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0/3.0),
                                      heightDimension: .absolute(132))
                )
                item.contentInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8)

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .absolute(132)),
                    subitem: item,
                    count: 3
                )

                let s = NSCollectionLayoutSection(group: group)
                s.contentInsets = .init(top: 8, leading: 16, bottom: 8, trailing: 16)
                return s

            case .createCTA:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(52))
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(52)),
                    subitems: [item]
                )
                let s = NSCollectionLayoutSection(group: group)
                s.contentInsets = .init(top: 4, leading: 16, bottom: 4, trailing: 16)
                return s

            case .requestSwitcher:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(48))
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(48)),
                    subitems: [item]
                )
                let s = NSCollectionLayoutSection(group: group)
                s.contentInsets = .init(top: 12, leading: 16, bottom: 4, trailing: 16)
                return s

            case .search:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(50))
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(50)),
                    subitems: [item]
                )
                let s = NSCollectionLayoutSection(group: group)
                s.contentInsets = .init(top: 0, leading: 16, bottom: 8, trailing: 16)
                return s

            case .requests:
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(72))
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(72)),
                    subitems: [item]
                )
                let s = NSCollectionLayoutSection(group: group)
                s.interGroupSpacing = 8
                s.contentInsets = .init(top: 8, leading: 16, bottom: 32, trailing: 16)
                return s
            }
        }
    }

    // MARK: - Bootstrap Identity

    private func bootstrapIdentityAndLoad() async {

        if let storedPersonId = UserDefaults.standard.string(forKey: "current_person_id"),
           !storedPersonId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            myUserId = storedPersonId
            await loadAllForCurrentUser()
            return
        }

        do {
            let personId = try await SupabaseManager.shared.currentPersonId()
            myUserId = personId
            UserDefaults.standard.set(personId, forKey: "current_person_id")
            await loadAllForCurrentUser()
        } catch {
            await MainActor.run {
                self.showAlert(title: "Login Required", message: "Session missing. Please login again.")
            }
        }
    }

    private func loadAllForCurrentUser() async {
        print("🟦 [TeamVC] myUserId =", myUserId)

        myName = (try? await SupabaseManager.shared.fetchStudentFullName(personIdString: myUserId)) ?? "Student"
        print("🟦 [TeamVC] myName fetched =", myName)

        do {
            let mini = try await SupabaseManager.shared.fetchStudentMiniProfile(personIdString: myUserId)
            myRegNo = mini.reg_no ?? ""
            myDept  = mini.department ?? ""
            mySrmMail = mini.srm_mail ?? ""
            print("✅ [TeamVC] MiniProfile => reg:", myRegNo, "dept:", myDept)
        } catch {
            print("❌ [TeamVC] MiniProfile fetch FAILED:", error.localizedDescription)
        }

        await loadExistingTeam(personIdString: myUserId)
        await loadSendAndReceivedLists()

        await MainActor.run {
            self.collectionView.reloadData()
        }
    }

    // MARK: - Load Existing Team (no auto-create)

    private func loadExistingTeam(personIdString: String) async {
        do {
            if let team = try await SupabaseManager.shared.fetchActiveTeamForUser(userId: personIdString) {
                currentTeam = team
                print("✅ [TeamVC] Loaded existing team #\(team.teamNumber)")
                await loadTeamMemberInfo(team: team)
            } else {
                currentTeam = nil
                memberInfos = []
                print("ℹ️ [TeamVC] No team found — user can create or join")
                // Default to Join a Team tab when no team
                await MainActor.run { self.requestSegment = 2 }
            }

            await MainActor.run {
                self.applyTeamToUI()
                self.collectionView.reloadData()
            }
        } catch {
            print("❌ [TeamVC] loadExistingTeam error:", error.localizedDescription)
            await MainActor.run {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    // MARK: - Create Team (explicit user action)

    @objc private func didTapCreateTeam() {
        createTeamWithSize(3)
    }

    private func createTeamWithSize(_ maxMembers: Int) {
        Task {
            let loadingAlert = await MainActor.run {
                self.presentLoadingAlert(title: "Creating Team...")
            }
            do {
                let newTeam = try await SupabaseManager.shared.createTeamIfNone(
                    personIdString: myUserId,
                    fallbackUserName: myName,
                    maxMembers: maxMembers
                )
                currentTeam = newTeam
                print("✅ [TeamVC] Created new team #\(newTeam.teamNumber) with max \(maxMembers) members")
                await loadTeamMemberInfo(team: newTeam)
                await loadSendAndReceivedLists()

                await MainActor.run {
                    self.notifyTeamMembershipUpdated()
                    self.dismissLoadingAlert(loadingAlert)
                    self.requestSegment = 0  // Switch to Send Invites
                    self.applyTeamToUI()
                    self.collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.dismissLoadingAlert(loadingAlert)
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
    
    // ✅ Load team member info with names — dynamic based on maxMembers
    private func loadTeamMemberInfo(team: SupabaseManager.NewTeamRow) async {
        var infos: [MemberInfo] = []
        let maxSlots = team.maxMembers  // e.g. 2, 3, or 4
        let isCreator = team.createdById == myUserId

        // Creator (always slot 0)
        let initial = String(myName.prefix(1).uppercased())
        if isCreator {
            infos.append(MemberInfo(
                personId: myUserId,
                name: myName,
                regNo: myRegNo,
                dept: myDept,
                slot: .currentInitial(initial.isEmpty ? "S" : initial)
            ))
        } else {
            if let creatorInfo = try? await SupabaseManager.shared.fetchStudentPickerInfo(personId: team.createdById) {
                infos.append(MemberInfo(
                    personId: team.createdById,
                    name: creatorInfo.displayName,
                    regNo: creatorInfo.reg_no ?? "",
                    dept: creatorInfo.department ?? "",
                    slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())
                ))
            } else {
                infos.append(MemberInfo(
                    personId: team.createdById,
                    name: team.createdByName,
                    regNo: "",
                    dept: "",
                    slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())
                ))
            }
        }

        // Member 2
        if let member2Id = team.member2Id {
            if member2Id == myUserId {
                let i = String(myName.prefix(1).uppercased())
                infos.append(MemberInfo(personId: myUserId, name: myName, regNo: myRegNo, dept: myDept,
                                        slot: .currentInitial(i.isEmpty ? "S" : i)))
            } else if let info = try? await SupabaseManager.shared.fetchStudentPickerInfo(personId: member2Id) {
                infos.append(MemberInfo(personId: member2Id, name: info.displayName,
                                        regNo: info.reg_no ?? "", dept: info.department ?? "",
                                        slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())))
            } else {
                infos.append(MemberInfo(personId: member2Id, name: team.member2Name ?? "Member",
                                        regNo: "", dept: "",
                                        slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())))
            }
        } else if maxSlots >= 2 {
            infos.append(MemberInfo(personId: "", name: "", regNo: "", dept: "",
                                    slot: isCreator ? .addSlot : .empty))
        }

        // Member 3
        if maxSlots >= 3 {
            if let member3Id = team.member3Id {
                if member3Id == myUserId {
                    let i = String(myName.prefix(1).uppercased())
                    infos.append(MemberInfo(personId: myUserId, name: myName, regNo: myRegNo, dept: myDept,
                                            slot: .currentInitial(i.isEmpty ? "S" : i)))
                } else if let info = try? await SupabaseManager.shared.fetchStudentPickerInfo(personId: member3Id) {
                    infos.append(MemberInfo(personId: member3Id, name: info.displayName,
                                            regNo: info.reg_no ?? "", dept: info.department ?? "",
                                            slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())))
                } else {
                    infos.append(MemberInfo(personId: member3Id, name: team.member3Name ?? "Member",
                                            regNo: "", dept: "",
                                            slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())))
                }
            } else {
                infos.append(MemberInfo(personId: "", name: "", regNo: "", dept: "",
                                        slot: isCreator ? .addSlot : .empty))
            }
        }

        // Member 4 (only if maxSlots == 4, stored info is not in new_teams schema yet)
        // Show an add-slot placeholder when team supports 4 members
        if maxSlots >= 4 {
            infos.append(MemberInfo(personId: "", name: "", regNo: "", dept: "",
                                    slot: isCreator ? .addSlot : .empty))
        }

        memberInfos = infos
        print("✅ [TeamVC] Loaded \(infos.count) member infos (maxSlots=\(maxSlots))")
    }

    // MARK: - ✅ Send Requests = Student List | Received Requests = Invites

    private func loadSendAndReceivedLists() async {
        guard !myUserId.isEmpty else { return }

        do {
            print("🟦 [TeamVC] loadSendAndReceivedLists START")

            // 1) Students list for SEND tab
            let students = try await SupabaseManager.shared.fetchAllEligibleStudents()
            let activeTeams = try await SupabaseManager.shared.fetchAllActiveTeams()
            let occupiedMemberIds = Set(
                activeTeams.flatMap { team in
                    [team.createdById, team.member2Id, team.member3Id].compactMap { $0 }
                }
            )
            
            // ✅ Filter out self, current team members, and any student already in another active team
            var filtered = students.filter {
                $0.person_id != myUserId && !occupiedMemberIds.contains($0.person_id)
            }
            
            if let team = currentTeam {
                let teamMemberIds = [team.createdById, team.member2Id, team.member3Id].compactMap { $0 }
                filtered = filtered.filter { !teamMemberIds.contains($0.person_id) }
            }
            
            print("✅ [TeamVC] eligibleStudents =", filtered.count)

            // 2) Received invites & Join requests for RECEIVED tab
            let rInvites = try await SupabaseManager.shared.fetchReceivedInvites(toPersonId: myUserId)
            let rJoinReqs = try? await SupabaseManager.shared.fetchReceivedJoinRequests(toPersonId: myUserId)
            
            var combinedReceived: [ReceivedItem] = rInvites.map { .invite($0) }
            if let reqs = rJoinReqs {
                combinedReceived.append(contentsOf: reqs.map { .joinRequest($0) })
            }
            
            print("✅ [TeamVC] receivedItems =", combinedReceived.count)

            // 3) Sent invites (only for max-2 rule)
            if let team = currentTeam {
                let sent = try await SupabaseManager.shared.fetchSentInvites(fromPersonId: myUserId, teamId: team.id)
                print("✅ [TeamVC] sentInvites =", sent.count)
                await MainActor.run { self.sentInvites = sent }
            } else {
                await MainActor.run { self.sentInvites = [] }
            }

            // 4) Join a Team tab — load other teams and sent join requests
            let allTeams = try await SupabaseManager.shared.fetchAllActiveTeams()
            let myTeamId = currentTeam?.id
            let otherTeams = allTeams.filter { $0.id != myTeamId }
            
            var teamsWithCreators: [(team: SupabaseManager.NewTeamRow, creator: SupabaseManager.StudentPickerRow)] = []
            for team in otherTeams {
                if let creatorInfo = try? await SupabaseManager.shared.fetchStudentPickerInfo(personId: team.createdById) {
                    teamsWithCreators.append((team: team, creator: creatorInfo))
                }
            }
            
            let sentJoins = try await SupabaseManager.shared.fetchSentJoinRequests(fromPersonId: myUserId)
            print("✅ [TeamVC] availableTeams =", teamsWithCreators.count, "sentJoinRequests =", sentJoins.count)

            await MainActor.run {
                self.eligibleStudents = filtered
                self.receivedItems = combinedReceived
                self.availableTeams = teamsWithCreators
                self.sentJoinRequests = sentJoins
                self.collectionView.reloadData()
            }
        } catch {
            print("❌ [TeamVC] loadSendAndReceivedLists error:", error.localizedDescription)
            await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
        }
    }

    // MARK: - Send Invite (max 2)

    private func inviteStudent(_ student: SupabaseManager.StudentPickerRow) {
        guard let team = currentTeam else {
            showAlert(title: "No Team", message: "Create a team first.")
            return
        }

        // ✅ Max invites = maxMembers - 1 (excluding self)
        let maxInvites = (currentTeam?.maxMembers ?? 3) - 1
        if sentInvites.count >= maxInvites {
            showAlert(title: "Limit Reached", message: "You can invite maximum \(maxInvites) student(s).")
            return
        }

        print("📨 [TeamVC] inviteStudent:", student.displayName, "id:", student.person_id)

        Task {
            let loadingAlert = await MainActor.run {
                self.presentLoadingAlert(title: "Sending Request...")
            }
            do {
                try await SupabaseManager.shared.sendInviteToStudent(
                    teamId: team.id,
                    teamNumber: team.teamNumber,
                    fromPersonId: myUserId,
                    fromName: myName,
                    toPersonId: student.person_id,
                    toName: student.displayName
                )

                await loadSendAndReceivedLists()

                await MainActor.run {
                    self.dismissLoadingAlert(loadingAlert)
                    self.showAlert(title: "Invite Sent", message: "Invite sent to \(student.displayName)")
                }
            } catch {
                print("❌ [TeamVC] inviteStudent failed:", error.localizedDescription)
                
                var errorMessage = error.localizedDescription
                if errorMessage.contains("row-level security") || errorMessage.contains("RLS") {
                    errorMessage = "Permission denied. Please check your database RLS policies for team_member_invites table."
                }
                
                await MainActor.run {
                    self.dismissLoadingAlert(loadingAlert)
                    self.showAlert(title: "Invite Failed", message: errorMessage)
                }
            }
        }
    }

    // MARK: - Join a Team (send join request to another team)

    private func hasAlreadySentJoinRequest(to teamId: UUID) -> Bool {
        return sentJoinRequests.contains { $0.to_team_id == teamId }
    }

    private func sendJoinRequest(to teamInfo: (team: SupabaseManager.NewTeamRow, creator: SupabaseManager.StudentPickerRow)) {
        let team = teamInfo.team
        print("📨 [TeamVC] Sending join request to Team #\(team.teamNumber)")

        Task {
            let loadingAlert = await MainActor.run {
                self.presentLoadingAlert(title: "Sending Request...")
            }
            do {
                try await SupabaseManager.shared.sendTeamJoinRequest(
                    fromPersonId: myUserId,
                    fromName: myName,
                    fromRegNo: myRegNo,
                    fromDepartment: myDept,
                    fromSrmMail: mySrmMail,
                    toTeamId: team.id,
                    toTeamNumber: team.teamNumber,
                    toCreatedById: team.createdById
                )

                await loadSendAndReceivedLists()

                await MainActor.run {
                    self.dismissLoadingAlert(loadingAlert)
                    self.showAlert(title: "Request Sent", message: "Join request sent to Team #\(team.teamNumber) ✅")
                }
            } catch {
                print("❌ [TeamVC] sendJoinRequest error:", error.localizedDescription)

                var errorMessage = error.localizedDescription
                if errorMessage.contains("row-level security") || errorMessage.contains("RLS") {
                    errorMessage = "Permission denied. Please check your database RLS policies."
                } else if errorMessage.contains("duplicate") || errorMessage.contains("unique") {
                    errorMessage = "You've already sent a request to this team."
                }

                await MainActor.run {
                    self.dismissLoadingAlert(loadingAlert)
                    self.showAlert(title: "Error", message: errorMessage)
                }
            }
        }
    }

    // ✅ Accept Invite
    private func acceptIncomingInvite(_ invite: SupabaseManager.TeamInviteRow) async {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎯 [TeamVC] acceptIncomingInvite START")
        print("   Invite ID:", invite.id)
        print("   From:", invite.from_name)
        print("   To Team:", invite.team_number)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let shouldProceed = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Join Team #\(invite.team_number)?",
                    message: "You are about to join a new team. If you currently have your own empty team, it will be automatically deleted.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    continuation.resume(returning: false)
                })
                alert.addAction(UIAlertAction(title: "Join", style: .default) { _ in
                    continuation.resume(returning: true)
                })
                self.present(alert, animated: true)
            }
        }
        
        guard shouldProceed else {
            print("❌ User cancelled accept invite.")
            return
        }
        
        // Show loading
        let loadingAlert = UIAlertController(title: "Joining...", message: "\nPlease wait", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = CGPoint(x: 135, y: 65)
        spinner.startAnimating()
        loadingAlert.view.addSubview(spinner)
        
        await MainActor.run {
            present(loadingAlert, animated: true)
        }
        
        do {
            print("📡 Calling server: acceptInvite")
            
            try await SupabaseManager.shared.acceptInvite(
                inviteId: invite.id,
                receiverId: myUserId
            )
            
            print("✅ acceptInvite completed")
            
            await MainActor.run {
                loadingAlert.dismiss(animated: true)
            }
            
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            print("⏸️  Reloading...")
            await loadExistingTeam(personIdString: myUserId)
            await loadSendAndReceivedLists()
            print("✅ Reload complete")
            
            let redirected = await redirectToFullTeamDetailIfNeeded()

            await MainActor.run {
                self.notifyTeamMembershipUpdated()
                if !redirected {
                    self.showAlert(title: "Success", message: "You joined team #\(invite.team_number)! ✅")
                }
            }
            
            print("🎉 COMPLETE SUCCESS\n")
            
        } catch {
            print("❌ ERROR:", error)
            
            await MainActor.run {
                loadingAlert.dismiss(animated: true)
            }
            
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            var errorMessage = error.localizedDescription
            if errorMessage.contains("Team is full") {
                errorMessage = "This team is full (maximum 3 members)."
            }
            
            await MainActor.run {
                self.showAlert(title: "Error", message: errorMessage)
            }
        }
    }

    // ✅ Accept Join Request
    private func acceptIncomingJoinRequest(_ req: SupabaseManager.TeamJoinRequestRow) async {
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print("🎯 [TeamVC] acceptIncomingJoinRequest START")
        print("   Request ID:", req.id)
        print("   From:", req.from_name)
        print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        let shouldProceed = await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let alert = UIAlertController(
                    title: "Accept \(req.from_name)?",
                    message: "Add \(req.from_name) to your team?",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    continuation.resume(returning: false)
                })
                alert.addAction(UIAlertAction(title: "Accept", style: .default) { _ in
                    continuation.resume(returning: true)
                })
                self.present(alert, animated: true)
            }
        }
        
        guard shouldProceed else { return }
        
        let loadingAlert = UIAlertController(title: "Accepting...", message: "\nPlease wait", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.center = CGPoint(x: 135, y: 65)
        spinner.startAnimating()
        loadingAlert.view.addSubview(spinner)
        
        await MainActor.run { present(loadingAlert, animated: true) }
        
        do {
            try await SupabaseManager.shared.acceptTeamJoinRequest(
                requestId: req.id,
                receiverId: myUserId
            )
            
            await MainActor.run { loadingAlert.dismiss(animated: true) }
            try? await Task.sleep(nanoseconds: 300_000_000)
            
            await loadExistingTeam(personIdString: myUserId)
            await loadSendAndReceivedLists()
            
            let redirected = await redirectToFullTeamDetailIfNeeded()

            await MainActor.run {
                self.notifyTeamMembershipUpdated()
                if !redirected {
                    self.showAlert(title: "Success", message: "\(req.from_name) added to your team. ✅")
                }
            }
        } catch {
            await MainActor.run { loadingAlert.dismiss(animated: true) }
            try? await Task.sleep(nanoseconds: 300_000_000)
            await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
        }
    }

    // MARK: - UI

    private func applyTeamToUI() {
        // This is now handled by memberInfos loaded from loadTeamMemberInfo
    }

    @objc private func didTapDeleteTeam() {
        guard let team = currentTeam, team.createdById == myUserId else { return }

        let alert = UIAlertController(title: "Delete Team?",
                                      message: "This will permanently delete the team.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            Task { await self.deleteTeamFlow(teamId: team.id) }
        })
        present(alert, animated: true)
    }

    private func deleteTeamFlow(teamId: UUID) async {
        do {
            try await SupabaseManager.shared.deleteTeam(teamId: teamId, creatorId: myUserId)
            await MainActor.run {
                self.clearLocalStudentTeamCache()
            }
            currentTeam = nil
            memberInfos = []
            await MainActor.run {
                self.collectionView.reloadData()
                self.dismiss(animated: true)
            }
        } catch {
            await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
        }
    }

    @objc private func didTapLeaveTeam() {
        guard let team = currentTeam else { return }

        let alert = UIAlertController(
            title: "Leave Team?",
            message: "You will be removed from this team.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Leave", style: .destructive) { _ in
            Task { await self.leaveTeamFlow(team: team) }
        })

        present(alert, animated: true)
    }

    private func leaveTeamFlow(team: SupabaseManager.NewTeamRow) async {
        do {
            try await SupabaseManager.shared.leaveTeam(team: team, userId: myUserId)
            await MainActor.run {
                self.clearLocalStudentTeamCache()
            }
            currentTeam = try await SupabaseManager.shared.fetchActiveTeamForUser(userId: myUserId)
            
            if let updatedTeam = currentTeam {
                await loadTeamMemberInfo(team: updatedTeam)
            } else {
                memberInfos = []
            }
            
            await MainActor.run {
                self.collectionView.reloadData()
                self.collectionView.reloadData()
                self.dismiss(animated: true)
            }
        } catch {
            await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
        }
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    @MainActor
    private func presentLoadingAlert(title: String) -> UIAlertController {
        let loadingAlert = UIAlertController(title: title, message: "\nPlease wait", preferredStyle: .alert)
        let spinner = UIActivityIndicatorView(style: .large)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.startAnimating()
        loadingAlert.view.addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: loadingAlert.view.centerXAnchor),
            spinner.topAnchor.constraint(equalTo: loadingAlert.view.topAnchor, constant: 54)
        ])

        present(loadingAlert, animated: true)
        return loadingAlert
    }

    @MainActor
    private func dismissLoadingAlert(_ alert: UIAlertController?) {
        guard let alert else { return }
        alert.dismiss(animated: true)
    }

    private func clearLocalStudentTeamCache() {
        UserDefaults.standard.removeObject(forKey: TeamCacheKeys.currentTeamId)
        UserDefaults.standard.removeObject(forKey: TeamCacheKeys.currentTeamNumber)
        NotificationCenter.default.post(name: .tasksDidUpdate, object: nil)
        NotificationCenter.default.post(name: .teamMembershipDidChange, object: nil)
    }

    private func notifyTeamMembershipUpdated() {
        NotificationCenter.default.post(name: .tasksDidUpdate, object: nil)
        NotificationCenter.default.post(name: .teamMembershipDidChange, object: nil)
    }

    private func redirectToFullTeamDetailIfNeeded() async -> Bool {
        guard let teamInfo = try? await SupabaseManager.shared.fetchTeamInfoForStudent(personId: myUserId),
              teamInfo.isFull else {
            return false
        }

        await MainActor.run {
            let detailVC = TeamDetailViewController(teamInfo: teamInfo)

            if let presenter = self.presentingViewController {
                self.dismiss(animated: false) {
                    presenter.presentAsProfileSheet(detailVC)
                }
            } else {
                self.presentAsProfileSheet(detailVC)
            }
        }

        return true
    }

    @objc private func handleTeamMembershipDidChange() {
        if presentedViewController == nil {
            dismiss(animated: true)
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Collection Data Source

extension TeamViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        Section.allCases.count
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .summary:         return 1
        case .members:         return currentTeam?.maxMembers ?? 3
        case .createCTA:       return currentTeam == nil ? 1 : 0
        case .requestSwitcher: return 1
        case .search:          return requestSegment == 0 ? 1 : 0
        case .requests:
            switch requestSegment {
            case 0:  return max(1, filteredEligibleStudents.count)
            case 1:  return max(1, receivedItems.count)
            case 2:  return max(1, availableTeams.count)
            default: return 0
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let sec = Section(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }

        switch sec {

        case .summary:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeamSummaryCell", for: indexPath) as! TeamSummaryCell

            let title: String
            if let team = currentTeam {
                title = "Team \(team.teamNumber)"
            } else {
                title = "No Team Yet"
            }

            cell.configure(teamName: title,
                           icon: UIImage(systemName: "person.3.fill")?.withRenderingMode(.alwaysTemplate))

            cell.teamImageView.tintColor = UIColor(red: 0x77/255.0, green: 0x9C/255.0, blue: 0xB3/255.0, alpha: 1.0)

            cell.layoutIfNeeded()
            cell.circleView.layer.cornerRadius = cell.circleView.bounds.height / 2
            cell.circleView.layer.masksToBounds = true
            cell.circleView.backgroundColor = .white
            return cell

        case .members:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemberAvatarCell", for: indexPath) as! MemberAvatarCell

            guard indexPath.item < memberInfos.count else {
                // Empty slot
                cell.configure(
                    slot: .empty,
                    name: "",
                    regNo: "",
                    dept: "",
                    onTapAdd: {}
                )
                return cell
            }
            
            let memberInfo = memberInfos[indexPath.item]
            
            cell.configure(
                slot: memberInfo.slot,
                name: memberInfo.name,
                regNo: memberInfo.regNo,
                dept: memberInfo.dept,
                onTapAdd: {}
            )
            return cell

        case .createCTA:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "CreateTeamCTACollectionViewCell", for: indexPath) as! CreateTeamCTACollectionViewCell
            cell.configure(title: "Create Team") { [weak self] in
                self?.didTapCreateTeamAuth()
            }
            return cell

        case .requestSwitcher:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestSwitcherCell", for: indexPath) as! RequestSwitcherCell
            cell.configure(selectedIndex: requestSegment) { [weak self] index in
                guard let self else { return }
                self.requestSegment = index
                self.searchQuery = "" // Reset search when switching tabs
                self.reloadRequestSections()
            }
            return cell

        case .search:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "SearchCell", for: indexPath) as! SearchCell
            cell.searchBar.text = searchQuery
            cell.onSearchTextChanged = { [weak self] query in
                guard self?.searchQuery != query else { return }
                guard self?.requestSegment == 0 else { return }
                self?.searchQuery = query
                self?.reloadRequestSections()
            }
            return cell

        case .requests:
            // ✅ Check for empty state first
            let isEmpty: Bool
            let emptyMessage: String
            switch requestSegment {
            case 0:
                isEmpty = filteredEligibleStudents.isEmpty
                emptyMessage = currentTeam == nil ? "Create a team to send invites" : (searchQuery.isEmpty ? "No students available" : "No results found")
            case 1:
                isEmpty = receivedItems.isEmpty
                emptyMessage = "No received requests yet"
            case 2:
                isEmpty = availableTeams.isEmpty
                emptyMessage = "No teams available to join"
            default:
                isEmpty = true
                emptyMessage = ""
            }

            if isEmpty {
                let emptyCell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmptyStateCell", for: indexPath)
                emptyCell.contentView.subviews.forEach { $0.removeFromSuperview() }
                let label = UILabel()
                label.text = emptyMessage
                label.textColor = .secondaryLabel
                label.font = .systemFont(ofSize: 15, weight: .regular)
                label.textAlignment = .center
                label.translatesAutoresizingMaskIntoConstraints = false
                emptyCell.contentView.addSubview(label)
                NSLayoutConstraint.activate([
                    label.centerXAnchor.constraint(equalTo: emptyCell.contentView.centerXAnchor),
                    label.centerYAnchor.constraint(equalTo: emptyCell.contentView.centerYAnchor),
                    label.leadingAnchor.constraint(greaterThanOrEqualTo: emptyCell.contentView.leadingAnchor, constant: 16),
                    label.trailingAnchor.constraint(lessThanOrEqualTo: emptyCell.contentView.trailingAnchor, constant: -16),
                ])
                return emptyCell
            }

            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestItemCell", for: indexPath) as! RequestItemCell

            switch requestSegment {
            case 0:
                // ✅ SEND INVITES — student list
                let s = filteredEligibleStudents[indexPath.item]
                let subtitle = s.srm_mail ?? s.reg_no ?? s.department ?? "Student"
                let isLast = indexPath.item == filteredEligibleStudents.count - 1

                // Check if this student already has a pending invite
                if let existingInvite = sentInvites.first(where: { $0.to_person_id == s.person_id }) {
                    // Already invited — show Undo
                    cell.configureForSentWithUndo(
                        name: s.displayName,
                        subtitle: "Invite Sent",
                        showsDivider: !isLast,
                        onUndo: { [weak self] in
                            guard let self else { return }
                            Task {
                                do {
                                    try await SupabaseManager.shared.rejectInvite(inviteId: existingInvite.id)
                                    await self.loadSendAndReceivedLists()
                                    await MainActor.run {
                                        self.showAlert(title: "Withdrawn", message: "Invite to \(s.displayName) withdrawn.")
                                    }
                                } catch {
                                    await MainActor.run {
                                        self.showAlert(title: "Error", message: error.localizedDescription)
                                    }
                                }
                            }
                        }
                    )
                } else if sentInvites.count >= 2 {
                    // Limit reached — disabled
                    cell.configureDisabled(
                        name: s.displayName,
                        subtitle: subtitle,
                        showsDivider: !isLast
                    )
                } else {
                    // Available to invite
                    cell.configure(
                        name: s.displayName,
                        subtitle: subtitle,
                        onTap: { [weak self] in
                            self?.inviteStudent(s)
                        },
                        showsDivider: !isLast
                    )
                }

            case 1:
                // ✅ RECEIVED INVITES & JOIN REQUESTS — with Accept + Reject buttons
                let item = receivedItems[indexPath.item]
                let isLast = indexPath.item == receivedItems.count - 1
                
                switch item {
                case .invite(let inv):
                    cell.configureForReceived(
                        name: inv.from_name,
                        subtitle: "Invited you to Team #\(inv.team_number)",
                        avatar: UIImage(systemName: "person.crop.circle.fill"),
                        showsDivider: !isLast,
                        onAccept: { [weak self] in
                            guard let self else { return }
                            Task { await self.acceptIncomingInvite(inv) }
                        },
                        onReject: { [weak self] in
                            guard let self else { return }
                            Task {
                                do {
                                    try await SupabaseManager.shared.rejectInvite(inviteId: inv.id)
                                    await self.loadSendAndReceivedLists()
                                    await MainActor.run {
                                        self.showAlert(title: "Rejected", message: "Invite from \(inv.from_name) was rejected.")
                                    }
                                } catch {
                                    await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
                                }
                            }
                        }
                    )
                case .joinRequest(let req):
                    cell.configureForReceived(
                        name: req.from_name,
                        subtitle: "Wants to join your team",
                        avatar: UIImage(systemName: "person.crop.circle.fill"),
                        showsDivider: !isLast,
                        onAccept: { [weak self] in
                            guard let self else { return }
                            Task { await self.acceptIncomingJoinRequest(req) }
                        },
                        onReject: { [weak self] in
                            guard let self else { return }
                            Task {
                                do {
                                    try await SupabaseManager.shared.rejectTeamJoinRequest(requestId: req.id)
                                    await self.loadSendAndReceivedLists()
                                    await MainActor.run {
                                        self.showAlert(title: "Rejected", message: "Join request from \(req.from_name) was rejected.")
                                    }
                                } catch {
                                    await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
                                }
                            }
                        }
                    )
                }

            case 2:
                // ✅ JOIN A TEAM — browse other teams
                let teamInfo = availableTeams[indexPath.item]
                let team = teamInfo.team
                let creator = teamInfo.creator
                let teamName = "Team #\(team.teamNumber)"
                let subtitle = "Created by \(creator.displayName)"
                let isLast = indexPath.item == availableTeams.count - 1

                if hasAlreadySentJoinRequest(to: team.id) {
                    cell.configureForSentWithUndo(
                        name: teamName,
                        subtitle: "Request Sent",
                        showsDivider: !isLast,
                        onUndo: { [weak self] in
                            guard let self else { return }
                            // Find the matching sent request to withdraw
                            guard let request = self.sentJoinRequests.first(where: { $0.to_team_id == team.id }) else { return }
                            Task {
                                do {
                                    try await SupabaseManager.shared.rejectTeamJoinRequest(requestId: request.id)
                                    await self.loadSendAndReceivedLists()
                                    await MainActor.run {
                                        self.showAlert(title: "Withdrawn", message: "Join request to Team #\(team.teamNumber) withdrawn.")
                                    }
                                } catch {
                                    await MainActor.run {
                                        self.showAlert(title: "Error", message: error.localizedDescription)
                                    }
                                }
                            }
                        }
                    )
                } else {
                    cell.configure(
                        name: teamName,
                        subtitle: subtitle,
                        onTap: { [weak self] in
                            self?.sendJoinRequest(to: teamInfo)
                        },
                        showsDivider: !isLast
                    )
                }

            default:
                break
            }

            return cell
        }
    }
}

private final class CreateTeamCTACollectionViewCell: UICollectionViewCell {
    private let button = UIButton(type: .system)
    private var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildUI()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        AppTheme.styleNativeFloatingControl(button, cornerRadius: 22)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onTap = nil
    }

    func configure(title: String, onTap: @escaping () -> Void) {
        self.onTap = onTap
        var config = UIButton.Configuration.plain()
        config.title = title
        config.baseForegroundColor = .label
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        config.attributedTitle = AttributedString(
            title,
            attributes: AttributeContainer([.foregroundColor: UIColor.label])
        )
        button.configuration = config
        button.setTitleColor(.label, for: .normal)
        button.tintColor = .label
        AppTheme.styleNativeFloatingControl(button, cornerRadius: 22)
    }

    private func buildUI() {
        contentView.backgroundColor = .clear
        backgroundColor = .clear

        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(didTapButton), for: .touchUpInside)
        contentView.addSubview(button)

        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: contentView.topAnchor),
            button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            button.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func didTapButton() {
        onTap?()
    }
}

// MARK: - Search Cell

class SearchCell: UICollectionViewCell, UISearchBarDelegate {
    let searchBar = UISearchBar()
    var onSearchTextChanged: ((String) -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        searchBar.searchBarStyle = .minimal
        searchBar.placeholder = "Search users..."
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(searchBar)
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: contentView.topAnchor),
            searchBar.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            searchBar.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: contentView.trailingAnchor)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        onSearchTextChanged?(searchText)
    }
}
