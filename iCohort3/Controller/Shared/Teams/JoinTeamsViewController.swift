import UIKit

final class JoinTeamsViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    private var showingSent: Bool = true

    // Current user identity
    private var myUserId: String = ""
    private var myName: String = "Student"
    private var myRegNo: String = ""
    private var myDept: String = ""
    private var mySrmMail: String = ""

    // ✅ Teams list to show (for sending join requests)
    private var availableTeams: [(team: SupabaseManager.NewTeamRow, creator: SupabaseManager.StudentPickerRow)] = []
    
    // ✅ Received Requests = incoming team join requests to MY team
    private var incomingRequests: [SupabaseManager.TeamJoinRequestRow] = []
    
    // ✅ Sent Requests = outgoing team join requests I've sent
    private var sentRequests: [SupabaseManager.TeamJoinRequestRow] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle()
        setupCollectionView()
        
        Task {
            await bootstrapIdentity()
            await loadDataForCurrentMode()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task { await loadDataForCurrentMode() }
    }

    private func setupTitle() {
        titleLabel.text = "Join Team"
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.backgroundColor = .clear
        collectionView.collectionViewLayout = makeLayout()

        collectionView.register(
            UINib(nibName: "RequestSwitcherCell", bundle: nil),
            forCellWithReuseIdentifier: "RequestSwitcherCell"
        )

        collectionView.register(
            RequestItemCell.self,
            forCellWithReuseIdentifier: "RequestItemCell"
        )
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            if sectionIndex == 0 {
                // Switcher section
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(44))
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(44)),
                    subitems: [item]
                )
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 16, leading: 16, bottom: 8, trailing: 16)
                return section
            } else {
                // List section
                let item = NSCollectionLayoutItem(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(72))
                )
                let group = NSCollectionLayoutGroup.vertical(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .estimated(72)),
                    subitems: [item]
                )
                let section = NSCollectionLayoutSection(group: group)
                section.interGroupSpacing = 8
                section.contentInsets = .init(top: 8, leading: 16, bottom: 32, trailing: 16)
                return section
            }
        }
    }

    @IBAction func closeTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    // MARK: - Bootstrap Identity

    private func bootstrapIdentity() async {
        // Get current user ID
        if let storedPersonId = UserDefaults.standard.string(forKey: "current_person_id"),
           !storedPersonId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            myUserId = storedPersonId
        } else {
            do {
                let personId = try await SupabaseManager.shared.currentPersonId()
                myUserId = personId
                UserDefaults.standard.set(personId, forKey: "current_person_id")
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Login Required", message: "Session missing. Please login again.")
                }
                return
            }
        }

        // Get current user name and profile
        myName = (try? await SupabaseManager.shared.fetchStudentFullName(personIdString: myUserId)) ?? "Student"
        
        do {
            let mini = try await SupabaseManager.shared.fetchStudentMiniProfile(personIdString: myUserId)
            myRegNo = mini.reg_no ?? ""
            myDept = mini.department ?? ""
            mySrmMail = mini.srm_mail ?? ""
        } catch {
            print("❌ [JoinTeamsVC] MiniProfile fetch failed:", error.localizedDescription)
        }

        print("✅ [JoinTeamsVC] Identity loaded - userId:", myUserId, "name:", myName)
    }

    // MARK: - Data Loading

    private func loadDataForCurrentMode() async {
        guard !myUserId.isEmpty else {
            print("⚠️ [JoinTeamsVC] myUserId is empty, skipping data load")
            return
        }

        do {
            if showingSent {
                // ✅ SEND REQUESTS TAB = Show all teams (to send join requests)
                print("🟦 [JoinTeamsVC] Loading teams for SEND tab")
                
                // Get all active teams
                let allTeams = try await SupabaseManager.shared.fetchAllActiveTeams()
                
                // Filter out my own team
                let myTeam = try await SupabaseManager.shared.fetchActiveTeamForUser(userId: myUserId)
                let filteredTeams = allTeams.filter { $0.id != myTeam?.id }
                
                // Get creator info for each team
                var teamsWithCreators: [(team: SupabaseManager.NewTeamRow, creator: SupabaseManager.StudentPickerRow)] = []
                
                for team in filteredTeams {
                    if let creatorInfo = try? await SupabaseManager.shared.fetchStudentPickerInfo(personId: team.createdById) {
                        teamsWithCreators.append((team: team, creator: creatorInfo))
                    }
                }
                
                // Also load sent requests to show which ones are already sent
                let sent = try await SupabaseManager.shared.fetchSentJoinRequests(fromPersonId: myUserId)
                
                await MainActor.run {
                    self.availableTeams = teamsWithCreators
                    self.sentRequests = sent
                    self.incomingRequests = []
                    print("✅ [JoinTeamsVC] Loaded \(teamsWithCreators.count) teams, \(sent.count) sent requests")
                    self.safeReloadListSection()
                }

            } else {
                // ✅ RECEIVED REQUESTS TAB = Show incoming join requests to my team
                print("🟦 [JoinTeamsVC] Loading incoming requests for RECEIVED tab")
                
                let incoming = try await SupabaseManager.shared.fetchReceivedJoinRequests(toPersonId: myUserId)
                
                await MainActor.run {
                    self.incomingRequests = incoming
                    self.availableTeams = []
                    self.sentRequests = []
                    print("✅ [JoinTeamsVC] Loaded \(incoming.count) incoming requests")
                    self.safeReloadListSection()
                }
            }

        } catch {
            print("❌ [JoinTeamsVC] loadDataForCurrentMode error:", error.localizedDescription)
            await MainActor.run {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    private func safeReloadListSection() {
        guard collectionView.numberOfSections >= 2 else {
            collectionView.reloadData()
            return
        }
        collectionView.reloadSections(IndexSet(integer: 1))
    }

    // MARK: - Actions

    /// ✅ Send a join request to another team
    private func sendJoinRequest(to teamInfo: (team: SupabaseManager.NewTeamRow, creator: SupabaseManager.StudentPickerRow)) async {
        let team = teamInfo.team
        let creator = teamInfo.creator
        
        print("📨 [JoinTeamsVC] Sending join request to Team #\(team.teamNumber)")

        do {
            // ✅ Send the join request
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

            await MainActor.run {
                self.showToast("Request sent to Team #\(team.teamNumber) ✅")
            }

            // Reload to update UI
            await loadDataForCurrentMode()

        } catch {
            print("❌ [JoinTeamsVC] sendJoinRequest error:", error.localizedDescription)
            
            var errorMessage = error.localizedDescription
            if errorMessage.contains("row-level security") || errorMessage.contains("RLS") {
                errorMessage = "Permission denied. Please check your database RLS policies for team_join_requests table."
            } else if errorMessage.contains("duplicate") || errorMessage.contains("unique") {
                errorMessage = "You've already sent a request to this team."
            }
            
            await MainActor.run {
                self.showAlert(title: "Error", message: errorMessage)
            }
        }
    }

    /// ✅ Accept an incoming join request (WITH TEAM SWITCHING)
    private func acceptJoinRequest(_ request: SupabaseManager.TeamJoinRequestRow) async {
        print("✅ [JoinTeamsVC] Accepting join request from:", request.from_name)

        // Show confirmation alert
        let shouldProceed = await MainActor.run { () -> Bool in
            let alert = UIAlertController(
                title: "Accept Request",
                message: "\(request.from_name) will join your team. They will leave their current team if they have one.",
                preferredStyle: .alert
            )
            
            var result = false
            let semaphore = DispatchSemaphore(value: 0)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                semaphore.signal()
            })
            
            alert.addAction(UIAlertAction(title: "Accept", style: .default) { _ in
                result = true
                semaphore.signal()
            })
            
            self.present(alert, animated: true)
            semaphore.wait()
            
            return result
        }
        
        guard shouldProceed else { return }

        do {
            try await SupabaseManager.shared.acceptTeamJoinRequest(
                requestId: request.id,
                receiverId: myUserId
            )

            await MainActor.run {
                self.showToast("\(request.from_name) joined your team ✅")
            }

            // Reload to update UI
            await loadDataForCurrentMode()

        } catch {
            print("❌ [JoinTeamsVC] acceptJoinRequest error:", error.localizedDescription)
            await MainActor.run {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    /// ✅ Reject an incoming join request
    private func rejectJoinRequest(_ request: SupabaseManager.TeamJoinRequestRow) async {
        print("❌ [JoinTeamsVC] Rejecting join request from:", request.from_name)

        do {
            try await SupabaseManager.shared.rejectTeamJoinRequest(requestId: request.id)

            await MainActor.run {
                self.showToast("Request rejected")
            }

            // Reload to update UI
            await loadDataForCurrentMode()

        } catch {
            print("❌ [JoinTeamsVC] rejectJoinRequest error:", error.localizedDescription)
            await MainActor.run {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    // MARK: - Helpers

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    private func showToast(_ text: String) {
        let ac = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        present(ac, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak ac] in
            ac?.dismiss(animated: true)
        }
    }

    /// Check if a team has already been sent a request
    private func hasAlreadySentRequest(to teamId: UUID) -> Bool {
        return sentRequests.contains { $0.to_team_id == teamId }
    }
}

// MARK: - UICollectionViewDataSource / Delegate

extension JoinTeamsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1 } // Switcher
        return showingSent ? availableTeams.count : incomingRequests.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
            // Switcher cell
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "RequestSwitcherCell",
                for: indexPath
            ) as! RequestSwitcherCell

            cell.configure(showingSent: showingSent) { [weak self] isSent in
                guard let self else { return }
                self.showingSent = isSent
                Task { await self.loadDataForCurrentMode() }
            }

            return cell
        }

        // List cell
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RequestItemCell",
            for: indexPath
        ) as! RequestItemCell

        let isLast = indexPath.item == (showingSent ? availableTeams.count : incomingRequests.count) - 1

        if showingSent {
            // ✅ SEND REQUESTS TAB - Show all teams
            let teamInfo = availableTeams[indexPath.item]
            let team = teamInfo.team
            let creator = teamInfo.creator
            
            let teamName = "Team #\(team.teamNumber)"
            let subtitle = "Created by \(creator.displayName)"
            
            // Check if already sent
            if hasAlreadySentRequest(to: team.id) {
                cell.configureForSent(
                    name: teamName,
                    showsDivider: !isLast
                )
            } else {
                cell.configure(
                    name: teamName,
                    subtitle: subtitle,
                    onTap: { [weak self] in
                        guard let self else { return }
                        Task { await self.sendJoinRequest(to: teamInfo) }
                    },
                    showsDivider: !isLast
                )
            }

        } else {
            // ✅ RECEIVED REQUESTS TAB - Show incoming join requests
            let request = incomingRequests[indexPath.item]
            let subtitle = "From: \(request.from_department ?? "Student")"
            
            cell.configureForReceived(
                name: request.from_name,
                avatar: UIImage(systemName: "person.crop.circle.fill"),
                showsDivider: !isLast
            ) { [weak self] in
                guard let self else { return }
                
                // Show accept/reject options
                let alert = UIAlertController(
                    title: "Join Request",
                    message: "\(request.from_name) wants to join your team",
                    preferredStyle: .alert
                )
                
                alert.addAction(UIAlertAction(title: "Accept", style: .default) { _ in
                    Task { await self.acceptJoinRequest(request) }
                })
                
                alert.addAction(UIAlertAction(title: "Reject", style: .destructive) { _ in
                    Task { await self.rejectJoinRequest(request) }
                })
                
                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                
                self.present(alert, animated: true)
            }
        }

        return cell
    }
}
