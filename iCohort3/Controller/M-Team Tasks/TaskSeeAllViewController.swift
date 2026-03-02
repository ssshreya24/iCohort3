//
//  TaskSeeAllViewController.swift
//  iCohort3
//
//  ✅ FIXED:
//    - didUpdateTask now calls saveAttachments with team_id: nil
//    - base64-encodes images before Supabase insert (plain INSERT, no upsert)
//

import UIKit
import Supabase
import PostgREST

// MARK: - Delegate

protocol TaskSeeAllDelegate: AnyObject {
    func didUpdateTask(in category: TaskCategory, at index: Int, with task: TaskModel)
    func didDeleteTask(in category: TaskCategory, at index: Int)
}

// MARK: - TaskSeeAllViewController

class TaskSeeAllViewController: UIViewController {

    weak var delegate:       TaskSeeAllDelegate?
    weak var reviewDelegate: ReviewViewControllerDelegate?

    private var category: TaskCategory
    private var tasks:    [TaskModel]

    var teamMemberImages: [UIImage] = []
    var teamMemberNames:  [String]  = []
    var teamId:           String    = ""
    var mentorId:         String    = ""

    private let backButton    = UIButton()
    private let titleLabel    = UILabel()
    private let collectionView: UICollectionView

    // MARK: - Init

