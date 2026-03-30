import UIKit
import Supabase
import PostgREST

// MARK: - Segment Options
enum TaskSegment: Int, CaseIterable {
    case assigned   = 0
    case review     = 1
    case completed  = 2
    case rejected   = 3

    var title: String {
        switch self {
        case .assigned:  return "Assigned"
        case .review:    return "Review"
        case .completed: return "Done"
        case .rejected:  return "Rejected"
        }
    }

    var color: UIColor {
        switch self {
        case .assigned:  return UIColor.systemBlue
        case .review:    return UIColor.systemOrange
        case .completed: return UIColor.systemGreen
        case .rejected:  return UIColor.systemRed
        }
    }

    var taskCategory: TaskCategory {
        switch self {
        case .assigned:  return .assigned
        case .review:    return .review
        case .completed: return .completed
        case .rejected:  return .rejected
        }
    }
}

// MARK: - LiquidGlassSegmentControl
final class LiquidGlassSegmentControl: UIView {

    // MARK: Public
    var selectedIndex: Int = 0 {
        didSet { animateSelection(to: selectedIndex) }
    }
    var onSelectionChanged: ((Int) -> Void)?

    // MARK: Private
    private let segments = TaskSegment.allCases
    private var buttons: [UIButton] = []

    /// Sliding white pill — matches the tab bar style in the reference image
    private let pill: UIView = {
        let v = UIView()
        v.backgroundColor     = .white
        v.layer.cornerRadius  = 22
        v.layer.masksToBounds = false
        v.layer.shadowColor   = UIColor.black.cgColor
        v.layer.shadowOpacity = 0.10
        v.layer.shadowRadius  = 6
        v.layer.shadowOffset  = CGSize(width: 0, height: 2)
        return v
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis         = .horizontal
        sv.distribution = .fillEqually
        sv.spacing      = 0
        return sv
    }()

    /// Light grey track — matches the rounded capsule background in the reference image
    private let track: UIView = {
        let v = UIView()
        v.backgroundColor    = UIColor(red: 233/255, green: 233/255, blue: 238/255, alpha: 1)
        v.layer.cornerRadius = 26
        v.clipsToBounds      = true
        return v
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear
        layer.shadowColor   = UIColor.black.cgColor
        layer.shadowOpacity = 0.07
        layer.shadowRadius  = 10
        layer.shadowOffset  = CGSize(width: 0, height: 3)

        addSubview(track)
        addSubview(pill)
        addSubview(stackView)

        segments.forEach { seg in
            let btn = makeButton(for: seg)
            buttons.append(btn)
            stackView.addArrangedSubview(btn)
        }
    }

    private func makeButton(for segment: TaskSegment) -> UIButton {
        let btn = UIButton(type: .system)
        btn.tag = segment.rawValue

        var config = UIButton.Configuration.plain()
        config.title = segment.title
        config.baseForegroundColor = UIColor.label.withAlphaComponent(0.40)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var out = incoming
            out.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
            return out
        }
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 2, bottom: 0, trailing: 2)
        btn.configuration    = config
        btn.addTarget(self, action: #selector(segmentTapped(_:)), for: .touchUpInside)
        return btn
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        track.frame     = bounds
        stackView.frame = bounds

        if pill.frame == .zero, bounds.width > 0 {
            pill.frame = pillFrame(for: selectedIndex)
        }
        updateButtonColors(animated: false)
    }

    private func pillFrame(for index: Int) -> CGRect {
        guard bounds.width > 0, !segments.isEmpty else { return .zero }
        let w     = bounds.width / CGFloat(segments.count)
        let inset = CGFloat(4)
        return CGRect(x: CGFloat(index) * w + inset,
                      y: inset,
                      width: w - inset * 2,
                      height: bounds.height - inset * 2)
    }

    private func animateSelection(to index: Int) {
        UIView.animate(
            withDuration: 0.38,
            delay: 0,
            usingSpringWithDamping: 0.75,
            initialSpringVelocity: 0.2,
            options: [.curveEaseInOut, .allowUserInteraction]
        ) {
            self.pill.frame = self.pillFrame(for: index)
            self.updateButtonColors(animated: false)
        }
    }

    private func updateButtonColors(animated: Bool) {
        for (i, btn) in buttons.enumerated() {
            let isSelected = i == selectedIndex
            var config = btn.configuration ?? UIButton.Configuration.plain()
            // Selected = near-black label; unselected = muted grey
            config.baseForegroundColor = isSelected
                ? UIColor.label
                : UIColor.label.withAlphaComponent(0.40)
            if animated {
                UIView.transition(with: btn, duration: 0.2, options: .transitionCrossDissolve) {
                    btn.configuration = config
                }
            } else {
                btn.configuration = config
            }
        }
    }

    @objc private func segmentTapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        selectedIndex = sender.tag
        onSelectionChanged?(sender.tag)
    }
}

