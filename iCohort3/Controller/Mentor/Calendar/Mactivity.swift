import Foundation

struct Mactivity {
    let id: Int?  // nil for local-only activities
    let title: String
    let time: String?
    let note: String?
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let alertOption: String?
    let sendTo: String?
    
    // Convenience initializer for display
    init(
        id: Int? = nil,
        title: String,
        time: String? = nil,
        note: String? = nil,
        startDate: Date = Date(),
        endDate: Date = Date(),
        isAllDay: Bool = false,
        alertOption: String? = nil,
        sendTo: String? = nil
    ) {
        self.id = id
        self.title = title
        self.time = time
        self.note = note
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.alertOption = alertOption
        self.sendTo = sendTo
    }
    
    // Convert from Supabase row
    static func from(_ row: SupabaseManager.MentorActivityRow) -> Mactivity {
        let formatter = ISO8601DateFormatter()
        let startDate = formatter.date(from: row.start_date) ?? Date()
        let endDate = formatter.date(from: row.end_date) ?? Date()
        
        // Format time string for display
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = row.is_all_day ? "MMM d" : "h:mm a"
        let timeString = timeFormatter.string(from: startDate)
        
        return Mactivity(
            id: row.id,
            title: row.title,
            time: timeString,
            note: row.note,
            startDate: startDate,
            endDate: endDate,
            isAllDay: row.is_all_day,
            alertOption: row.alert_option,
            sendTo: row.send_to
        )
    }
}
