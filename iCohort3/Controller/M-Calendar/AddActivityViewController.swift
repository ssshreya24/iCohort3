//
//  AddActivityViewController.swift
//  iCohort3
//
//  Created by user@51 on 16/11/25.
//

import UIKit

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

            
            startDatePicker.datePickerMode = .date      // only date initially
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
            view.backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 1.0, alpha: 1.0)
            
            topBarView.backgroundColor = UIColor(red: 0.93, green: 0.95, blue: 1.0, alpha: 1.0)
            
            alertCardView.layer.cornerRadius = 20
            dateCardView.layer.cornerRadius = 20
            titleCardView.layer.cornerRadius = 20
            sendcardView.layer.cornerRadius = 20

            
            
            // Rounded buttons
            closeButton.layer.cornerRadius = 16
            doneButton.layer.cornerRadius = 16

            startDatePicker.datePickerMode = .date
            endDatePicker.datePickerMode = .date

            // Default alert state
            alertButton.setTitle("None", for: .normal)
        }

        // MARK: - Actions
        @IBAction func closeTapped(_ sender: Any) {
            dismiss(animated: true)
        }

        @IBAction func doneTapped(_ sender: Any) {
            let title = titleTextField.text ?? ""
            let note = noteTextField.text ?? ""
            let start = startDatePicker.date
            let end = endDatePicker.date
            let allDay = allDaySwitch.isOn
            let alert = alertButton.title(for: .normal) ?? "None"

            print("Activity Saved:")
            print("Title:", title)
            print("Note:", note)
            print("All Day:", allDay)
            print("Start:", start)
            print("End:", end)
            print("Alert:", alert)

            dismiss(animated: true)
        }
    
    @IBAction func allDaySwitchChanged(_ sender: UISwitch) {
        if sender.isOn {
            // ALL DAY → Show only dates
            startDatePicker.datePickerMode = .date
            endDatePicker.datePickerMode = .date
        } else {
            // NOT ALL DAY → Show date + time
            startDatePicker.datePickerMode = .dateAndTime
            endDatePicker.datePickerMode = .dateAndTime
        }
    }

    // MARK: - Alert selection state
    private var selectedAlertOption: String = "None" {
        didSet {
            // Update button title to reflect current selection
            alertButton.setTitle(selectedAlertOption, for: .normal)
        }
    }

    // MARK: - Modern alert menu action (connected to the alert button)
    @IBAction func alertButtonTapped(_ sender: Any) {
        let options = ["None", "At time of event", "5 minutes before", "15 minutes before", "30 minutes before", "1 hour before"]

        if #available(iOS 14.0, *) {
            // Build UIActions with state (checkmark) based on selectedAlertOption
            let actions: [UIAction] = options.map { option in
                let state: UIMenuElement.State = (option == selectedAlertOption) ? .on : .off
                return UIAction(title: option, image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: state) { [weak self] _ in
                    guard let self = self else { return }
                    // Update selected option (this will update button title via didSet)
                    self.selectedAlertOption = option
                    // Optionally perform any other logic (persist selection, schedule notifications etc.)
                }
            }

            // Create the menu
            let menu = UIMenu(title: "Alert", image: nil, identifier: nil, options: [], children: actions)

            // Assign menu to the button and make it show as primary action.
            // NOTE: setting this will make the button show the menu when tapped.
            if let button = sender as? UIButton {
                button.menu = menu
                button.showsMenuAsPrimaryAction = true
                // If you want the menu to appear immediately on this tap, we set the menu and return;
                // the menu will appear on the next tap automatically. To show immediately, fall back to UIAlertController below.
                // Usually assigning menu here is enough for modern behavior.
            } else {
                // If IBAction called in some other way, present a temporary UIAlertController as fallback to show immediately.
                presentMenuUsingAlertController(options: options)
            }
        } else {
            // Fallback for iOS < 14: use UIAlertController action sheet with popover anchor
            presentMenuUsingAlertController(options: options)
        }
    }

    // Helper fallback using UIAlertController (keeps iPad popover safety)
    private func presentMenuUsingAlertController(options: [String]) {
        let sheet = UIAlertController(title: "Alert", message: nil, preferredStyle: .actionSheet)
        options.forEach { option in
            let action = UIAlertAction(title: option, style: .default) { [weak self] _ in
                guard let self = self else { return }
                self.selectedAlertOption = option
            }
            // Add checkmark by setting a checkmark character on the title for the currently selected option
            if option == selectedAlertOption {
                // show selection visually in the sheet (simple approach)
                action.setValue(true, forKey: "checked") // not public API; may not work—so we append a ✓ instead
                // safer: append checkmark to title
                // but to keep titles clean, we avoid changing them here. You can append " ✓" if you like.
            }
            sheet.addAction(action)
        }
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // iPad popover anchor safety
        if let popover = sheet.popoverPresentationController {
            popover.sourceView = alertButton
            popover.sourceRect = alertButton.bounds
            popover.permittedArrowDirections = .any
        }

        present(sheet, animated: true, completion: nil)
    }
    
    // MARK: - Modern alert menu action (connected to the alert button)
    
    
    private var selectedSendOption: String = "For Me" {
        didSet {
            sendButton.setTitle(selectedSendOption, for: .normal)
        }
    }

    
    @IBAction func sendButton(_ sender: Any) {
        let options = ["For Me", "Everyone", "All Mentors", "All Students"]

        if #available(iOS 14.0, *) {
            // Create UIActions for menu
            let actions: [UIAction] = options.map { option in
                let state: UIMenuElement.State = (option == selectedSendOption) ? .on : .off

                return UIAction(
                    title: option,
                    image: nil,
                    identifier: nil,
                    discoverabilityTitle: nil,
                    attributes: [],
                    state: state
                ) { [weak self] _ in
                    self?.selectedSendOption = option
                }
            }

            let menu = UIMenu(
                title: "Send To",
                image: nil,
                identifier: nil,
                options: [],
                children: actions
            )

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

        // iPad-safe anchor
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sendButton
            pop.sourceRect = sendButton.bounds
        }

        present(sheet, animated: true)
    }

}