// MARK: - StudentAllTasksViewController (Redesigned)

final class StudentAllTasksViewController: UIViewController {

    // IBOutlets kept for storyboard compatibility — safe to leave unused
    @IBOutlet weak var verticalCollectionView: UICollectionView!
    @IBOutlet weak var teamTitleLabel:          UILabel!
    @IBOutlet weak var backButton:              UIButton!
    @IBOutlet weak var addButton:               UIButton!

    var teamId:   String = ""
    var teamNo:   Int    = 0
    var teamName: String?
    var currentMentorId: String = ""

    // MARK: - Data
    private var teamMemberNames:  [String]   = []
    private var teamMemberImages: [UIImage]  = []
    private var assignedTasks:    [TaskModel] = []
    private var ongoingTasks:     [TaskModel] = []
    private var reviewTasks:      [TaskModel] = []
    private var completedTasks:   [TaskModel] = []
    private var rejectedTasks:    [TaskModel] = []

    // MARK: - Segment State
    private var selectedSegment: TaskSegment = .assigned

    // MARK: - Custom UI (programmatic — below storyboard header row)
    private let segmentControl    = LiquidGlassSegmentControl()
    private let taskCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection    = .vertical
        layout.minimumLineSpacing = 16
        layout.sectionInset       = UIEdgeInsets(top: 16, left: 16, bottom: 32, right: 16)
        return UICollectionView(frame: .zero, collectionViewLayout: layout)
    }()
    private let emptyStateView = UIView()
    private let emptyStateLabel = UILabel()
    private let emptyStateIcon  = UIImageView()

    // MARK: - Computed tasks for active segment
    private var displayedTasks: [TaskModel] {
        switch selectedSegment {
        case .assigned:  return assignedTasks
        case .review:    return reviewTasks
        case .completed: return completedTasks
        case .rejected:  return rejectedTasks
        }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        if let mid = UserDefaults.standard.string(forKey: "current_person_id"), !mid.isEmpty {
            currentMentorId = mid
        }

        let bg = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        view.backgroundColor = bg

        buildUI()
        setupTaskCollectionView()
        applyTitle()

        Task {
            await loadTeamMembersFromNewTeams()
            await loadTasksFromSupabase()
        }
    }

    // MARK: - Build UI
    private func buildUI() {
        // The storyboard already provides backButton, addButton, teamTitleLabel.
        // We just hide verticalCollectionView (replaced by taskCollectionView)
        // and anchor our new views below the existing storyboard header row.
        verticalCollectionView?.isHidden = true
        teamTitleLabel?.isHidden = true   // title is shown via backButton row in storyboard

        buildTeamProfile()
        buildSegmentControl()
        buildTaskCollection()
        buildEmptyState()
        setupRefreshControl()
    }
    
    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        taskCollectionView.refreshControl = refreshControl
    }
    
    @objc private func handleRefresh() {
        Task { await loadTasksFromSupabase() }
    }

    private func buildHeader() {
        // No-op: header (back/add buttons + title) is handled by the storyboard.
    }

    private func buildTeamProfile() {
        let profileContainer = UIView()
        profileContainer.translatesAutoresizingMaskIntoConstraints = false
        profileContainer.backgroundColor = .clear
        view.addSubview(profileContainer)

        // Anchor below the storyboard's existing back/add button row
        let topAnchor = backButton?.bottomAnchor ?? view.safeAreaLayoutGuide.topAnchor
        NSLayoutConstraint.activate([
            profileContainer.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            profileContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            profileContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            profileContainer.heightAnchor.constraint(equalToConstant: 90),
        ])
        profileContainer.tag = 9001
    }

    private func buildSegmentControl() {
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentControl)

        let profileContainer = view.viewWithTag(9001)!
        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: profileContainer.bottomAnchor, constant: 12),
            segmentControl.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentControl.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentControl.heightAnchor.constraint(equalToConstant: 52),
        ])

        segmentControl.onSelectionChanged = { [weak self] index in
            guard let self, let seg = TaskSegment(rawValue: index) else { return }
            self.selectedSegment = seg
            self.updateSegmentUI()
        }
    }

    private func buildTaskCollection() {
        taskCollectionView.translatesAutoresizingMaskIntoConstraints = false
        taskCollectionView.backgroundColor = .clear
        taskCollectionView.delegate        = self
        taskCollectionView.dataSource      = self
        taskCollectionView.register(
            UINib(nibName: "TaskCardCellNew", bundle: nil),
            forCellWithReuseIdentifier: "TaskCardCellNew"
        )
        view.addSubview(taskCollectionView)

        NSLayoutConstraint.activate([
            taskCollectionView.topAnchor.constraint(equalTo: segmentControl.bottomAnchor, constant: 8),
            taskCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            taskCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            taskCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func buildEmptyState() {
        emptyStateView.translatesAutoresizingMaskIntoConstraints = false
        emptyStateView.isHidden = true
        view.addSubview(emptyStateView)

        NSLayoutConstraint.activate([
            emptyStateView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyStateView.centerYAnchor.constraint(equalTo: taskCollectionView.centerYAnchor),
        ])

        emptyStateIcon.translatesAutoresizingMaskIntoConstraints = false
        emptyStateIcon.tintColor    = .systemGray3
        emptyStateIcon.contentMode  = .scaleAspectFit
        emptyStateView.addSubview(emptyStateIcon)

        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        emptyStateLabel.font      = UIFont.systemFont(ofSize: 15, weight: .regular)
        emptyStateLabel.textColor = .systemGray2
        emptyStateLabel.textAlignment = .center
        emptyStateView.addSubview(emptyStateLabel)

        NSLayoutConstraint.activate([
            emptyStateIcon.topAnchor.constraint(equalTo: emptyStateView.topAnchor),
            emptyStateIcon.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateIcon.widthAnchor.constraint(equalToConstant: 48),
            emptyStateIcon.heightAnchor.constraint(equalToConstant: 48),

            emptyStateLabel.topAnchor.constraint(equalTo: emptyStateIcon.bottomAnchor, constant: 12),
            emptyStateLabel.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
            emptyStateLabel.bottomAnchor.constraint(equalTo: emptyStateView.bottomAnchor),
        ])
    }

    // MARK: - Helpers
    private func applyTitle() {
        // Use the storyboard's existing teamTitleLabel
        teamTitleLabel?.isHidden = false
        if !teamId.isEmpty {
            teamTitleLabel?.text = "Team \(teamNo)"
        } else if let teamName {
            teamTitleLabel?.text = teamName
        } else {
            teamTitleLabel?.text = "Team"
        }
    }

    private func updateSegmentUI() {
        taskCollectionView.reloadData()
        let tasks = displayedTasks
        let isEmpty = tasks.isEmpty

        emptyStateView.isHidden = !isEmpty
        taskCollectionView.isHidden = isEmpty

        if isEmpty {
            let iconName: String
            let message: String
            switch selectedSegment {
            case .assigned:
                iconName = "doc.badge.plus"
                message  = "No tasks assigned yet"
            case .review:
                iconName = "magnifyingglass.circle"
                message  = "No tasks for review yet"
            case .completed:
                iconName = "checkmark.circle"
                message  = "No completed tasks yet"
            case .rejected:
                iconName = "xmark.circle"
                message  = "No rejected tasks"
            }
            emptyStateIcon.image = UIImage(systemName: iconName,
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 40, weight: .thin))
            emptyStateLabel.text = message
        }
    }

    private func reloadTeamProfile() {
        guard let container = view.viewWithTag(9001) else { return }
        container.subviews.forEach { $0.removeFromSuperview() }

        let stack = UIStackView()
        stack.axis         = .horizontal
        stack.distribution = .equalCentering
        stack.alignment    = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
        ])

        for (i, name) in teamMemberNames.enumerated() {
            let memberView  = UIView()
            let avatarView  = UIImageView()
            let nameLabel   = UILabel()

            memberView.translatesAutoresizingMaskIntoConstraints = false
            avatarView.translatesAutoresizingMaskIntoConstraints = false
            nameLabel.translatesAutoresizingMaskIntoConstraints  = false

            avatarView.image              = i < teamMemberImages.count ? teamMemberImages[i] : nil
            avatarView.contentMode        = .scaleAspectFill
            avatarView.layer.cornerRadius = 28
            avatarView.clipsToBounds      = true
            avatarView.backgroundColor    = .systemGray5
            // Ring
            avatarView.layer.borderWidth  = 2
            avatarView.layer.borderColor  = UIColor.white.cgColor
            avatarView.layer.shadowColor  = UIColor.black.cgColor
            avatarView.layer.shadowOpacity = 0.1
            avatarView.layer.shadowRadius = 4

            nameLabel.text          = name.components(separatedBy: " ").first ?? name
            nameLabel.font          = UIFont.systemFont(ofSize: 12, weight: .medium)
            nameLabel.textColor     = .secondaryLabel
            nameLabel.textAlignment = .center

            memberView.addSubview(avatarView)
            memberView.addSubview(nameLabel)
            stack.addArrangedSubview(memberView)

            NSLayoutConstraint.activate([
                avatarView.topAnchor.constraint(equalTo: memberView.topAnchor),
                avatarView.centerXAnchor.constraint(equalTo: memberView.centerXAnchor),
                avatarView.widthAnchor.constraint(equalToConstant: 56),
                avatarView.heightAnchor.constraint(equalToConstant: 56),

                nameLabel.topAnchor.constraint(equalTo: avatarView.bottomAnchor, constant: 4),
                nameLabel.centerXAnchor.constraint(equalTo: memberView.centerXAnchor),
                nameLabel.bottomAnchor.constraint(equalTo: memberView.bottomAnchor),
                nameLabel.widthAnchor.constraint(lessThanOrEqualToConstant: 72),

                memberView.widthAnchor.constraint(equalToConstant: 72),
            ])
        }
    }

    // MARK: - Load Data
    private func loadTeamMembersFromNewTeams() async {
        guard !teamId.isEmpty else { return }
        do {
            let names   = try await SupabaseManager.shared.fetchMemberNamesFromNewTeams(teamId: teamId)
            let avatars = names.map { Self.makeInitialAvatar(from: $0, size: CGSize(width: 56, height: 56)) }
            await MainActor.run {
                self.teamMemberNames  = names
                self.teamMemberImages = avatars
                self.reloadTeamProfile()
            }
        } catch {
            print("❌ loadTeamMembersFromNewTeams:", error)
        }
    }

    private func loadTasksFromSupabase() async {
        guard !teamId.isEmpty else { return }
        do {
            async let assignedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "assigned")
            async let ongoingRows   = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "ongoing")
            async let reviewRows    = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "for_review")
            async let completedRows = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "completed")
            async let rejectedRows  = SupabaseManager.shared.fetchTasksForTeam(teamId: teamId, status: "rejected")

            let (aData, oData, rData, cData, xData) = try await
                (assignedRows, ongoingRows, reviewRows, completedRows, rejectedRows)

            let allRows = aData + oData + rData + cData + xData
            let taskIds = allRows.map(\.id)
            async let assigneeNamesFetch = SupabaseManager.shared.resolveAssigneeNamesFromNewTeams(taskIds: taskIds, teamId: teamId)
            async let attachmentMetadataFetch = SupabaseManager.shared.fetchTaskAttachmentMetadata(taskIds: taskIds)
            let assigneeNamesByTaskId = try await assigneeNamesFetch
            let attachmentMetadata = try await attachmentMetadataFetch
            let attachmentFilenamesByTaskId = Dictionary(grouping: attachmentMetadata, by: \.task_id)
                .mapValues { $0.map(\.filename) }

            let assigned  = convert(aData, assigneeNamesByTaskId: assigneeNamesByTaskId, attachmentFilenamesByTaskId: attachmentFilenamesByTaskId)
            let ongoing   = convert(oData, assigneeNamesByTaskId: assigneeNamesByTaskId, attachmentFilenamesByTaskId: attachmentFilenamesByTaskId)
            let review    = convert(rData, assigneeNamesByTaskId: assigneeNamesByTaskId, attachmentFilenamesByTaskId: attachmentFilenamesByTaskId)
            let completed = convert(cData, assigneeNamesByTaskId: assigneeNamesByTaskId, attachmentFilenamesByTaskId: attachmentFilenamesByTaskId)
            let rejected  = convert(xData, assigneeNamesByTaskId: assigneeNamesByTaskId, attachmentFilenamesByTaskId: attachmentFilenamesByTaskId)

            await MainActor.run {
                self.assignedTasks  = assigned
                self.ongoingTasks   = ongoing
                self.reviewTasks    = review
                self.completedTasks = completed
                self.rejectedTasks  = rejected
                self.updateSegmentUI()
                self.taskCollectionView.refreshControl?.endRefreshing()
            }
        } catch {
            print("❌ loadTasksFromSupabase:", error)
            await MainActor.run { self.taskCollectionView.refreshControl?.endRefreshing() }
        }
    }

    private func convert(
        _ rows: [SupabaseManager.TaskRow],
        assigneeNamesByTaskId: [String: String],
        attachmentFilenamesByTaskId: [String: [String]]
    ) -> [TaskModel] {
        rows.map { row in
            let filenames = attachmentFilenamesByTaskId[row.id]
            return TaskModel.fromRow(
                taskRow: row,
                assigneeName: assigneeNamesByTaskId[row.id] ?? "Team Task",
                attachmentFilenames: filenames,
                hasLazyAttachments: (filenames?.isEmpty == false)
            )
        }
    }

    // MARK: - Setup collection (now flat list)
    private func setupTaskCollectionView() {
        // already done in buildTaskCollection
    }



    // MARK: - Actions
    @IBAction func backButtonTapped(_ sender: Any) { dismiss(animated: true) }
    @IBAction func addButtonTapped(_ sender: Any)  {
        presentNewTaskViewController(isEditMode: false)
    }




    // MARK: - Present NewTask VC
    private func presentNewTaskViewController(isEditMode: Bool,
                                              task: TaskModel? = nil,
                                              category: TaskCategory? = nil,
                                              taskIndex: Int? = nil) {
        let vc      = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)
        vc.delegate = self
        vc.teamMemberImages = teamMemberImages
        vc.teamMemberNames  = teamMemberNames
        vc.teamId           = teamId
        vc.mentorId         = currentMentorId

        if isEditMode, let task, let category, let taskIndex {
            vc.isEditMode          = true
            vc.existingTaskId      = task.id
            vc.existingTitle       = task.title
            vc.existingDescription = task.desc
            vc.existingDate        = task.assignedDate
            vc.selectedMemberName  = task.name
            vc.existingAttachments = task.attachments ?? []
            vc.editingTaskIndex    = taskIndex
            vc.editingCategory     = category
            if let fn = task.attachmentFilenames { vc.attachmentFilenames = fn }
        }

        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    private func presentAttachmentViewer(attachments: [UIImage], filenames: [String] = []) {
        let vc = AttachmentViewerViewController(attachments: attachments, attachmentFilenames: filenames)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle   = .crossDissolve
        present(vc, animated: true)
    }

    private func loadAttachments(for task: TaskModel) async -> ([UIImage], [String]) {
        guard let taskId = task.id else { return ([], task.attachmentFilenames ?? []) }
        do {
            let attachmentRows = try await SupabaseManager.shared.fetchTaskAttachments(taskId: taskId)
            var images: [UIImage] = []
            var filenames: [String] = []

            for attachmentRow in attachmentRows {
                filenames.append(attachmentRow.filename)
                if attachmentRow.file_type == "link" {
                    images.append(SupabaseManager.shared.createLinkPlaceholderImage())
                } else if let base64Data = attachmentRow.file_data,
                          let imageData = Data(base64Encoded: base64Data),
                          let image = UIImage(data: imageData) {
                    images.append(image)
                }
            }

            return (images, filenames)
        } catch {
            print("❌ loadAttachments(for:) failed:", error)
            return ([], task.attachmentFilenames ?? [])
        }
    }

    func getTasksArray(for category: TaskCategory) -> [TaskModel] {
        switch category {
        case .assigned:  return assignedTasks
        case .review:    return reviewTasks
        case .completed: return completedTasks
        case .rejected:  return rejectedTasks
        }
    }

    private func deleteTask(in category: TaskCategory, at index: Int, task: TaskModel) {
        let alert = UIAlertController(
            title: "Delete Task",
            message: "Are you sure you want to delete '\(task.title ?? "this task")'?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            Task {
                do {
                    if let id = task.id { try await SupabaseManager.shared.deleteTask(taskId: id) }
                    await self.loadTasksFromSupabase()
                    await MainActor.run {
                        let ok = UIAlertController(title: "Task Deleted",
                                                   message: "Task deleted successfully.",
                                                   preferredStyle: .alert)
                        ok.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(ok, animated: true)
                    }
                } catch {
                    await MainActor.run {
                        let err = UIAlertController(title: "Error",
                                                    message: "Failed to delete task.",
                                                    preferredStyle: .alert)
                        err.addAction(UIAlertAction(title: "OK", style: .default))
                        self.present(err, animated: true)
                    }
                }
            }
        })
        present(alert, animated: true)
    }

    // MARK: - Save Attachments
    private func saveAttachments(taskId: String, filenames: [String], images: [UIImage]) async {
        guard !filenames.isEmpty else { return }
        struct AttachmentInsert: Encodable {
            let task_id: String; let filename: String; let file_type: String
            let file_data: String?; let mentor_id: String?; let team_id: String?
            let student_id: String?; let mentor_attachment: Bool
        }
        let mentorPersonId = currentMentorId.isEmpty ? nil : currentMentorId
        for (i, filename) in filenames.enumerated() {
            let isLink = filename.hasPrefix("http://") || filename.hasPrefix("https://")
            var base64Data: String? = nil
            if !isLink && i < images.count {
                base64Data = images[i].jpegData(compressionQuality: 0.75)?.base64EncodedString()
            }
            let ext = (filename as NSString).pathExtension.lowercased()
            let mimeType: String = {
                if isLink { return "text/url" }
                switch ext {
                case "pdf": return "application/pdf"
                case "jpg","jpeg": return "image/jpeg"
                case "png": return "image/png"
                case "doc","docx": return "application/msword"
                default: return "application/octet-stream"
                }
            }()
            let row = AttachmentInsert(task_id: taskId, filename: filename, file_type: mimeType,
                                       file_data: base64Data, mentor_id: mentorPersonId,
                                       team_id: nil, student_id: nil, mentor_attachment: true)
            do {
                try await SupabaseManager.shared.client.from("task_attachments").insert(row).execute()
                print("✅ Attachment saved: \(filename)")
            } catch {
                print("❌ Attachment save failed (\(filename)):", error)
            }
        }
    }

    // MARK: - Initial Avatar
    static func makeInitialAvatar(from fullName: String, size: CGSize) -> UIImage {
        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let first   = trimmed.components(separatedBy: .whitespacesAndNewlines).first ?? trimmed
        let letter  = String(first.prefix(1)).uppercased().isEmpty
            ? "?" : String(first.prefix(1)).uppercased()
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: size)
            UIBezierPath(ovalIn: rect).addClip()
            UIColor.systemGray4.setFill()
            ctx.fill(rect)
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: size.width * 0.42, weight: .semibold),
                .foregroundColor: UIColor.label
            ]
            let ts = letter.size(withAttributes: attrs)
            letter.draw(in: CGRect(x: (size.width - ts.width) / 2,
                                   y: (size.height - ts.height) / 2,
                                   width: ts.width, height: ts.height),
                        withAttributes: attrs)
        }
    }
}

