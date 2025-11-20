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
    
    // Attachments
    var attachments: [UIImage] = []
    
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
            assignButton.setTitle(memberName, for: .normal)
            confirmAssign.isHidden = false
        }
        
        attachments = existingAttachments
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
        
        // If "All Members" is selected, assign to each member
        if isAllMembersSelected {
            for memberName in teamMemberNames {
                if isEditMode, let index = editingTaskIndex {
                    delegate?.didUpdateTask(at: index, memberName: memberName, description: description, date: selectedDate, title: title, attachments: attachments)
                } else {
                    delegate?.didAssignTask(to: memberName, description: description, date: selectedDate, title: title, attachments: attachments)
                }
            }
        } else {
            // Single member assignment
            let memberName = selectedMemberName ?? ""
            if isEditMode, let index = editingTaskIndex {
                delegate?.didUpdateTask(at: index, memberName: memberName, description: description, date: selectedDate, title: title, attachments: attachments)
            } else {
                delegate?.didAssignTask(to: memberName, description: description, date: selectedDate, title: title, attachments: attachments)
            }
        }
        
        // Dismiss the view controller
        self.dismiss(animated: true)
    }
    
    @IBAction func attachmentButtonTapped(_ sender: Any) {
        showAttachmentOptions()
    }
    
    func showAttachmentOptions() {
        let alert = UIAlertController(title: "Add Attachment", message: "Choose an option", preferredStyle: .actionSheet)
        
        // Camera option
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            alert.addAction(cameraAction)
        }
        
        // Photo Library option (iOS 14+)
        if #available(iOS 14, *) {
            let photoAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
                self?.presentPHPicker()
            }
            alert.addAction(photoAction)
        } else {
            let photoAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .photoLibrary)
            }
            alert.addAction(photoAction)
        }
        
        // Files option
        let filesAction = UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        }
        alert.addAction(filesAction)
        
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
    
    func updateAttachmentUI() {
        // Clear existing attachment views
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if attachments.isEmpty {
            stackViewHeightContainer.constant = 0
            attachmentContainerHeightConstraint.constant = 50
            return
        }
        
        // Add attachment previews
        for (index, image) in attachments.enumerated() {
            let containerView = UIView()
            containerView.translatesAutoresizingMaskIntoConstraints = false
            containerView.heightAnchor.constraint(equalToConstant: 80).isActive = true
            
            let imageView = UIImageView(image: image)
            imageView.contentMode = .scaleAspectFill
            imageView.clipsToBounds = true
            imageView.layer.cornerRadius = 8
            imageView.translatesAutoresizingMaskIntoConstraints = false
            
            let removeButton = UIButton(type: .system)
            removeButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
            removeButton.tintColor = .systemRed
            removeButton.backgroundColor = .white
            removeButton.layer.cornerRadius = 12
            removeButton.translatesAutoresizingMaskIntoConstraints = false
            removeButton.tag = index
            removeButton.addTarget(self, action: #selector(removeAttachment(_:)), for: .touchUpInside)
            
            containerView.addSubview(imageView)
            containerView.addSubview(removeButton)
            
            NSLayoutConstraint.activate([
                imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                
                removeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                removeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
                removeButton.widthAnchor.constraint(equalToConstant: 24),
                removeButton.heightAnchor.constraint(equalToConstant: 24)
            ])
            
            stackView.addArrangedSubview(containerView)
        }
        
        // Update height constraints
        let totalHeight = CGFloat(attachments.count * 80) + CGFloat((attachments.count - 1) * 8)
        stackViewHeightContainer.constant = totalHeight
        attachmentContainerHeightConstraint.constant = totalHeight + 60
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc func removeAttachment(_ sender: UIButton) {
        let index = sender.tag
        if index < attachments.count {
            attachments.remove(at: index)
            updateAttachmentUI()
        }
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
                }
            }
        }
        updateAttachmentUI()
    }
}
