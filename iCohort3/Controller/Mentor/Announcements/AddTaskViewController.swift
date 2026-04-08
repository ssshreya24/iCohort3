import UIKit
internal import UniformTypeIdentifiers

protocol AddTaskViewControllerDelegate: AnyObject {
    func didSaveAnnouncement()
}

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

    internal enum DraftAttachment {
        case image(name: String, image: UIImage)
        case document(name: String, url: URL)
        case link(title: String, urlString: String)
    }

    internal var draftAttachments: [DraftAttachment] = []
    
    // Internal enum for UI purposes only
    internal enum AttachmentDisplayType {
        case image
        case document
        case link
    }
    
    internal var selectedColor: UIColor = .systemYellow
    weak var delegate: AddTaskViewControllerDelegate?
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
    
        setupTextFieldListener()
        
        titleTextField.autocapitalizationType = .sentences
        descriptionTextField.autocapitalizationType = .sentences
        categoryName.autocapitalizationType = .sentences
        
        titleView.layer.cornerRadius = 20
        categoryView.layer.cornerRadius = 20
        colorChangeView.layer.cornerRadius = 40
        addAttachmentView.layer.cornerRadius = 20
        colorOptionsView.layer.cornerRadius = 20
        
        categoryName.layer.cornerRadius = 20
        categoryName.layer.masksToBounds = true
        
        // Initialize attachment container height
        setupColorButtons()
        updateAttachmentContainerHeight()
        applyTheme()
        applySelectedColor()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
        styleFloatingButton(closeButton, imageName: "xmark")
        styleFloatingButton(doneButton, imageName: "checkmark")
    }
    
    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }
    
    private func setupTextFieldListener() {
        categoryName.addTarget(self, action: #selector(categoryNameChanged(_:)), for: .editingChanged)
    }

    @objc private func categoryNameChanged(_ sender: UITextField) {
        categoryLabel.text = sender.text?.isEmpty == false ? sender.text : "Category Name"
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
    
    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        styleOuterHierarchy(in: view)
        [headerView, titleView, categoryView, colorOptionsView, addAttachmentView].forEach {
            guard let card = $0 else { return }
            AppTheme.styleElevatedCard(card, cornerRadius: 20)
            card.layer.cornerCurve = .continuous
        }
        colorChangeView.backgroundColor = selectedColor
        titleTextField.textColor = .label
        titleTextField.tintColor = AppTheme.accent
        descriptionTextField.textColor = .label
        descriptionTextField.tintColor = AppTheme.accent
        categoryName.textColor = .label
        categoryName.tintColor = AppTheme.accent
        categoryName.backgroundColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.white
        categoryLabel.layer.cornerRadius = categoryLabel.bounds.height / 2
        categoryLabel.clipsToBounds = true
        addAttachmentButton.tintColor = .label
        addAttachmentButton.setTitleColor(.label, for: .normal)
        styleFloatingButton(closeButton, imageName: "xmark")
        styleFloatingButton(doneButton, imageName: "checkmark")
    }
    
    private func styleOuterHierarchy(in root: UIView) {
        for subview in root.subviews {
            switch subview {
            case headerView, titleView, categoryView, colorOptionsView, addAttachmentView, closeButton, doneButton:
                break
            case is UILabel, is UIStackView, is UIScrollView, is UIImageView, is UITextField:
                subview.backgroundColor = .clear
            default:
                subview.backgroundColor = .clear
            }
            styleOuterHierarchy(in: subview)
        }
    }
    
    private func styleFloatingButton(_ button: UIButton, imageName: String? = nil, title: String? = nil) {
        let foreground = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        var config = UIButton.Configuration.plain()
        config.baseForegroundColor = foreground
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        if let imageName {
            config.image = UIImage(systemName: imageName)
        }
        if let title {
            config.title = title
            config.attributedTitle = AttributedString(
                title,
                attributes: AttributeContainer([.foregroundColor: foreground])
            )
        }
        button.configuration = config
        AppTheme.styleNativeFloatingControl(button, cornerRadius: button.bounds.height / 2)
        button.backgroundColor = .clear
        button.tintColor = foreground
        button.setTitleColor(foreground, for: .normal)
    }
    
    internal func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    internal func currentAnnouncementAttachments() -> [AttachmentType] {
        draftAttachments.compactMap { attachment in
            switch attachment {
            case .image(_, let image):
                return .image(image)
            case .document(let name, let url):
                return .pdf(name, url)
            case .link(let title, let urlString):
                guard let url = URL(string: urlString) else { return nil }
                return .link(title, url)
            }
        }
    }

    internal func syncLegacyAttachmentStorage() {
        attachedImages = draftAttachments.compactMap {
            if case .image(_, let image) = $0 { return image }
            return nil
        }
        attachedDocumentURLs = draftAttachments.compactMap {
            if case .document(_, let url) = $0 { return url }
            return nil
        }
        attachedLinks = draftAttachments.compactMap {
            if case .link(_, let urlString) = $0 { return urlString }
            return nil
        }
    }

    internal func renderDraftAttachments() {
        attachmentsStackView.arrangedSubviews.forEach { view in
            attachmentsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (index, attachment) in draftAttachments.enumerated() {
            switch attachment {
            case .image(let name, _):
                addAttachmentLabel(name, type: .image)
            case .document(let name, _):
                addAttachmentLabel(name, type: .document)
            case .link(let title, _):
                let displayName = title.count > 40 ? String(title.prefix(37)) + "..." : title
                addAttachmentLabel(displayName, type: .link)
            }
            attachmentsStackView.arrangedSubviews.last?.subviews.compactMap { $0 as? UIButton }.first?.tag = index
        }

        updateAttachmentContainerHeight()
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
        guard let title = titleTextField.text, !title.isEmpty else {
                    showAlert(title: "Missing Title", message: "Please enter a title.")
                    return
                }

                let description = descriptionTextField.text
                let category = categoryName.text
                let colorHex = selectedColor.toHexString()
                let encodedDescription = AnnouncementPayloadCodec.encodedDescription(
                    body: description,
                    attachments: currentAnnouncementAttachments()
                )
                Task {
                    do {
                        try await SupabaseManager.shared.saveAnnouncementToSupabase(
                            title: title,
                            description: encodedDescription,
                            category: category,
                            colorHex: colorHex
                        )

                        await MainActor.run {
                            // ✅ Call the delegate before dismissing
                            self.delegate?.didSaveAnnouncement()
                            self.dismiss(animated: true)
                        }
                    } catch {
                        print("Supabase insert error:", error)

                        await MainActor.run {
                            self.showAlert(
                                message: "Failed to save announcement.\n\(error.localizedDescription)"
                            )
                        }
                    }
                }
            }
        


//    private func showAlert(title: String, message: String) {
//        let alert = UIAlertController(title: title,
//                                      message: message,
//                                      preferredStyle: .alert)
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }



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
                self?.draftAttachments.append(.link(title: urlString, urlString: urlString))
                self?.syncLegacyAttachmentStorage()
                self?.renderDraftAttachments()
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
        let deleteIndex = attachmentsStackView.arrangedSubviews.count

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
        deleteButton.tag = deleteIndex
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
        let index = sender.tag
        guard draftAttachments.indices.contains(index) else { return }
        draftAttachments.remove(at: index)
        syncLegacyAttachmentStorage()
        renderDraftAttachments()
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
            
            // FIX: Manual content size update since AutoLayout bottom constraint is missing in XIB
            if let scrollView = self.view.subviews.first(where: { $0 is UIScrollView }) as? UIScrollView {
                let bottomPadding: CGFloat = 60
                let totalHeight = self.addAttachmentView.frame.maxY + bottomPadding
                scrollView.contentSize = CGSize(width: scrollView.frame.width, height: max(totalHeight, scrollView.frame.height + 1))
            }
        }
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AddTaskViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        
        if let image = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            let imageName = "Image_\(Date().timeIntervalSince1970).jpg"
            draftAttachments.append(.image(name: imageName, image: image))
            syncLegacyAttachmentStorage()
            renderDraftAttachments()
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
        
        draftAttachments.append(.document(name: url.lastPathComponent, url: url))
        syncLegacyAttachmentStorage()
        renderDraftAttachments()
        print("Document attached: \(url.lastPathComponent)")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        controller.dismiss(animated: true)
    }
}