// MARK: - UICollectionView (flat task cards)

extension StudentAllTasksViewController: UICollectionViewDelegate,
                                         UICollectionViewDataSource,
                                         UICollectionViewDelegateFlowLayout {

    func collectionView(_ cv: UICollectionView, numberOfItemsInSection s: Int) -> Int {
        displayedTasks.count
    }

    func collectionView(_ cv: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = cv.dequeueReusableCell(
            withReuseIdentifier: "TaskCardCellNew", for: indexPath) as! TaskCardCellNew
        let task = displayedTasks[indexPath.row]
        let cat  = selectedSegment.taskCategory

        cell.configure(
            profile:     TaskCardCellNew.makeAssignedAvatar(from: task.name),
            assignedTo:  "Assigned To",
            name:        task.name,
            desc:        task.desc,
            date:        task.date,
            remark:      task.remark,
            remarkDesc:  task.remarkDesc,
            title:       task.title,
            attachments: task.attachments,
            attachmentCount: task.attachmentFilenames?.count ?? 0
        )

        cell.onEllipsisMenu = { [weak self] _ in
            guard let self else { return }
            self.presentNewTaskViewController(
                isEditMode: true, task: task,
                category: cat, taskIndex: indexPath.row)
        }

        cell.onAttachmentTapped = { [weak self] in
            guard let self else { return }
            Task {
                let loaded = await self.loadAttachments(for: task)
                guard !loaded.0.isEmpty || !loaded.1.isEmpty else { return }
                await MainActor.run {
                    self.presentAttachmentViewer(attachments: loaded.0, filenames: loaded.1)
                }
            }
        }

        cell.onDeleteTapped = { [weak self] _ in
            guard let self else { return }
            self.deleteTask(in: cat, at: indexPath.row, task: task)
        }

        return cell
    }

    func collectionView(_ cv: UICollectionView,
                        layout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let task      = displayedTasks[indexPath.row]
        let hasRemarks = task.remark != nil && task.remarkDesc != nil
        let height: CGFloat = hasRemarks ? 200 : 170
        let width = cv.frame.width - 32
        return CGSize(width: width, height: height)
    }
}