    init(category: TaskCategory, tasks: [TaskModel]) {
        self.category = category
        self.tasks    = tasks

        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection    = .vertical
        layout.minimumLineSpacing = 16
        self.collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)

        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        transitioningDelegate  = self
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 242/255, green: 242/255, blue: 247/255, alpha: 1)
        setupBackButton()
        setupTitleLabel()
        setupCollectionView()
    }

    // MARK: - UI Setup

    private func setupBackButton() {
        view.addSubview(backButton)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16)
        ])
        backButton.backgroundColor     = .white
        backButton.layer.cornerRadius  = 22
        backButton.layer.masksToBounds = true

        let chevron = UIImage(
            systemName: "chevron.left",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        )?.withTintColor(.black, renderingMode: .alwaysOriginal)

        backButton.setImage(chevron, for: .normal)
        backButton.imageView?.contentMode = .scaleAspectFit
        backButton.addTarget(self, action: #selector(backButtonPressed), for: .touchUpInside)
    }

    @objc private func backButtonPressed() { dismiss(animated: true) }

    private func setupTitleLabel() {
        titleLabel.font = .boldSystemFont(ofSize: 28)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: backButton.trailingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -16)
        ])

        switch category {
        case .assigned:
            titleLabel.text      = "Assigned"
            titleLabel.textColor = .systemBlue
        case .review:
            titleLabel.text      = "For Review"
            titleLabel.textColor = .systemYellow
        case .completed:
            titleLabel.text      = "Completed"
            titleLabel.textColor = .systemGreen
        case .rejected:
            titleLabel.text      = "Rejected"
            titleLabel.textColor = .systemRed
        }
    }

    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 16),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        collectionView.delegate   = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "TaskCardCellNew", bundle: nil),
                                forCellWithReuseIdentifier: "TaskCardCellNew")
    }

    // MARK: - Delete Task

    private func handleDeleteTask(at index: Int) {
        let a = UIAlertController(title: "Delete Task",
                                  message: "Are you sure you want to delete this task?",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let self else { return }
            self.tasks.remove(at: index)
            self.delegate?.didDeleteTask(in: self.category, at: index)
            self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        })
        present(a, animated: true)
    }

    // MARK: - Edit Task

    private func presentEditTask(at index: Int) {
        let task = tasks[index]

        let vc                 = NewTaskViewController(nibName: "NewTaskViewController", bundle: nil)
        vc.delegate            = self
        vc.teamMemberImages    = teamMemberImages
        vc.teamMemberNames     = teamMemberNames
        vc.teamId              = teamId
        vc.mentorId            = mentorId
        vc.isEditMode          = true
        vc.existingTaskId      = task.id
        vc.existingTitle       = task.title
        vc.existingDescription = task.desc
        vc.existingDate        = task.assignedDate
        vc.selectedMemberName  = task.name
        vc.existingAttachments = task.attachments ?? []
        vc.editingTaskIndex    = index
        vc.editingCategory     = category
        if let fn = task.attachmentFilenames { vc.attachmentFilenames = fn }

        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    // MARK: - Attachment Viewer

    private func presentAttachmentViewer(attachments: [UIImage], filenames: [String] = []) {
        let vc = AttachmentViewerViewController(attachments: attachments, attachmentFilenames: filenames)
        vc.modalPresentationStyle = .fullScreen
        vc.modalTransitionStyle   = .crossDissolve
        present(vc, animated: true)
    }

    // MARK: - Open ReviewViewController

    private func presentReviewViewController(for task: TaskModel) {
        guard let taskId = task.id else { return }
        let vc         = ReviewViewController(nibName: "ReviewViewController", bundle: nil)
        vc.taskId      = taskId
        vc.teamId      = teamId
        vc.taskTitle   = task.title
        vc.delegate    = self
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    // MARK: - Save Attachments to Supabase
    //
    // ⚠️  team_id is ALWAYS nil.
    //     task_attachments.team_id FK → old `teams` table (not `new_teams`).
    //     Passing a new_teams UUID causes a FK violation.

    private func saveAttachments(
        taskId:    String,
        filenames: [String],
        images:    [UIImage]
    ) async {
        guard !filenames.isEmpty else { return }

        struct AttachmentInsert: Encodable {
            let task_id:           String
            let filename:          String
            let file_type:         String
            let file_data:         String?
            let mentor_id:         String?
            let team_id:           String?   // always nil
            let student_id:        String?
            let mentor_attachment: Bool
        }

        let mentorPersonId = mentorId.isEmpty ? nil : mentorId

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
                case "pdf":        return "application/pdf"
                case "jpg","jpeg": return "image/jpeg"
                case "png":        return "image/png"
                case "doc","docx": return "application/msword"
                default:           return "application/octet-stream"
                }
            }()

            let row = AttachmentInsert(
                task_id:           taskId,
                filename:          filename,
                file_type:         mimeType,
                file_data:         base64Data,
                mentor_id:         mentorPersonId,
                team_id:           nil,          // ← always nil
                student_id:        nil,
                mentor_attachment: true
            )

            do {
                try await SupabaseManager.shared.client
                    .from("task_attachments")
                    .insert(row)
                    .execute()
                print("✅ Attachment saved: \(filename)")
            } catch {
                print("❌ Attachment save failed (\(filename)):", error)
            }
        }
    }
}

// MARK: - ReviewViewControllerDelegate

extension TaskSeeAllViewController: ReviewViewControllerDelegate {
    func reviewViewController(_ vc: ReviewViewController,
                              didChangeStatusTo status: String,
                              forTaskId taskId: String) {
        if let idx = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks.remove(at: idx)
            collectionView.deleteItems(at: [IndexPath(row: idx, section: 0)])
        }
        reviewDelegate?.reviewViewController(vc, didChangeStatusTo: status, forTaskId: taskId)
    }
}

// MARK: - NewTaskDelegate

extension TaskSeeAllViewController: NewTaskDelegate {

    func didAssignTask(to memberName: String, description: String, date: Date,
                       title: String, attachments: [UIImage], attachmentFilenames: [String]) {
        // Not used — TaskSeeAllViewController only edits existing tasks
    }

