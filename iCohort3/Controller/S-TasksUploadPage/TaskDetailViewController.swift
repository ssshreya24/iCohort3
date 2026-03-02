//
//  TaskDetailViewController.swift
//  iCohort3


import UIKit
internal import UniformTypeIdentifiers
import PostgREST
import Supabase

// NOTE: DashboardTask is declared in DashboardTask.swift (shared model file).

// MARK: - In-memory attachment model

private struct AttachmentPayload {
    let filename: String
    let fileType: String
    let base64Data: String   // base64-encoded file bytes
    let isLink: Bool

    /// Convenience for URL-only attachments (no binary data)
    static func link(_ url: String) -> AttachmentPayload {
        AttachmentPayload(filename: url, fileType: "text/url", base64Data: "", isLink: true)
    }
}

// MARK: - ViewController

class TaskDetailViewController: UIViewController {

    // MARK: - ScrollView & Content
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!

    // MARK: - Title Card
    @IBOutlet weak var taskTitleLabel: UILabel!
    @IBOutlet weak var dueDateContainerView: UIView!
    @IBOutlet weak var dueDateLabel: UILabel!

    // MARK: - Assigned To Card
    @IBOutlet weak var assignedToContainerView: UIView!
    @IBOutlet weak var resourcesContainerView: UIView!
    @IBOutlet weak var assigneeImageView: UIImageView!
    @IBOutlet weak var assigneeNameLabel: UILabel!

    // MARK: - Assigned By (mentor)
    @IBOutlet weak var assignedByNameLabel: UILabel!

    // MARK: - Attachment Card
    @IBOutlet weak var attachmentContainerView: UIView!
    @IBOutlet weak var attachmentIconButton: UIButton!
    @IBOutlet weak var attachmentsStackView: UIStackView!

    // MARK: - Submit To
    @IBOutlet weak var submitToButton: UIButton!
    @IBOutlet weak var assignedByContainerView: UIView!
    @IBOutlet weak var submitToContainerView: UIView!

    // MARK: - Submit Button
    @IBOutlet weak var submitButton: UIButton!

    // MARK: - Height Constraint
    @IBOutlet weak var attachmentContainerHeightConstraint: NSLayoutConstraint!

    // MARK: - Task Model
    var task: DashboardTask?

    // MARK: - State

    private var isSubmitted = false
    private var mentorOptions: [(name: String, personId: String)] = []
    private var selectedSubmitTo: String = ""

    /// Pending attachments the student has picked — cleared on submit
    private var pendingAttachments: [AttachmentPayload] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBackButton()
        setupMentorUI()

        if let t = task { configure(with: t) }

