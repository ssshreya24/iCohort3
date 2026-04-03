import UIKit

class MCalendarViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var calendarView: UICalendarView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var addActivityButton: UIButton!
    
    private var chevronButton: UIButton!
    
    // MARK: - Properties
    private var currentDate = Date()
    private var selectedDate = Calendar.current.startOfDay(for: Date())
    
    private var activities: [Date: [Mactivity]] = [:]
    private var displayedActivities: [Mactivity] = []
    
    private var isCalendarExpanded = true
    private var isEditingMode = false
    
    private var isLoading = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        applyTheme()
        
        setupCalendar()
        setupTableView()
        setupChevronButton()
        setupMonthLabelTapGesture()
        setupEditButton()
        updateMonthLabel()
        
        updateActivitiesList(for: selectedDate)
        
        emptyStateLabel.isHidden = false
        emptyStateLabel.text = "No activities yet"
        
        calendarView.layer.cornerRadius = 20
        
        // Load activities from Supabase
        loadActivitiesFromSupabase()
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when returning to this screen
        loadActivitiesFromSupabase()
    }
    
    // MARK: - Supabase Data Loading
    
    private func loadActivitiesFromSupabase() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                let rows = try await SupabaseManager.shared.fetchAllMentorActivities()
                
                // Convert rows to activities and group by date
                var newActivities: [Date: [Mactivity]] = [:]
                
                for row in rows {
                    let activity = Mactivity.from(row)
                    let dateKey = Calendar.current.startOfDay(for: activity.startDate)
                    
                    if newActivities[dateKey] != nil {
                        newActivities[dateKey]?.append(activity)
                    } else {
                        newActivities[dateKey] = [activity]
                    }
                }
                
                // Update UI on main thread
                await MainActor.run {
                    self.activities = newActivities
                    self.updateActivitiesList(for: self.selectedDate)
                    self.reloadCalendarDecorations()
                    self.isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.showError("Failed to load activities: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func deleteActivityFromSupabase(_ activity: Mactivity, at indexPath: IndexPath) {
        guard let activityId = activity.id else {
            // Local-only activity, just remove from UI
            removeActivityLocally(at: indexPath)
            return
        }
        
        Task {
            do {
                try await SupabaseManager.shared.deleteMentorActivity(id: activityId)
                
                await MainActor.run {
                    self.removeActivityLocally(at: indexPath)
                }
                
            } catch {
                await MainActor.run {
                    self.showError("Failed to delete activity: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func removeActivityLocally(at indexPath: IndexPath) {
        // Remove from displayed activities
        displayedActivities.remove(at: indexPath.row)
        
        // Update the activities dictionary
        if displayedActivities.isEmpty {
            activities.removeValue(forKey: selectedDate)
            
            // Exit editing mode automatically when no activities remain
            tableView.setEditing(false, animated: true)
            isEditingMode = false
            editButton.isSelected = false
        } else {
            activities[selectedDate] = displayedActivities
        }
        
        // Delete the row with animation
        tableView.deleteRows(at: [indexPath], with: .fade)
        
        // Reload calendar decorations
        reloadCalendarDecorations()
        
        // Update UI
        updateActivitiesList(for: selectedDate)
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
    
    // MARK: - Actions
    
    @IBAction func addActivityButtonTapped(_ sender: Any) {
        let vc = AddActivityViewController(nibName: "AddActivityViewController", bundle: nil)
        vc.delegate = self
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(vc, animated: true)
    }

    func updateActivitiesList(for date: Date) {
        displayedActivities = activities[date] ?? []
        
        // Always ensure table view editing mode matches our flag
        if tableView.isEditing != isEditingMode {
            tableView.setEditing(isEditingMode, animated: false)
        }
        
        tableView.reloadData()
        
        emptyStateLabel.isHidden = !displayedActivities.isEmpty
        editButton.isHidden = displayedActivities.isEmpty
        
        updateAddActivityButtonPosition()
    }
    
    private func reloadCalendarDecorations() {
        let calendar = Calendar.current
        let visibleDateComponents = calendarView.visibleDateComponents
        
        guard let yearMonth = visibleDateComponents.month,
              let year = visibleDateComponents.year else {
            return
        }
        
        var allDaysInMonth: [DateComponents] = []
        if let date = calendar.date(from: visibleDateComponents),
           let range = calendar.range(of: .day, in: .month, for: date) {
            for day in range {
                let components = DateComponents(year: year, month: yearMonth, day: day)
                allDaysInMonth.append(components)
            }
        }
        
        calendarView.reloadDecorations(forDateComponents: allDaysInMonth, animated: true)
    }
}

// MARK: - Setup Methods
extension MCalendarViewController {
    
    private func applyTheme() {
        AppTheme.applyScreenBackground(to: view)
        tableView.superview?.backgroundColor = .clear
        monthLabel.textColor = .label
        emptyStateLabel.textColor = .secondaryLabel
        calendarView.backgroundColor = AppTheme.elevatedCardBackground
        calendarView.layer.borderWidth = 1
        calendarView.layer.borderColor = AppTheme.borderColor.resolvedColor(with: traitCollection).cgColor
        calendarView.tintColor = AppTheme.accent
        styleFloatingButton(editButton, mode: .text(isEditingMode ? "Done" : "Edit"))
        styleFloatingButton(addActivityButton, mode: .symbol("plus"))
        chevronButton?.tintColor = .label
    }

    private func setupCalendar() {
        calendarView.delegate = self
        calendarView.availableDateRange = DateInterval(start: Date(timeIntervalSince1970: 0),
                                                       end: .distantFuture)
        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
        selection.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        
        calendarView.clipsToBounds = true
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        calendarView.layoutMargins = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        calendarView.wantsDateDecorations = true
        calendarView.tintColor = AppTheme.accent
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelection = false
        emptyStateLabel.textColor = .secondaryLabel

        let nib = UINib(nibName: "MactivityTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "MactivityCell")
    }
    
    private func setupEditButton() {
        editButton.setTitle("Edit", for: .normal)
        editButton.setTitle("Done", for: .selected)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        editButton.isHidden = true
        styleFloatingButton(editButton, mode: .text("Edit"))
        
        updateAddActivityButtonPosition()
    }
    
    private enum FloatingButtonMode {
        case symbol(String)
        case text(String)
    }
    
    private func styleFloatingButton(_ button: UIButton?, mode: FloatingButtonMode) {
        guard let button else { return }
        let foreground = traitCollection.userInterfaceStyle == .dark ? UIColor.white : UIColor.black
        var config = UIButton.Configuration.plain()
        config.background.backgroundColor = .clear
        config.baseForegroundColor = foreground
        config.cornerStyle = .capsule
        switch mode {
        case .symbol(let name):
            config.image = UIImage(systemName: name)
        case .text(let title):
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
    
    @objc private func editButtonTapped() {
        toggleEditingMode()
    }
    
    private func toggleEditingMode() {
        isEditingMode.toggle()
        editButton.isSelected = isEditingMode
        tableView.setEditing(isEditingMode, animated: true)
        styleFloatingButton(editButton, mode: .text(isEditingMode ? "Done" : "Edit"))
    }
    
    private func setupChevronButton() {
        chevronButton = UIButton(type: .system)
        
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let chevronImage = UIImage(systemName: "chevron.up", withConfiguration: chevronConfig)
        chevronButton.setImage(chevronImage, for: .normal)
        chevronButton.tintColor = .label
        
        view.addSubview(chevronButton)
        chevronButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            chevronButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            chevronButton.leadingAnchor.constraint(equalTo: monthLabel.trailingAnchor, constant: 8),
            chevronButton.widthAnchor.constraint(equalToConstant: 30),
            chevronButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        chevronButton.addTarget(self, action: #selector(toggleCalendar), for: .touchUpInside)
    }
    
    private func setupMonthLabelTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleCalendar))
        monthLabel.isUserInteractionEnabled = true
        monthLabel.addGestureRecognizer(tapGesture)
        tapGesture.view?.tintColor = .black
    }
    
    @objc private func toggleCalendar() {
        isCalendarExpanded.toggle()
        
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let chevronImage = UIImage(systemName: isCalendarExpanded ? "chevron.up" : "chevron.down",
                                   withConfiguration: chevronConfig)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            self.monthLabel.isUserInteractionEnabled = false
            self.chevronButton.isUserInteractionEnabled = false
            
            self.chevronButton.setImage(chevronImage, for: .normal)
            
            self.calendarHeightConstraint.constant = self.isCalendarExpanded ? 420 : 0
            self.calendarView.alpha = self.isCalendarExpanded ? 1.0 : 0.0
            self.view.layoutIfNeeded()
            
        } completion: { _ in
            self.monthLabel.isUserInteractionEnabled = true
            self.chevronButton.isUserInteractionEnabled = true
            
            if self.isCalendarExpanded {
                self.calendarView.setNeedsLayout()
                self.calendarView.layoutIfNeeded()
            }
        }
    }
    
    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        monthLabel.text = formatter.string(from: currentDate)
    }
    
    private func updateAddActivityButtonPosition() {
        UIView.animate(withDuration: 0.3) {
            if self.editButton.isHidden {
                self.addActivityButton.transform = CGAffineTransform.identity
            } else {
                self.addActivityButton.transform = CGAffineTransform(translationX: -80, y: 0)
            }
        }
    }
}

// MARK: - Calendar Delegate Methods
extension MCalendarViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return }
        
        selectedDate = Calendar.current.startOfDay(for: date)
        
        // ALWAYS exit editing mode when switching dates
        if isEditingMode {
            isEditingMode = false
            editButton.isSelected = false
            tableView.setEditing(false, animated: false)
        }
        
        updateActivitiesList(for: selectedDate)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        currentDate = date
        monthLabel.text = formatter.string(from: date)
    }
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        if let dayActivities = activities[normalizedDate], !dayActivities.isEmpty {
            return .default(color: .systemBlue, size: .small)
        }
        
        return nil
    }
}

// MARK: - Table View Data Source & Delegate
extension MCalendarViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedActivities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MactivityCell", for: indexPath) as! MactivityTableViewCell
        
        let activity = displayedActivities[indexPath.row]
        cell.configure(with: activity.title, time: activity.time)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    // MARK: - Editing Support
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let activity = displayedActivities[indexPath.row]
            deleteActivityFromSupabase(activity, at: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}

// MARK: - AddActivityViewController Delegate
extension MCalendarViewController: AddActivityViewControllerDelegate {
    func didSaveActivity() {
        // Reload data from Supabase when a new activity is saved
        loadActivitiesFromSupabase()
    }
}
