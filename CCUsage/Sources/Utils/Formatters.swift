import Foundation

enum Formatters {
    
    static func percentage(_ value: Double) -> String {
        String(format: "%.1f%%", value)
    }
    
    static func timeRemaining(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return L10n.now }
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
    
    static func resetDescription(_ resetsAt: Date) -> String {
        let remaining = resetsAt.timeIntervalSince(Date())
        guard remaining > 0 else { return L10n.now }
        
        if remaining < 24 * 3600 {
            return L10n.resetsIn(timeRemaining(remaining))
        }
        
        let f = DateFormatter()
        f.dateFormat = "MMM d a h:mm"
        f.amSymbol = "AM"
        f.pmSymbol = "PM"
        return "\(L10n.resetsPrefix) \(f.string(from: resetsAt))"
    }
    
    static func relativeTime(_ date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 10 { return L10n.justNow }
        if seconds < 60 { return L10n.timeAgo("\(Int(seconds))s") }
        if seconds < 3600 { return L10n.timeAgo("\(Int(seconds / 60))m") }
        return L10n.timeAgo("\(Int(seconds / 3600))h")
    }
    
    static func fullTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
