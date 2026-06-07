import Foundation

/// Relative list timestamps matching canonical mock treatment (uppercase applied in view).
enum ConversationTimestampFormatter {
    private static let calendar = Calendar.current

    static func string(for date: Date, relativeTo now: Date = .now) -> String {
        if calendar.isDateInToday(date) {
            let minutes = max(1, Int(now.timeIntervalSince(date) / 60))
            if minutes < 60 {
                return "\(minutes) min ago"
            }
            return "Today"
        }

        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }

        let dayDelta = calendar.dateComponents([.day], from: calendar.startOfDay(for: date), to: calendar.startOfDay(for: now)).day ?? 0
        if dayDelta < 7 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = "EEE"
            return formatter.string(from: date)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.setLocalizedDateFormatFromTemplate("MMM d")
        return formatter.string(from: date)
    }
}
