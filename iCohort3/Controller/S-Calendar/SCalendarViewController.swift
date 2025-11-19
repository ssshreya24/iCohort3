//
//  SCalendarViewController.swift
//  iCohort3
//
//  Created by user@51 on 11/11/25.
//

import UIKit

class SCalendarViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var calendarView: UICalendarView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    private var chevronButton: UIButton!
    
    // MARK: - Properties
    private var currentDate = Date()
    private var selectedDate = Calendar.current.startOfDay(for: Date())
    
    private var activities: [Date: [Mactivity]] = [:]
    private var displayedActivities: [Mactivity] = []
    
    private var isCalendarExpanded = true
    private var isLoading = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCalendar()
        setupTableView()
        setupChevronButton()
        setupMonthLabelTapGesture()
        updateMonthLabel()
        
        updateActivitiesList(for: selectedDate)
        
        emptyStateLabel.isHidden = false
        emptyStateLabel.text = "No activities yet"
        
        calendarView.layer.cornerRadius = 20
        
        // Load activities from Supabase
        loadActivitiesFromSupabase()
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
                
                // Filter activities that are sent to students
                // Only show activities where send_to is "everyone" or "All Students"
                let studentActivities = rows.filter { row in
                    guard let sendTo = row.send_to?.lowercased() else { return false }
                    return sendTo.contains("everyone") || sendTo.contains("all students")
                }
                
                // Convert rows to Mactivity and group by date
                var newActivities: [Date: [Mactivity]] = [:]
                
                for row in studentActivities {
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
    
    private func showError(_ message: String) {
        let alert = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    func updateActivitiesList(for date: Date) {
        displayedActivities = activities[date] ?? []
        tableView.reloadData()
        
        emptyStateLabel.isHidden = !displayedActivities.isEmpty
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
extension SCalendarViewController {
    
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
        
        // Use MactivityTableViewCell instead of ActivityTableViewCell
        let nib = UINib(nibName: "MactivityTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "MactivityCell")
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
}

// MARK: - Calendar Delegate Methods
extension SCalendarViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return }
        
        selectedDate = Calendar.current.startOfDay(for: date)
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
extension SCalendarViewController: UITableViewDataSource, UITableViewDelegate {
    
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
}
