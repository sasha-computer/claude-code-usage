import Foundation
import Combine
import SwiftUI

@MainActor
final class UsageMonitor: ObservableObject {
    
    @Published var fiveHourPercent: Double = 0
    @Published var weeklyPercent: Double = 0
    @Published var fiveHourResetsAt: Date?
    @Published var weeklyResetsAt: Date?
    @Published var isLoading = false
    @Published var lastRefresh: Date?
    @Published var hasError = false
    
    private let api = ClaudeUsageAPI()
    private var timer: Timer?
    
    var fiveHourTimeRemaining: TimeInterval? {
        guard let reset = fiveHourResetsAt else { return nil }
        let remaining = reset.timeIntervalSince(Date())
        return remaining > 0 ? remaining : 0
    }
    
    var weeklyTimeRemaining: TimeInterval? {
        guard let reset = weeklyResetsAt else { return nil }
        let remaining = reset.timeIntervalSince(Date())
        return remaining > 0 ? remaining : 0
    }
    
    var fiveHourStatus: UsageStatus {
        UsageStatus.from(percent: fiveHourPercent)
    }
    
    var weeklyStatus: UsageStatus {
        UsageStatus.from(percent: weeklyPercent)
    }
    
    init() {
        Task { await refresh() }
        startAutoRefresh()
    }
    
    func refresh() async {
        isLoading = true
        
        if let limits = await api.fetchUsage() {
            fiveHourPercent = limits.fiveHourPercent
            weeklyPercent = limits.weeklyPercent
            fiveHourResetsAt = limits.fiveHourResetsAt
            weeklyResetsAt = limits.weeklyResetsAt
            hasError = false
        } else {
            hasError = true
        }
        
        lastRefresh = Date()
        isLoading = false
    }
    
    func startAutoRefresh() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.refresh()
            }
        }
    }
}

enum UsageStatus {
    case normal
    case warning
    case critical
    
    static func from(percent: Double) -> UsageStatus {
        if percent >= 90 { return .critical }
        if percent >= 70 { return .warning }
        return .normal
    }
    
    var color: Color {
        switch self {
        case .normal: return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }
    
    var iconName: String {
        switch self {
        case .normal: return "gauge.medium"
        case .warning: return "gauge.high"
        case .critical: return "exclamationmark.triangle.fill"
        }
    }
}
