import UIKit
internal import UniformTypeIdentifiers

class AddTaskViewController: UIViewController {

    @IBOutlet weak var attachmentLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var titleView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    @IBOutlet weak var categoryView: UIView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var categoryName: UITextField!
    
    @IBOutlet weak var colorChangeView: UIView!
    @IBOutlet weak var colorOptionsView: UIView!
    
    @IBOutlet weak var redColorView: UIButton!
    @IBOutlet weak var orangeColorView: UIButton!
    @IBOutlet weak var yellowColor: UIButton!
    @IBOutlet weak var greenColor: UIButton!
    @IBOutlet weak var blueColor: UIButton!
    @IBOutlet weak var tealColor: UIButton!
    @IBOutlet weak var addAttachmentView: UIView!
    
    @IBOutlet weak var addAttachmentButton: UIButton!
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    // CHANGED: Made these internal instead of private so subclasses can access
    @IBOutlet weak var attachmentsStackView: UIStackView!
    @IBOutlet weak var attachmentContainerHeightConstraint: NSLayoutConstraint!
    
    internal var attachedImages: [UIImage] = []
    internal var attachedDocumentURLs: [URL] = []
    internal var attachedLinks: [String] = []
    
    // Internal enum for UI purposes only
    internal enum AttachmentDisplayType {
        case image
        case document
        case link
    }
    
    internal var selectedColor: UIColor = .systemYellow
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        setupColorButtons()
        setupTextFieldListener()
        
        titleView.layer.cornerRadius = 20
        categoryView.layer.cornerRadius = 20
        colorChangeView.layer.cornerRadius = 20
        addAttachmentView.layer.cornerRadius = 20
        colorOptionsView.layer.cornerRadius = 20
        
        categoryName.layer.cornerRadius = 20
        
