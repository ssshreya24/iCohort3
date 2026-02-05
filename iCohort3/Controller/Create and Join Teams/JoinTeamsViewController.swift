import UIKit
import FirebaseAuth

struct JoinableStudent {
    let id: String
    let name: String
    let regNo: String
    let department: String
}

struct IncomingRequest {
    let requestId: String
    let fromId: String
    let fromName: String
}

final class JoinTeamsViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!

    private var showingSent: Bool = true

    private var students: [JoinableStudent] = []
    private var incoming: [SupabaseManager.TeamMemberRequestRow] = []


    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitle()
        setupCollectionView()

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
            UINib(nibName: "RequestItemCell", bundle: nil),
            forCellWithReuseIdentifier: "RequestItemCell"
        )
    }

    private func makeLayout() -> UICollectionViewCompositionalLayout {
        UICollectionViewCompositionalLayout { sectionIndex, _ in
            if sectionIndex == 0 {
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

    private func currentUserId() -> String? {
        Auth.auth().currentUser?.uid
    }

    private func currentUserNameFallback() -> String {
        if let name = Auth.auth().currentUser?.displayName, !name.isEmpty {
            return name
        }
        if let email = Auth.auth().currentUser?.email, !email.isEmpty {
            return email.components(separatedBy: "@").first ?? "Student"
        }
        return "Student"
    }

    private func safeReloadListSection() {
        // We always have 2 sections (0 switcher, 1 list)
        guard collectionView.numberOfSections >= 2 else {
            collectionView.reloadData()
            return
        }
        collectionView.reloadSections(IndexSet(integer: 1))
    }

    private func loadDataForCurrentMode() async {
        guard let uidString = currentUserId() else { return }
        guard let uidUUID = UUID(uuidString: uidString) else { return }

        do {
            if showingSent {

                // ✅ fetchAllStudents expects UUID
                let rows = try await SupabaseManager.shared.fetchAllStudents(excluding: uidUUID)

                // ✅ StudentProfileCompleteRow has: personId(UUID), fullName(String)
                let mapped: [JoinableStudent] = rows.map {
                    JoinableStudent(
                        id: $0.personId.uuidString,
                        name: $0.fullName ?? "Unknown Student",
                        regNo: "",
                        department: ""
                    )
                }


                await MainActor.run {
                    self.students = mapped
                    self.incoming = []
                    self.safeReloadListSection()
                }

            } else {

                // ✅ incoming requests expects String (person_id uuidString)
                let incomingRows = try await SupabaseManager.shared.fetchIncomingRequests(for: uidString)

                await MainActor.run {
                    self.incoming = incomingRows
                    self.students = []
                    self.safeReloadListSection()
                }
            }

        } catch {
            await MainActor.run {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }
    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }


    private func sendRequest(to student: JoinableStudent) async {
        guard let uid = currentUserId() else { return }

        do {
            try await SupabaseManager.shared.sendTeamMemberRequest(
                fromId: uid,
                fromName: currentUserNameFallback(),
                toId: student.id,
                toName: student.name
            )

            await MainActor.run {
                // Optional: show feedback (you can replace with toast)
                print("✅ Request sent to:", student.name)
            }
        } catch {
            await MainActor.run {
                print("❌ Send request error:", error)
            }
        }
    }

    private func acceptIncoming(request: SupabaseManager.TeamMemberRequestRow) async {
        guard let myId = currentUserId() else { return }

        do {
            try await SupabaseManager.shared.acceptTeamMemberRequest(
                requestId: request.id,        // ✅ UUID (correct)
                receiverId: myId,             // ✅ String (person_id uuidString)
                receiverName: nil
            )

            await MainActor.run {
                self.incoming.removeAll { $0.id == request.id }   // ✅ use id not requestId
                self.safeReloadListSection()
            }

        } catch {
            await MainActor.run {
                self.showAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

}

// MARK: - UICollectionViewDataSource / Delegate

extension JoinTeamsViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func numberOfSections(in collectionView: UICollectionView) -> Int { 2 }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 { return 1 }
        return showingSent ? students.count : incoming.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
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

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RequestItemCell",
            for: indexPath
        ) as! RequestItemCell

        if showingSent {
            let s = students[indexPath.item]

            cell.configureStudentRow(
                name: s.name,
                regNo: s.regNo,
                department: s.department
            ) { [weak self] in
                guard let self else { return }
                Task { await self.sendRequest(to: s) }
            }

        } else {
            let r = incoming[indexPath.item]

            cell.configureIncomingRequestRow(requesterName: r.fromStudentName) { [weak self] in
                guard let self else { return }
                Task { await self.acceptIncoming(request: r) }
            }

        }

        return cell
    }
}
