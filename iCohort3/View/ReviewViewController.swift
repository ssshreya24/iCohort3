//
//  ReviewViewController.swift
//  iCohort3
//

import UIKit
import SafariServices
import Supabase
import PostgREST
// MARK: - Delegate
protocol ReviewViewControllerDelegate: AnyObject {
    func reviewViewController(_ vc: ReviewViewController,
                              didChangeStatusTo status: String,
                              forTaskId taskId: String)
}

class ReviewViewController: UIViewController, UITextViewDelegate {

    // MARK: - Public (set before presenting)
    var teamId:    String = ""
    var teamNo:    Int    = 0
    var taskId:    String = ""
    var taskTitle: String?
    var teamName:  String?

    weak var delegate: ReviewViewControllerDelegate?

    // MARK: - Outlets
    @IBOutlet weak var backButton:               UIButton!
    @IBOutlet weak var titleLabel:               UILabel!
    @IBOutlet weak var scrollView:               UIScrollView!

    @IBOutlet weak var titleCardView:            UIView!
    @IBOutlet weak var attachmentCardView:       UIView!
    @IBOutlet weak var attachmentFileNameButton: UIButton!
    @IBOutlet weak var descriptionCardView:      UIView!
    @IBOutlet weak var assignedToCardView:       UIView!
    @IBOutlet weak var statusCardView:           UIView!

    @IBOutlet weak var taskTitleLabel:           UILabel!
    @IBOutlet weak var dueDateValueLabel:        UILabel!
    @IBOutlet weak var remarkTextView:           UITextView!
    @IBOutlet weak var assigneeNameLabel:        UILabel!
    @IBOutlet weak var statusValueLabel:         UILabel!


    @IBOutlet weak var rejectButton:             UIButton!
    @IBOutlet weak var completeButton:           UIButton!

    // MARK: - Private
    private let remarkPlaceholder    = "Add remark"
    private var firstAttachmentName: String?
    private var fetchedAttachments: [SupabaseManager.TaskAttachmentRow] = []
    private var isUpdating           = false

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor(red: 0xEF/255.0,
                                       green: 0xEF/255.0,
                                       blue:  0xF5/255.0,
                                       alpha: 1)

        // Immediate placeholders while Supabase loads
        taskTitleLabel.text    = taskTitle ?? "Loading…"
        assigneeNameLabel.text = "Loading…"
        dueDateValueLabel.text = "—"

        // Fix assigneeNameLabel truncation
        assigneeNameLabel.numberOfLines = 1
        assigneeNameLabel.adjustsFontSizeToFitWidth = true
        assigneeNameLabel.minimumScaleFactor = 0.7
        assigneeNameLabel.lineBreakMode = .byTruncatingTail

        // Show attachment card with placeholder until data loads
        attachmentCardView.isHidden = false
        attachmentFileNameButton.setTitle("Loading…", for: .normal)
        attachmentFileNameButton.setTitleColor(.systemGray3, for: .normal)
        attachmentFileNameButton.isEnabled = false

        setupCards()
        setupRemarkTextView()
        setupRefreshControl()
        applyStatusUI(for: "for_review")

