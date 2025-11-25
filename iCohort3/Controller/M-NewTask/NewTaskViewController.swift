import UIKit
import PhotosUI

// Protocol to pass data back
protocol NewTaskDelegate: AnyObject {
    func didAssignTask(to memberName: String, description: String, date: Date, title: String, attachments: [UIImage])
    func didUpdateTask(at index: Int, memberName: String, description: String, date: Date, title: String, attachments: [UIImage])
}

class NewTaskViewController: UIViewController {
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var newTaskLabel: UILabel!
    @IBOutlet weak var assignButton: UIButton!
    @IBOutlet weak var assignView: UIView!
    @IBOutlet weak var confirmAssign: UIButton!
    @IBOutlet weak var descritionTextField: UITextField!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var attachmentButton: UIButton!
    @IBOutlet weak var attachmentView: UIView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var taskView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var stackView: UIStackView!
    @IBOutlet weak var stackViewHeightContainer: NSLayoutConstraint!
    @IBOutlet weak var attachmentContainerHeightConstraint: NSLayoutConstraint!
    
    // Delegate
    weak var delegate: NewTaskDelegate?
    
    // Properties to store team member data
    var teamMemberImages: [UIImage] = []
    var teamMemberNames: [String] = []
    var selectedMemberIndex: Int?
    var selectedMemberName: String?
    var isAllMembersSelected: Bool = false
    
    // Edit mode properties
    var isEditMode: Bool = false
    var editingTaskIndex: Int?
    var editingCategory: TaskCategory?
    var existingTitle: String?
    var existingDescription: String?
    var existingDate: Date?
    var existingAttachments: [UIImage] = []
    
    // Attachments - store images and their filenames
    var attachments: [UIImage] = []
    var attachmentFilenames: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskView.layer.cornerRadius = 20
        descriptionView.layer.cornerRadius = 20
        assignView.layer.cornerRadius = 20
        attachmentView.layer.cornerRadius = 20
        
        // Initially hide confirm button or disable it
        confirmAssign.isHidden = true
        
        // Set up for edit mode if needed
        if isEditMode {
            newTaskLabel.text = "Edit Task"
            confirmAssign.setTitle("Update Task", for: .normal)
            loadExistingData()
        }
        