        // Initialize attachment container height
        updateAttachmentContainerHeight()
    }
    
    private func setupTextFieldListener() {
        categoryName.addTarget(self, action: #selector(categoryNameChanged(_:)), for: .editingChanged)
    }

    @objc private func categoryNameChanged(_ sender: UITextField) {
        categoryLabel.text = sender.text?.isEmpty == false ? sender.text : "Label"
    }
    
    private func setupColorButtons() {
        let buttons = [redColorView, orangeColorView, yellowColor, greenColor, blueColor, tealColor]

        for btn in buttons {
            btn?.layer.cornerRadius = (btn?.frame.height ?? 40) / 2
            btn?.layer.masksToBounds = true
            btn?.addTarget(self, action: #selector(colorTapped(_:)), for: .touchUpInside)
        }
    }
    
    @objc private func colorTapped(_ sender: UIButton) {
        switch sender {
        case redColorView:
            selectedColor = UIColor.systemRed
        case orangeColorView:
            selectedColor = UIColor.orange
        case yellowColor:
            selectedColor = UIColor.systemYellow
        case greenColor:
            selectedColor = UIColor.systemGreen
        case blueColor:
            selectedColor = UIColor.systemBlue
        case tealColor:
            selectedColor = UIColor.systemTeal
        default:
            break
        }

        applySelectedColor()
        updateColorSelectionIndicators(selected: sender)
    }
    
    private func applySelectedColor() {
        colorChangeView.backgroundColor = selectedColor
        categoryLabel.backgroundColor = selectedColor
        categoryLabel.textColor = selectedColor.isLight ? .black : .white
    }
    
    // MARK: - Public helper method to select color button
    func selectColorButton(for color: UIColor) {
        // Find and trigger the corresponding button
        var targetButton: UIButton?
        
        if color == UIColor.systemRed {
            targetButton = redColorView
        } else if color == UIColor.orange {
            targetButton = orangeColorView
        } else if color == UIColor.systemYellow {
            targetButton = yellowColor
        } else if color == UIColor.systemGreen {
            targetButton = greenColor
        } else if color == UIColor.systemBlue {
            targetButton = blueColor
        } else if color == UIColor.systemTeal {
            targetButton = tealColor
        }
        
        if let button = targetButton {
            selectedColor = color
            applySelectedColor()
            updateColorSelectionIndicators(selected: button)
        }
    }
    
    private func updateColorSelectionIndicators(selected: UIButton) {
        let allButtons = [redColorView, orangeColorView, yellowColor, greenColor, blueColor, tealColor]
        for btn in allButtons {
            btn?.setImage(nil, for: .normal)
        }
    }
    
    internal func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }

    @IBAction func doneButtonTapped(_ sender: Any) {
        if let title = titleTextField.text, title.isEmpty {
            showAlert(message: "Please enter a title.")
            return
        }
        
        // TODO: save your task here
        // You can access attachedImages, attachedDocumentURLs, attachedLinks arrays
        
        self.dismiss(animated: true)
    }
    
    // MARK: - Attachment Actions
    @IBAction func addAttachmentButtonTapped(_ sender: UIButton) {
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

        // Add Link action with icon
        let linkAction = UIAlertAction(title: "Add Link", style: .default, handler: { _ in
            self.showAddLinkDialog()
        })
        if let linkIcon = UIImage(systemName: "link")?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal) {
            linkAction.setValue(linkIcon, forKey: "image")
        }
        alert.addAction(linkAction)

        // Cancel action
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // For iPad support
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }

        present(alert, animated: true)
    }
    
    // MARK: - Camera & Photo Library
    private func openCamera() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            showAlert(title: "Camera Unavailable", message: "Camera is not available on this device.")
            return
        }
        
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    private func openPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - Document Picker
    private func openDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .text, .plainText, .image, .movie, .data, .item])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    // MARK: - Add Link
    private func showAddLinkDialog() {
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
                self?.showAlert(title: "Invalid URL", message: "Please enter a valid URL.")
                return
            }
            
            // Validate URL
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                // Store the link
                self?.attachedLinks.append(urlString)
                
                // Add to UI with shortened display name if URL is too long
                let displayName = urlString.count > 40 ? String(urlString.prefix(37)) + "..." : urlString
                self?.addAttachmentLabel(displayName, type: .link)
                
                print("Link attached: \(urlString)")
            } else {
                self?.showAlert(title: "Invalid URL", message: "The URL you entered is not valid.")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true)
    }
    
    // MARK: - Helper: Add attachments dynamically
    // CHANGED: Made internal so subclass can call it
    internal func addAttachmentLabel(_ name: String, type: AttachmentDisplayType = .document) {
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
        
        // Determine icon based on attachment type and file extension
        let iconName: String
        switch type {
        case .image:
            iconName = "photo.fill"
        case .link:
            iconName = "link"
        case .document:
            let fileExtension = (name as NSString).pathExtension.lowercased()
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
        }
        iconImageView.image = UIImage(systemName: iconName)
        
        // File name label
        let lbl = UILabel()
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.text = name
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = .darkGray
        lbl.numberOfLines = 1
        
        // Delete button
        let deleteButton = UIButton(type: .system)
        deleteButton.translatesAutoresizingMaskIntoConstraints = false
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .systemRed
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
    @objc func deleteAttachment(_ sender: UIButton) {
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
    func updateAttachmentContainerHeight() {
        // Force layout update
        attachmentsStackView.layoutIfNeeded()
        
        // Calculate required height based on number of attachments
        let numberOfAttachments = attachmentsStackView.arrangedSubviews.count
        
        if numberOfAttachments == 0 {
            // No attachments - use minimum height (title + button area)
            attachmentContainerHeightConstraint.constant = 50
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
}

// MARK: - UIImagePickerControllerDelegate
extension AddTaskViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            // Store the image
            attachedImages.append(image)
            
            // Generate a name for the image
            let imageName = "Image_\(Date().timeIntervalSince1970).jpg"
            
            // Add to UI
            addAttachmentLabel(imageName, type: .image)
            
            print("Image attached: \(imageName)")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - UIDocumentPickerDelegate
extension AddTaskViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else { return }
        
        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            showAlert(title: "Error", message: "Unable to access the document.")
            return
        }
        
        defer { url.stopAccessingSecurityScopedResource() }
        
        // Store the document URL
        attachedDocumentURLs.append(url)
        
        // Add to UI
        addAttachmentLabel(url.lastPathComponent, type: .document)
        
        print("Document attached: \(url.lastPathComponent)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - UIColor Extension
extension UIColor {
    var isLight: Bool {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green:&green, blue:&blue, alpha:&alpha)
        let brightness = ((red * 299) + (green * 587) + (blue * 114)) / 1000
        return brightness > 0.75
    }
}