        Task { await loadFromSupabase() }
    }
    
    private func setupRefreshControl() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        scrollView?.refreshControl = refreshControl
    }
    
    @objc private func handleRefresh() {
        Task { await loadFromSupabase() }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        styleBackButton()
        styleActionButtons()
    }

    // MARK: - Supabase Load

    private func loadFromSupabase() async {
        guard !taskId.isEmpty else { return }
        
        do {
            // ── 1. Task row ───────────────────────────────────────────────────
            struct TaskRow: Decodable {
                let title:              String?
                let assigned_date:      String?
                let remark_description: String?
                let status:             String?
            }

            let rows: [TaskRow] = try await SupabaseManager.shared.client
                .from("tasks")
                .select("title, assigned_date, remark_description, status")
                .eq("id", value: taskId)
                .limit(1)
                .execute()
                .value

            guard let row = rows.first else { 
                await MainActor.run { 
                    self.scrollView?.refreshControl?.endRefreshing()
                }
                return 
            }

            // ── 2. Assignee name ──────────────────────────────────────────────
            var assignee = "Team"
            if !teamId.isEmpty {
                assignee = (try? await SupabaseManager.shared
                    .resolveAssigneeNameFromNewTeams(taskId: taskId, teamId: teamId)) ?? "Team"
            }

            // ── 3. Attachments ────────────────────────────────────────────────
            let allAttachments = (try? await SupabaseManager.shared.fetchTaskAttachments(taskId: taskId)) ?? []
            let studentAttachments = allAttachments.filter { $0.mentor_attachment == false || $0.mentor_attachment == nil }
            let firstName   = studentAttachments.first?.filename

            // ── 4. Format date ────────────────────────────────────────────────
            let dueDateStr = formatISO(row.assigned_date)

            // ── 5. Main thread UI ─────────────────────────────────────────────
            await MainActor.run {
                // Title + date
                taskTitleLabel.text    = row.title ?? taskTitle ?? "—"
                dueDateValueLabel.text = dueDateStr

                // Assignee — never truncate awkwardly
                assigneeNameLabel.text = assignee

                // Status badge
                applyStatusUI(for: row.status ?? "for_review")

                // Remark — show placeholder text if no existing remark
                let existingRemark = row.remark_description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if existingRemark.isEmpty {
                    remarkTextView.text      = remarkPlaceholder
                    remarkTextView.textColor = .systemGray3
                } else {
                    remarkTextView.text      = existingRemark
                    remarkTextView.textColor = .label
                }

                // Attachment card — ALWAYS visible, show content or "No attachment"
                self.fetchedAttachments      = studentAttachments
                firstAttachmentName          = firstName
                attachmentCardView.isHidden  = false

                if let name = firstName {
                    let isLink  = name.hasPrefix("http://") || name.hasPrefix("https://")
                    let display = isLink ? (URL(string: name)?.host ?? name) : name
                    attachmentFileNameButton.setTitle(display, for: .normal)
                    attachmentFileNameButton.setTitleColor(.systemBlue, for: .normal)
                    attachmentFileNameButton.isEnabled = true
                } else {
                    attachmentFileNameButton.setTitle("No attachment", for: .normal)
                    attachmentFileNameButton.setTitleColor(.systemGray3, for: .normal)
                    attachmentFileNameButton.isEnabled = false
                }
                
                self.scrollView?.refreshControl?.endRefreshing()
            }

        } catch {
            print("❌ ReviewViewController.loadFromSupabase:", error)
            await MainActor.run {
                // Even on error keep the attachment card visible with error state
                attachmentFileNameButton.setTitle("Could not load", for: .normal)
                attachmentFileNameButton.setTitleColor(.systemGray3, for: .normal)
                attachmentFileNameButton.isEnabled = false
                self.scrollView?.refreshControl?.endRefreshing()
            }
        }
    }

    // MARK: - Status UI

    private func applyStatusUI(for raw: String) {
        statusValueLabel.text      = displayStatus(for: raw)
        statusValueLabel.textColor = statusColor(for: raw)
    }

    private func displayStatus(for raw: String) -> String {
        switch raw {
        case "for_review": return "In Review"
        case "approved":   return "Approved"
        case "completed":  return "Completed"
        case "rejected":   return "Rejected"
        case "assigned":   return "Assigned"
        case "ongoing":    return "Ongoing"
        default:           return raw.capitalized
        }
    }

    private func statusColor(for raw: String) -> UIColor {
        switch raw {
        case "for_review": return .systemYellow
        case "approved":   return .systemGreen
        case "completed":  return .systemGreen
        case "rejected":   return .systemRed
        default:           return .systemBlue
        }
    }

    // MARK: - Date Format

    private func formatISO(_ raw: String?) -> String {
        guard let raw else { return "—" }
        let f1 = ISO8601DateFormatter()
        f1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let f2 = ISO8601DateFormatter()
        if let d = f1.date(from: raw) ?? f2.date(from: raw) {
            let df = DateFormatter()
            df.dateFormat = "dd MMM yyyy"
            return df.string(from: d)
        }
        return raw
    }

    // MARK: - UI Setup

    private func setupCards() {
        [titleCardView, attachmentCardView, descriptionCardView,
         assignedToCardView, statusCardView]
            .compactMap { $0 }
            .forEach {
                $0.layer.cornerRadius  = 20
                $0.layer.masksToBounds = true
                $0.backgroundColor     = .white
            }
    }

    private func styleBackButton() {
        backButton.layer.cornerRadius  = backButton.bounds.height / 2
        backButton.layer.masksToBounds = true
        backButton.backgroundColor     = .white
    }

    private func styleActionButtons() {
        [rejectButton, completeButton].compactMap { $0 }.forEach {
            $0.layer.cornerRadius  = $0.bounds.height / 2
            $0.layer.masksToBounds = true
            $0.backgroundColor     = .white
        }
        rejectButton?.setTitleColor(.systemRed,    for: .normal)
        completeButton?.setTitleColor(.systemGreen, for: .normal)
    }

    private func setupRemarkTextView() {
        remarkTextView.delegate        = self
        remarkTextView.text            = remarkPlaceholder
        remarkTextView.textColor       = .systemGray3
        remarkTextView.backgroundColor = .clear
        // Ensure placeholder is visible on first render
        remarkTextView.font            = UIFont.systemFont(ofSize: 16)
    }

    // MARK: - IBActions

    @IBAction func backButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
        guard let name = firstAttachmentName else { return }
        
        // 1. Handle Link
        let isLink = name.hasPrefix("http://") || name.hasPrefix("https://")
        if isLink, let url = URL(string: name) {
            let safari = SFSafariViewController(url: url)
            safari.modalPresentationStyle = .pageSheet
            present(safari, animated: true)
            return
        }
        
        // 2. Decode Base64 Image
        if let attachmentRow = fetchedAttachments.first(where: { $0.filename == name }),
           let base64 = attachmentRow.file_data,
           let data = Data(base64Encoded: base64, options: .ignoreUnknownCharacters),
           let image = UIImage(data: data) {
            
            let viewer = AttachmentViewerViewController(attachments: [image], attachmentFilenames: [name])
            viewer.modalPresentationStyle = UIModalPresentationStyle.fullScreen
            present(viewer, animated: true)
            return
        }
        
        // 3. Fallback for files with no base64 content
        let a = UIAlertController(title: "Attachment", message: name, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    @IBAction func rejectButtonTapped(_ sender: UIButton) {
        guard !isUpdating else { return }
        let a = UIAlertController(title: "Reject Task",
                                  message: "Are you sure you want to reject this task?",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Reject", style: .destructive) { [weak self] _ in
            self?.commitStatusUpdate("rejected")
        })
        present(a, animated: true)
    }

    @IBAction func completeButtonTapped(_ sender: UIButton) {
        guard !isUpdating else { return }
        let a = UIAlertController(title: "Approve Task",
                                  message: "Mark this task as approved?",
                                  preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        a.addAction(UIAlertAction(title: "Approve", style: .default) { [weak self] _ in
            self?.commitStatusUpdate("approved")
        })
        present(a, animated: true)
    }

    // MARK: - Supabase Update

    private func commitStatusUpdate(_ newStatus: String) {
        guard !taskId.isEmpty else {
            showAlert(title: "Error", message: "Task ID is missing.")
            return
        }
        isUpdating = true

        let remarkText: String? = {
            let t = remarkTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            return (t.isEmpty || t == remarkPlaceholder) ? nil : t
        }()

        Task {
            do {
                struct TaskUpdate: Encodable {
                    let status:             String
                    let remark:             String
                    let remark_description: String?
                    let updated_at:         String
                }

                let payload = TaskUpdate(
                    status:             newStatus,
                    remark:             newStatus == "rejected" ? "Rejected by mentor" : "Approved by mentor",
                    remark_description: remarkText,
                    updated_at:         ISO8601DateFormatter().string(from: Date())
                )

                try await SupabaseManager.shared.client
                    .from("tasks")
                    .update(payload)
                    .eq("id", value: taskId)
                    .execute()
                
                // Sync counters for mentor dashboard
                if !teamId.isEmpty {
                    try? await SupabaseManager.shared.recalculateAndSyncTeamTaskCounters(teamId: teamId)
                }

                await MainActor.run {
                    self.isUpdating = false
                    self.applyStatusUI(for: newStatus)

                    self.delegate?.reviewViewController(self,
                                                       didChangeStatusTo: newStatus,
                                                       forTaskId: self.taskId)

                    let title   = newStatus == "rejected" ? "Task Rejected"  : "Task Approved"
                    let message = newStatus == "rejected"
                        ? "The task has been rejected successfully."
                        : "The task has been marked as approved."

                    let ok = UIAlertController(title: title, message: message, preferredStyle: .alert)
                    ok.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                        self?.dismiss(animated: true)
                    })
                    self.present(ok, animated: true)
                }
            } catch {
                await MainActor.run {
                    self.isUpdating = false
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - UITextViewDelegate

    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == remarkPlaceholder {
            textView.text      = ""
            textView.textColor = .label
        }
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            textView.text      = remarkPlaceholder
            textView.textColor = .systemGray3
        }
    }
}
