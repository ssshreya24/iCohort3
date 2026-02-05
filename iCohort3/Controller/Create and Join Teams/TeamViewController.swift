import UIKit
import FirebaseAuth
import SwiftUI

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

    struct SentRequest {
        let requestId: UUID
        let studentId: String
        let studentName: String
        let avatar: UIImage?
    }

    struct ReceivedRequest {
        let requestId: UUID
        let fromStudentId: String
        let studentName: String
        let avatar: UIImage?
    }

    enum MemberSlot {
        case filled(UIImage)
        case empty
        case addSlot
    }

    var startMode: TeamStartMode = .create
    private var showingSent = true

    private var currentTeam: SupabaseManager.NewTeamRow?

    // ✅ Keep BOTH forms once, never convert repeatedly
    private var myPersonUUID: UUID?
    private var myUserId: String = ""          // person_id uuidString
    private var myName: String = "Student"

    private var members: [MemberSlot] = [.empty, .empty, .empty]
    private var sentRequests: [SentRequest] = []
    private var receivedRequests: [ReceivedRequest] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle()
        setupCollection()
        Task { await bootstrapIdentityAndLoad() }
    }

    private func setupTitle() {
        switch startMode {
        case .create: titleLabel.text = "Create Team"
        case .join:   titleLabel.text = "Join Team"
        }
    }

    private func setupCollection() {
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.collectionViewLayout = makeLayout()

        collectionView.register(UINib(nibName: "TeamSummaryCell", bundle: nil),
                                forCellWithReuseIdentifier: "TeamSummaryCell")
        collectionView.register(UINib(nibName: "MemberAvatarCell", bundle: nil),
                                forCellWithReuseIdentifier: "MemberAvatarCell")
        collectionView.register(UINib(nibName: "RequestSwitcherCell", bundle: nil),
                                forCellWithReuseIdentifier: "RequestSwitcherCell")
        collectionView.register(UINib(nibName: "RequestItemCell", bundle: nil),
                                forCellWithReuseIdentifier: "RequestItemCell")
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
                                      heightDimension: .absolute(72))
                )
                item.contentInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8)

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(widthDimension: .fractionalWidth(1.0),
                                      heightDimension: .absolute(72)),
                    subitems: [item, item, item]
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

    // MARK: - Bootstrap

    private func bootstrapIdentityAndLoad() async {

        // ✅ 0) Ensure still logged in (optional but safe)
        let firebaseUid = Auth.auth().currentUser?.uid ?? ""
        if firebaseUid.isEmpty {
            await MainActor.run {
                self.showAlert(title: "Login Required", message: "Please login again.")
            }
            return
        }

        // ✅ 1) DO NOT MAP UID AGAIN.
        // Use person_id stored by migration at login.
        let storedPersonId = UserDefaults.standard.string(forKey: "current_person_id") ?? ""
        if storedPersonId.isEmpty {
            await MainActor.run {
                self.showAlert(title: "Session Missing", message: "No person_id found. Please login again.")
            }
            return
        }

        myUserId = storedPersonId
        myPersonUUID = UUID(uuidString: storedPersonId) // may be nil if not uuid, but ok

        do {
            // ✅ 2) Fetch name using person_id -> student_profile_complete
            myName = (try? await SupabaseManager.shared.fetchStudentFullName(personIdString: myUserId)) ?? "Student"

            // ✅ 3) Load or create team
            await loadOrCreateTeamIfNeeded(personIdString: myUserId)

            // ✅ 4) Load requests
            await loadRequests()

        } catch {
            await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
        }
    }

    // MARK: - Load / Create Team

    private func loadOrCreateTeamIfNeeded(personIdString: String) async {
        do {
            if let team = try await SupabaseManager.shared.fetchActiveTeamForUser(userId: personIdString) {
                currentTeam = team
            } else {
                if startMode == .create {
                    currentTeam = try await SupabaseManager.shared.createTeamIfNone(
                        personIdString: personIdString,
                        fallbackUserName: myName
                    )
                } else {
                    currentTeam = nil
                }
            }

            await MainActor.run {
                self.applyTeamToUI()
                self.configureActionButton()
                self.collectionView.reloadData()
            }

        } catch {
            await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
        }
    }

    // MARK: - Requests

    private func loadRequests() async {
        guard !myUserId.isEmpty else { return }

        do {
            let sentRows = try await SupabaseManager.shared.fetchSentRequests(from: myUserId)
            let incomingRows = try await SupabaseManager.shared.fetchIncomingRequests(for: myUserId)

            let mappedSent: [SentRequest] = sentRows.map {
                SentRequest(
                    requestId: $0.id,
                    studentId: $0.toStudentId,
                    studentName: $0.toStudentName,
                    avatar: UIImage(systemName: "person.circle")
                )
            }

            let mappedIncoming: [ReceivedRequest] = incomingRows.map {
                ReceivedRequest(
                    requestId: $0.id,
                    fromStudentId: $0.fromStudentId,
                    studentName: $0.fromStudentName,
                    avatar: UIImage(systemName: "person.circle.fill")
                )
            }

            await MainActor.run {
                self.sentRequests = mappedSent
                self.receivedRequests = mappedIncoming
                self.collectionView.reloadSections(IndexSet(integer: Section.requests.rawValue))
            }

        } catch {
            await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
        }
    }

    // MARK: - Open Student List (SwiftUI)

    private func openStudentListToSendRequest() {
        // ✅ Pass the required params
        let view = StudentListView(myPersonId: myUserId, myName: myName) { [weak self] in
            guard let self else { return }
            Task { await self.loadRequests() }   // refresh sent requests after sending
        }

        let hosting = UIHostingController(rootView: view)
        hosting.title = "Students"
        navigationController?.pushViewController(hosting, animated: true)
    }


    // MARK: - UI

    private func applyTeamToUI() {
        guard let team = currentTeam else {
            members = (startMode == .create) ? [.addSlot, .empty, .empty] : [.empty, .empty, .empty]
            return
        }

        let creatorAvatar = UIImage(systemName: "person.crop.circle.fill") ?? UIImage()
        let memberAvatar  = UIImage(systemName: "person.circle") ?? UIImage()

        var slots: [MemberSlot] = []
        slots.append(.filled(creatorAvatar))

        if team.member2Id == nil {
            slots.append(team.createdById == myUserId ? .addSlot : .empty)
        } else {
            slots.append(.filled(memberAvatar))
        }

        if team.member3Id == nil {
            slots.append(.empty)
        } else {
            slots.append(.filled(memberAvatar))
        }

        while slots.count < 3 { slots.append(.empty) }
        if slots.count > 3 { slots = Array(slots.prefix(3)) }

        members = slots
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

        let alert = UIAlertController(
            title: "Delete Team?",
            message: "This will permanently delete the team.",
            preferredStyle: .alert
        )
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

            await MainActor.run {
                self.applyTeamToUI()
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

            await MainActor.run {
                self.applyTeamToUI()
                self.configureActionButton()
                self.collectionView.reloadData()
                self.showAlert(title: "Left Team", message: "You have been removed from the team.")
            }
        } catch {
            await MainActor.run { self.showAlert(title: "Error", message: error.localizedDescription) }
        }
    }

    private func acceptIncomingRequest(_ req: ReceivedRequest) async {
        do {
            try await SupabaseManager.shared.acceptTeamMemberRequest(
                requestId: req.requestId,
                receiverId: myUserId,
                receiverName: myName
            )

            await loadOrCreateTeamIfNeeded(personIdString: myUserId)
            await loadRequests()

            await MainActor.run {
                self.showAlert(title: "Accepted", message: "Request accepted and team updated.")
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

// MARK: - Collection DataSource/Delegate

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
        case .requests:        return showingSent ? sentRequests.count : receivedRequests.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

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

            cell.configure(
                teamName: title,
                icon: UIImage(systemName: "person.3.fill")?.withRenderingMode(.alwaysTemplate)
            )

            cell.teamImageView.tintColor = UIColor(
                red: 0x77/255.0,
                green: 0x9C/255.0,
                blue: 0xB3/255.0,
                alpha: 1.0
            )

            cell.layoutIfNeeded()
            cell.circleView.layer.cornerRadius = cell.circleView.bounds.height / 2
            cell.circleView.layer.masksToBounds = true
            cell.circleView.backgroundColor = .white
            return cell

        case .members:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MemberAvatarCell", for: indexPath) as! MemberAvatarCell
            let slot = members[indexPath.item]

            cell.configure(slot: slot) { [weak self] in
                guard let self else { return }
                self.openStudentListToSendRequest()
            }
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
                let item = sentRequests[indexPath.item]
                cell.configureForSent(name: item.studentName, avatar: item.avatar) {
                    print("Sent request tapped for \(item.studentName) requestId=\(item.requestId)")
                }
            } else {
                let item = receivedRequests[indexPath.item]
                cell.configureForReceived(name: item.studentName, avatar: item.avatar) { [weak self] in
                    guard let self else { return }
                    Task { await self.acceptIncomingRequest(item) }
                }
            }
            return cell
        }
    }
}
