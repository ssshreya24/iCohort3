//
//  TaskDetailViewController.swift
//  iCohort3
//

import UIKit

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
    @IBOutlet weak var assigneeImageView: UIImageView!
    @IBOutlet weak var assigneeNameLabel: UILabel!

    // MARK: - Attachment Card
    @IBOutlet weak var attachmentContainerView: UIView!
    @IBOutlet weak var attachmentIconButton: UIButton!
    @IBOutlet weak var attachmentsStackView: UIStackView!

    // MARK: - Submit Button
    @IBOutlet weak var submitButton: UIButton!

    // MARK: - Task Model
    var task: Task?
    
    // MARK: - Height Constraint for dynamic sizing
    @IBOutlet weak var attachmentContainerHeightConstraint: NSLayoutConstraint!

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBackButton()

        // Apply the task only AFTER outlets exist
        if let t = task {
            configure(with: t)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide the default navigation back button
        navigationController?.navigationBar.isHidden = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Show navigation bar when leaving
        navigationController?.navigationBar.isHidden = false
    }

    // MARK: - Custom Back Button Setup
    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Circular background
        backButton.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        backButton.layer.cornerRadius = 22 // Half of height (44)
        
        // Back arrow symbol (SF Symbol)
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let arrowImage = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(arrowImage, for: .normal)
        backButton.tintColor = UIColor.black
        
        // Add target action
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        
        // Add to view
        view.addSubview(backButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44)
        ])
    }
    @objc private func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }

    // MARK: - UI SETUP
    private func setupUI() {

        view.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)

        // Style all card containers
        let cards = [
            dueDateContainerView,
            assignedToContainerView,
            attachmentContainerView
        ]

        cards.forEach { card in
            card?.backgroundColor = .white
            card?.layer.cornerRadius = 20
            card?.layer.shadowColor = UIColor.black.cgColor
            card?.layer.shadowOpacity = 0.06
            card?.layer.shadowOffset = CGSize(width: 0, height: 2)
            card?.layer.shadowRadius = 6
        }

        // Title
        taskTitleLabel.font = UIFont.systemFont(ofSize: 22, weight: .semibold)

        // Due date
        dueDateLabel.font = UIFont.systemFont(ofSize: 16)
        dueDateLabel.textColor = .darkGray

        // Assignee
        assigneeImageView.layer.cornerRadius = 20
        assigneeImageView.clipsToBounds = true
        assigneeNameLabel.font = UIFont.systemFont(ofSize: 16)

        // Attachment stack
        attachmentsStackView.axis = .vertical
        attachmentsStackView.spacing = 8
        attachmentsStackView.alignment = .fill
        attachmentsStackView.distribution = .fill

        // Submit button
        submitButton.layer.cornerRadius = 25
        submitButton.backgroundColor = .systemBlue
        submitButton.setTitleColor(.white, for: .normal)
        submitButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    }

    // MARK: - CONFIGURE TASK
    func configure(with task: Task) {

        // Save the task
        self.task = task

        // If the view is not loaded yet, stop here.
        guard isViewLoaded else { return }

        taskTitleLabel.text = task.title
        dueDateLabel.text = task.dueDate
        assigneeNameLabel.text = task.assigneeName

        // Profile Image
        if let img = task.assigneeImage {
            assigneeImageView.image = img
        } else {
            assigneeImageView.image = placeholderImage(for: task.assigneeName)
        }

        // Clear old attachments
        attachmentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Add new
        for file in task.attachmentNames {
            addAttachmentLabel(file)
        }
        
        // Update container height
        updateAttachmentContainerHeight()
    }

    // MARK: - Helper: Add attachments dynamically
    private func addAttachmentLabel(_ name: String) {
        // Create container for each attachment
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        containerView.layer.cornerRadius = 12
        
        // File icon
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        
        // Determine icon based on file extension
        let fileExtension = (name as NSString).pathExtension.lowercased()
        let iconName: String
        switch fileExtension {
        case "pdf":
            iconName = "doc.text.fill"
        case "jpg", "jpeg", "png", "heic":
            iconName = "photo.fill"
        case "doc", "docx":
            iconName = "doc.text.fill"
        default:
            iconName = "doc.fill"
        }
        iconImageView.image = UIImage(systemName: iconName)
        
        // File name label
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = name
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = .darkGray
        lbl.numberOfLines = 1
        
        // Add subviews
        containerView.addSubview(iconImageView)
        containerView.addSubview(lbl)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 50),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            
            lbl.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            lbl.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            lbl.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
        
        attachmentsStackView.addArrangedSubview(containerView)
        
        // Update the container height after adding
        updateAttachmentContainerHeight()
    }
    
    // MARK: - Update Attachment Container Height
    private func updateAttachmentContainerHeight() {
        // Force layout update
        attachmentsStackView.layoutIfNeeded()
        
        // Calculate required height based on number of attachments
        let numberOfAttachments = attachmentsStackView.arrangedSubviews.count
        
        if numberOfAttachments == 0 {
            // No attachments - use minimum height (title + button area)
            attachmentContainerHeightConstraint.constant = 120
        } else {
            // Calculate height: base height + (attachment height * count) + spacing
            // Base height: 70 (title + button padding)
            // Each attachment: 50 (item height) + 8 (spacing)
            let baseHeight: CGFloat = 70
            let attachmentHeight: CGFloat = 50
            let spacing: CGFloat = 8
            
            let totalAttachmentsHeight = (attachmentHeight * CGFloat(numberOfAttachments)) + (spacing * CGFloat(numberOfAttachments - 1))
            attachmentContainerHeightConstraint.constant = baseHeight + totalAttachmentsHeight + 20 // Extra padding
        }
        
        // Animate the height change
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        }
    }

    // MARK: - Placeholder Circle Image
    private func placeholderImage(for name: String) -> UIImage {
        let size = CGSize(width: 40, height: 40)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)

        let ctx = UIGraphicsGetCurrentContext()!
        UIColor.systemBlue.setFill()
        ctx.fillEllipse(in: CGRect(origin: .zero, size: size))

        let initial = String(name.prefix(1)).uppercased()
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: UIColor.white
        ]

        let t = initial.size(withAttributes: attrs)
        let r = CGRect(
            x: (size.width - t.width) / 2,
            y: (size.height - t.height) / 2,
            width: t.width,
            height: t.height
        )

        initial.draw(in: r, withAttributes: attrs)

        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return img
    }

    // MARK: - Actions
    @IBAction func attachmentButtonTapped(_ sender: UIButton) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Gallery action with icon
        let galleryAction = UIAlertAction(title: "Gallery", style: .default, handler: { _ in
            self.addAttachmentLabel("Photo_\(Date().timeIntervalSince1970).jpeg")
        })
        if let galleryIcon = UIImage(systemName: "photo.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            galleryAction.setValue(galleryIcon, forKey: "image")
        }
        alert.addAction(galleryAction)

        // Documents action with icon
        let documentsAction = UIAlertAction(title: "Documents", style: .default, handler: { _ in
            self.addAttachmentLabel("Document_\(Date().timeIntervalSince1970).pdf")
        })
        if let docIcon = UIImage(systemName: "doc.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            documentsAction.setValue(docIcon, forKey: "image")
        }
        alert.addAction(documentsAction)

        // Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }

        present(alert, animated: true)
    }

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        UIView.animate(withDuration: 0.25) {
            sender.alpha = 0
        } completion: { _ in
            sender.isHidden = true
        }
    }
}

// MARK: - MODEL
struct Task {
    let title: String
    let dueDate: String
    let assigneeName: String
    let assigneeImage: UIImage?
    let attachmentNames: [String]
}
