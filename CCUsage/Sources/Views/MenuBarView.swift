import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var monitor: UsageMonitor
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider().padding(.horizontal, 12)
            usageSection
            Divider().padding(.horizontal, 12)
            footerSection
        }
        .frame(width: 280)
        .padding(.vertical, 8)
    }
    
    private var headerSection: some View {
        HStack {
            Text("Claude Code")
                .font(.system(size: 13, weight: .semibold))
            
            Spacer()
            
            if monitor.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            } else if let last = monitor.lastRefresh {
                Text(Formatters.relativeTime(last))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var usageSection: some View {
        VStack(spacing: 14) {
            UsageRow(
                label: "5-Hour",
                percent: monitor.fiveHourPercent,
                resetsAt: monitor.fiveHourResetsAt,
                timeRemaining: monitor.fiveHourTimeRemaining,
                status: monitor.fiveHourStatus
            )
            
            UsageRow(
                label: "Weekly",
                percent: monitor.weeklyPercent,
                resetsAt: monitor.weeklyResetsAt,
                timeRemaining: monitor.weeklyTimeRemaining,
                status: monitor.weeklyStatus
            )
            
            if let error = monitor.error {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 10))
                    Text(error.localizedMessage)
                        .font(.system(size: 10))
                }
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private var footerSection: some View {
        HStack {
            Button(action: {
                Task { await monitor.refresh() }
            }) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text("Quit")
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct UsageRow: View {
    let label: String
    let percent: Double
    let resetsAt: Date?
    let timeRemaining: TimeInterval?
    let status: UsageStatus
    
    var body: some View {
        VStack(spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 11, weight: .medium))
                
                Spacer()
                
                Text(Formatters.percentage(percent))
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(status.color)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.quaternary)
                        .frame(height: 6)
                    
                    Capsule()
                        .fill(status.color)
                        .frame(width: max(0, geo.size.width * percent / 100), height: 6)
                        .animation(.easeInOut(duration: 0.4), value: percent)
                }
            }
            .frame(height: 6)
            
            if let resetDate = resetsAt {
                HStack {
                    Spacer()
                    Text("Resets \(Formatters.resetDescription(resetDate))")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
