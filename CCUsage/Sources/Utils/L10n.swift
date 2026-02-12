import Foundation

enum Language: String, CaseIterable {
    case ko = "ko"
    case en = "en"
    
    var label: String {
        switch self {
        case .ko: return "KO"
        case .en: return "EN"
        }
    }
    
    /// Returns the next language in the cycle
    var next: Language {
        switch self {
        case .ko: return .en
        case .en: return .ko
        }
    }
}

enum L10n {
    
    // MARK: - Current Language
    
    private static let languageKey = "appLanguage"
    
    static var current: Language {
        get {
            if let raw = UserDefaults.standard.string(forKey: languageKey),
               let lang = Language(rawValue: raw) {
                return lang
            }
            // Default to system language, fallback to English
            let preferred = Locale.preferredLanguages.first ?? "en"
            return preferred.hasPrefix("ko") ? .ko : .en
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: languageKey)
        }
    }
    
    // MARK: - Error Messages
    
    static var errorNotLoggedIn: String {
        switch current {
        case .ko: return "Claude Code에 로그인하세요 (claude login)"
        case .en: return "Not logged in — run claude login"
        }
    }
    
    static var errorTokenExpired: String {
        switch current {
        case .ko: return "인증 만료 — claude login으로 재로그인하세요"
        case .en: return "Token expired — run claude login to re-authenticate"
        }
    }
    
    static var errorConnectionFailed: String {
        switch current {
        case .ko: return "API 연결 실패 — 네트워크를 확인하세요"
        case .en: return "API connection failed — check your network"
        }
    }
    
    static var errorParseFailed: String {
        switch current {
        case .ko: return "API 응답을 처리할 수 없습니다"
        case .en: return "Failed to parse API response"
        }
    }
    
    // MARK: - UI Labels
    
    static var headerTitle: String {
        switch current {
        case .ko: return "Claude Code"
        case .en: return "Claude Code"
        }
    }
    
    static var fiveHourLabel: String {
        switch current {
        case .ko: return "5시간"
        case .en: return "5-Hour"
        }
    }
    
    static var weeklyLabel: String {
        switch current {
        case .ko: return "주간"
        case .en: return "Weekly"
        }
    }
    
    static var resetsPrefix: String {
        switch current {
        case .ko: return "초기화"
        case .en: return "Resets"
        }
    }
    
    static var quit: String {
        switch current {
        case .ko: return "종료"
        case .en: return "Quit"
        }
    }
    
    // MARK: - Time Formatting
    
    static var now: String {
        switch current {
        case .ko: return "지금"
        case .en: return "now"
        }
    }
    
    static func timeAgo(_ value: String) -> String {
        switch current {
        case .ko: return "\(value) 전"
        case .en: return "\(value) ago"
        }
    }
    
    static var justNow: String {
        switch current {
        case .ko: return "방금"
        case .en: return "just now"
        }
    }
    
    static func resetsIn(_ time: String) -> String {
        switch current {
        case .ko: return "\(resetsPrefix) \(time) 후"
        case .en: return "\(resetsPrefix) in \(time)"
        }
    }
    
    // MARK: - Settings
    
    static var settingsTitle: String {
        switch current {
        case .ko: return "CCUsage 설정"
        case .en: return "CCUsage Settings"
        }
    }
    
    static var settingsCurrentUsage: String {
        switch current {
        case .ko: return "현재 사용량"
        case .en: return "Current Usage"
        }
    }
    
    static var settingsFiveHourUsage: String {
        switch current {
        case .ko: return "5시간 사용량"
        case .en: return "5-Hour Usage"
        }
    }
    
    static var settingsWeeklyUsage: String {
        switch current {
        case .ko: return "주간 사용량"
        case .en: return "Weekly Usage"
        }
    }
    
    static var settingsFiveHourResets: String {
        switch current {
        case .ko: return "5시간 초기화"
        case .en: return "5-Hour Resets At"
        }
    }
    
    static var settingsWeeklyResets: String {
        switch current {
        case .ko: return "주간 초기화"
        case .en: return "Weekly Resets At"
        }
    }
    
    static var settingsInfo: String {
        switch current {
        case .ko: return "정보"
        case .en: return "Info"
        }
    }
    
    static var settingsDataSource: String {
        switch current {
        case .ko: return "데이터 소스"
        case .en: return "Data Source"
        }
    }
    
    static var settingsRefreshInterval: String {
        switch current {
        case .ko: return "갱신 주기"
        case .en: return "Refresh Interval"
        }
    }
    
    static var settingsAuth: String {
        switch current {
        case .ko: return "인증"
        case .en: return "Auth"
        }
    }
}
