//
//  TaskDetailViewController.swift
//  iCohort3
//

import UIKit
internal import UniformTypeIdentifiers

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
    
    // MARK: - Submission State
    private var isSubmitted = false

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

    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        backButton.backgroundColor = UIColor(white: 1.0, alpha: 0.8)
        backButton.layer.cornerRadius = 22
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let arrowImage = UIImage(systemName: "chevron.left", withConfiguration: config)
        backButton.setImage(arrowImage, for: .normal)
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
        
        // Delete button (only show if not submitted)
        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.isHidden = isSubmitted
        deleteButton.addTarget(self, action: #selector(deleteAttachment(_:)), for: .touchUpInside)
        
        // Add subviews
        containerView.addSubview(iconImageView)
        containerView.addSubview(lbl)
        containerView.addSubview(deleteButton)
        
        // Constraints
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 50),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            
            lbl.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
            lbl.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
            lbl.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        attachmentsStackView.addArrangedSubview(containerView)
        
        // Update the container height after adding
        updateAttachmentContainerHeight()
    }
    
    // MARK: - Delete Attachment
    @objc private func deleteAttachment(_ sender: UIButton) {
        guard let containerView = sender.superview else { return }
        
        // Animate removal
        UIView.animate(withDuration: 0.3, animations: {
            containerView.alpha = 0
        }) { _ in
            containerView.removeFromSuperview()
            self.updateAttachmentContainerHeight()
        }
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
        // Don't allow adding attachments if already submitted
        guard !isSubmitted else {
            showAlert(title: "Already Submitted", message: "You cannot add attachments after submission. Please use 'Redo Submission' to modify.")
            return
        }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        // Camera action with icon
        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        })
        if let cameraIcon = UIImage(systemName: "camera.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            cameraAction.setValue(cameraIcon, forKey: "image")
        }
        alert.addAction(cameraAction)

        // Gallery action with icon
        let galleryAction = UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openPhotoLibrary()
        })
        if let galleryIcon = UIImage(systemName: "photo.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            galleryAction.setValue(galleryIcon, forKey: "image")
        }
        alert.addAction(galleryAction)

        // Documents action with icon
        let documentsAction = UIAlertAction(title: "Documents", style: .default, handler: { _ in
            self.openDocumentPicker()
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
    
    // MARK: - Open Camera
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = false
            present(picker, animated: true)
        } else {
            showAlert(title: "Camera Not Available", message: "Camera is not available on this device.")
        }
    }
    
    // MARK: - Open Photo Library
    private func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = false
            present(picker, animated: true)
        } else {
            showAlert(title: "Photo Library Not Available", message: "Photo library is not available on this device.")
        }
    }
    
    // MARK: - Open Document Picker
    private func openDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .data])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        if isSubmitted {
            // Redo submission
            let alert = UIAlertController(
                title: "Redo Submission",
                message: "Are you sure you want to redo your submission? This will allow you to modify and resubmit.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Redo", style: .destructive) { _ in
                self.redoSubmission()
            })
            
            present(alert, animated: true)
        } else {
            // First time submission
            submitTask()
        }
    }
    
    // MARK: - Submit Task
    private func submitTask() {
        isSubmitted = true
        
        // Update button appearance
        submitButton.setTitle("Redo Submission", for: .normal)
        submitButton.backgroundColor = .systemOrange
        
        // Disable attachment button
        attachmentIconButton.isEnabled = false
        attachmentIconButton.alpha = 0.5
        
        // Hide delete buttons on all attachments
        attachmentsStackView.arrangedSubviews.forEach { containerView in
            containerView.subviews.forEach { subview in
                if let deleteButton = subview as? UIButton,
                   deleteButton.currentImage == UIImage(systemName: "xmark.circle.fill") {
                    UIView.animate(withDuration: 0.3) {
                        deleteButton.alpha = 0
                    } completion: { _ in
                        deleteButton.isHidden = true
                    }
                }
            }
        }
        
        // Show success message
        showAlert(title: "Success", message: "Your task has been submitted for review!")
    }
    
    // MARK: - Redo Submission
    private func redoSubmission() {
        isSubmitted = false
        
        // Update button appearance
        submitButton.setTitle("Submit for review", for: .normal)
        submitButton.backgroundColor = .systemBlue
        
        // Enable attachment button
        attachmentIconButton.isEnabled = true
        attachmentIconButton.alpha = 1.0
        
        // Show delete buttons on all attachments
        attachmentsStackView.arrangedSubviews.forEach { containerView in
            containerView.subviews.forEach { subview in
                if let deleteButton = subview as? UIButton,
                   deleteButton.image(for: .normal) == UIImage(systemName: "xmark.circle.fill") {
                    deleteButton.isHidden = false
                    UIView.animate(withDuration: 0.3) {
                        deleteButton.alpha = 1.0
                    }
                }
            }
        }
        
        showAlert(title: "Ready to Edit", message: "You can now modify your attachments and resubmit.")
    }
    
    // MARK: - Helper: Show Alert
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate & UINavigationControllerDelegate
extension TaskDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        // Get the image
        if info[.originalImage] is UIImage {
            // Generate filename based on source
            let fileName: String
            if picker.sourceType == .camera {
                fileName = "Camera_\(Date().timeIntervalSince1970).jpeg"
            } else {
                fileName = "Photo_\(Date().timeIntervalSince1970).jpeg"
            }
            
            // Add the attachment
            addAttachmentLabel(fileName)
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension TaskDetailViewController: UIDocumentPickerDelegate {
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Get the filename
        let fileName = url.lastPathComponent
        
        // Add the attachment
        addAttachmentLabel(fileName)
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
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
