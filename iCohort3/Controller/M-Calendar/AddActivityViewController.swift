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

        alertCardView.layer.cornerRadius = 20
        dateCardView.layer.cornerRadius = 20
        titleCardView.layer.cornerRadius = 20
        sendcardView.layer.cornerRadius = 20
        
        closeButton.layer.cornerRadius = 16
        doneButton.layer.cornerRadius = 16

        startDatePicker.datePickerMode = .date
        endDatePicker.datePickerMode = .date

        alertButton.setTitle("None", for: .normal)
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