// MARK: - ReviewViewControllerDelegate

extension StudentAllTasksViewController: ReviewViewControllerDelegate {
    func reviewViewController(_ vc: ReviewViewController,
                              didChangeStatusTo status: String,
                              forTaskId taskId: String) {
        Task { await loadTasksFromSupabase() }
    }
}

// MARK: - TaskSeeAllDelegate

extension StudentAllTasksViewController: TaskSeeAllDelegate {
    func didUpdateTask(in category: TaskCategory, at index: Int, with task: TaskModel) {
        Task { await loadTasksFromSupabase() }
    }
    func didDeleteTask(in category: TaskCategory, at index: Int) {
        Task { await loadTasksFromSupabase() }
    }
}

// MARK: - NewTaskDelegate

extension StudentAllTasksViewController: NewTaskDelegate {

    func didAssignTask(to memberName: String, description: String, date: Date,
                       title: String, attachments: [UIImage], attachmentFilenames: [String]) {
        Task {
            do {
                let assignToAll = (memberName == "All Members" || memberName == "Team Task")
                var specificStudentId: String? = nil
                if !assignToAll {
                    specificStudentId = try await SupabaseManager.shared
                        .getStudentIdByName(teamId: teamId, studentName: memberName)
                    guard specificStudentId != nil else {
                        throw NSError(domain: "SATVC", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Student ID not found for \(memberName)"])
                    }
                }
                let taskId = try await createTaskRow(title: title, description: description,
                                                      date: date, assignToAll: assignToAll,
                                                      specificStudentId: specificStudentId)
                await saveAttachments(taskId: taskId, filenames: attachmentFilenames, images: attachments)
                
                // Sync counters for mentor dashboard
                try? await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamId)
                
                await loadTasksFromSupabase()
                await MainActor.run {
                    let a = UIAlertController(title: "Task Assigned ✅",
                                              message: "'\(title)' assigned to \(memberName)",
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Error", message: error.localizedDescription,
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            }
        }
    }

    func didUpdateTask(at index: Int, memberName: String, description: String,
                       date: Date, title: String, attachments: [UIImage],
                       attachmentFilenames: [String]) {
        Task {
            do {
                guard let taskId = findTaskId(at: index) else {
                    throw NSError(domain: "SATVC", code: -1,
                                  userInfo: [NSLocalizedDescriptionKey: "Task ID not found"])
                }
                let assignToAll = (memberName == "All Members" || memberName == "Team Task")
                var specificStudentId: String? = nil
                if !assignToAll {
                    specificStudentId = try await SupabaseManager.shared
                        .getStudentIdByName(teamId: teamId, studentName: memberName)
                    guard specificStudentId != nil else {
                        throw NSError(domain: "SATVC", code: -1,
                                      userInfo: [NSLocalizedDescriptionKey: "Student ID not found for \(memberName)"])
                    }
                }
                try await updateTaskRow(taskId: taskId, title: title, description: description,
                                        date: date, assignToAll: assignToAll,
                                        specificStudentId: specificStudentId)
                await saveAttachments(taskId: taskId, filenames: attachmentFilenames, images: attachments)
                
                // Sync counters for mentor dashboard
                try? await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamId)
                
                await loadTasksFromSupabase()
                await MainActor.run {
                    let a = UIAlertController(title: "Task Updated ✅",
                                              message: "'\(title)' updated successfully",
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            } catch {
                await MainActor.run {
                    let a = UIAlertController(title: "Error", message: error.localizedDescription,
                                              preferredStyle: .alert)
                    a.addAction(UIAlertAction(title: "OK", style: .default))
                    self.present(a, animated: true)
                }
            }
        }
    }

    // MARK: Supabase helpers
    private func createTaskRow(title: String, description: String, date: Date,
                               assignToAll: Bool, specificStudentId: String?) async throws -> String {
        struct TaskInsert: Encodable {
            let team_id, mentor_id, title, description, status, assigned_date: String
        }
        struct CreatedRow: Decodable { let id: String }
        let payload = TaskInsert(team_id: teamId, mentor_id: currentMentorId, title: title,
                                 description: description, status: "assigned",
                                 assigned_date: ISO8601DateFormatter().string(from: date))
        let created: [CreatedRow] = try await SupabaseManager.shared.client
            .from("tasks").insert(payload).select("id").execute().value
        guard let taskId = created.first?.id else {
            throw NSError(domain: "SATVC", code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Task created but ID not returned"])
        }
        if !assignToAll, let studentId = specificStudentId {
            try await insertAssigneeRow(taskId: taskId, studentId: studentId)
        } else if assignToAll {
            await insertAssigneesForAllMembers(taskId: taskId)
        }
        return taskId
    }

    private func updateTaskRow(taskId: String, title: String, description: String,
                               date: Date, assignToAll: Bool, specificStudentId: String?) async throws {
        struct TaskUpdate: Encodable { let title, description, assigned_date, updated_at: String }
        try await SupabaseManager.shared.client.from("tasks")
            .update(TaskUpdate(title: title, description: description,
                               assigned_date: ISO8601DateFormatter().string(from: date),
                               updated_at: ISO8601DateFormatter().string(from: Date())))
            .eq("id", value: taskId).execute()
        try await SupabaseManager.shared.client.from("task_assignees")
            .delete().eq("task_id", value: taskId).execute()
        if !assignToAll, let studentId = specificStudentId {
            try await insertAssigneeRow(taskId: taskId, studentId: studentId)
        } else if assignToAll {
            await insertAssigneesForAllMembers(taskId: taskId)
        }
    }

    private func insertAssigneeRow(taskId: String, studentId: String) async throws {
        struct AssigneeInsert: Encodable { let task_id, student_id: String }
        try await SupabaseManager.shared.client.from("task_assignees")
            .insert(AssigneeInsert(task_id: taskId, student_id: studentId)).execute()
    }

    private func insertAssigneesForAllMembers(taskId: String) async {
        do {
            struct TeamRow: Decodable { let created_by_id: String; let member2_id, member3_id: String? }
            let rows: [TeamRow] = try await SupabaseManager.shared.client
                .from("new_teams").select("created_by_id, member2_id, member3_id")
                .eq("id", value: teamId).limit(1).execute().value
            guard let team = rows.first else { return }
            var ids = [team.created_by_id]
            if let m2 = team.member2_id { ids.append(m2) }
            if let m3 = team.member3_id { ids.append(m3) }
            for id in ids { try? await insertAssigneeRow(taskId: taskId, studentId: id) }
        } catch { print("⚠️ insertAssigneesForAllMembers failed:", error) }
    }

    private func findTaskId(at index: Int) -> String? {
        let all = assignedTasks + reviewTasks + completedTasks + rejectedTasks
        guard index >= 0, index < all.count else { return nil }
        return all[index].id
    }
}
