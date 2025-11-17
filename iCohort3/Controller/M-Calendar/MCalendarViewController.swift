//
//  MCalendarViewController.swift
//  iCohort3
//
//  Created by user@51 on 15/11/25.
//

import UIKit

class MCalendarViewController: UIViewController {

    // MARK: - Outlets (from Storyboard)
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
    
    private var activities: [Date: [Activity]] = [:]
    private var displayedActivities: [Activity] = []
    
    private var isCalendarExpanded = true
    private var isEditingMode = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCalendar()
        setupTableView()
        setupChevronButton()
        setupMonthLabelTapGesture()
        setupEditButton()
        updateMonthLabel()
        
        updateActivitiesList(for: selectedDate)
        
        emptyStateLabel.isHidden = false
        emptyStateLabel.text = "No mentor activities yet"
        
        calendarView.layer.cornerRadius = 20
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self else { return }

            self.setupSampleData()
            self.updateActivitiesList(for: self.selectedDate)

            self.reloadCalendarDecorations()

            UIView.transition(with: self.tableView,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: {
                                  self.tableView.reloadData()
                              },
                              completion: nil)
        }
    }
    
    
    @IBAction func addActivityButtonTapped(_ sender: Any) {
        let vc = AddActivityViewController(nibName: "AddActivityViewController", bundle: nil)
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
        
        // Hide edit button if no activities
        editButton.isHidden = displayedActivities.isEmpty
        
        // Update addActivityButton position when editButton visibility changes
        updateAddActivityButtonPosition()
    }
    
    private func reloadCalendarDecorations() {
        // Get the visible date range from the calendar
        let calendar = Calendar.current
        let visibleDateComponents = calendarView.visibleDateComponents
        
        guard let yearMonth = visibleDateComponents.month,
              let year = visibleDateComponents.year else {
            return
        }
        
        // Create date components for all days in the visible month
        var allDaysInMonth: [DateComponents] = []
        if let date = calendar.date(from: visibleDateComponents),
           let range = calendar.range(of: .day, in: .month, for: date) {
            for day in range {
                let components = DateComponents(year: year, month: yearMonth, day: day)
                allDaysInMonth.append(components)
            }
        }
        
        // Reload all visible dates to ensure decorations are updated correctly
        calendarView.reloadDecorations(forDateComponents: allDaysInMonth, animated: true)
    }
}

// MARK: - Setup Methods
extension MCalendarViewController {
    
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
        
        calendarView.tintColor = .black
    }
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelection = false

        let nib = UINib(nibName: "MactivityTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "MactivityCell")
    }
    
    private func setupEditButton() {
        editButton.setTitle("Edit", for: .normal)
        editButton.setTitle("Done", for: .selected)
        editButton.addTarget(self, action: #selector(editButtonTapped), for: .touchUpInside)
        editButton.isHidden = true // Hidden initially until activities are loaded
        
        // Update addActivityButton trailing constraint based on editButton visibility
        updateAddActivityButtonPosition()
    }
    
    @objc private func editButtonTapped() {
        toggleEditingMode()
    }
    
    private func toggleEditingMode() {
        isEditingMode.toggle()
        editButton.isSelected = isEditingMode
        tableView.setEditing(isEditingMode, animated: true)
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
        // Animate the position change smoothly
        UIView.animate(withDuration: 0.3) {
            if self.editButton.isHidden {
                // Move addActivityButton to the trailing edge when Edit button is hidden
                self.addActivityButton.transform = CGAffineTransform.identity
            } else {
                // Shift addActivityButton left to make space for Edit button
                // Adjust the value based on your layout (editButton width + spacing)
                self.addActivityButton.transform = CGAffineTransform(translationX: -80, y: 0)
            }
        }
    }
}

// MARK: - Mentor Sample Data
extension MCalendarViewController {
    
    private func setupSampleData() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let dayAfter = Calendar.current.date(byAdding: .day, value: 2, to: today)!
        
        activities[today] = [
            Activity(title: "Review Student Reports", time: "9:00 AM"),
            Activity(title: "Mentor Sync Meeting", time: "2:00 PM")
        ]
        
        activities[tomorrow] = [
            Activity(title: "1:1 Session with Student A", time: "11:00 AM"),
            Activity(title: "Team Guidance Session", time: "4:30 PM")
        ]
        
        activities[dayAfter] = [
            Activity(title: "Weekly Planning", time: "6:00 PM")
        ]
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
            // Remove from displayed activities
            displayedActivities.remove(at: indexPath.row)
            
            // Update the activities dictionary
            if displayedActivities.isEmpty {
                activities.removeValue(forKey: selectedDate)
                
                // Exit editing mode automatically when no activities remain
                // IMPORTANT: Must call setEditing BEFORE any UI updates
                tableView.setEditing(false, animated: true)
                isEditingMode = false
                editButton.isSelected = false
            } else {
                activities[selectedDate] = displayedActivities
            }
            
            // Delete the row with animation
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // Reload calendar decorations BEFORE updating activities list
            // This ensures the dot is removed from the calendar
            reloadCalendarDecorations()
            
            // Update UI (this will hide edit button if no activities remain)
            updateActivitiesList(for: selectedDate)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return .delete
    }
}
