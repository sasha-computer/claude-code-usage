import Foundation

enum Formatters {
    
    static func percentage(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }
    
    static func timeRemaining(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "now" }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    static func resetDescription(_ resetsAt: Date) -> String {
        let remaining = resetsAt.timeIntervalSince(Date())
        guard remaining > 0 else { return "now" }
        
        if remaining < 24 * 3600 {
            return "in \(timeRemaining(remaining))"
        }
        
        let f = DateFormatter()
        f.dateFormat = "MMM d a h:mm"
        f.amSymbol = "AM"
        f.pmSymbol = "PM"
        return f.string(from: resetsAt)
    }
    
    static func relativeTime(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 10 { return "just now" }
        if seconds < 60 { return "\(Int(seconds))s ago" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        return "\(Int(seconds / 3600))h ago"
    }
    
    static func fullTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