        Task { await loadSupabaseData() }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
    }

    // MARK: - Back Button

    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        backButton.layer.cornerRadius = 22
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: config), for: .normal)
        backButton.tintColor = .black
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        view.addSubview(backButton)
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }

    @objc private func backButtonTapped() { dismiss(animated: true) }

    // MARK: - Mentor UI placeholder

    private func setupMentorUI() {
        assignedByNameLabel.text      = "Loading..."
        assignedByNameLabel.textColor = .darkGray
        assignedByNameLabel.font      = UIFont.systemFont(ofSize: 16)

        submitToButton.setTitle("Select Mentor", for: .normal)
        submitToButton.setTitleColor(.darkGray, for: .normal)
        submitToButton.titleLabel?.font       = UIFont.systemFont(ofSize: 16)
        submitToButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        submitToButton.semanticContentAttribute    = .forceRightToLeft
        submitToButton.contentHorizontalAlignment  = .trailing
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)

        let cards: [UIView?] = [
            dueDateContainerView, assignedToContainerView, attachmentContainerView,
            assignedByContainerView, submitToContainerView, resourcesContainerView
        ]
        cards.forEach {
            $0?.backgroundColor    = .white
            $0?.layer.cornerRadius = 20
            $0?.layer.shadowColor   = UIColor.black.cgColor
            $0?.layer.shadowOpacity = 0.06
            $0?.layer.shadowOffset  = CGSize(width: 0, height: 2)
            $0?.layer.shadowRadius  = 6
        }

        taskTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        dueDateLabel.font   = UIFont.systemFont(ofSize: 16)
        dueDateLabel.textColor = .darkGray

        assigneeImageView.layer.cornerRadius = 20
        assigneeImageView.clipsToBounds      = true
        assigneeNameLabel.font = UIFont.systemFont(ofSize: 16)

        attachmentsStackView.axis         = .vertical
        attachmentsStackView.spacing      = 8
        attachmentsStackView.alignment    = .fill
        attachmentsStackView.distribution = .fill

        submitButton.layer.cornerRadius = 25
        submitButton.backgroundColor    = .systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font   = .systemFont(ofSize: 17, weight: .semibold)
    }

    // MARK: - Configure with DashboardTask

    func configure(with task: DashboardTask) {
        self.task = task
        guard isViewLoaded else { return }

        taskTitleLabel.text    = task.title
        dueDateLabel.text      = task.dueDate
        assigneeNameLabel.text = task.assigneeName
        assigneeImageView.image = task.assigneeImage ?? placeholderImage(for: task.assigneeName)

        attachmentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        resourcesContainerView.isHidden = false
        if task.attachmentNames.isEmpty {
            showNoResourcesLabel()
        } else {
            removeNoResourcesLabel()
            for file in task.attachmentNames { addAttachmentRow(filename: file, canDelete: !isSubmitted) }
        }
        updateAttachmentContainerHeight()
    }

    // MARK: - Load Supabase data

    private func loadSupabaseData() async {
        guard let task = task else { return }

        async let mentorName   = fetchMentorName(task: task)
        async let assigneeName = fetchAssigneeName(task: task)
        async let mentors      = fetchAllMentors()
        async let resources    = fetchResources(task: task)

        let (mentor, assignee, allMentors, attachments) =
            await (mentorName, assigneeName, mentors, resources)

        await MainActor.run {
            assignedByNameLabel.text = mentor
            assigneeNameLabel.text   = assignee
            assigneeImageView.image  = placeholderImage(for: assignee)

            self.mentorOptions = allMentors
            let actions = allMentors.map { m in
                UIAction(title: m.name) { [weak self] _ in
                    self?.selectedSubmitTo = m.personId
                    self?.submitToButton.setTitle(m.name, for: .normal)
                }
            }
            if !actions.isEmpty {
                submitToButton.menu = UIMenu(children: actions)
                submitToButton.showsMenuAsPrimaryAction = true
                submitToButton.setTitle(actions[0].title, for: .normal)
                selectedSubmitTo = allMentors[0].personId
            }

            // Resources section — existing mentor-attached files (read-only display)
            attachmentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
            resourcesContainerView.isHidden = false
            if attachments.isEmpty {
                showNoResourcesLabel()
            } else {
                removeNoResourcesLabel()
                for name in attachments { addAttachmentRow(filename: name, canDelete: false) }
            }
            updateAttachmentContainerHeight()
        }
    }

    // MARK: - No-resources empty state

    private let noResourcesTag = 99_001

    private func showNoResourcesLabel() {
        guard attachmentsStackView.viewWithTag(noResourcesTag) == nil else { return }
        let label           = UILabel()
        label.tag           = noResourcesTag
        label.text          = "No resources attached"
        label.textColor     = .systemGray
        label.font          = UIFont.systemFont(ofSize: 15)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        label.heightAnchor.constraint(equalToConstant: 40).isActive = true
        attachmentsStackView.addArrangedSubview(label)
        attachmentContainerHeightConstraint.constant = 90
    }

    private func removeNoResourcesLabel() {
        if let v = attachmentsStackView.viewWithTag(noResourcesTag) {
            attachmentsStackView.removeArrangedSubview(v); v.removeFromSuperview()
        }
    }

    // MARK: - Supabase fetch helpers

    private func fetchMentorName(task: DashboardTask) async -> String {
        if let teamId = task.teamId {
            do {
                struct TeamMentorRow: Decodable { let mentor_name: String?; let mentor_id: String? }
                let rows: [TeamMentorRow] = try await SupabaseManager.shared.client
                    .from("new_teams").select("mentor_name, mentor_id")
                    .eq("id", value: teamId).limit(1).execute().value
                if let name = rows.first?.mentor_name, !name.isEmpty { return name }
                if let mid = rows.first?.mentor_id ?? task.mentorId {
                    return (try? await SupabaseManager.shared.fetchMentorFullName(personId: mid)) ?? "Mentor"
                }
            } catch { print("❌ fetchMentorName:", error) }
        }
        if let mid = task.mentorId {
            return (try? await SupabaseManager.shared.fetchMentorFullName(personId: mid)) ?? "Mentor"
        }
        return "Mentor"
    }

    private func fetchAssigneeName(task: DashboardTask) async -> String {
        guard let taskId = task.taskId, let teamId = task.teamId else { return task.assigneeName }
        return (try? await SupabaseManager.shared.resolveAssigneeNameFromNewTeams(
            taskId: taskId, teamId: teamId)) ?? task.assigneeName
    }

    private func fetchAllMentors() async -> [(name: String, personId: String)] {
        struct MentorRow: Decodable { let person_id: String; let first_name: String?; let last_name: String? }
        guard let rows = try? await SupabaseManager.shared.client
            .from("mentor_profiles").select("person_id, first_name, last_name")
            .execute().value as [MentorRow] else { return [] }
        return rows.compactMap {
            let full = "\($0.first_name ?? "") \($0.last_name ?? "")".trimmingCharacters(in: .whitespaces)
            return full.isEmpty ? nil : (name: full, personId: $0.person_id)
        }
    }

    private func fetchResources(task: DashboardTask) async -> [String] {
        guard let taskId = task.taskId else { return task.attachmentNames }
        return (try? await SupabaseManager.shared.fetchTaskAttachments(taskId: taskId).map { $0.filename })
            ?? task.attachmentNames
    }

    // MARK: - Attachment row UI

    /// Adds a display row in the stack. `canDelete` controls whether the × button shows.
    private func addAttachmentRow(filename: String, canDelete: Bool) {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor    = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        container.layer.cornerRadius = 12

        let isLink   = filename.hasPrefix("http://") || filename.hasPrefix("https://")
        let ext      = (filename as NSString).pathExtension.lowercased()
        let iconName: String = {
            if isLink { return "link" }
            switch ext {
            case "pdf":                     return "doc.text.fill"
            case "jpg","jpeg","png","heic": return "photo.fill"
            case "doc","docx":              return "doc.text.fill"
            default:                        return "doc.fill"
            }
        }()

        let icon = UIImageView(image: UIImage(systemName: iconName))
        icon.translatesAutoresizingMaskIntoConstraints = false
        icon.contentMode = .scaleAspectFit
        icon.tintColor   = .systemBlue

        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text          = isLink ? (URL(string: filename)?.host ?? filename) : filename
        lbl.font          = UIFont.systemFont(ofSize: 16)
        lbl.textColor     = isLink ? .systemBlue : .darkGray
        lbl.numberOfLines = 1

        let delBtn = UIButton(type: .system)
        delBtn.translatesAutoresizingMaskIntoConstraints = false
        delBtn.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        delBtn.tintColor = .systemRed
        delBtn.isHidden  = !canDelete
        delBtn.addTarget(self, action: #selector(deleteAttachmentRow(_:)), for: .touchUpInside)

        container.addSubview(icon); container.addSubview(lbl); container.addSubview(delBtn)
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 50),
            icon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            icon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            icon.widthAnchor.constraint(equalToConstant: 28),
            icon.heightAnchor.constraint(equalToConstant: 28),
            lbl.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
            lbl.trailingAnchor.constraint(equalTo: delBtn.leadingAnchor, constant: -8),
            lbl.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            delBtn.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            delBtn.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            delBtn.widthAnchor.constraint(equalToConstant: 24),
            delBtn.heightAnchor.constraint(equalToConstant: 24)
        ])

        // Tag the container with the pendingAttachments index so delete can find it
        container.tag = pendingAttachments.count  // meaningful only for pending rows

        attachmentsStackView.addArrangedSubview(container)
        updateAttachmentContainerHeight()
    }

    @objc private func deleteAttachmentRow(_ sender: UIButton) {
        guard let container = sender.superview else { return }

        // Find which pending attachment this row corresponds to by matching the tag
        let rowTag = container.tag
        if rowTag < pendingAttachments.count {
            pendingAttachments.remove(at: rowTag)
            // Re-tag remaining rows
            for (i, view) in attachmentsStackView.arrangedSubviews.enumerated() {
                view.tag = i
            }
        }

        UIView.animate(withDuration: 0.25, animations: { container.alpha = 0 }) { _ in
            self.attachmentsStackView.removeArrangedSubview(container)
            container.removeFromSuperview()
            if self.attachmentsStackView.arrangedSubviews.isEmpty { self.showNoResourcesLabel() }
            self.updateAttachmentContainerHeight()
        }
    }

    private func updateAttachmentContainerHeight() {
        attachmentsStackView.layoutIfNeeded()
        let count = attachmentsStackView.arrangedSubviews.count
        let h: CGFloat = count == 0 ? 50 : 70 + (50 + 8) * CGFloat(count) + 20
        attachmentContainerHeightConstraint.constant = h
        UIView.animate(withDuration: 0.3) { self.view.layoutIfNeeded() }
    }

    // MARK: - Placeholder image

    private func placeholderImage(for name: String) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        let ctx = UIGraphicsGetCurrentContext()!
        UIColor.systemBlue.setFill(); ctx.fillEllipse(in: CGRect(origin: .zero, size: size))
        let initial = String(name.prefix(1)).uppercased()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18), .foregroundColor: UIColor.white
        ]
        let t = initial.size(withAttributes: attrs)
        initial.draw(in: CGRect(x: (size.width-t.width)/2, y: (size.height-t.height)/2,
                                width: t.width, height: t.height), withAttributes: attrs)
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }

    // MARK: - Attachment picker

    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
        guard !isSubmitted else {
            showAlert(title: "Already Submitted", message: "Use 'Redo Submission' to modify attachments.")
            return
        }
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cam = UIAlertAction(title: "Camera", style: .default) { _ in self.openCamera() }
        cam.setValue(UIImage(systemName: "camera.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal), forKey: "image")
        sheet.addAction(cam)

        let gal = UIAlertAction(title: "Photo Library", style: .default) { _ in self.openPhotoLibrary() }
        gal.setValue(UIImage(systemName: "photo.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal), forKey: "image")
        sheet.addAction(gal)

        let doc = UIAlertAction(title: "Documents", style: .default) { _ in self.openDocumentPicker() }
        doc.setValue(UIImage(systemName: "doc.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal), forKey: "image")
        sheet.addAction(doc)

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let pop = sheet.popoverPresentationController { pop.sourceView = sender; pop.sourceRect = sender.bounds }
        present(sheet, animated: true)
    }

    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Unavailable", message: "Camera not available."); return
        }
        let p = UIImagePickerController(); p.sourceType = .camera; p.delegate = self
        present(p, animated: true)
    }

    private func openPhotoLibrary() {
        let p = UIImagePickerController(); p.sourceType = .photoLibrary; p.delegate = self
        present(p, animated: true)
    }

    private func openDocumentPicker() {
        let p = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .data])
        p.delegate = self; p.allowsMultipleSelection = false
        present(p, animated: true)
    }

    // MARK: - Submit

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        if isSubmitted {
            let a = UIAlertController(title: "Redo Submission",
                                      message: "Allow modifying and resubmitting?",
                                      preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            a.addAction(UIAlertAction(title: "Redo", style: .destructive) { _ in self.redoSubmissionInSupabase() })
            present(a, animated: true)
        } else {
            submitTaskToSupabase()
        }
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate

extension TaskDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage,
              let jpegData = image.jpegData(compressionQuality: 0.75) else { return }

        let base64Str = jpegData.base64EncodedString()
        let filename  = picker.sourceType == .camera
            ? "Camera_\(Int(Date().timeIntervalSince1970)).jpeg"
            : "Photo_\(Int(Date().timeIntervalSince1970)).jpeg"

        let payload = AttachmentPayload(filename: filename, fileType: "image/jpeg",
                                        base64Data: base64Str, isLink: false)

        removeNoResourcesLabel()
        let idx = pendingAttachments.count
        pendingAttachments.append(payload)

        // Tag the newly added row with its index so delete works
        addAttachmentRow(filename: filename, canDelete: true)
        attachmentsStackView.arrangedSubviews.last?.tag = idx
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate

extension TaskDetailViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController,
                        didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }

        // Read raw bytes and base64-encode
        guard url.startAccessingSecurityScopedResource() else { return }
        defer { url.stopAccessingSecurityScopedResource() }

        guard let data = try? Data(contentsOf: url) else {
            showAlert(title: "Error", message: "Could not read file."); return
        }

        let base64Str = data.base64EncodedString()
        let filename  = url.lastPathComponent
        let ext       = url.pathExtension.lowercased()
        let mimeType: String = {
            switch ext {
            case "pdf":        return "application/pdf"
            case "doc","docx": return "application/msword"
            case "txt":        return "text/plain"
            default:           return "application/octet-stream"
            }
        }()

        let payload = AttachmentPayload(filename: filename, fileType: mimeType,
                                        base64Data: base64Str, isLink: false)

        removeNoResourcesLabel()
        let idx = pendingAttachments.count
        pendingAttachments.append(payload)

        addAttachmentRow(filename: filename, canDelete: true)
        attachmentsStackView.arrangedSubviews.last?.tag = idx
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - Supabase Submit / Redo

extension TaskDetailViewController {

    // MARK: Submit for review

    func submitTaskToSupabase() {
        guard let task, let taskId = task.taskId else {
            showAlert(title: "Error", message: "Task information is missing."); return
        }

        guard !pendingAttachments.isEmpty else {
            // Allow submission with no new files — just update status
            updateTaskStatusOnly(taskId: taskId, to: "for_review"); return
        }

        Task {
            do {
                let studentId = UserDefaults.standard.string(forKey: "current_person_id") ?? ""
                let teamIdStr = task.teamId ?? ""

                // ── INSERT each attachment (plain insert, no upsert) ──────────
                for attachment in pendingAttachments {

                    struct AttachmentInsert: Encodable {
                        let task_id:           String
                        let filename:          String
                        let file_type:         String
                        let file_data:         String?   // base64
                        let student_id:        String?
                        let team_id:           String?
                        let mentor_attachment: Bool
                    }

                    let row = AttachmentInsert(
                        task_id:           taskId,
                        filename:          attachment.filename,
                        file_type:         attachment.fileType,
                        file_data:         attachment.base64Data.isEmpty ? nil : attachment.base64Data,
                        student_id:        studentId.isEmpty ? nil : studentId,
                        team_id:           teamIdStr.isEmpty ? nil : teamIdStr,
                        mentor_attachment: false
                    )

                    try await SupabaseManager.shared.client
                        .from("task_attachments")
                        .insert(row)           // ← plain INSERT, no conflict clause
                        .execute()
                }

                // ── Update task status ────────────────────────────────────────
                try await updateStatusRow(taskId: taskId, status: "for_review")

                await MainActor.run { self.markSubmitted() }

            } catch {
                await MainActor.run {
                    self.showAlert(title: "Submission Failed", message: error.localizedDescription)
                }
            }
        }
    }

    /// Update status only (no attachments)
    private func updateTaskStatusOnly(taskId: String, to status: String) {
        Task {
            do {
                try await updateStatusRow(taskId: taskId, status: status)
                await MainActor.run {
                    if status == "for_review" { self.markSubmitted() }
                }
            } catch {
                await MainActor.run {
                    self.showAlert(title: "Submission Failed", message: error.localizedDescription)
                }
            }
        }
    }

    private func updateStatusRow(taskId: String, status: String) async throws {
        struct StatusUpdate: Encodable { let status: String; let updated_at: String }
        try await SupabaseManager.shared.client
            .from("tasks")
            .update(StatusUpdate(status: status,
                                 updated_at: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: taskId)
            .execute()
    }

    private func markSubmitted() {
        isSubmitted = true
        pendingAttachments.removeAll()        // clear in-memory buffer
        submitButton.setTitle("Redo Submission", for: .normal)
        submitButton.backgroundColor   = .systemOrange
        attachmentIconButton.isEnabled = false
        attachmentIconButton.alpha     = 0.5

        // Hide delete buttons on all rows
        attachmentsStackView.arrangedSubviews.forEach { container in
            container.subviews.compactMap { $0 as? UIButton }.forEach { btn in
                UIView.animate(withDuration: 0.3) { btn.alpha = 0 } completion: { _ in btn.isHidden = true }
            }
        }

        showAlert(title: "Submitted ✅",
                  message: "Your task has been sent to the mentor for review.")
    }

    // MARK: Redo submission

    func redoSubmissionInSupabase() {
        guard let task, let taskId = task.taskId else { return }

        Task {
            do {
                try await updateStatusRow(taskId: taskId, status: "ongoing")
                await MainActor.run {
                    isSubmitted = false
                    submitButton.setTitle("Submit for review", for: .normal)
                    submitButton.backgroundColor   = .systemBlue
                    attachmentIconButton.isEnabled = true
                    attachmentIconButton.alpha     = 1.0

                    attachmentsStackView.arrangedSubviews.forEach { container in
                        container.subviews.compactMap { $0 as? UIButton }.forEach { btn in
                            btn.isHidden = false
                            UIView.animate(withDuration: 0.3) { btn.alpha = 1 }
                        }
                    }

                    showAlert(title: "Ready to Edit",
                              message: "You can now modify attachments and resubmit.")
                }
            } catch {
                await MainActor.run {
                    showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
}
