import UIKit
import SafariServices

class ReviewViewController: UIViewController, UITextViewDelegate  {
    
    // MARK: - Properties to receive data from dashboard (DB / Navigation)
    var teamId: String = ""        // ✅ added
    var teamNo: Int = 0            // ✅ added
    var taskId: String = ""        // ✅ added
    
    // Existing ones (keep)
    var taskTitle: String?
    var teamName: String?
    
    // MARK: - Top
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!      // "Review"
    
    // MARK: - Cards (containers)
    @IBOutlet weak var titleCardView: UIView!        // Colour Palette + Due Date
    @IBOutlet weak var attachmentCardView: UIView!   // Attachment
    
    @IBOutlet weak var attachmentFileNameButton: UIButton!
    
    @IBOutlet weak var descriptionCardView: UIView!  // Add remark
    @IBOutlet weak var assignedToCardView: UIView!   // Assigned To
    @IBOutlet weak var statusCardView: UIView!       // Status
    
    // MARK: - Inside cards
    @IBOutlet weak var taskTitleLabel: UILabel!          // Task title label
    @IBOutlet weak var dueDateValueLabel: UILabel!       // right side of "Due Date"
    @IBOutlet weak var remarkTextView: UITextView!       // description / remark
    @IBOutlet weak var assigneeNameLabel: UILabel!       // "Shreya Singh"
    @IBOutlet weak var statusValueLabel: UILabel!        // "In Review"
    
    // MARK: - Bottom buttons
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var completeButton: UIButton!
    
    // Placeholder text for remark
    private let remarkPlaceholder = "Add remark"
    
    let attachmentURLString = "https://drive.google.com/file/d/15u49CPwtkgH7QgTGV1jvwiGVs3yrF25z/view?usp=sharing"
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("✅ ReviewViewController loaded")
        print("✅ teamId: \(teamId)")
        print("✅ teamNo: \(teamNo)")
        print("✅ taskId: \(taskId)")
        print("✅ Task Title: \(taskTitle ?? "nil")")
        print("✅ Team Name: \(teamName ?? "nil")")

        view.backgroundColor = UIColor(
            red: 0xEF/255.0,
            green: 0xEF/255.0,
            blue: 0xF5/255.0,
            alpha: 1.0
        )
        
        setupCards()
        setupDueDateLabel()
        setupRemarkTextView()
        setupAssignedTo()
        setupStatus()
        
        // Display the task data passed from dashboard
        displayTaskData()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        styleTopBackButton()
        styleBottomButtons()
    }
    
    // MARK: - Display Task Data
    private func displayTaskData() {
        // Prefer DB-driven teamNo if available, else fallback to teamName
        if teamNo != 0 {
            print("✅ Team No passed: \(teamNo)")
        }
        
        if let title = taskTitle, !title.isEmpty {
            taskTitleLabel.text = title
            print("✅ Task title set to: \(title)")
        } else {
            taskTitleLabel.text = "No Task Title"
            print("⚠️ No task title provided")
        }
        
        if let team = teamName {
            print("✅ Reviewing task from: \(team)")
        }
    }
    
    // MARK: - Setup helpers
    
    private func setupCards() {
        let cards = [
            titleCardView,
            attachmentCardView,
            descriptionCardView,
            assignedToCardView,
            statusCardView
        ]
        
        for card in cards.compactMap({ $0 }) {
            card.layer.cornerRadius = 20
            card.layer.masksToBounds = true
            card.backgroundColor = .white
        }
    }
    
    private func styleTopBackButton() {
        backButton.layer.cornerRadius = backButton.bounds.height / 2
        backButton.layer.masksToBounds = true
        backButton.backgroundColor = .white
    }
    
    private func styleBottomButtons() {
        [rejectButton, completeButton].forEach { button in
            guard let button = button else { return }
            button.layer.cornerRadius = button.bounds.height / 2
            button.layer.masksToBounds = true
            button.backgroundColor = .white
        }
        
        rejectButton.setTitleColor(.systemRed, for: .normal)
        completeButton.setTitleColor(.systemGreen, for: .normal)
    }
    
    // MARK: - Specific UI elements
    
    private func setupDueDateLabel() {
        dueDateValueLabel.text = "25 Sep 2025"
        dueDateValueLabel.textColor = .systemGray
    }
    
    private func setupRemarkTextView() {
        remarkTextView.delegate = self
        remarkTextView.text = remarkPlaceholder
        remarkTextView.textColor = .systemGray3
        remarkTextView.backgroundColor = .clear
    }
    
    private func setupAssignedTo() {
        assigneeNameLabel.text = "Shreya Singh"
        assigneeNameLabel.textColor = .systemGray
    }
    
    private func setupStatus() {
        statusValueLabel.text = "In Review"
        statusValueLabel.textColor = UIColor.systemYellow
    }
    
    // MARK: - Actions
    
    @IBAction func backButtonTapped(_ sender: UIButton) {
        print("✅ Back button tapped")
        
        if navigationController != nil {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
        guard let url = URL(string: attachmentURLString) else { return }
        let safariVC = SFSafariViewController(url: url)
        safariVC.modalPresentationStyle = .pageSheet
        present(safariVC, animated: true)
    }
    
    @IBAction func rejectButtonTapped(_ sender: UIButton) {
        print("Reject tapped for task: \(taskTitle ?? "Unknown")")
        
        let alert = UIAlertController(
            title: "Reject Task",
            message: "Are you sure you want to reject this task?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Reject", style: .destructive) { [weak self] _ in
            self?.handleRejection()
        })
        
        present(alert, animated: true)
    }
    
    @IBAction func completeButtonTapped(_ sender: UIButton) {
        print("Complete tapped for task: \(taskTitle ?? "Unknown")")
        
        let alert = UIAlertController(
            title: "Complete Task",
            message: "Mark this task as complete?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Complete", style: .default) { [weak self] _ in
            self?.handleCompletion()
        })
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper Methods
    
    private func handleRejection() {
        let successAlert = UIAlertController(
            title: "Task Rejected",
            message: "The task has been rejected successfully.",
            preferredStyle: .alert
        )
        
        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if self?.navigationController != nil {
                self?.navigationController?.popViewController(animated: true)
            } else {
                self?.dismiss(animated: true)
            }
        })
        
        present(successAlert, animated: true)
    }
    
    private func handleCompletion() {
        let successAlert = UIAlertController(
            title: "Task Completed",
            message: "The task has been marked as complete.",
            preferredStyle: .alert
        )
        
        successAlert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            if self?.navigationController != nil {
                self?.navigationController?.popViewController(animated: true)
            } else {
                self?.dismiss(animated: true)
            }
        })
        
        present(successAlert, animated: true)
    }
    
    // MARK: - UITextViewDelegate (placeholder behaviour)
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView == remarkTextView,
           textView.text == remarkPlaceholder {
            textView.text = ""
            textView.textColor = .label
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView == remarkTextView {
            let trimmed = textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty {
                textView.text = remarkPlaceholder
                textView.textColor = .systemGray3
            }
        }
    }
}
