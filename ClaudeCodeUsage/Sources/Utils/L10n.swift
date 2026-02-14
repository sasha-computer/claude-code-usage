import Foundation

enum L10n {
    
    // MARK: - Error Messages
    
    static let errorNotLoggedIn = "Not logged in -- run claude login"
    static let errorTokenExpired = "Token expired -- run claude login to re-authenticate"
    static let errorConnectionFailed = "API connection failed -- check your network"
    static let errorParseFailed = "Failed to parse API response"
    
    // MARK: - UI Labels
    
    static let headerTitle = "Claude Code"
    static let fiveHourLabel = "5-Hour"
    static let weeklyLabel = "Weekly"
    static let resetsPrefix = "Resets"
    static let quit = "Quit"
    
    // MARK: - Time Formatting
    
    static let now = "now"
    static let justNow = "just now"
    
    static func timeAgo(_ value: String) -> String {
        "\(value) ago"
    }
    
    static func resetsIn(_ time: String) -> String {
        "\(resetsPrefix) in \(time)"
    }
    
    // MARK: - Settings
    
    static let settingsTitle = "Claude Code Usage Settings"
    static let settingsCurrentUsage = "Current Usage"
    static let settingsFiveHourUsage = "5-Hour Usage"
    static let settingsWeeklyUsage = "Weekly Usage"
    static let settingsFiveHourResets = "5-Hour Resets At"
    static let settingsWeeklyResets = "Weekly Resets At"
    static let settingsUpdates = "Updates"
    static let settingsCheckAutomatically = "Check for updates automatically"
    static let settingsCheckNow = "Check Now"
    static let settingsLastChecked = "Last Checked"
    static let settingsVersion = "Version"
    static let settingsInfo = "Info"
    static let settingsDataSource = "Data Source"
    static let settingsRefreshInterval = "Refresh Interval"
    static let settingsAuth = "Auth"
    
    static func settingsUpToDate(_ version: String) -> String {
        "Up to date (v\(version))"
    }
}
