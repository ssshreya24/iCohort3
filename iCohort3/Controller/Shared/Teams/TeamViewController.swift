import UIKit
import Supabase

enum TeamStartMode {
    case create
    case join
}

final class TeamViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!

    enum Section: Int, CaseIterable {
        case summary
        case members
        case requestSwitcher
        case requests
    }

    var startMode: TeamStartMode = .create
    private var showingSent = true  // ✅ TRUE = Send Requests (student list), FALSE = Received Requests

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
    private var receivedInvites: [SupabaseManager.TeamInviteRow] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        setupTitle()
        setupCollection()
        Task { await bootstrapIdentityAndLoad() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyTheme()
        Task {
            await loadSendAndReceivedLists()
            // ✅ Refresh team data to get updated team_number
            if currentTeam != nil {
                await loadOrCreateTeamIfNeeded(personIdString: myUserId)
            }
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
            collectionView.reloadData()
        }
    }

    private func setupTitle() {
        switch startMode {
        case .create: titleLabel.text = "Create Team"
        case .join:   titleLabel.text = "Join Team"
        }
        titleLabel.textColor = .white
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
    }

    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        view.tintColor = AppTheme.accent
        collectionView?.backgroundColor = .clear
        titleLabel?.textColor = .white
        styleButtons(in: view)
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
            print("✅ [TeamVC] MiniProfile => reg:", myRegNo, "dept:", myDept)
        } catch {
            print("❌ [TeamVC] MiniProfile fetch FAILED:", error.localizedDescription)
        }

        await loadOrCreateTeamIfNeeded(personIdString: myUserId)
        await loadSendAndReceivedLists()

        await MainActor.run {
            self.collectionView.reloadData()
        }
    }

    // MARK: - Load / Create Team

    private func loadOrCreateTeamIfNeeded(personIdString: String) async {
        do {
            // ✅ First check if team exists
            if let team = try await SupabaseManager.shared.fetchActiveTeamForUser(userId: personIdString) {
                currentTeam = team
                print("✅ [TeamVC] Loaded existing team #\(team.teamNumber)")
                
                // ✅ Load member info with names
                await loadTeamMemberInfo(team: team)
                
            } else if startMode == .create {
                // ✅ Only create if in create mode
                let newTeam = try await SupabaseManager.shared.createTeamIfNone(
                    personIdString: personIdString,
                    fallbackUserName: myName
                )
                currentTeam = newTeam
                print("✅ [TeamVC] Created new team #\(newTeam.teamNumber)")
                
                // ✅ Load member info
                await loadTeamMemberInfo(team: newTeam)
                
            } else {
                currentTeam = nil
                memberInfos = []
                print("⚠️ [TeamVC] No team found (join mode)")
            }

            await MainActor.run {
                self.applyTeamToUI()
                self.configureActionButton()
                self.collectionView.reloadSections(IndexSet([Section.summary.rawValue, Section.members.rawValue]))
            }
        } catch {
            print("❌ [TeamVC] loadOrCreateTeamIfNeeded error:", error.localizedDescription)
            await MainActor.run {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    
    // ✅ Load team member info with names
    private func loadTeamMemberInfo(team: SupabaseManager.NewTeamRow) async {
        var infos: [MemberInfo] = []
        
        // Creator (always slot 0)
        let initial = String(myName.prefix(1).uppercased())
        if team.createdById == myUserId {
            infos.append(MemberInfo(
                personId: myUserId,
                name: myName,
                regNo: myRegNo,
                dept: myDept,
                slot: .currentInitial(initial.isEmpty ? "S" : initial)
            ))
        } else {
            // Fetch creator info
            if let creatorInfo = try? await SupabaseManager.shared.fetchStudentPickerInfo(personId: team.createdById) {
                let creatorInitial = String(creatorInfo.displayName.prefix(1).uppercased())
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
                let initial = String(myName.prefix(1).uppercased())
                infos.append(MemberInfo(
                    personId: myUserId,
                    name: myName,
                    regNo: myRegNo,
                    dept: myDept,
                    slot: .currentInitial(initial.isEmpty ? "S" : initial)
                ))
            } else {
                if let memberInfo = try? await SupabaseManager.shared.fetchStudentPickerInfo(personId: member2Id) {
                    infos.append(MemberInfo(
                        personId: member2Id,
                        name: memberInfo.displayName,
                        regNo: memberInfo.reg_no ?? "",
                        dept: memberInfo.department ?? "",
                        slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())
                    ))
                } else {
                    infos.append(MemberInfo(
                        personId: member2Id,
                        name: team.member2Name ?? "Member",
                        regNo: "",
                        dept: "",
                        slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())
                    ))
                }
            }
        } else {
            // Add slot
            infos.append(MemberInfo(
                personId: "",
                name: "",
                regNo: "",
                dept: "",
                slot: team.createdById == myUserId ? .addSlot : .empty
            ))
        }
        
        // Member 3
        if let member3Id = team.member3Id {
            if member3Id == myUserId {
                let initial = String(myName.prefix(1).uppercased())
                infos.append(MemberInfo(
                    personId: myUserId,
                    name: myName,
                    regNo: myRegNo,
                    dept: myDept,
                    slot: .currentInitial(initial.isEmpty ? "S" : initial)
                ))
            } else {
                if let memberInfo = try? await SupabaseManager.shared.fetchStudentPickerInfo(personId: member3Id) {
                    infos.append(MemberInfo(
                        personId: member3Id,
                        name: memberInfo.displayName,
                        regNo: memberInfo.reg_no ?? "",
                        dept: memberInfo.department ?? "",
                        slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())
                    ))
                } else {
                    infos.append(MemberInfo(
                        personId: member3Id,
                        name: team.member3Name ?? "Member",
                        regNo: "",
                        dept: "",
                        slot: .filled(UIImage(systemName: "person.crop.circle.fill") ?? UIImage())
                    ))
                }
            }
        } else {
            // Add slot
            infos.append(MemberInfo(
                personId: "",
                name: "",
                regNo: "",
                dept: "",
                slot: team.createdById == myUserId ? .addSlot : .empty
            ))
        }
        
        memberInfos = infos
        print("✅ [TeamVC] Loaded \(infos.count) member infos")
    }

    // MARK: - ✅ Send Requests = Student List | Received Requests = Invites

    private func loadSendAndReceivedLists() async {
        guard !myUserId.isEmpty else { return }

        do {
            print("🟦 [TeamVC] loadSendAndReceivedLists START")

            // 1) Students list for SEND tab
            let students = try await SupabaseManager.shared.fetchProfileCompleteStudents()
            
            // ✅ Filter out self AND anyone in current team
            var filtered = students.filter { $0.person_id != myUserId }
            
            if let team = currentTeam {
                let teamMemberIds = [team.createdById, team.member2Id, team.member3Id].compactMap { $0 }
                filtered = filtered.filter { !teamMemberIds.contains($0.person_id) }
            }
            
            print("✅ [TeamVC] eligibleStudents =", filtered.count)

            // 2) Received invites for RECEIVED tab
            let received = try await SupabaseManager.shared.fetchReceivedInvites(toPersonId: myUserId)
            print("✅ [TeamVC] receivedInvites =", received.count)

            // 3) Sent invites (only for max-2 rule)
            if let team = currentTeam {
                let sent = try await SupabaseManager.shared.fetchSentInvites(fromPersonId: myUserId, teamId: team.id)
                print("✅ [TeamVC] sentInvites =", sent.count)
                await MainActor.run { self.sentInvites = sent }
            } else {
                await MainActor.run { self.sentInvites = [] }
            }

            await MainActor.run {
                self.eligibleStudents = filtered
                self.receivedInvites = received
                self.collectionView.reloadSections(IndexSet(integer: Section.requests.rawValue))
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

        // ✅ Max 2 pending invites
        if sentInvites.count >= 2 {
            showAlert(title: "Limit Reached", message: "You can invite maximum 2 students.")
            return
        }

        print("📨 [TeamVC] inviteStudent:", student.displayName, "id:", student.person_id)

        Task {
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
                    self.showAlert(title: "Invite Sent", message: "Invite sent to \(student.displayName)")
                }
            } catch {
                print("❌ [TeamVC] inviteStudent failed:", error.localizedDescription)
                
                var errorMessage = error.localizedDescription
                if errorMessage.contains("row-level security") || errorMessage.contains("RLS") {
                    errorMessage = "Permission denied. Please check your database RLS policies for team_member_invites table."
                }
                
                await MainActor.run {
                    self.showAlert(title: "Invite Failed", message: errorMessage)
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
                    title: "Accept Invite",
                    message: "Join team #\(invite.team_number)? You will leave your current team if you have one.",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                    print("❌ User cancelled")
                    continuation.resume(returning: false)
                })
                
                alert.addAction(UIAlertAction(title: "Accept", style: .default) { _ in
                    print("✅ User confirmed")
                    continuation.resume(returning: true)
                })
                
                self.present(alert, animated: true)
            }
        }
        
        guard shouldProceed else {
            print("🛑 User cancelled - EXITING\n")
            return
        }
        
        let loadingAlert = await MainActor.run { () -> UIAlertController in
            let alert = UIAlertController(title: nil, message: "Joining team...", preferredStyle: .alert)
            let spinner = UIActivityIndicatorView(style: .medium)
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            alert.view.addSubview(spinner)
            NSLayoutConstraint.activate([
                spinner.centerXAnchor.constraint(equalTo: alert.view.centerXAnchor),
                spinner.bottomAnchor.constraint(equalTo: alert.view.bottomAnchor, constant: -20)
            ])
            self.present(alert, animated: true)
            return alert
        }
        
        do {
            print("⏸️  Calling acceptInvite...")
            
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
            await loadOrCreateTeamIfNeeded(personIdString: myUserId)
            await loadSendAndReceivedLists()
            print("✅ Reload complete")
            
            await MainActor.run {
                self.showAlert(title: "Success", message: "You joined team #\(invite.team_number)! ✅")
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

    // MARK: - UI

    private func applyTeamToUI() {
        // This is now handled by memberInfos loaded from loadTeamMemberInfo
    }

    private func configureActionButton() {
        guard let team = currentTeam else {
            navigationItem.rightBarButtonItem = nil
            return
        }

        if team.createdById == myUserId {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Delete Team",
                style: .plain,
                target: self,
                action: #selector(didTapDeleteTeam)
            )
        } else if team.member2Id == myUserId || team.member3Id == myUserId {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                title: "Leave Team",
                style: .plain,
                target: self,
                action: #selector(didTapLeaveTeam)
            )
        } else {
            navigationItem.rightBarButtonItem = nil
        }
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
            currentTeam = nil
            memberInfos = []
            await MainActor.run {
                self.configureActionButton()
                self.collectionView.reloadData()
                self.showAlert(title: "Deleted", message: "Team deleted successfully.")
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
            currentTeam = try await SupabaseManager.shared.fetchActiveTeamForUser(userId: myUserId)
            
            if let updatedTeam = currentTeam {
                await loadTeamMemberInfo(team: updatedTeam)
            } else {
                memberInfos = []
            }
            
            await MainActor.run {
                self.configureActionButton()
                self.collectionView.reloadData()
                self.showAlert(title: "Left Team", message: "You have been removed from the team.")
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
        case .members:         return 3
        case .requestSwitcher: return 1
        case .requests:
            return showingSent ? eligibleStudents.count : receivedInvites.count
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
                title = (startMode == .create) ? "Creating..." : "No Active Team"
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

        case .requestSwitcher:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestSwitcherCell", for: indexPath) as! RequestSwitcherCell
            cell.configure(showingSent: showingSent) { [weak self] showSent in
                guard let self else { return }
                self.showingSent = showSent
                self.collectionView.reloadSections(IndexSet(integer: Section.requests.rawValue))
            }
            return cell

        case .requests:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "RequestItemCell", for: indexPath) as! RequestItemCell

            if showingSent {
                // ✅ STUDENT LIST (Send Requests)
                let s = eligibleStudents[indexPath.item]
                let subtitle = s.srm_mail ?? s.reg_no ?? s.department ?? "Student"
                let isLast = indexPath.item == eligibleStudents.count - 1

                // ✅ Check if limit reached
                if sentInvites.count >= 2 {
                    cell.configureDisabled(
                        name: s.displayName,
                        subtitle: subtitle,
                        showsDivider: !isLast
                    )
                } else {
                    cell.configure(
                        name: s.displayName,
                        subtitle: subtitle,
                        onTap: { [weak self] in
                            self?.inviteStudent(s)
                        },
                        showsDivider: !isLast
                    )
                }
            } else {
                // ✅ RECEIVED INVITES
                let inv = receivedInvites[indexPath.item]
                let isLast = indexPath.item == receivedInvites.count - 1
                cell.configureForReceived(
                    name: inv.from_name,
                    avatar: UIImage(systemName: "person.crop.circle.fill"),
                    showsDivider: !isLast
                ) { [weak self] in
                    guard let self else { return }
                    Task { await self.acceptIncomingInvite(inv) }
                }
            }
            return cell
        }
    }
}
