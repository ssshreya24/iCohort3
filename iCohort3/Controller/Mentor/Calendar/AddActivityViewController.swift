import UIKit

protocol AddActivityViewControllerDelegate: AnyObject {
    func didSaveActivity()
}

class AddActivityViewController: UIViewController {
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var sendcardView: UIView!
    @IBOutlet weak var alertCardView: UIView!
    @IBOutlet weak var dateCardView: UIView!
    @IBOutlet weak var titleCardView: UIView!
    @IBOutlet weak var topBarView: UIView!
    @IBOutlet weak var titleTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var allDaySwitch: UISwitch!
    @IBOutlet weak var startDatePicker: UIDatePicker!
    @IBOutlet weak var endDatePicker: UIDatePicker!
    @IBOutlet weak var alertButton: UIButton!
    @IBOutlet weak var sendButton: UIButton!
    
    weak var delegate: AddActivityViewControllerDelegate?
    
    private var isSaving = false
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        enableKeyboardDismissOnTap()
        setupUI()
        
        if #available(iOS 14.0, *) {
            setupSendMenu()
        }
        
        if #available(iOS 14.0, *) {
            startDatePicker.preferredDatePickerStyle = .compact
            endDatePicker.preferredDatePickerStyle = .compact
        }
        
        startDatePicker.datePickerMode = .date
        endDatePicker.datePickerMode = .date
        applyTheme()
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
    
    @available(iOS 14.0, *)
    private func setupSendMenu() {
        let options = ["For Me", "Everyone", "All Mentors", "All Students"]

        let actions = options.map { option in
            UIAction(title: option, state: option == selectedSendOption ? .on : .off) { [weak self] _ in
                self?.selectedSendOption = option
            }
        }

        sendButton.menu = UIMenu(title: "Send To", children: actions)
        sendButton.showsMenuAsPrimaryAction = true
    }

    // MARK: - UI Setup
    private func setupUI() {
        startDatePicker.datePickerMode = .date
        endDatePicker.datePickerMode = .date

        alertButton.setTitle("None", for: .normal)
    }
    
    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        [sendcardView, alertCardView, dateCardView, titleCardView, topBarView].forEach {
            guard let card = $0 else { return }
            AppTheme.styleElevatedCard(card, cornerRadius: 20)
            card.layer.cornerCurve = .continuous
        }
        [titleTextField, noteTextField].forEach {
            $0?.textColor = .label
            $0?.tintColor = AppTheme.accent
        }
        [alertButton, sendButton].forEach {
            $0?.setTitleColor(.label, for: .normal)
            $0?.tintColor = .label
            $0?.backgroundColor = traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.10)
                : UIColor.systemFill
            $0?.layer.cornerRadius = ($0?.bounds.height ?? 0) / 2
        }
        allDaySwitch.onTintColor = AppTheme.accent
        allDaySwitch.thumbTintColor = .white
        let offTrackColor = traitCollection.userInterfaceStyle == .dark
            ? UIColor.white.withAlphaComponent(0.18)
            : UIColor(red: 0.21, green: 0.33, blue: 0.49, alpha: 0.24)
        allDaySwitch.tintColor = offTrackColor
        allDaySwitch.backgroundColor = offTrackColor
        allDaySwitch.layer.cornerRadius = allDaySwitch.bounds.height / 2
        allDaySwitch.layer.masksToBounds = true
        startDatePicker.tintColor = AppTheme.accent
        endDatePicker.tintColor = AppTheme.accent
        styleFloatingButton(closeButton, imageName: "xmark")
        styleFloatingButton(doneButton, imageName: "checkmark")
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

    // MARK: - Actions
    @IBAction func closeTapped(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func doneTapped(_ sender: Any) {
        saveActivityToSupabase()
    }
    
    private func saveActivityToSupabase() {
        guard !isSaving else { return }
        
        // Validate input
        guard let title = titleTextField.text, !title.isEmpty else {
            showError("Please enter a title")
            return
        }
        
        isSaving = true
        doneButton.isEnabled = false
        doneButton.setTitle("Saving...", for: .normal)
        
        let note = noteTextField.text
        let start = startDatePicker.date
        let end = endDatePicker.date
        let allDay = allDaySwitch.isOn
        let alert = selectedAlertOption
        let sendTo = selectedSendOption
        
        Task {
            do {
                _ = try await SupabaseManager.shared.saveMentorActivity(
                    title: title,
                    note: note,
                    startDate: start,
                    endDate: end,
                    isAllDay: allDay,
                    alertOption: alert,
                    sendTo: sendTo,
                    mentorId: nil  // You can set this to the current user's ID if available
                )
                
                await MainActor.run {
                    self.isSaving = false
                    self.delegate?.didSaveActivity()
                    self.dismiss(animated: true)
                }
                
            } catch {
                await MainActor.run {
                    self.isSaving = false
                    self.doneButton.isEnabled = true
                    self.doneButton.setTitle("Done", for: .normal)
                    self.showError("Failed to save activity: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func allDaySwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            startDatePicker.datePickerMode = .date
            endDatePicker.datePickerMode = .date
        } else {
            startDatePicker.datePickerMode = .dateAndTime
            endDatePicker.datePickerMode = .dateAndTime
        }
    }

    // MARK: - Alert selection state
    private var selectedAlertOption: String = "None" {
        didSet {
            alertButton.setTitle(selectedAlertOption, for: .normal)
        }
    }

    @IBAction func alertButtonTapped(_ sender: Any) {
        let options = ["None", "At time of event", "5 minutes before", "15 minutes before", "30 minutes before", "1 hour before"]

        if #available(iOS 14.0, *) {
            let actions: [UIAction] = options.map { option in
                let state: UIMenuElement.State = (option == selectedAlertOption) ? .on : .off
                return UIAction(title: option, state: state) { [weak self] _ in
                    self?.selectedAlertOption = option
                }
            }

            let menu = UIMenu(title: "Alert", children: actions)

            if let button = sender as? UIButton {
                button.menu = menu
                button.showsMenuAsPrimaryAction = true
            } else {
                presentMenuUsingAlertController(options: options)
            }
        } else {
            presentMenuUsingAlertController(options: options)
        }
    }

    private func presentMenuUsingAlertController(options: [String]) {
        let sheet = UIAlertController(title: "Alert", message: nil, preferredStyle: .actionSheet)
        options.forEach { option in
            let action = UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.selectedAlertOption = option
            }
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if let popover = sheet.popoverPresentationController {
            popover.sourceView = alertButton
            popover.sourceRect = alertButton.bounds
            popover.permittedArrowDirections = .any
        }

        present(sheet, animated: true, completion: nil)
    }
    
    private var selectedSendOption: String = "For Me" {
        didSet {
            sendButton.setTitle(selectedSendOption, for: .normal)
        }
    }

    @IBAction func sendButton(_ sender: Any) {
        let options = ["For Me", "Everyone", "All Mentors", "All Students"]

        if #available(iOS 14.0, *) {
            let actions: [UIAction] = options.map { option in
                let state: UIMenuElement.State = (option == selectedSendOption) ? .on : .off

                return UIAction(title: option, state: state) { [weak self] _ in
                    self?.selectedSendOption = option
                }
            }

            let menu = UIMenu(title: "Send To", children: actions)

            if let button = sender as? UIButton {
                button.menu = menu
                button.showsMenuAsPrimaryAction = true
            }

        } else {
            presentSendMenuViaActionSheet(options: options)
        }
    }

    private func presentSendMenuViaActionSheet(options: [String]) {
        let sheet = UIAlertController(title: "Send To", message: nil, preferredStyle: .actionSheet)

        for option in options {
            let action = UIAlertAction(title: option, style: .default) { [weak self] _ in
                self?.selectedSendOption = option
            }
            sheet.addAction(action)
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sendButton
            pop.sourceRect = sendButton.bounds
        }

        present(sheet, animated: true)
    }
}