    func didUpdateTask(at index: Int, memberName: String, description: String,
                       date: Date, title: String, attachments: [UIImage],
                       attachmentFilenames: [String]) {
        guard index < tasks.count else { return }

        let df = DateFormatter()
        df.dateFormat = "dd MMM yyyy"

        let updated = TaskModel(
            id:                  tasks[index].id,
            name:                memberName,
            desc:                description,
            date:                df.string(from: date),
            remark:              tasks[index].remark,
            remarkDesc:          tasks[index].remarkDesc,
            title:               title,
            attachments:         attachments,
            attachmentFilenames: attachmentFilenames,
            assignedDate:        date,
            status:              tasks[index].status
        )

        tasks[index] = updated
        delegate?.didUpdateTask(in: category, at: index, with: updated)
        collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])

        // Persist the update + new attachments to Supabase
        if let taskId = updated.id {
            Task {
                // Update task row fields
                struct TaskUpdate: Encodable {
                    let title: String; let description: String
                    let assigned_date: String; let updated_at: String
                }
                do {
                    try await SupabaseManager.shared.client
                        .from("tasks")
                        .update(TaskUpdate(
                            title:         title,
                            description:   description,
                            assigned_date: ISO8601DateFormatter().string(from: date),
                            updated_at:    ISO8601DateFormatter().string(from: Date())
                        ))
                        .eq("id", value: taskId)
                        .execute()
                } catch {
                    print("❌ TaskSeeAll updateTask failed:", error)
                }

                // Save new attachments (team_id nil to avoid FK violation)
                await saveAttachments(
                    taskId:    taskId,
                    filenames: attachmentFilenames,
                    images:    attachments
                )
            }
        }

        let a = UIAlertController(title: "Task Updated ✅",
                                  message: "'\(title)' updated successfully",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Collection View

extension TaskSeeAllViewController: UICollectionViewDelegate,
                                    UICollectionViewDataSource,
                                    UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int { tasks.count }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "TaskCardCellNew", for: indexPath) as! TaskCardCellNew
        let task = tasks[indexPath.row]

        cell.configure(
            profile:     UIImage(named: "Student"),
            assignedTo:  "Assigned To",
            name:        task.name,
            desc:        task.desc,
            date:        task.date,
            remark:      task.remark,
            remarkDesc:  task.remarkDesc,
            title:       task.title,
            attachments: task.attachments
        )

        cell.onEllipsisMenu = { [weak self] _ in
            guard let self else { return }
            if self.category == .review {
                self.presentReviewViewController(for: task)
            } else {
                self.presentEditTask(at: indexPath.row)
            }
        }

        cell.onAttachmentTapped = { [weak self] attachments in
            guard let self else { return }
            let filenames = self.tasks[indexPath.row].attachmentFilenames ?? []
            self.presentAttachmentViewer(attachments: attachments, filenames: filenames)
        }

        cell.onDeleteTapped = { [weak self] _ in
            self?.handleDeleteTask(at: indexPath.row)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let task   = tasks[indexPath.row]
        let height: CGFloat = (task.remark != nil && task.remarkDesc != nil) ? 200 : 170
        return CGSize(width: collectionView.frame.width, height: height)
    }
}

// MARK: - Custom Transition

extension TaskSeeAllViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        SlideInFromRightAnimator()
    }
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        SlideOutToRightAnimator()
    }
}

// MARK: - Animators (kept in same file to avoid duplication)

class SlideInFromRightAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.35 }
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let toView = ctx.view(forKey: .to) else { return }
        let container = ctx.containerView
        container.addSubview(toView)
        toView.frame = container.bounds.offsetBy(dx: container.bounds.width, dy: 0)
        UIView.animate(withDuration: 0.35, animations: { toView.frame = container.bounds }) { done in
            ctx.completeTransition(done)
        }
    }
}

class SlideOutToRightAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using ctx: UIViewControllerContextTransitioning?) -> TimeInterval { 0.35 }
    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        guard let fromView = ctx.view(forKey: .from),
              let toView   = ctx.view(forKey: .to) else { return }
        let container = ctx.containerView
        container.insertSubview(toView, belowSubview: fromView)
        UIView.animate(
            withDuration: 0.35,
            animations: { fromView.frame = fromView.frame.offsetBy(dx: container.bounds.width, dy: 0) },
            completion: { done in ctx.completeTransition(done) }
        )
    }
}
