import UIKit
import SwiftUI
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

    var startMode: TeamStartMode = .create
    private var showingSent = true

    private var currentTeam: SupabaseManager.NewTeamRow?

    // Identity
    private var myUserId: String = ""   // person_id uuidString
    private var myName: String = "Student"

    // ✅ fetched from public.student_profile_complete
    private var myRegNo: String = ""
    private var myDept: String = ""

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

        // ✅ MemberAvatarCell is programmatic
        collectionView.register(MemberAvatarCell.self,
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
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0/3.0),
                        heightDimension: .absolute(132)
                    )
                )
                item.contentInsets = .init(top: 0, leading: 8, bottom: 0, trailing: 8)

                let group = NSCollectionLayoutGroup.horizontal(
                    layoutSize: .init(
                        widthDimension: .fractionalWidth(1.0),
                        heightDimension: .absolute(132)
                    ),
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

    // MARK: - Bootstrap

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
        myName = (try? await SupabaseManager.shared.fetchStudentFullName(personIdString: myUserId)) ?? "Student"

        // ✅ fetch from public.student_profile_complete (department, reg_no)
        do {
            let mini = try await SupabaseManager.shared.fetchStudentMiniProfile(personIdString: myUserId)
            myRegNo = mini.reg_no ?? ""
            myDept  = mini.department ?? ""

            print("✅ student_profile_complete fetched")
            print("person_id:", myUserId)
            print("reg_no:", myRegNo)
            print("department:", myDept)
        } catch {
            myRegNo = ""
            myDept = ""
            print("❌ student_profile_complete fetch FAILED:", error.localizedDescription)
            print("person_id:", myUserId)
        }

        await loadOrCreateTeamIfNeeded(personIdString: myUserId)
        await loadRequests()

        await MainActor.run {
            self.collectionView.reloadSections(IndexSet(integer: Section.members.rawValue))
        }
    }

    // MARK: - Load / Create Team

    private func loadOrCreateTeamIfNeeded(personIdString: String) async {
        do {
            if let team = try await SupabaseManager.shared.fetchActiveTeamForUser(userId: personIdString) {
                currentTeam = team
            } else {
                currentTeam = (startMode == .create)
                ? try await SupabaseManager.shared.createTeamIfNone(personIdString: personIdString, fallbackUserName: myName)
                : nil
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
                    avatar: UIImage(systemName: "person.crop.circle.fill")
                )
            }

            let mappedIncoming: [ReceivedRequest] = incomingRows.map {
                ReceivedRequest(
                    requestId: $0.id,
                    fromStudentId: $0.fromStudentId,
                    studentName: $0.fromStudentName,
                    avatar: UIImage(systemName: "person.crop.circle.fill")
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
        let view = StudentListView(myPersonId: myUserId, myName: myName) { [weak self] in
            guard let self else { return }
            Task { await self.loadRequests() }
        }

        let hosting = UIHostingController(rootView: view)
        hosting.title = "Add Members"
        navigationController?.pushViewController(hosting, animated: true)
    }

    // MARK: - UI

    private func applyTeamToUI() {
        guard let team = currentTeam else {
            if startMode == .create {
                let initial = String(myName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1))
                members = [.currentInitial(initial.isEmpty ? "S" : initial), .addSlot, .addSlot]
            } else {
                members = [.empty, .empty, .empty]
            }
            return
        }

        let icon = UIImage(systemName: "person.crop.circle.fill") ?? UIImage()

        var slots: [MemberSlot] = []
        let initial = String(myName.trimmingCharacters(in: .whitespacesAndNewlines).prefix(1))
        slots.append(.currentInitial(initial.isEmpty ? "S" : initial))

        if team.member2Id == nil {
            slots.append(team.createdById == myUserId ? .addSlot : .empty)
        } else {
            slots.append(.filled(icon))
        }

        if team.member3Id == nil {
            slots.append(team.createdById == myUserId ? .addSlot : .empty)
        } else {
            slots.append(.filled(icon))
        }

        members = Array(slots.prefix(3))
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
            await MainActor.run { self.showAlert(title: "Accepted", message: "Request accepted and team updated.") }
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

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        guard let sec = Section(rawValue: indexPath.section) else {
            return UICollectionViewCell()
        }

        switch sec {

        case .summary:
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TeamSummaryCell", for: indexPath) as! TeamSummaryCell

            let title: String = (currentTeam != nil)
                ? "Team \(currentTeam!.teamNumber)"
                : ((startMode == .create) ? "Creating..." : "No Active Team")

            cell.configure(teamName: title,
                           icon: UIImage(systemName: "person.3.fill")?.withRenderingMode(.alwaysTemplate))

            cell.teamImageView.tintColor = UIColor(red: 0x77/255.0, green: 0x9C/255.0, blue: 0xB3/255.0, alpha: 1.0)

            cell.layoutIfNeeded()
            cell.circleView.layer.cornerRadius = cell.circleView.bounds.height / 2
            cell.circleView.layer.masksToBounds = true
            cell.circleView.backgroundColor = .white
            return cell

        case .members:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "MemberAvatarCell",
                for: indexPath
            ) as! MemberAvatarCell

            let slot = members[indexPath.item]

            let name: String?
            let regNo: String?
            let dept: String?

            switch slot {
            case .currentInitial:
                name = myName
                regNo = myRegNo
                dept = myDept

                print("🟦 UI currentInitial cell gets:", myName, myRegNo, myDept)

            case .filled:
                name = ""
                regNo = ""
                dept = ""

            case .addSlot, .empty:
                name = ""
                regNo = ""
                dept = ""
            }

            cell.configure(
                slot: slot,
                name: name,
                regNo: regNo,
                dept: dept,
                onTapAdd: { [weak self] in
                    self?.openStudentListToSendRequest()
                }
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
                let item = sentRequests[indexPath.item]
                cell.configureForSent(name: item.studentName, avatar: item.avatar) { }
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
