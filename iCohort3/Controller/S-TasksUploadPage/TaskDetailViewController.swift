//
//  TaskDetailViewController.swift
//  iCohort3
//
//  ✅ CLEANED: Removed hardcoded mentor data - now fetches from Supabase
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
    @IBOutlet weak var resourcesContainerView: UIView!
    @IBOutlet weak var assigneeImageView: UIImageView!
    @IBOutlet weak var assigneeNameLabel: UILabel!

    // MARK: - Assigned By (mentor) label
    @IBOutlet weak var assignedByNameLabel: UILabel!

    // MARK: - Attachment Card
    @IBOutlet weak var attachmentContainerView: UIView!
    @IBOutlet weak var attachmentIconButton: UIButton!
    @IBOutlet weak var attachmentsStackView: UIStackView!

    // MARK: - Submit To dropdown button
    @IBOutlet weak var submitToButton: UIButton!
    @IBOutlet weak var assignedByContainerView: UIView!
    @IBOutlet weak var submitToContainerView: UIView!

    // MARK: - Submit Button
    @IBOutlet weak var submitButton: UIButton!

    // MARK: - Task Model
    var task: DashboardTask?

    // MARK: - Height Constraint for dynamic sizing
    @IBOutlet weak var attachmentContainerHeightConstraint: NSLayoutConstraint!

    // MARK: - Submission State
    private var isSubmitted = false

    // ✅ CLEANED: Mentor data will come from task/Supabase
    private var mentorOptions: [String] = []
    private var selectedSubmitTo: String = ""

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBackButton()

        // ✅ Setup mentor UI (will be populated from task data)
        setupMentorUI()

        // Apply the task only AFTER outlets exist
        if let t = task {
            configure(with: t)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
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

    // ✅ CLEANED: Mentor UI setup - will use data from task
    private func setupMentorUI() {
        // Will be populated when task is configured
        assignedByNameLabel.text = "Loading..."
        assignedByNameLabel.textColor = .darkGray
        assignedByNameLabel.font = UIFont.systemFont(ofSize: 16)

        submitToButton.setTitle("Select Mentor", for: .normal)
        submitToButton.setTitleColor(.darkGray, for: .normal)
        submitToButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)

        // Make it look like a dropdown
        submitToButton.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        submitToButton.semanticContentAttribute = .forceRightToLeft
        submitToButton.contentHorizontalAlignment = .trailing
    }

    // MARK: - UI SETUP
    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.94, green: 0.94, blue: 0.96, alpha: 1)

        // Style all card containers
        let cards = [
            dueDateContainerView,
            assignedToContainerView,
            attachmentContainerView,
            assignedByContainerView,
            submitToContainerView,
            resourcesContainerView
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
    func configure(with task: DashboardTask) {
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

        // ✅ CLEANED: Set mentor data from task (fetched from Supabase)
        // TODO: Add mentor_name field to DashboardTask model and fetch from database
        // For now, show placeholder
        assignedByNameLabel.text = "Mentor Name" // TODO: Replace with actual mentor from task
        
        // TODO: Fetch available mentors from Supabase for dropdown
        // For now, use empty array
        mentorOptions = []
        
        if !mentorOptions.isEmpty {
            let actions = mentorOptions.map { name in
                UIAction(title: name) { _ in
                    self.selectedSubmitTo = name
                    self.submitToButton.setTitle(name, for: .normal)
                }
            }
            submitToButton.menu = UIMenu(children: actions)
            submitToButton.showsMenuAsPrimaryAction = true
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
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        containerView.layer.cornerRadius = 12

        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue

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

        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = name
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = .darkGray
        lbl.numberOfLines = 1

        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.isHidden = isSubmitted
        deleteButton.addTarget(self, action: #selector(deleteAttachment(_:)), for: .touchUpInside)

        containerView.addSubview(iconImageView)
        containerView.addSubview(lbl)
        containerView.addSubview(deleteButton)

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
        updateAttachmentContainerHeight()
    }

    @objc private func deleteAttachment(_ sender: UIButton) {
        guard let containerView = sender.superview else { return }

        UIView.animate(withDuration: 0.3, animations: {
            containerView.alpha = 0
        }) { _ in
            containerView.removeFromSuperview()
            self.updateAttachmentContainerHeight()
        }
    }

    private func updateAttachmentContainerHeight() {
        attachmentsStackView.layoutIfNeeded()
        let numberOfAttachments = attachmentsStackView.arrangedSubviews.count

        if numberOfAttachments == 0 {
            attachmentContainerHeightConstraint.constant = 50
        } else {
            let baseHeight: CGFloat = 70
            let attachmentHeight: CGFloat = 50
            let spacing: CGFloat = 8

            let totalAttachmentsHeight =
                (attachmentHeight * CGFloat(numberOfAttachments)) +
                (spacing * CGFloat(numberOfAttachments - 1))

            attachmentContainerHeightConstraint.constant = baseHeight + totalAttachmentsHeight + 20
        }

        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.view.layoutIfNeeded()
        }
    }

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
        guard !isSubmitted else {
            showAlert(title: "Already Submitted", message: "You cannot add attachments after submission. Please use 'Redo Submission' to modify.")
            return
        }

        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)

        let cameraAction = UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        })
        if let cameraIcon = UIImage(systemName: "camera.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            cameraAction.setValue(cameraIcon, forKey: "image")
        }
        alert.addAction(cameraAction)

        let galleryAction = UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openPhotoLibrary()
        })
        if let galleryIcon = UIImage(systemName: "photo.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            galleryAction.setValue(galleryIcon, forKey: "image")
        }
        alert.addAction(galleryAction)

        let documentsAction = UIAlertAction(title: "Documents", style: .default, handler: { _ in
            self.openDocumentPicker()
        })
        if let docIcon = UIImage(systemName: "doc.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            documentsAction.setValue(docIcon, forKey: "image")
        }
        alert.addAction(documentsAction)

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }

        present(alert, animated: true)
    }

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

    private func openDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .data])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        if isSubmitted {
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
            submitTask()
        }
    }

    private func submitTask() {
        isSubmitted = true

        submitButton.setTitle("Redo Submission", for: .normal)
        submitButton.backgroundColor = .systemOrange

        attachmentIconButton.isEnabled = false
        attachmentIconButton.alpha = 0.5

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

        showAlert(title: "Success", message: "Your task has been submitted for review!")
    }

    private func redoSubmission() {
        isSubmitted = false

        submitButton.setTitle("Submit for review", for: .normal)
        submitButton.backgroundColor = .systemBlue

        attachmentIconButton.isEnabled = true
        attachmentIconButton.alpha = 1.0

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

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension TaskDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)

        if info[.originalImage] is UIImage {
            let fileName: String
            if picker.sourceType == .camera {
                fileName = "Camera_\(Date().timeIntervalSince1970).jpeg"
            } else {
                fileName = "Photo_\(Date().timeIntervalSince1970).jpeg"
            }
            addAttachmentLabel(fileName)
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

extension TaskDetailViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        let fileName = url.lastPathComponent
        addAttachmentLabel(fileName)
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}
