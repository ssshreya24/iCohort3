//
//  SCalendarViewController.swift
//  iCohort3
//
//  Created by user@51 on 11/11/25.
//

import UIKit

class SCalendarViewController: UIViewController {

    // MARK: - Outlets (from Storyboard)
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var calendarView: UICalendarView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    @IBOutlet weak var calendarHeightConstraint: NSLayoutConstraint!
    
    // Add chevron button outlet (connect this in storyboard)
    private var chevronButton: UIButton!
    
    // MARK: - Properties
    private var currentDate = Date()
    private var selectedDate = Calendar.current.startOfDay(for: Date())
    
    private var activities: [Date: [Activity]] = [:]
    private var displayedActivities: [Activity] = []
    
    private var isCalendarExpanded = true

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
    
    func updateActivitiesList(for date: Date) {
        displayedActivities = activities[date] ?? []
        tableView.reloadData()
        
        emptyStateLabel.isHidden = !displayedActivities.isEmpty
    }
    
    private func reloadCalendarDecorations() {
        var dateComponents: [DateComponents] = []
        
        for date in activities.keys {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            dateComponents.append(components)
        }
        
        calendarView.reloadDecorations(forDateComponents: dateComponents, animated: true)
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
        
        let nib = UINib(nibName: "ActivityTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "ActivityCell")
    }
    
    // ✅ NEW: Setup chevron button programmatically
    private func setupChevronButton() {
        chevronButton = UIButton(type: .system)
        
        // Configure button appearance
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let chevronImage = UIImage(systemName: "chevron.up", withConfiguration: chevronConfig)
        chevronButton.setImage(chevronImage, for: .normal)
        chevronButton.tintColor = .label
        
        // Add to view
        view.addSubview(chevronButton)
        chevronButton.translatesAutoresizingMaskIntoConstraints = false
        
        // Position it next to the month label
        NSLayoutConstraint.activate([
            chevronButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            chevronButton.leadingAnchor.constraint(equalTo: monthLabel.trailingAnchor, constant: 8),
            chevronButton.widthAnchor.constraint(equalToConstant: 30),
            chevronButton.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Add tap action
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
        
        // ✅ Update chevron icon
        let chevronConfig = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let chevronImage = UIImage(systemName: isCalendarExpanded ? "chevron.up" : "chevron.down",
                                   withConfiguration: chevronConfig)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut) {
            // Disable interactions during animation
            self.monthLabel.isUserInteractionEnabled = false
            self.chevronButton.isUserInteractionEnabled = false
            
            // Rotate chevron
            self.chevronButton.setImage(chevronImage, for: .normal)
            
            // Animate height & opacity
            self.calendarHeightConstraint.constant = self.isCalendarExpanded ? 420 : 0
            self.calendarView.alpha = self.isCalendarExpanded ? 1.0 : 0.0
            self.view.layoutIfNeeded()
            
        } completion: { _ in
            // Re-enable interactions after animation
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

// MARK: - Sample Data
extension SCalendarViewController {
    
    private func setupSampleData() {
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        let dayAfter = Calendar.current.date(byAdding: .day, value: 2, to: today)!
        
        activities[today] = [
            Activity(title: "UI/UX Workshop", time: "10:00 AM"),
            Activity(title: "Team Sync-Up", time: "3:00 PM")
        ]
        
        activities[tomorrow] = [
            Activity(title: "Project Review", time: "11:30 AM"),
            Activity(title: "Client Meeting", time: "2:00 PM")
        ]
        
        activities[dayAfter] = [
            Activity(title: "Research Session", time: "5:00 PM")
        ]
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath) as! ActivityTableViewCell
        let activity = displayedActivities[indexPath.row]
        cell.configure(with: activity.title, time: activity.time)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}
