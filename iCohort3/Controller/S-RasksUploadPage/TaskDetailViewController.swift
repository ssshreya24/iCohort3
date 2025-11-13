//
//  TaskDetailViewController.swift
//  iCohort3
//
//  Created by user@51 on 12/11/25.
//

import UIKit

class TaskDetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var taskTitleLabel: UILabel!
    @IBOutlet weak var dueDateContainerView: UIView!
    @IBOutlet weak var dueDateLabel: UILabel!
    @IBOutlet weak var assignedToContainerView: UIView!
    @IBOutlet weak var assigneeImageView: UIImageView!
    @IBOutlet weak var assigneeNameLabel: UILabel!
    @IBOutlet weak var attachmentContainerView: UIView!
    @IBOutlet weak var attachmentFileLabel: UILabel!
    @IBOutlet weak var attachmentIconButton: UIButton!
    @IBOutlet weak var submitButton: UIButton!
    @IBOutlet weak var successMessageLabel: UILabel!
    
    // MARK: - Properties
    var task: Task?
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureWithSampleData()
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        
        
        // Configure container views
        configureContainerView(dueDateContainerView)
        configureContainerView(assignedToContainerView)
        configureContainerView(attachmentContainerView)
        
        // Configure task title
        taskTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)
        taskTitleLabel.textColor = .black
        
        // Configure due date label
        dueDateLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        dueDateLabel.textColor = UIColor.lightGray
        
        // Configure assignee
        assigneeImageView.layer.cornerRadius = 20
        assigneeImageView.clipsToBounds = true
        assigneeImageView.contentMode = .scaleAspectFill
        assigneeNameLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        assigneeNameLabel.textColor = UIColor.lightGray
        
        // Configure attachment
        attachmentFileLabel.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        attachmentFileLabel.textColor = UIColor.lightGray
        attachmentFileLabel.text = ""
        
        // Configure submit button
        submitButton.backgroundColor = UIColor.systemBlue
        submitButton.setTitle("Submit for review", for: .normal)
        submitButton.titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        submitButton.layer.cornerRadius = 25
        submitButton.isHidden = false
        
        // Configure success message
        successMessageLabel.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        successMessageLabel.textColor = UIColor.systemBlue
        successMessageLabel.text = "Task Submitted!"
        successMessageLabel.isHidden = true
    }
    
    private func configureContainerView(_ view: UIView) {
        view.backgroundColor = .white
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.05
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 8
    }
    
    // MARK: - Configure with Sample Data
    private func configureWithSampleData() {
        // Sample task data
        let sampleTask = Task(
            title: "Design on-Boarding Flow",
            dueDate: "25 Sep 2025",
            assigneeName: "Shreya",
            assigneeImage: nil,
            attachmentName: nil
        )
        
        configure(with: sampleTask)
    }
    
    func configure(with task: Task) {
        self.task = task
        
        taskTitleLabel.text = task.title
        dueDateLabel.text = task.dueDate
        assigneeNameLabel.text = task.assigneeName
        
        // Set assignee image or placeholder
        if let image = task.assigneeImage {
            assigneeImageView.image = image
        } else {
            // Create placeholder with initials
            assigneeImageView.image = createPlaceholderImage(for: task.assigneeName)
        }
        
        // Configure attachment
        if let attachmentName = task.attachmentName {
            attachmentFileLabel.text = attachmentName
            submitButton.isHidden = false
            successMessageLabel.isHidden = true
        } else {
            attachmentFileLabel.text = ""
            submitButton.isHidden = false
            successMessageLabel.isHidden = true
        }
    }
    
    private func createPlaceholderImage(for name: String) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        let context = UIGraphicsGetCurrentContext()!
        
        // Draw circle background
        UIColor(red: 0.4, green: 0.5, blue: 0.6, alpha: 1.0).setFill()
        context.fillEllipse(in: CGRect(origin: .zero, size: size))
        
        // Draw initials
        let initials = String(name.prefix(1))
        let attributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 16, weight: .medium),
            .foregroundColor: UIColor.white
        ]
        
        let textSize = initials.size(withAttributes: attributes)
        let textRect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        initials.draw(in: textRect, withAttributes: attributes)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        
        return image
    }
    
    // MARK: - Actions
    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
        showAttachmentOptions()
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        // Animate button out and show success message
        UIView.animate(withDuration: 0.3, animations: {
            self.submitButton.alpha = 0
        }) { _ in
            self.submitButton.isHidden = true
            self.successMessageLabel.isHidden = false
            self.successMessageLabel.alpha = 0
            
            UIView.animate(withDuration: 0.3) {
                self.successMessageLabel.alpha = 1
            }
        }
    }
    
    private func showAttachmentOptions() {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let galleryAction = UIAlertAction(title: "Gallery", style: .default) { [weak self] _ in
            self?.attachmentFileLabel.text = "Flow.jpeg"
            self?.submitButton.isHidden = false
            self?.successMessageLabel.isHidden = true
        }
        
        let documentsAction = UIAlertAction(title: "Documents", style: .default) { [weak self] _ in
            self?.attachmentFileLabel.text = "Flow.jpeg"
            self?.submitButton.isHidden = false
            self?.successMessageLabel.isHidden = true
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        // Add icons to actions (iOS 13+)
        if #available(iOS 13.0, *) {
            galleryAction.setValue(UIImage(systemName: "photo"), forKey: "image")
            documentsAction.setValue(UIImage(systemName: "doc"), forKey: "image")
        }
        
        alertController.addAction(galleryAction)
        alertController.addAction(documentsAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}

// MARK: - Task Model
struct Task {
    let title: String
    let dueDate: String
    let assigneeName: String
    let assigneeImage: UIImage?
    let attachmentName: String?
}
