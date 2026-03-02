//import UIKit
//
//// MARK: - Models
//struct AssigneeModel {
//    let name: String
//    let imageUrl: String?
//}
//
//struct AssignedTaskModel {
//    var title: String
//    var dueDate: Date
//    var attachment: String?
//    var assignedTo: AssigneeModel
//}
//
//// MARK: - Main View Controller
//class TaskAssignmentViewController: UIViewController {
//    
//    // MARK: - Properties
//    private var assignedTask: AssignedTaskModel
//    private let availableAssignees = [
//        AssigneeModel(name: "Shreya", imageUrl: nil),
//        AssigneeModel(name: "Lakshy", imageUrl: nil),
//        AssigneeModel(name: "Shruti", imageUrl: nil)
//    ]
//    
//    private var isEditMode = false {
//        didSet {
//            updateEditMode()
//        }
//    }
//    
//    // MARK: - UI Components
//    private let scrollView: UIScrollView = {
//        let sv = UIScrollView()
//        sv.translatesAutoresizingMaskIntoConstraints = false
//        return sv
//    }()
//    
//    private let contentView: UIView = {
//        let view = UIView()
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let backButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.setImage(UIImage(systemName: "chevron.left"), for: .normal)
//        btn.tintColor = .black
//        btn.backgroundColor = .white
//        btn.layer.cornerRadius = 22
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        return btn
//    }()
//    
//    private let titleLabel: UILabel = {
//        let lbl = UILabel()
//        lbl.text = "Assigned"
//        lbl.font = .systemFont(ofSize: 28, weight: .bold)
//        lbl.translatesAutoresizingMaskIntoConstraints = false
//        return lbl
//    }()
//    
//    private let editButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.setTitle("Edit", for: .normal)
//        btn.setTitleColor(.black, for: .normal)
//        btn.titleLabel?.font = .systemFont(ofSize: 17)
//        btn.backgroundColor = .white
//        btn.layer.cornerRadius = 22
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        return btn
//    }()
//    
//    private let checkButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.setImage(UIImage(systemName: "checkmark"), for: .normal)
//        btn.tintColor = .black
//        btn.backgroundColor = .white
//        btn.layer.cornerRadius = 22
//        btn.isHidden = true
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        return btn
//    }()
//    
//    private let closeButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.setImage(UIImage(systemName: "xmark"), for: .normal)
//        btn.tintColor = .black
//        btn.backgroundColor = .white
//        btn.layer.cornerRadius = 22
//        btn.isHidden = true
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        return btn
//    }()
//    
//    // Task Card
//    private let taskCard: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        view.layer.cornerRadius = 24
//        view.layer.shadowColor = UIColor.black.cgColor
//        view.layer.shadowOpacity = 0.05
//        view.layer.shadowOffset = CGSize(width: 0, height: 2)
//        view.layer.shadowRadius = 8
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let taskTextField: UITextField = {
//        let tf = UITextField()
//        tf.font = .systemFont(ofSize: 17)
//        tf.isEnabled = false
//        tf.translatesAutoresizingMaskIntoConstraints = false
//        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: tf.frame.height))
//        tf.leftView = paddingView
//        tf.leftViewMode = .always
//        return tf
//    }()
//    
//    private let pencilIcon: UIImageView = {
//        let iv = UIImageView(image: UIImage(systemName: "pencil"))
//        iv.tintColor = .black
//        iv.translatesAutoresizingMaskIntoConstraints = false
//        return iv
//    }()
//    
//    private let separator1: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor(white: 0.9, alpha: 1)
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let calendarIcon: UIImageView = {
//        let iv = UIImageView(image: UIImage(systemName: "calendar"))
//        iv.tintColor = .systemRed
//        iv.translatesAutoresizingMaskIntoConstraints = false
//        return iv
//    }()
//    
//    private let dueDateLabel: UILabel = {
//        let lbl = UILabel()
//        lbl.text = "Due Date"
//        lbl.font = .systemFont(ofSize: 17)
//        lbl.translatesAutoresizingMaskIntoConstraints = false
//        return lbl
//    }()
//    
//    private let dueDateTextField: UITextField = {
//        let tf = UITextField()
//        tf.textColor = .systemGray
//        tf.font = .systemFont(ofSize: 17)
//        tf.textAlignment = .right
//        tf.tintColor = .clear
//        tf.translatesAutoresizingMaskIntoConstraints = false
//        return tf
//    }()
//    
//    private let dueDateButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.backgroundColor = .clear
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        return btn
//    }()
//    
//    private let datePicker: UIDatePicker = {
//        let dp = UIDatePicker()
//        if #available(iOS 14.0, *) {
//            dp.preferredDatePickerStyle = .inline
//        } else {
//            dp.preferredDatePickerStyle = .wheels
//        }
//        dp.datePickerMode = .date
//        dp.backgroundColor = .white
//        return dp
//    }()
//    
//    // Attachment Card
//    private let attachmentCard: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        view.layer.cornerRadius = 24
//        view.layer.shadowColor = UIColor.black.cgColor
//        view.layer.shadowOpacity = 0.05
//        view.layer.shadowOffset = CGSize(width: 0, height: 2)
//        view.layer.shadowRadius = 8
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let attachmentLabel: UILabel = {
//        let lbl = UILabel()
//        lbl.text = "Attachment"
//        lbl.font = .systemFont(ofSize: 17)
//        lbl.translatesAutoresizingMaskIntoConstraints = false
//        return lbl
//    }()
//    
//    private let attachmentIcon: UIImageView = {
//        let iv = UIImageView(image: UIImage(systemName: "paperclip"))
//        iv.tintColor = .systemGray
//        iv.translatesAutoresizingMaskIntoConstraints = false
//        return iv
//    }()
//    
//    private let separator2: UIView = {
//        let view = UIView()
//        view.backgroundColor = UIColor(white: 0.9, alpha: 1)
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let attachmentFileLabel: UILabel = {
//        let lbl = UILabel()
//        lbl.font = .systemFont(ofSize: 17)
//        lbl.textColor = .systemGray
//        lbl.translatesAutoresizingMaskIntoConstraints = false
//        return lbl
//    }()
//    
//    // Assignment Card
//    private let assignmentCard: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        view.layer.cornerRadius = 24
//        view.layer.shadowColor = UIColor.black.cgColor
//        view.layer.shadowOpacity = 0.05
//        view.layer.shadowOffset = CGSize(width: 0, height: 2)
//        view.layer.shadowRadius = 8
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let assignToLabel: UILabel = {
//        let lbl = UILabel()
//        lbl.text = "Assign To"
//        lbl.font = .systemFont(ofSize: 17)
//        lbl.translatesAutoresizingMaskIntoConstraints = false
//        return lbl
//    }()
//    
//    private let assigneeImageView: UIImageView = {
//        let iv = UIImageView()
//        iv.contentMode = .scaleAspectFill
//        iv.layer.cornerRadius = 20
//        iv.clipsToBounds = true
//        iv.backgroundColor = .systemGray5
//        iv.translatesAutoresizingMaskIntoConstraints = false
//        return iv
//    }()
//    
//    private let assigneeLabel: UILabel = {
//        let lbl = UILabel()
//        lbl.font = .systemFont(ofSize: 17)
//        lbl.textColor = .systemGray
//        lbl.translatesAutoresizingMaskIntoConstraints = false
//        return lbl
//    }()
//    
//    private let dropdownIcon: UIImageView = {
//        let iv = UIImageView(image: UIImage(systemName: "chevron.up.chevron.down"))
//        iv.tintColor = .systemGray
//        iv.isHidden = true
//        iv.translatesAutoresizingMaskIntoConstraints = false
//        return iv
//    }()
//    
//    private let assigneeButton: UIButton = {
//        let btn = UIButton(type: .system)
//        btn.backgroundColor = .clear
//        btn.isEnabled = false
//        btn.translatesAutoresizingMaskIntoConstraints = false
//        return btn
//    }()
//    
//    // Updated Dropdown Menu with ScrollView
//    private let dropdownMenu: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        view.layer.cornerRadius = 20
//        view.layer.shadowColor = UIColor.black.cgColor
//        view.layer.shadowOpacity = 0.15
//        view.layer.shadowOffset = CGSize(width: 0, height: 4)
//        view.layer.shadowRadius = 16
//        view.isHidden = true
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private let dropdownHeaderLabel: UILabel = {
//        let lbl = UILabel()
//        lbl.text = "Assign To"
//        lbl.font = .systemFont(ofSize: 22, weight: .bold)
//        lbl.translatesAutoresizingMaskIntoConstraints = false
//        return lbl
//    }()
//    
//    private let dropdownSubtitleLabel: UILabel = {
//        let lbl = UILabel()
//        lbl.text = "Select a team member"
//        lbl.font = .systemFont(ofSize: 15)
//        lbl.textColor = .systemGray
//        lbl.translatesAutoresizingMaskIntoConstraints = false
//        return lbl
//    }()
//    
//    private let dropdownScrollView: UIScrollView = {
//        let sv = UIScrollView()
//        sv.showsVerticalScrollIndicator = true
//        sv.translatesAutoresizingMaskIntoConstraints = false
//        return sv
//    }()
//    
//    private let dropdownStack: UIStackView = {
//        let sv = UIStackView()
//        sv.axis = .vertical
//        sv.spacing = 12
//        sv.translatesAutoresizingMaskIntoConstraints = false
//        return sv
//    }()
//    
//    private let calendarContainer: UIView = {
//        let view = UIView()
//        view.backgroundColor = .white
//        view.layer.cornerRadius = 20
//        view.layer.shadowColor = UIColor.black.cgColor
//        view.layer.shadowOpacity = 0.15
//        view.layer.shadowOffset = CGSize(width: 0, height: 4)
//        view.layer.shadowRadius = 16
//        view.isHidden = true
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//    
//    private var dropdownHeightConstraint: NSLayoutConstraint?
//    
//    // MARK: - Initialization
//    init(assignedTask: AssignedTaskModel) {
//        self.assignedTask = assignedTask
//        super.init(nibName: nil, bundle: nil)
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Lifecycle
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = UIColor(red: 0xEF/255, green: 0xEF/255, blue: 0xF5/255, alpha: 1)
//        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissCalendar))
//        tap.cancelsTouchesInView = false
//        view.addGestureRecognizer(tap)
//
//        setupUI()
//        setupActions()
//        updateUI()
//    }
//    
//    // MARK: - Setup
//    private func setupUI() {
//        view.addSubview(scrollView)
//        scrollView.addSubview(contentView)
//        
//        contentView.addSubview(backButton)
//        contentView.addSubview(titleLabel)
//        contentView.addSubview(editButton)
//        contentView.addSubview(checkButton)
//        contentView.addSubview(closeButton)
//        contentView.addSubview(taskCard)
//        contentView.addSubview(attachmentCard)
//        contentView.addSubview(assignmentCard)
//        contentView.addSubview(dropdownMenu)
//        contentView.addSubview(calendarContainer)
//        
//        // Task Card
//        taskCard.addSubview(pencilIcon)
//        taskCard.addSubview(taskTextField)
//        taskCard.addSubview(separator1)
//        taskCard.addSubview(calendarIcon)
//        taskCard.addSubview(dueDateLabel)
//        taskCard.addSubview(dueDateTextField)
//        taskCard.addSubview(dueDateButton)
//        
//        // Attachment Card
//        attachmentCard.addSubview(attachmentLabel)
//        attachmentCard.addSubview(attachmentIcon)
//        attachmentCard.addSubview(separator2)
//        attachmentCard.addSubview(attachmentFileLabel)
//        
//        // Assignment Card
//        assignmentCard.addSubview(assignToLabel)
//        assignmentCard.addSubview(assigneeImageView)
//        assignmentCard.addSubview(assigneeLabel)
//        assignmentCard.addSubview(dropdownIcon)
//        assignmentCard.addSubview(assigneeButton)
//        
//        // Dropdown Menu
//        dropdownMenu.addSubview(dropdownStack)
//        
//        calendarContainer.addSubview(datePicker)
//        
//        setupConstraints()
//        setupDropdownMenu()
//    }
//    
//    private func setupConstraints() {
//        dropdownHeightConstraint = dropdownMenu.heightAnchor.constraint(equalToConstant: 150)
//        
//        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            
//            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//            
//            backButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
//            backButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            backButton.widthAnchor.constraint(equalToConstant: 44),
//            backButton.heightAnchor.constraint(equalToConstant: 44),
//            
//            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
//            titleLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
//            
//            editButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
//            editButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            editButton.widthAnchor.constraint(equalToConstant: 70),
//            editButton.heightAnchor.constraint(equalToConstant: 44),
//            
//            checkButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
//            checkButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            checkButton.widthAnchor.constraint(equalToConstant: 44),
//            checkButton.heightAnchor.constraint(equalToConstant: 44),
//            
//            closeButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
//            closeButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            closeButton.widthAnchor.constraint(equalToConstant: 44),
//            closeButton.heightAnchor.constraint(equalToConstant: 44),
//            
//            taskCard.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 32),
//            taskCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            taskCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            pencilIcon.topAnchor.constraint(equalTo: taskCard.topAnchor, constant: 20),
//            pencilIcon.leadingAnchor.constraint(equalTo: taskCard.leadingAnchor, constant: 20),
//            pencilIcon.widthAnchor.constraint(equalToConstant: 24),
//            pencilIcon.heightAnchor.constraint(equalToConstant: 24),
//            
//            taskTextField.centerYAnchor.constraint(equalTo: pencilIcon.centerYAnchor),
//            taskTextField.leadingAnchor.constraint(equalTo: pencilIcon.trailingAnchor, constant: 16),
//            taskTextField.trailingAnchor.constraint(equalTo: taskCard.trailingAnchor, constant: -20),
//            
//            separator1.topAnchor.constraint(equalTo: taskTextField.bottomAnchor, constant: 16),
//            separator1.leadingAnchor.constraint(equalTo: taskCard.leadingAnchor, constant: 20),
//            separator1.trailingAnchor.constraint(equalTo: taskCard.trailingAnchor, constant: -20),
//            separator1.heightAnchor.constraint(equalToConstant: 1),
//            
//            calendarIcon.topAnchor.constraint(equalTo: separator1.bottomAnchor, constant: 16),
//            calendarIcon.leadingAnchor.constraint(equalTo: taskCard.leadingAnchor, constant: 20),
//            calendarIcon.widthAnchor.constraint(equalToConstant: 24),
//            calendarIcon.heightAnchor.constraint(equalToConstant: 24),
//            calendarIcon.bottomAnchor.constraint(equalTo: taskCard.bottomAnchor, constant: -20),
//            
//            dueDateLabel.centerYAnchor.constraint(equalTo: calendarIcon.centerYAnchor),
//            dueDateLabel.leadingAnchor.constraint(equalTo: calendarIcon.trailingAnchor, constant: 16),
//            
//            dueDateTextField.centerYAnchor.constraint(equalTo: calendarIcon.centerYAnchor),
//            dueDateTextField.trailingAnchor.constraint(equalTo: taskCard.trailingAnchor, constant: -20),
//            dueDateTextField.widthAnchor.constraint(greaterThanOrEqualToConstant: 120),
//            
//            dueDateButton.topAnchor.constraint(equalTo: separator1.bottomAnchor),
//            dueDateButton.leadingAnchor.constraint(equalTo: taskCard.leadingAnchor),
//            dueDateButton.trailingAnchor.constraint(equalTo: taskCard.trailingAnchor),
//            dueDateButton.bottomAnchor.constraint(equalTo: taskCard.bottomAnchor),
//            
//            attachmentCard.topAnchor.constraint(equalTo: taskCard.bottomAnchor, constant: 16),
//            attachmentCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            attachmentCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            
//            attachmentLabel.topAnchor.constraint(equalTo: attachmentCard.topAnchor, constant: 20),
//            attachmentLabel.leadingAnchor.constraint(equalTo: attachmentCard.leadingAnchor, constant: 20),
//            
//            attachmentIcon.centerYAnchor.constraint(equalTo: attachmentLabel.centerYAnchor),
//            attachmentIcon.trailingAnchor.constraint(equalTo: attachmentCard.trailingAnchor, constant: -20),
//            
//            separator2.topAnchor.constraint(equalTo: attachmentLabel.bottomAnchor, constant: 16),
//            separator2.leadingAnchor.constraint(equalTo: attachmentCard.leadingAnchor, constant: 20),
//            separator2.trailingAnchor.constraint(equalTo: attachmentCard.trailingAnchor, constant: -20),
//            separator2.heightAnchor.constraint(equalToConstant: 1),
//            
//            attachmentFileLabel.topAnchor.constraint(equalTo: separator2.bottomAnchor, constant: 16),
//            attachmentFileLabel.leadingAnchor.constraint(equalTo: attachmentCard.leadingAnchor, constant: 20),
//            attachmentFileLabel.bottomAnchor.constraint(equalTo: attachmentCard.bottomAnchor, constant: -20),
//            
//            assignmentCard.topAnchor.constraint(equalTo: attachmentCard.bottomAnchor, constant: 16),
//            assignmentCard.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            assignmentCard.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            assignmentCard.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -32),
//            
//            assignToLabel.topAnchor.constraint(equalTo: assignmentCard.topAnchor, constant: 20),
//            assignToLabel.leadingAnchor.constraint(equalTo: assignmentCard.leadingAnchor, constant: 20),
//            assignToLabel.bottomAnchor.constraint(equalTo: assignmentCard.bottomAnchor, constant: -20),
//            
//            assigneeImageView.centerYAnchor.constraint(equalTo: assignToLabel.centerYAnchor),
//            assigneeImageView.trailingAnchor.constraint(equalTo: assigneeLabel.leadingAnchor, constant: -8),
//            assigneeImageView.widthAnchor.constraint(equalToConstant: 40),
//            assigneeImageView.heightAnchor.constraint(equalToConstant: 40),
//            
//            assigneeLabel.centerYAnchor.constraint(equalTo: assignToLabel.centerYAnchor),
//            assigneeLabel.trailingAnchor.constraint(equalTo: dropdownIcon.leadingAnchor, constant: -8),
//            
//            dropdownIcon.centerYAnchor.constraint(equalTo: assignToLabel.centerYAnchor),
//            dropdownIcon.trailingAnchor.constraint(equalTo: assignmentCard.trailingAnchor, constant: -20),
//            dropdownIcon.widthAnchor.constraint(equalToConstant: 16),
//            dropdownIcon.heightAnchor.constraint(equalToConstant: 16),
//            
//            assigneeButton.centerYAnchor.constraint(equalTo: assignToLabel.centerYAnchor),
//            assigneeButton.trailingAnchor.constraint(equalTo: assignmentCard.trailingAnchor),
//            assigneeButton.widthAnchor.constraint(equalToConstant: 200),
//            assigneeButton.heightAnchor.constraint(equalToConstant: 44),
//            
//            dropdownStack.topAnchor.constraint(equalTo: dropdownMenu.topAnchor, constant: 16),
//            dropdownStack.leadingAnchor.constraint(equalTo: dropdownMenu.leadingAnchor, constant: 20),
//            dropdownStack.trailingAnchor.constraint(equalTo: dropdownMenu.trailingAnchor, constant: -20),
//            dropdownStack.bottomAnchor.constraint(equalTo: dropdownMenu.bottomAnchor, constant: -16)
//        ])
//    }
//    
//    private func setupDropdownMenu() {
//        for assignee in availableAssignees {
//            let optionView = createDropdownOption(assignee: assignee)
//            dropdownStack.addArrangedSubview(optionView)
//        }
//    }
//    
//    private func createDropdownOption(assignee: AssigneeModel) -> UIView {
//        let container = UIView()
//        container.translatesAutoresizingMaskIntoConstraints = false
//
//        container.backgroundColor = UIColor.systemGray5
//        container.layer.cornerRadius = 24
//
//        let label = UILabel()
//        label.text = assignee.name
//        label.font = .systemFont(ofSize: 17, weight: .regular)
//        label.textColor = .black
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//
//        let button = UIButton(type: .system)
//        button.backgroundColor = .clear
//        button.translatesAutoresizingMaskIntoConstraints = false
//        button.addTarget(self, action: #selector(assigneeSelected(_:)), for: .touchUpInside)
//        button.tag = availableAssignees.firstIndex(where: { $0.name == assignee.name }) ?? 0
//
//        container.addSubview(label)
//        container.addSubview(button)
//
//        NSLayoutConstraint.activate([
//            container.heightAnchor.constraint(equalToConstant: 48),
//            
//            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
//            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -20),
//            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
//
//            button.topAnchor.constraint(equalTo: container.topAnchor),
//            button.leadingAnchor.constraint(equalTo: container.leadingAnchor),
//            button.trailingAnchor.constraint(equalTo: container.trailingAnchor),
//            button.bottomAnchor.constraint(equalTo: container.bottomAnchor)
//        ])
//
//        return container
//    }
//    
//    private func setupActions() {
//        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
//        editButton.addTarget(self, action: #selector(editTapped), for: .touchUpInside)
//        checkButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
//        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
//        assigneeButton.addTarget(self, action: #selector(assigneeButtonTapped), for: .touchUpInside)
//        dueDateButton.addTarget(self, action: #selector(dateButtonTapped), for: .touchUpInside)
//        datePicker.addTarget(self, action: #selector(dateChanged), for: .valueChanged)
//    }
//    
//    private func updateUI() {
//        taskTextField.text = assignedTask.title
//        assigneeLabel.text = assignedTask.assignedTo.name
//        attachmentFileLabel.text = assignedTask.attachment
//        updateDateTextField()
//        datePicker.date = assignedTask.dueDate
//    }
//    
//    private func updateDateTextField() {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "dd MMM yyyy"
//        dueDateTextField.text = formatter.string(from: assignedTask.dueDate)
//    }
//    
//    private func updateEditMode() {
//        if isEditMode {
//            editButton.isHidden = true
//            backButton.isHidden = true
//            checkButton.isHidden = false
//            closeButton.isHidden = false
//            taskTextField.isEnabled = true
//            taskTextField.backgroundColor = UIColor.systemGray6
//            taskTextField.layer.cornerRadius = 8
//            dueDateButton.isEnabled = true
//            dueDateTextField.isUserInteractionEnabled = true
//            dropdownIcon.isHidden = false
//            assigneeButton.isEnabled = true
//        } else {
//            editButton.isHidden = false
//            backButton.isHidden = false
//            checkButton.isHidden = true
//            closeButton.isHidden = true
//            taskTextField.isEnabled = false
//            taskTextField.backgroundColor = .clear
//            dueDateButton.isEnabled = false
//            dueDateTextField.isUserInteractionEnabled = false
//            dropdownIcon.isHidden = true
//            dropdownMenu.isHidden = true
//            assigneeButton.isEnabled = false
//        }
//    }
//    
//    // MARK: - Actions
//    @objc private func dismissCalendar() {
//        calendarContainer.isHidden = true
//    }
//
//    @objc private func backTapped() {
//        navigationController?.popViewController(animated: true)
//    }
//    
//    @objc private func editTapped() {
//        isEditMode = true
//    }
//    
//    @objc private func saveTapped() {
//        assignedTask.title = taskTextField.text ?? ""
//        isEditMode = false
//        print("Task saved: \(assignedTask)")
//    }
//    
//    @objc private func cancelTapped() {
//        updateUI()
//        isEditMode = false
//    }
//    
//    @objc private func dateButtonTapped() {
//        guard isEditMode else { return }
//
//        calendarContainer.isHidden.toggle()
//
//        if !calendarContainer.isHidden {
//            calendarContainer.removeFromSuperview()
//            contentView.addSubview(calendarContainer)
//
//            datePicker.translatesAutoresizingMaskIntoConstraints = false
//
//            NSLayoutConstraint.activate([
//                calendarContainer.topAnchor.constraint(equalTo: taskCard.bottomAnchor, constant: -90),
//                calendarContainer.leadingAnchor.constraint(equalTo: taskCard.leadingAnchor),
//                calendarContainer.trailingAnchor.constraint(equalTo: taskCard.trailingAnchor),
//                calendarContainer.heightAnchor.constraint(equalToConstant: 320),
//
//                datePicker.topAnchor.constraint(equalTo: calendarContainer.topAnchor, constant: 8),
//                datePicker.leadingAnchor.constraint(equalTo: calendarContainer.leadingAnchor, constant: 8),
//                datePicker.trailingAnchor.constraint(equalTo: calendarContainer.trailingAnchor, constant: -8),
//                datePicker.bottomAnchor.constraint(equalTo: calendarContainer.bottomAnchor, constant: -8)
//            ])
//        }
//    }
//
//    @objc private func assigneeButtonTapped() {
//        if isEditMode {
//            dropdownMenu.isHidden.toggle()
//            
//            if !dropdownMenu.isHidden {
//                dropdownMenu.removeFromSuperview()
//                contentView.addSubview(dropdownMenu)
//                
//                dropdownMenu.translatesAutoresizingMaskIntoConstraints = false
//                
//                NSLayoutConstraint.activate([
//                    dropdownMenu.bottomAnchor.constraint(equalTo: assignmentCard.topAnchor, constant: -12),
//                    dropdownMenu.trailingAnchor.constraint(equalTo: assignmentCard.trailingAnchor, constant: -16),
//                    dropdownMenu.widthAnchor.constraint(equalTo: assignmentCard.widthAnchor, multiplier: 0.7),
//                    dropdownMenu.heightAnchor.constraint(equalToConstant: 260)
//
//                ])
//            }
//        }
//    }
//    
//    @objc private func assigneeSelected(_ sender: UIButton) {
//        let selectedAssignee = availableAssignees[sender.tag]
//        assignedTask.assignedTo = selectedAssignee
//        assigneeLabel.text = selectedAssignee.name
//        dropdownMenu.isHidden = true
//    }
//    
//    @objc private func dateChanged() {
//        assignedTask.dueDate = datePicker.date
//        updateDateTextField()
//    }
//}
