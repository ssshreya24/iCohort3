import UIKit

final class StudentPickerViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchField: UITextField!

    var currentTeam: SupabaseManager.NewTeamRow!
    var myUserId: String = ""   // leader person_id
    var myName: String = ""     // leader name

    private var allStudents: [SupabaseManager.StudentPickerRow] = []
    private var filtered: [SupabaseManager.StudentPickerRow] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        print("🟣 [StudentPickerVC] viewDidLoad")
        print("🟣 currentTeam:", currentTeam?.id.uuidString ?? "nil", "teamNumber:", currentTeam?.teamNumber ?? -1)
        print("🟣 myUserId:", myUserId)
        print("🟣 myName:", myName)

        configureUI()
        configureCollection()
        loadStudents()
    }

    private func configureUI() {
        view.backgroundColor = .systemBackground
        searchField.addTarget(self, action: #selector(searchChanged), for: .editingChanged)
    }

    private func configureCollection() {
        collectionView.dataSource = self
        collectionView.delegate = self
    }

    private func loadStudents() {
        Task {
            do {
                print("🟣 [StudentPickerVC] loadStudents() called")

                let rows = try await SupabaseManager.shared.fetchProfileCompleteStudents()

                // optional: remove yourself from list
                let cleaned = rows.filter { $0.person_id != myUserId }
                

                await MainActor.run {
                    self.allStudents = cleaned
                    self.filtered = cleaned
                    self.collectionView.reloadData()
                }
            } catch {
                await MainActor.run {
                    self.showError("Failed to load students", message: error.localizedDescription)
                }
            }
            
        }
    }

    @objc private func searchChanged() {
        let q = (searchField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            filtered = allStudents
        } else {
            filtered = allStudents.filter {
                $0.displayName.lowercased().contains(q) ||
                ($0.srm_mail ?? "").lowercased().contains(q) ||
                ($0.reg_no ?? "").lowercased().contains(q)
            }
        }
        collectionView.reloadData()
    }

    private func sendInvite(to student: SupabaseManager.StudentPickerRow) {
        Task {
            do {
                try await SupabaseManager.shared.sendInviteToStudent(
                    teamId: currentTeam.id,
                    teamNumber: currentTeam.teamNumber,
                    fromPersonId: myUserId,
                    fromName: myName,
                    toPersonId: student.person_id,
                    toName: student.displayName
                )

                await MainActor.run {
                    self.showToast("Invite sent ✅")
                }

            } catch {
                await MainActor.run {
                    self.showError("Invite failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func showError(_ title: String, message: String) {
        let ac = UIAlertController(title: title, message: message, preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        present(ac, animated: true)
    }

    private func showToast(_ text: String) {
        let ac = UIAlertController(title: nil, message: text, preferredStyle: .alert)
        present(ac, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak ac] in
            ac?.dismiss(animated: true)
        }
    }
}

extension StudentPickerViewController: UICollectionViewDataSource, UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filtered.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "RequestItemCell",
            for: indexPath
        ) as! RequestItemCell

        let s = filtered[indexPath.item]
        let subtitle = s.srm_mail ?? (s.reg_no ?? "Student")
        let isLast = indexPath.item == filtered.count - 1

        cell.configure(
            name: s.displayName,
            subtitle: subtitle,
            avatar: nil,
            onTap: { [weak self] in
                self?.sendInvite(to: s)
            },
            showsDivider: !isLast
        )

        return cell
    }
}
