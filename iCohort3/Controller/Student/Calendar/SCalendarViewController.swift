//
//  SCalendarViewController.swift
//  iCohort3
//
//  Created by user@51 on 11/11/25.
//

import UIKit

class SCalendarViewController: UIViewController {

    @IBOutlet weak var scrollingCalendarView: UICollectionView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var emptyStateLabel: UILabel!
    
    private var calendarButton: UIButton!
    
    // MARK: - Properties
    private var currentDate = Date()
    private var selectedDate = Calendar.current.startOfDay(for: Date())
    
    private var activities: [Date: [Mactivity]] = [:]
    private var displayedActivities: [Mactivity] = []
    
    private var isLoading = false
    
    // Scrolling Calendar Properties
    private var scrollingDates: [Date] = []
    private var selectedIndexPath: IndexPath?

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        AppTheme.applyScreenBackground(to: view)
        view.subviews.forEach { subview in
            if subview !== scrollingCalendarView && subview !== monthLabel && subview !== tableView && subview !== emptyStateLabel {
                subview.backgroundColor = .clear
            }
        }
        
        setupScrollingCalendar()
        setupTableView()
        setupCalendarButton()
        setupMonthLabelTapGesture()
        updateMonthLabel()
        
        generateScrollingDates()
        scrollToToday(animated: false)
        
        updateActivitiesList(for: selectedDate)
        
        emptyStateLabel.isHidden = false
        emptyStateLabel.text = "No activities today"
        
