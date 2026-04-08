import UIKit
import PhotosUI
import MobileCoreServices

protocol NewTaskDelegate: AnyObject {
    func didAssignTask(to memberName: String, description: String, date: Date, title: String, attachments: [UIImage], attachmentFilenames: [String])
    func didUpdateTask(at index: Int, memberName: String, description: String, date: Date, title: String, attachments: [UIImage], attachmentFilenames: [String])
}

final class NewTaskViewController: UIViewController {

    weak var delegate: NewTaskDelegate?
    
    // MARK: - Flags & Data
    var isEditMode: Bool = false
    var editingTaskIndex: Int?
    var editingCategory: TaskCategory?
    
    var existingTitle: String?
    var existingDescription: String?
    var selectedMemberName: String?
    var selectedMemberIndex: Int?
    var isAllMembersSelected: Bool = false
    var teamMemberNames: [String] = []
    var teamMemberImages: [UIImage] = []
    
    var existingDate: Date?
    var existingAttachments: [UIImage] = []
    
    var attachments: [UIImage] = []
    var attachmentFilenames: [String] = []
    
    var teamId: String = ""
    var mentorId: String = ""
    var existingTaskId: String?
    
    // MARK: - UI Components
    private let scrollView = UIScrollView()
    private let contentStackView = UIStackView()
    
    private let headerView = UIView()
    private let closeButton = UIButton(type: .system)
    private let newTaskLabel = UILabel()
    
    private let taskCard = UIView()
    private let titleTextField = UITextField()
    private let datePicker = UIDatePicker()
    
    private let attachmentCard = UIView()
    private let attachmentButton = UIButton(type: .system)
    private let attachmentsStackView = UIStackView()
    
    private let descriptionCard = UIView()
    private let descritionTextField = UITextField() // Kept original spelling to maintain compatibility
    
    private let assignCard = UIView()
    private let assignButton = UIButton(type: .system)
    
    private let confirmAssign = UIButton(type: .system)
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        buildLayout()
        
        confirmAssign.isHidden = true
        
        if isEditMode {
            newTaskLabel.text = "Edit Task"
            confirmAssign.setTitle("Update Task", for: .normal)
            loadExistingData()
        } else {
            newTaskLabel.text = "New Task"
        }
        