// MARK: - UIColor Extension
extension UIColor {
    func toHexString() -> String {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            
            guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return "#000000" // fallback if conversion fails
            }
            
            let r = Int(red * 255)
            let g = Int(green * 255)
            let b = Int(blue * 255)

            return String(format: "#%02X%02X%02X", r, g, b)
        }

        var isLight: Bool {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            let brightness = (red * 299 + green * 587 + blue * 114) / 1000
            return brightness > 0.75
        }
    /// Create a UIColor from a hex string like "#FFAA00" or "FFAA00" or "FFAA00FF"
        static func fromHex(_ hex: String) -> UIColor? {
            var cleaned = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()

            // Remove leading "#" if present
            if cleaned.hasPrefix("#") {
                cleaned.removeFirst()
            }

            // Must be 6 (RGB) or 8 (RGBA) characters
            guard cleaned.count == 6 || cleaned.count == 8 else { return nil }

            var rgbValue: UInt64 = 0
            Scanner(string: cleaned).scanHexInt64(&rgbValue)

            let r, g, b, a: CGFloat

            if cleaned.count == 6 {
                r = CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0
                g = CGFloat((rgbValue & 0x00FF00) >> 8)  / 255.0
                b = CGFloat(rgbValue & 0x0000FF) / 255.0
                a = 1.0
            } else {
                r = CGFloat((rgbValue & 0xFF000000) >> 24) / 255.0
                g = CGFloat((rgbValue & 0x00FF0000) >> 16) / 255.0
                b = CGFloat((rgbValue & 0x0000FF00) >> 8)  / 255.0
                a = CGFloat(rgbValue & 0x000000FF) / 255.0
            }

            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
}