        // Load activities from Supabase
        loadActivitiesFromSupabase()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        AppTheme.applyScreenBackground(to: view)
        tableView.superview?.backgroundColor = .clear
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadActivitiesFromSupabase()
    }
    
    // MARK: - Scrolling Calendar Setup
    
    private func setupScrollingCalendar() {
        scrollingCalendarView.delegate = self
        scrollingCalendarView.dataSource = self
        scrollingCalendarView.showsHorizontalScrollIndicator = false
        scrollingCalendarView.backgroundColor = .clear
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        scrollingCalendarView.collectionViewLayout = layout
        
        // Register cell
        scrollingCalendarView.register(DateScrollCell.self, forCellWithReuseIdentifier: "datesScroll")
    }
    
    private func generateScrollingDates() {
        let calendar = Calendar.current
        scrollingDates.removeAll()
        
        // Generate dates from 30 days ago to 30 days in future
        for dayOffset in -30...30 {
            if let date = calendar.date(byAdding: .day, value: dayOffset, to: Date()) {
                scrollingDates.append(calendar.startOfDay(for: date))
            }
        }
    }
    
    private func generateScrollingDatesAround(date: Date) {
        let calendar = Calendar.current
        scrollingDates.removeAll()
        
        // Generate dates from 30 days before to 30 days after the selected date
        for dayOffset in -30...30 {
            if let newDate = calendar.date(byAdding: .day, value: dayOffset, to: date) {
                scrollingDates.append(calendar.startOfDay(for: newDate))
            }
        }
    }
    
    private func scrollToToday(animated: Bool) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let index = scrollingDates.firstIndex(of: today) {
            let indexPath = IndexPath(item: index, section: 0)
            selectedIndexPath = indexPath
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.scrollingCalendarView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: animated)
                self.scrollingCalendarView.reloadData()
            }
        }
    }
    
    // MARK: - Supabase Data Loading
    
    private func loadActivitiesFromSupabase() {
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            do {
                let rows = try await SupabaseManager.shared.fetchAllMentorActivities()
                
                let studentActivities = rows.filter { row in
                    guard let sendTo = row.send_to?.lowercased() else { return false }
                    return sendTo.contains("everyone") || sendTo.contains("all students")
                }
                
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
                
                await MainActor.run {
                    self.activities = newActivities
                    self.updateActivitiesList(for: self.selectedDate)
                    self.scrollingCalendarView.reloadData()
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
        
        if displayedActivities.isEmpty {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            let dateString = formatter.string(from: date)
            
            let calendar = Calendar.current
            if calendar.isDateInToday(date) {
                emptyStateLabel.text = "No activities today"
            } else {
                emptyStateLabel.text = "No activities on \(dateString)"
            }
        }
    }
}

// MARK: - Setup Methods
extension SCalendarViewController {
    
    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.backgroundView = {
            let bg = UIView()
            bg.backgroundColor = .clear
            return bg
        }()
        tableView.showsVerticalScrollIndicator = false
        tableView.allowsSelection = false
        monthLabel.textColor = .label
        emptyStateLabel.textColor = .secondaryLabel
        
        let nib = UINib(nibName: "MactivityTableViewCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "MactivityCell")
    }
    
    private func setupCalendarButton() {
        calendarButton = UIButton(type: .system)
        
        let calendarConfig = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let calendarImage = UIImage(systemName: "calendar", withConfiguration: calendarConfig)
        calendarButton.setImage(calendarImage, for: .normal)
        calendarButton.tintColor = .label
        
        view.addSubview(calendarButton)
        calendarButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            calendarButton.centerYAnchor.constraint(equalTo: monthLabel.centerYAnchor),
            calendarButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            calendarButton.widthAnchor.constraint(equalToConstant: 40),
            calendarButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        calendarButton.addTarget(self, action: #selector(showCalendarPicker), for: .touchUpInside)
    }
    
    private func setupMonthLabelTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showCalendarPicker))
        monthLabel.isUserInteractionEnabled = true
        monthLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc private func showCalendarPicker() {
        let calendarVC = CalendarPickerViewController()
        calendarVC.selectedDate = selectedDate
        calendarVC.activities = activities
        calendarVC.modalPresentationStyle = .popover
        
        if let popover = calendarVC.popoverPresentationController {
            popover.sourceView = calendarButton
            popover.sourceRect = calendarButton.bounds
            popover.permittedArrowDirections = .up
            popover.delegate = self
        }
        
        calendarVC.preferredContentSize = CGSize(width: 350, height: 450)
        
        calendarVC.onDateSelected = { [weak self] date in
            guard let self = self else { return }
            self.selectedDate = date
            self.currentDate = date
            self.updateMonthLabel()
            self.updateActivitiesList(for: date)
            
            // Update scrolling calendar
            if let index = self.scrollingDates.firstIndex(of: date) {
                let indexPath = IndexPath(item: index, section: 0)
                let previousIndexPath = self.selectedIndexPath
                self.selectedIndexPath = indexPath
                
                var indexPathsToReload = [indexPath]
                if let previous = previousIndexPath {
                    indexPathsToReload.append(previous)
                }
                self.scrollingCalendarView.reloadItems(at: indexPathsToReload)
                self.scrollingCalendarView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            } else {
                // If selected date is outside the current range, regenerate dates around it
                self.generateScrollingDatesAround(date: date)
                self.scrollingCalendarView.reloadData()
                
                if let index = self.scrollingDates.firstIndex(of: date) {
                    let indexPath = IndexPath(item: index, section: 0)
                    self.selectedIndexPath = indexPath
                    self.scrollingCalendarView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                }
            }
        }
        
        present(calendarVC, animated: true)
    }
    
    private func updateMonthLabel() {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        monthLabel.text = formatter.string(from: currentDate)
    }
}

// MARK: - Popover Delegate
extension SCalendarViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none // Force popover on iPhone
    }
}

// MARK: - Collection View Data Source & Delegate
extension SCalendarViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return scrollingDates.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "datesScroll", for: indexPath) as! DateScrollCell
        
        let date = scrollingDates[indexPath.item]
        let isSelected = indexPath == selectedIndexPath
        let hasActivity = activities[date] != nil && !activities[date]!.isEmpty
        
        cell.configure(with: date, isSelected: isSelected, hasActivity: hasActivity)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 70)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let previousIndexPath = selectedIndexPath
        selectedIndexPath = indexPath
        
        let date = scrollingDates[indexPath.item]
        selectedDate = date
        currentDate = date
        
        // Update month label
        updateMonthLabel()
        
        // Update activities list
        updateActivitiesList(for: selectedDate)
        
        // Reload cells
        var indexPathsToReload = [indexPath]
        if let previous = previousIndexPath {
            indexPathsToReload.append(previous)
        }
        collectionView.reloadItems(at: indexPathsToReload)
        
        // Scroll to center
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
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