        updateAttachmentUI()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
    }
    
    @available(iOS, deprecated: 17.0, message: "Use registerForTraitChanges")
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
            applyTheme()
        }
    }
    
    // MARK: - UI Construction
    private func buildLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.alwaysBounceVertical = true
        view.addSubview(scrollView)
        
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.axis = .vertical
        contentStackView.spacing = 20
        contentStackView.alignment = .fill
        scrollView.addSubview(contentStackView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.frameLayoutGuide.trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -100)
        ])
        
        buildHeaderView()
        buildTaskCard()
        buildAttachmentCard()
        buildDescriptionCard()
        buildAssignCard()
        buildConfirmButton()
        
        applyTheme()
    }
    
    private func buildHeaderView() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        headerView.addSubview(closeButton)
        
        newTaskLabel.translatesAutoresizingMaskIntoConstraints = false
        newTaskLabel.font = .systemFont(ofSize: 18, weight: .bold)
        headerView.addSubview(newTaskLabel)
        
        NSLayoutConstraint.activate([
            closeButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 0),
            closeButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            newTaskLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            newTaskLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
        
        contentStackView.addArrangedSubview(headerView)
    }
    
    private func buildTaskCard() {
        taskCard.translatesAutoresizingMaskIntoConstraints = false
        
        let pencilIcon = UIImageView(image: UIImage(systemName: "pencil"))
        pencilIcon.translatesAutoresizingMaskIntoConstraints = false
        pencilIcon.contentMode = .scaleAspectFit
        
        titleTextField.translatesAutoresizingMaskIntoConstraints = false
        titleTextField.placeholder = "Enter Task Title"
        titleTextField.autocapitalizationType = .sentences
        
        let separator = UIView()
        separator.translatesAutoresizingMaskIntoConstraints = false
        separator.backgroundColor = UIColor.separator.withAlphaComponent(0.2)
        
        let calendarIcon = UIImageView(image: UIImage(systemName: "calendar"))
        calendarIcon.translatesAutoresizingMaskIntoConstraints = false
        calendarIcon.contentMode = .scaleAspectFit
        calendarIcon.tintColor = .white
        
        let dueLabel = UILabel()
        dueLabel.translatesAutoresizingMaskIntoConstraints = false
        dueLabel.text = "Due Date"
        dueLabel.font = .systemFont(ofSize: 16)
        
        datePicker.translatesAutoresizingMaskIntoConstraints = false
        datePicker.datePickerMode = .date
        
        taskCard.addSubview(pencilIcon)
        taskCard.addSubview(titleTextField)
        taskCard.addSubview(separator)
        taskCard.addSubview(calendarIcon)
        taskCard.addSubview(dueLabel)
        taskCard.addSubview(datePicker)
        
        NSLayoutConstraint.activate([
            pencilIcon.leadingAnchor.constraint(equalTo: taskCard.leadingAnchor, constant: 16),
            pencilIcon.topAnchor.constraint(equalTo: taskCard.topAnchor, constant: 16),
            pencilIcon.widthAnchor.constraint(equalToConstant: 24),
            pencilIcon.heightAnchor.constraint(equalToConstant: 24),
            
            titleTextField.leadingAnchor.constraint(equalTo: pencilIcon.trailingAnchor, constant: 16),
            titleTextField.trailingAnchor.constraint(equalTo: taskCard.trailingAnchor, constant: -16),
            titleTextField.centerYAnchor.constraint(equalTo: pencilIcon.centerYAnchor),
            titleTextField.heightAnchor.constraint(equalToConstant: 40),
            
            separator.leadingAnchor.constraint(equalTo: taskCard.leadingAnchor, constant: 40),
            separator.trailingAnchor.constraint(equalTo: taskCard.trailingAnchor, constant: -16),
            separator.topAnchor.constraint(equalTo: pencilIcon.bottomAnchor, constant: 16),
            separator.heightAnchor.constraint(equalToConstant: 1),
            
            calendarIcon.leadingAnchor.constraint(equalTo: taskCard.leadingAnchor, constant: 16),
            calendarIcon.topAnchor.constraint(equalTo: separator.bottomAnchor, constant: 16),
            calendarIcon.bottomAnchor.constraint(equalTo: taskCard.bottomAnchor, constant: -16),
            calendarIcon.widthAnchor.constraint(equalToConstant: 24),
            calendarIcon.heightAnchor.constraint(equalToConstant: 24),
            
            dueLabel.leadingAnchor.constraint(equalTo: calendarIcon.trailingAnchor, constant: 16),
            dueLabel.centerYAnchor.constraint(equalTo: calendarIcon.centerYAnchor),
            
            datePicker.trailingAnchor.constraint(equalTo: taskCard.trailingAnchor, constant: -16),
            datePicker.centerYAnchor.constraint(equalTo: calendarIcon.centerYAnchor)
        ])
        
        contentStackView.addArrangedSubview(taskCard)
    }
    
    private func buildAttachmentCard() {
        attachmentCard.translatesAutoresizingMaskIntoConstraints = false
        
        attachmentButton.translatesAutoresizingMaskIntoConstraints = false
        attachmentButton.setTitle("Add Attachment...", for: .normal)
        attachmentButton.contentHorizontalAlignment = .left
        attachmentButton.titleLabel?.font = .systemFont(ofSize: 16)
        attachmentButton.addTarget(self, action: #selector(attachmentButtonTapped), for: .touchUpInside)
        
        attachmentsStackView.translatesAutoresizingMaskIntoConstraints = false
        attachmentsStackView.axis = .vertical
        attachmentsStackView.spacing = 8
        
        attachmentCard.addSubview(attachmentButton)
        attachmentCard.addSubview(attachmentsStackView)
        
        NSLayoutConstraint.activate([
            attachmentButton.topAnchor.constraint(equalTo: attachmentCard.topAnchor, constant: 12),
            attachmentButton.leadingAnchor.constraint(equalTo: attachmentCard.leadingAnchor, constant: 16),
            attachmentButton.trailingAnchor.constraint(equalTo: attachmentCard.trailingAnchor, constant: -16),
            attachmentButton.heightAnchor.constraint(equalToConstant: 30),
            
            attachmentsStackView.topAnchor.constraint(equalTo: attachmentButton.bottomAnchor, constant: 12),
            attachmentsStackView.leadingAnchor.constraint(equalTo: attachmentCard.leadingAnchor, constant: 16),
            attachmentsStackView.trailingAnchor.constraint(equalTo: attachmentCard.trailingAnchor, constant: -16),
            attachmentsStackView.bottomAnchor.constraint(equalTo: attachmentCard.bottomAnchor, constant: -12)
        ])
        
        contentStackView.addArrangedSubview(attachmentCard)
    }
    
    private func buildDescriptionCard() {
        descriptionCard.translatesAutoresizingMaskIntoConstraints = false
        
        descritionTextField.translatesAutoresizingMaskIntoConstraints = false
        descritionTextField.placeholder = "Add Description"
        descritionTextField.autocapitalizationType = .sentences
        descritionTextField.contentVerticalAlignment = .top
        
        descriptionCard.addSubview(descritionTextField)
        
        NSLayoutConstraint.activate([
            descritionTextField.topAnchor.constraint(equalTo: descriptionCard.topAnchor, constant: 16),
            descritionTextField.leadingAnchor.constraint(equalTo: descriptionCard.leadingAnchor, constant: 16),
            descritionTextField.trailingAnchor.constraint(equalTo: descriptionCard.trailingAnchor, constant: -16),
            descritionTextField.bottomAnchor.constraint(equalTo: descriptionCard.bottomAnchor, constant: -16),
            descriptionCard.heightAnchor.constraint(equalToConstant: 100)
        ])
        
        contentStackView.addArrangedSubview(descriptionCard)
    }
    
    private func buildAssignCard() {
        assignCard.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Assign To"
        label.font = .systemFont(ofSize: 16)
        
        assignButton.translatesAutoresizingMaskIntoConstraints = false
        assignButton.setImage(UIImage(systemName: "chevron.up.chevron.down"), for: .normal)
        assignButton.addTarget(self, action: #selector(assignButtonTapped), for: .touchUpInside)
        
        assignCard.addSubview(label)
        assignCard.addSubview(assignButton)
        
        NSLayoutConstraint.activate([
            assignCard.heightAnchor.constraint(equalToConstant: 56),
            
            label.leadingAnchor.constraint(equalTo: assignCard.leadingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: assignCard.centerYAnchor),
            
            assignButton.trailingAnchor.constraint(equalTo: assignCard.trailingAnchor, constant: -16),
            assignButton.centerYAnchor.constraint(equalTo: assignCard.centerYAnchor)
        ])
        
        contentStackView.addArrangedSubview(assignCard)
    }
    
    private func buildConfirmButton() {
        confirmAssign.translatesAutoresizingMaskIntoConstraints = false
        confirmAssign.setTitle("Assign", for: .normal)
        confirmAssign.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        confirmAssign.addTarget(self, action: #selector(confirmAssignTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            confirmAssign.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        contentStackView.addArrangedSubview(confirmAssign)
    }
    
    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        view.backgroundColor = .clear
        scrollView.backgroundColor = .clear
        let primaryColor = AppTheme.buttonColor
        
        [taskCard, attachmentCard, descriptionCard, assignCard].forEach { card in
            AppTheme.styleElevatedCard(card, cornerRadius: 20)
            card.layer.cornerCurve = .continuous
            card.subviews.forEach { sub in
                if let img = sub as? UIImageView { img.tintColor = .label }
                if let lbl = sub as? UILabel { lbl.textColor = .label }
            }
        }
        
        newTaskLabel.textColor = .label
        
        [titleTextField, descritionTextField].forEach {
            $0.textColor = .label
            $0.tintColor = primaryColor
        }

        assignButton.setTitleColor(.label, for: .normal)
        assignButton.tintColor = primaryColor
        
        let attColor: UIColor = traitCollection.userInterfaceStyle == .dark ? .white : .secondaryLabel
        attachmentButton.setTitleColor(attColor, for: .normal)
        attachmentButton.tintColor = attColor
        
        confirmAssign.setTitleColor(.white, for: .normal)
        confirmAssign.tintColor = .white
        confirmAssign.backgroundColor = primaryColor
        confirmAssign.layer.cornerRadius = 25

        datePicker.tintColor = primaryColor
        datePicker.addTarget(self, action: #selector(datePickerValueChanged), for: .valueChanged)
        
        styleFloatingButton(closeButton, imageName: "xmark")
    }
    
    private func styleFloatingButton(_ button: UIButton, imageName: String) {
        let foreground = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: imageName)
        config.baseForegroundColor = foreground
        config.background.backgroundColor = .clear
        config.cornerStyle = .capsule
        button.configuration = config
        AppTheme.styleNativeFloatingControl(button, cornerRadius: 22)
        button.backgroundColor = .clear
        button.tintColor = foreground
    }
    
    // MARK: - Handlers
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
    
    @objc private func datePickerValueChanged(_ sender: UIDatePicker) {
        if let presented = self.presentedViewController, !presented.isProxy() {
            presented.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func closeButtonTapped() {
        self.dismiss(animated: true)
    }
    
    @objc private func assignButtonTapped() {
        showTeamMemberPicker()
    }
    
    @objc private func confirmAssignTapped() {
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
    
    @objc private func attachmentButtonTapped() {
        showAttachmentOptions()
    }
    
    private func showAttachmentOptions() {
        let alert = UIAlertController(title: "Add Attachment", message: "Choose an option", preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let cameraAction = UIAlertAction(title: "Camera", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }
            if let cameraIcon = UIImage(systemName: "camera.fill")?.withTintColor(AppTheme.buttonColor, renderingMode: .alwaysOriginal) {
                cameraAction.setValue(cameraIcon, forKey: "image")
            }
            alert.addAction(cameraAction)
        }
        
        if #available(iOS 14, *) {
            let photoAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
                self?.presentPHPicker()
            }
            if let photoIcon = UIImage(systemName: "photo.fill")?.withTintColor(AppTheme.buttonColor, renderingMode: .alwaysOriginal) {
                photoAction.setValue(photoIcon, forKey: "image")
            }
            alert.addAction(photoAction)
        } else {
            let photoAction = UIAlertAction(title: "Photo Library", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .photoLibrary)
            }
            if let photoIcon = UIImage(systemName: "photo.fill")?.withTintColor(AppTheme.buttonColor, renderingMode: .alwaysOriginal) {
                photoAction.setValue(photoIcon, forKey: "image")
            }
            alert.addAction(photoAction)
        }
        
        let filesAction = UIAlertAction(title: "Files", style: .default) { [weak self] _ in
            self?.presentDocumentPicker()
        }
        if let fileIcon = UIImage(systemName: "doc.fill")?.withTintColor(AppTheme.buttonColor, renderingMode: .alwaysOriginal) {
            filesAction.setValue(fileIcon, forKey: "image")
        }
        alert.addAction(filesAction)
        
        let linkAction = UIAlertAction(title: "Add Link", style: .default) { [weak self] _ in
            self?.showAddLinkDialog()
        }
        if let linkIcon = UIImage(systemName: "link")?.withTintColor(AppTheme.buttonColor, renderingMode: .alwaysOriginal) {
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
    
    // MARK: - Picker Presentations
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = false
        present(picker, animated: true)
    }
    
    @available(iOS 14, *)
    private func presentPHPicker() {
        var config = PHPickerConfiguration()
        config.selectionLimit = 5
        config.filter = .images
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func presentDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.image, .pdf])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = true
        present(documentPicker, animated: true)
    }
    
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
                self?.showAlert(message: "Please enter a valid URL.")
                return
            }
            
            if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
                let linkImage = self?.createLinkPlaceholderImage() ?? UIImage()
                self?.attachments.append(linkImage)
                self?.attachmentFilenames.append(urlString)
                self?.updateAttachmentUI()
            } else {
                self?.showAlert(message: "The URL you entered is not valid.")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        alert.addAction(addAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
    }
    
    private func createLinkPlaceholderImage() -> UIImage {
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            AppTheme.buttonColor.withAlphaComponent(0.1).setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let iconConfig = UIImage.SymbolConfiguration(pointSize: 40, weight: .regular)
            let linkIcon = UIImage(systemName: "link", withConfiguration: iconConfig)
            linkIcon?.withTintColor(AppTheme.buttonColor, renderingMode: .alwaysOriginal).draw(in: CGRect(x: 30, y: 30, width: 40, height: 40))
        }
        return image
    }
    
    // MARK: - Attachments UI
    private func updateAttachmentUI() {
        attachmentsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (index, _) in attachments.enumerated() {
            let filename = index < attachmentFilenames.count ? attachmentFilenames[index] : "Image_\(index).jpg"
            let isLink = filename.hasPrefix("http://") || filename.hasPrefix("https://")
            
            let view = isLink ? createLinkAttachmentView(url: filename, index: index) : createImageAttachmentView(filename: filename, index: index)
            attachmentsStackView.addArrangedSubview(view)
        }
        
        attachmentCard.isHidden = false
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    private func createLinkAttachmentView(url: String, index: Int) -> UIView {
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = isDarkMode
            ? AppTheme.buttonColor.withAlphaComponent(0.18)
            : AppTheme.buttonColor.withAlphaComponent(0.08)
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = AppTheme.buttonColor.withAlphaComponent(isDarkMode ? 0.35 : 0.20).cgColor
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = AppTheme.buttonColor
        let iconConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .medium)
        iconImageView.image = UIImage(systemName: "link", withConfiguration: iconConfig)
        
        let urlLabel = UILabel()
        urlLabel.translatesAutoresizingMaskIntoConstraints = false
        if let urlObj = URL(string: url) {
            urlLabel.text = urlObj.host ?? url
        } else {
            urlLabel.text = url
        }
        urlLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        urlLabel.textColor = .label
        urlLabel.numberOfLines = 2
        
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
        let isDarkMode = traitCollection.userInterfaceStyle == .dark
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = isDarkMode
            ? UIColor.white.withAlphaComponent(0.10)
            : UIColor.systemFill
        containerView.layer.cornerRadius = 12
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.separator.withAlphaComponent(isDarkMode ? 0.28 : 0.16).cgColor
        
        let iconImageView = UIImageView()
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = AppTheme.buttonColor
        
        let fileExtension = (filename as NSString).pathExtension.lowercased()
        let iconName: String
        switch fileExtension {
        case "pdf": iconName = "doc.text.fill"
        case "jpg", "jpeg", "png", "heic": iconName = "photo.fill"
        case "doc", "docx": iconName = "doc.text.fill"
        default: iconName = "photo.fill"
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
    
    @objc private func removeAttachment(_ sender: UIButton) {
        let index = sender.tag
        guard index >= 0 && index < attachments.count else { return }
        attachments.remove(at: index)
        if index < attachmentFilenames.count {
            attachmentFilenames.remove(at: index)
        }
        updateAttachmentUI()
    }
    
    private func showTeamMemberPicker() {
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
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popoverController = alert.popoverPresentationController {
            popoverController.sourceView = assignButton
            popoverController.sourceRect = assignButton.bounds
        }
        
        present(alert, animated: true)
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Picker Delegates
extension NewTaskViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            attachments.append(image)
            let timestamp = Date().timeIntervalSince1970
            attachmentFilenames.append("Image_\(Int(timestamp)).jpg")
            updateAttachmentUI()
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

@available(iOS 14, *)
extension NewTaskViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        for result in results {
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
                if let image = object as? UIImage {
                    DispatchQueue.main.async {
                        self?.attachments.append(image)
                        let timestamp = Date().timeIntervalSince1970
                        self?.attachmentFilenames.append("Image_\(Int(timestamp)).jpg")
                        self?.updateAttachmentUI()
                    }
                }
            }
        }
    }
}

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