        updateAttachmentUI()
    }
    
    func loadExistingData() {
        titleTextField.text = existingTitle
        descritionTextField.text = existingDescription
        
        if let date = existingDate {
            datePicker.date = date
        }
        
        if let memberName = selectedMemberName {
            // Check if it's "All Members"
            if memberName == "All Members" {
                isAllMembersSelected = true
                selectedMemberIndex = nil
                self.selectedMemberName = nil
            }
            assignButton.setTitle(memberName, for: .normal)
            confirmAssign.isHidden = false
        }
        
        attachments = existingAttachments
        
        // Generate filenames for existing attachments
        for (index, _) in existingAttachments.enumerated() {
            attachmentFilenames.append("Image_\(index + 1).jpg")
        }
        
        updateAttachmentUI()
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func assignButtonTapped(_ sender: Any) {
        showTeamMemberPicker()
    }
    
    @IBAction func confirmAssignTapped(_ sender: Any) {
        guard selectedMemberName != nil || isAllMembersSelected else {
            showAlert(message: "Please select a team member first")
            return
        }
        
        let title = titleTextField.text ?? ""
        let description = descritionTextField.text ?? ""
        let selectedDate = datePicker.date
        
        if title.isEmpty {
            showAlert(message: "Please enter a task title")
            return
        }
        
        // FIXED: Create only ONE task regardless of selection
        let memberName: String
        if isAllMembersSelected {
            memberName = "All Members"
        } else {
            memberName = selectedMemberName ?? ""
        }
        
        if isEditMode, let index = editingTaskIndex {
            // Update existing task
            delegate?.didUpdateTask(
                at: index,
                memberName: memberName,
                description: description,
                date: selectedDate,
                title: title,
                attachments: attachments
            )
        } else {
            // Create new task - ONLY ONE CALL
            delegate?.didAssignTask(
                to: memberName,
                description: description,
                date: selectedDate,
                title: title,
                attachments: attachments
            )
        }
        
        // Dismiss the view controller
        self.dismiss(animated: true)
    }
    
    @IBAction func attachmentButtonTapped(_ sender: Any) {
        showAttachmentOptions()
    }
    
    func showAttachmentOptions() {
        let alert = UIAlertController(title: "Add Attachment", message: "Choose an option", preferredStyle: .actionSheet)
        
        // Camera option with icon
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            if let cameraIcon = UIImage(systemName: "camera.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
                cameraAction.setValue(cameraIcon, forKey: "image")
            }
            alert.addAction(cameraAction)
        }
        
        // Photo Library option (iOS 14+) with icon
        if #available(iOS 14, *) {
            let photoAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
                self?.presentPHPicker()
            }
            if let photoIcon = UIImage(systemName: "photo.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
                photoAction.setValue(photoIcon, forKey: "image")
            }
            alert.addAction(photoAction)
        } else {
            let photoAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .photoLibrary)
            }
            if let photoIcon = UIImage(systemName: "photo.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
                photoAction.setValue(photoIcon, forKey: "image")
            }
            alert.addAction(photoAction)
        }
        
        // Files option with icon
        let filesAction = UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        }
        if let fileIcon = UIImage(systemName: "doc.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            filesAction.setValue(fileIcon, forKey: "image")
        }
        alert.addAction(filesAction)
        
        // Add Link option with icon
        let linkAction = UIAlertAction(title: "Add Link", style: .default) { [weak self] _ in
            self?.showAddLinkDialog()
        }
        if let linkIcon = UIImage(systemName: "link")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            linkAction.setValue(linkIcon, forKey: "image")
        }
        alert.addAction(linkAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
        // For iPad support
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = attachmentButton
            popoverController.sourceRect = attachmentButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    @available(iOS 14, *)
    func presentPHPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .pdf])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
    }
    
    // MARK: - Add Link Dialog
    func showAddLinkDialog() {
        let alert = UIAlertController(title: "Add Link", message: "Enter a URL", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.placeholder = "https://example.com"
            textField.keyboardType = .URL
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
        }
        
        let addAction = UIAlertAction(title: "Add", style: .default) { [weak alert, weak self] _ in
            guard let textField = alert?.textFields?.first,
                  let urlString = textField.text,
                  !urlString.isEmpty else {
                self?.showAlert(message: "Please enter a valid URL.")
                return
            }
            
            // Validate URL
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                // Create a placeholder image for the link
                let linkImage = self?.createLinkPlaceholderImage() ?? UIImage()
                self?.attachments.append(linkImage)
                self?.attachmentFilenames.append(urlString)
                self?.updateAttachmentUI()
                
                print("Link attached: \(urlString)")
            } else {
                self?.showAlert(message: "The URL you entered is not valid.")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // Create a simple placeholder image for links
    func createLinkPlaceholderImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor.systemBlue.withAlphaComponent(0.1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            let linkIcon = UIImage(systemName: "link", withConfiguration: iconConfig)
            linkIcon?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal).draw(in: CGRect(x: 30, y: 30, width: 40, height: 40))
        }
        
        return image
    }
    
    // MARK: - Update Attachment UI (AddTaskViewController Style)
    func updateAttachmentUI() {
        // Clear existing attachment views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if attachments.isEmpty {
            stackViewHeightContainer.constant = 0
            attachmentContainerHeightConstraint.constant = 50
            return
        }
        
        // Add attachment cards (like AddTaskViewController)
        for (index, _) in attachments.enumerated() {
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
            containerView.layer.cornerRadius = 12
            
            // File icon
            let iconImageView = UIImageView()
            iconImageView.translatesAutoresizingMaskIntoConstraints = false
            iconImageView.contentMode = .scaleAspectFit
            iconImageView.tintColor = .systemBlue
            
            // Determine icon based on filename
            let filename = index < attachmentFilenames.count ? attachmentFilenames[index] : "Image_\(index).jpg"
            let fileExtension = (filename as NSString).pathExtension.lowercased()
            
            let iconName: String
            if filename.hasPrefix("http://") || filename.hasPrefix("https://") {
                iconName = "link"
            } else {
                switch fileExtension {
                case "pdf":
                    iconName = "doc.text.fill"
                case "jpg", "jpeg", "png", "heic":
                    iconName = "photo.fill"
                case "doc", "docx":
                    iconName = "doc.text.fill"
                default:
                    iconName = "photo.fill"
                }
            }
            iconImageView.image = UIImage(systemName: iconName)
            
            // File name label
            let nameLabel = UILabel()
            nameLabel.translatesAutoresizingMaskIntoConstraints = false
            nameLabel.text = filename
            nameLabel.font = UIFont.systemFont(ofSize: 16)
            nameLabel.textColor = .darkGray
            nameLabel.numberOfLines = 1
            
            // Delete button
            let deleteButton = UIButton(type: .system)
            deleteButton.translatesAutoresizingMaskIntoConstraints = false
            deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            deleteButton.tintColor = .systemRed
            deleteButton.tag = index
            deleteButton.addTarget(self, action: #selector(removeAttachment(_:)), for: .touchUpInside)
            
            // Add subviews
            containerView.addSubview(iconImageView)
            containerView.addSubview(nameLabel)
            containerView.addSubview(deleteButton)
            
            // Constraints
            NSLayoutConstraint.activate([
                containerView.heightAnchor.constraint(equalToConstant: 50),
                
                iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
                iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                iconImageView.widthAnchor.constraint(equalToConstant: 28),
                iconImageView.heightAnchor.constraint(equalToConstant: 28),
                
                nameLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 16),
                nameLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
                nameLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                
                deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
                deleteButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
                deleteButton.widthAnchor.constraint(equalToConstant: 24),
                deleteButton.heightAnchor.constraint(equalToConstant: 24)
            ])
            
            stackView.addArrangedSubview(containerView)
        }
        
        // Update height constraints
        let numberOfAttachments = attachments.count
        let baseHeight: CGFloat = 70
        let attachmentHeight: CGFloat = 50
        let spacing: CGFloat = 8
        
        let totalAttachmentsHeight = (attachmentHeight * CGFloat(numberOfAttachments)) + (spacing * CGFloat(numberOfAttachments - 1))
        stackViewHeightContainer.constant = totalAttachmentsHeight
        attachmentContainerHeightConstraint.constant = baseHeight + totalAttachmentsHeight + 20
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func removeAttachment(_ sender: UIButton) {
        let index = sender.tag
        
        guard index >= 0 && index < attachments.count else {
            print("Invalid index: \(index)")
            return
        }
        
        // Remove from both arrays
        attachments.remove(at: index)
        if index < attachmentFilenames.count {
            attachmentFilenames.remove(at: index)
        }
        
        // Update UI
        updateAttachmentUI()
    }
    
    func showTeamMemberPicker() {
        let alert = UIAlertController(title: "Assign To", message: "Select a team member", preferredStyle: .actionSheet)
        
        // Add "All Members" option
        let allMembersAction = UIAlertAction(title: "All Members", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.isAllMembersSelected = true
            self.selectedMemberIndex = nil
            self.selectedMemberName = nil
            self.assignButton.setTitle("All Members", for: .normal)
            self.confirmAssign.isHidden = false
        }
        alert.addAction(allMembersAction)
        
        // Add individual team members
        for (index, name) in teamMemberNames.enumerated() {
            let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.isAllMembersSelected = false
                self.selectedMemberIndex = index
                self.selectedMemberName = name
                self.assignButton.setTitle(name, for: .normal)
                self.confirmAssign.isHidden = false
            }
            alert.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
        // For iPad support
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = assignButton
            popoverController.sourceRect = assignButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension NewTaskViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            attachments.append(image)
            
            // Generate a filename
            let timestamp = Date().timeIntervalSince1970
            let filename = "Image_\(Int(timestamp)).jpg"
            attachmentFilenames.append(filename)
            
            updateAttachmentUI()
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - PHPickerViewControllerDelegate
@available(iOS 14, *)
extension NewTaskViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.attachments.append(image)
                        
                        // Generate a filename
                        let timestamp = Date().timeIntervalSince1970
                        let filename = "Image_\(Int(timestamp)).jpg"
                        self?.attachmentFilenames.append(filename)
                        
                        self?.updateAttachmentUI()
                    }
                }
            }
        }
    }
}

// MARK: - UIDocumentPickerDelegate
extension NewTaskViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            if url.startAccessingSecurityScopedResource() {
                defer { url.stopAccessingSecurityScopedResource() }
                
                if let image = UIImage(contentsOfFile: url.path) {
                    attachments.append(image)
                    attachmentFilenames.append(url.lastPathComponent)
                }
            }
        }
        updateAttachmentUI()
    }
}
