import UIKit

// Protocol to pass data back
protocol NewTaskDelegate: AnyObject {
    func didAssignTask(to memberName: String, description: String, date: Date)
}

class NewTaskViewController: UIViewController {
    @IBOutlet weak var headerView: UIView!
    
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
    
    // Delegate
    weak var delegate: NewTaskDelegate?
    
    // Properties to store team member data
    var teamMemberImages: [UIImage] = []
    var teamMemberNames: [String] = []
    var selectedMemberIndex: Int?
    var selectedMemberName: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        taskView.layer.cornerRadius = 20
        descriptionView.layer.cornerRadius = 20
        assignView.layer.cornerRadius = 20
        attachmentView.layer.cornerRadius = 20
        
        // Initially hide confirm button or disable it
        confirmAssign.isHidden = true
        
        
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        self.dismiss(animated: true)
    }


    
    @IBAction func assignButtonTapped(_ sender: Any) {
        showTeamMemberPicker()
    }
    
    @IBAction func confirmAssignTapped(_ sender: Any) {
        guard let memberName = selectedMemberName else {
            showAlert(message: "Please select a team member first")
            return
        }
        
        let description = descritionTextField.text ?? ""
        let selectedDate = datePicker.date
        
        // Call delegate method
        delegate?.didAssignTask(to: memberName, description: description, date: selectedDate)
        
        // Dismiss the view controller
        self.dismiss(animated: true)
    }
    
    func showTeamMemberPicker() {
        let alert = UIAlertController(title: "Assign To", message: "Select a team member", preferredStyle: .actionSheet)
        
        for (index, name) in teamMemberNames.enumerated() {
            let action = UIAlertAction(title: name, style: .default) { [weak self] _ in
                self?.selectedMemberIndex = index
                self?.selectedMemberName = name
                self?.assignButton.setTitle(name, for: .normal)
                self?.confirmAssign.isHidden = false // Show confirm button
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