// MARK: - DateScrollCell
class DateScrollCell: UICollectionViewCell {
    
    private let dayLabel = UILabel()
    private let dateLabel = UILabel()
    private let activityDot = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        contentView.backgroundColor = .clear
        contentView.layer.cornerRadius = 12
        contentView.clipsToBounds = true
        
        dayLabel.font = .systemFont(ofSize: 12, weight: .medium)
        dayLabel.textAlignment = .center
        dayLabel.textColor = .secondaryLabel
        
        dateLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        dateLabel.textAlignment = .center
        dateLabel.textColor = .label
        
        activityDot.backgroundColor = .black
        activityDot.layer.cornerRadius = 3
        activityDot.isHidden = true
        
        contentView.addSubview(dayLabel)
        contentView.addSubview(dateLabel)
        contentView.addSubview(activityDot)
        
        dayLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        activityDot.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            dayLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            dayLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            dayLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            dateLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: 2),
            dateLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            dateLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            
            activityDot.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            activityDot.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            activityDot.widthAnchor.constraint(equalToConstant: 6),
            activityDot.heightAnchor.constraint(equalToConstant: 6)
        ])
    }
    
    func configure(with date: Date, isSelected: Bool, hasActivity: Bool) {
        let calendar = Calendar.current
        
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        dayLabel.text = dayFormatter.string(from: date).uppercased()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        dateLabel.text = dateFormatter.string(from: date)
        
        activityDot.isHidden = !hasActivity
        
        if isSelected {
            contentView.backgroundColor = AppTheme.accent
            dayLabel.textColor = .white
            dateLabel.textColor = .white
            activityDot.backgroundColor = .white
        } else if calendar.isDateInToday(date) {
            contentView.backgroundColor = UIColor.systemFill
            dayLabel.textColor = .label
            dateLabel.textColor = .label
            activityDot.backgroundColor = AppTheme.accent
        } else {
            contentView.backgroundColor = UIColor.clear
            dayLabel.textColor = .secondaryLabel
            dateLabel.textColor = .label
            activityDot.backgroundColor = AppTheme.accent
        }
    }
}

// MARK: - Calendar Picker View Controller
class CalendarPickerViewController: UIViewController {
    
    private var calendarView: UICalendarView!
    var selectedDate = Date()
    var activities: [Date: [Mactivity]] = [:]
    var onDateSelected: ((Date) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        
        setupCalendarView()
    }
    
    private func setupCalendarView() {
        calendarView = UICalendarView()
        calendarView.delegate = self
        calendarView.translatesAutoresizingMaskIntoConstraints = false
        
        calendarView.availableDateRange = DateInterval(start: Date(timeIntervalSince1970: 0),
                                                       end: .distantFuture)
        
        let selection = UICalendarSelectionSingleDate(delegate: self)
        calendarView.selectionBehavior = selection
        selection.selectedDate = Calendar.current.dateComponents([.year, .month, .day], from: selectedDate)
        
        calendarView.wantsDateDecorations = true
        calendarView.tintColor = AppTheme.accent
        
        view.addSubview(calendarView)
        
        NSLayoutConstraint.activate([
            calendarView.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            calendarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            calendarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            calendarView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -10)
        ])
        
        // Scroll to selected month
        let components = Calendar.current.dateComponents([.year, .month], from: selectedDate)
        calendarView.setVisibleDateComponents(components, animated: false)
    }
}

// MARK: - Calendar Picker Delegate
extension CalendarPickerViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return }
        
        let normalizedDate = Calendar.current.startOfDay(for: date)
        onDateSelected?(normalizedDate)
        
        dismiss(animated: true)
    }
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        let normalizedDate = Calendar.current.startOfDay(for: date)
        
        if let dayActivities = activities[normalizedDate], !dayActivities.isEmpty {
            return .default(color: AppTheme.accent, size: .small)
        }
        
        return nil
    }
}
