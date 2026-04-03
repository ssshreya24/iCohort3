import UIKit
import PhotosUI

// Protocol to pass data back
protocol NewTaskDelegate: AnyObject {
    func didAssignTask(
        to memberName: String,
        description: String,
        date: Date,
        title: String,
        attachments: [UIImage],
        attachmentFilenames: [String]
    )
    
    func didUpdateTask(
        at index: Int,
        memberName: String,
        description: String,
        date: Date,
        title: String,
        attachments: [UIImage],
        attachmentFilenames: [String]
    )
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
    
    var teamId: String = ""
    var mentorId: String = ""
    var existingTaskId: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        
        confirmAssign.isHidden = true
        
        if isEditMode {
            newTaskLabel.text = "Edit Task"
            confirmAssign.setTitle("Update Task", for: .normal)
            loadExistingData()
        }
        
        updateAttachmentUI()
        applyTheme()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
        styleFloatingButton(closeButton, imageName: "xmark")
    }
    
    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }
    
    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        [headerView, taskView, descriptionView, assignView, attachmentView].forEach {
            guard let card = $0 else { return }
            AppTheme.styleElevatedCard(card, cornerRadius: 20)
            card.layer.cornerCurve = .continuous
        }
        newTaskLabel.textColor = .label
        [titleTextField, descritionTextField].forEach {
            $0?.textColor = .label
            $0?.tintColor = AppTheme.accent
        }
        assignButton.setTitleColor(.label, for: .normal)
        assignButton.tintColor = .label
        attachmentButton.setTitleColor(.secondaryLabel, for: .normal)
        attachmentButton.tintColor = .secondaryLabel
        confirmAssign.setTitleColor(.label, for: .normal)
        confirmAssign.tintColor = .label
        confirmAssign.backgroundColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.systemFill
        confirmAssign.layer.cornerRadius = confirmAssign.bounds.height / 2
        datePicker.tintColor = AppTheme.accent
        styleFloatingButton(closeButton, imageName: "xmark")
        updateAttachmentUI()
    }
    
    private func styleFloatingButton(_ button: UIButton, imageName: String) {
        let foreground = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: imageName)
        config.baseForegroundColor = foreground
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        button.configuration = config
        AppTheme.styleNativeFloatingControl(button, cornerRadius: button.bounds.height / 2)
        button.backgroundColor = .clear
        button.tintColor = foreground
    }
    
    func loadExistingData() {
        titleTextField.text = existingTitle
        descritionTextField.text = existingDescription
        
        if let date = existingDate {
            datePicker.date = date
        }
        
        if let memberName = selectedMemberName {
            if memberName == "All Members" {
                isAllMembersSelected = true
                selectedMemberIndex = nil
                self.selectedMemberName = nil
            }
            assignButton.setTitle(memberName, for: .normal)
            confirmAssign.isHidden = false
        }
        
        attachments = existingAttachments
        
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
        
        let memberName: String
        if isAllMembersSelected {
            memberName = "All Members"
        } else {
            memberName = selectedMemberName ?? ""
        }
        
        if isEditMode, let index = editingTaskIndex {
            delegate?.didUpdateTask(
                at: index,
                memberName: memberName,
                description: description,
                date: selectedDate,
                title: title,
                attachments: attachments,
                attachmentFilenames: attachmentFilenames
            )
        } else {
            delegate?.didAssignTask(
                to: memberName,
                description: description,
                date: selectedDate,
                title: title,
                attachments: attachments,
                attachmentFilenames: attachmentFilenames
            )
        }
        
        self.dismiss(animated: true)
    }
    
    @IBAction func attachmentButtonTapped(_ sender: Any) {
        showAttachmentOptions()
    }
    
    func showAttachmentOptions() {
        let alert = UIAlertController(title: "Add Attachment", message: "Choose an option", preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            if let cameraIcon = UIImage(systemName: "camera.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
                cameraAction.setValue(cameraIcon, forKey: "image")
            }
            alert.addAction(cameraAction)
        }
        
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
        
        let filesAction = UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        }
        if let fileIcon = UIImage(systemName: "doc.fill")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            filesAction.setValue(fileIcon, forKey: "image")
        }
        alert.addAction(filesAction)
        
        let linkAction = UIAlertAction(title: "Add Link", style: .default) { [weak self] _ in
            self?.showAddLinkDialog()
        }
        if let linkIcon = UIImage(systemName: "link")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            linkAction.setValue(linkIcon, forKey: "image")
        }
        alert.addAction(linkAction)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(cancelAction)
        
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
            
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                let linkImage = self?.createLinkPlaceholderImage() ?? UIImage()
                self?.attachments.append(linkImage)
                self?.attachmentFilenames.append(urlString)
                self?.updateAttachmentUI()
                
                print("✅ Link attached: \(urlString)")
            } else {
                self?.showAlert(message: "The URL you entered is not valid.")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
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
    
    // MARK: - Updated Attachment UI Methods
    
    func updateAttachmentUI() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        if attachments.isEmpty {
            stackViewHeightContainer.constant = 0
            attachmentContainerHeightConstraint.constant = 50
            return
        }
        
        for (index, _) in attachments.enumerated() {
            let filename = index < attachmentFilenames.count ? attachmentFilenames[index] : "Image_\(index).jpg"
            let isLink = filename.hasPrefix("http://") || filename.hasPrefix("https://")
            
            if isLink {
                // Create link attachment view
                let linkView = createLinkAttachmentView(url: filename, index: index)
                stackView.addArrangedSubview(linkView)
            } else {
                // Create image attachment view
                let imageView = createImageAttachmentView(filename: filename, index: index)
                stackView.addArrangedSubview(imageView)
            }
        }
        
        let numberOfAttachments = attachments.count
        let baseHeight: CGFloat = 70
        let attachmentHeight: CGFloat = 60 // Increased for link views
        let spacing: CGFloat = 8
        
        let totalAttachmentsHeight = (attachmentHeight * CGFloat(numberOfAttachments)) + (spacing * CGFloat(numberOfAttachments - 1))
        stackViewHeightContainer.constant = totalAttachmentsHeight
        attachmentContainerHeightConstraint.constant = baseHeight + totalAttachmentsHeight + 20
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func createLinkAttachmentView(url: String, index: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.systemBlue.withAlphaComponent(0.16)
            : UIColor.systemBlue.withAlphaComponent(0.1)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.3).cgColor
        
        // Link icon
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconImageView.image = UIImage(systemName: "link", withConfiguration: iconConfig)
        
        // URL label
        let urlLabel = UILabel()
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        if let urlObj = URL(string: url) {
            urlLabel.text = urlObj.host ?? url
        } else {
            urlLabel.text = url
        }
        urlLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        urlLabel.textColor = .systemBlue
        urlLabel.numberOfLines = 2
        
        // Delete button
        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.tag = index
        deleteButton.addTarget(self, action: #selector(removeAttachment(_:)), for: .touchUpInside)
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(urlLabel)
        containerView.addSubview(deleteButton)
        
        NSLayoutConstraint.activate([
            containerView.heightAnchor.constraint(equalToConstant: 60),
            
            iconImageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            iconImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 28),
            iconImageView.heightAnchor.constraint(equalToConstant: 28),
            
            urlLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 12),
            urlLabel.trailingAnchor.constraint(equalTo: deleteButton.leadingAnchor, constant: -8),
            urlLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            
            deleteButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            deleteButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            deleteButton.widthAnchor.constraint(equalToConstant: 24),
            deleteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
        
        return containerView
    }
    
    private func createImageAttachmentView(filename: String, index: Int) -> UIView {
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1)
        containerView.layer.cornerRadius = 12
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        let iconName: String
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
        iconImageView.image = UIImage(systemName: iconName)
        
        let nameLabel = UILabel()
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = filename
        nameLabel.font = UIFont.systemFont(ofSize: 16)
        nameLabel.textColor = .label
        nameLabel.numberOfLines = 1
        
        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
        deleteButton.tag = index
        deleteButton.addTarget(self, action: #selector(removeAttachment(_:)), for: .touchUpInside)
        
        containerView.addSubview(iconImageView)
        containerView.addSubview(nameLabel)
        containerView.addSubview(deleteButton)
        
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
        
        return containerView
    }
    
    @objc func removeAttachment(_ sender: UIButton) {
        let index = sender.tag
        
        guard index >= 0 && index < attachments.count else {
            print("⚠️ Invalid index: \(index)")
            return
        }
        
        attachments.remove(at: index)
        if index < attachmentFilenames.count {
            attachmentFilenames.remove(at: index)
        }
        
        updateAttachmentUI()
    }
    
    func showTeamMemberPicker() {
        let alert = UIAlertController(title: "Assign To", message: "Select a team member", preferredStyle: .actionSheet)
        
        let allMembersAction = UIAlertAction(title: "All Members", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.isAllMembersSelected = true
            self.selectedMemberIndex = nil
            self.selectedMemberName = nil
            self.assignButton.setTitle("All Members", for: .normal)
            self.confirmAssign.isHidden = false
        }
        alert.addAction(allMembersAction)
        
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
