import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @EnvironmentObject var accountStore: AccountStore
    @ObservedObject var updateChecker = UpdateChecker.shared
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection
            if updateChecker.updateAvailable {
                Divider().padding(.horizontal, 16)
                updateBanner
            }
            Divider().padding(.horizontal, 16)
            usageSection
            Divider().padding(.horizontal, 16)
            footerSection
        }
        .frame(width: 280)
        .padding(.vertical, 8)
    }
    
    private var updateBanner: some View {
        Button(action: { updateChecker.openDownload() }) {
            HStack(spacing: 8) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(.blue)
                            .frame(width: 18, height: 18)
                    )
                
                VStack(alignment: .leading, spacing: 1) {
                    Text("Update Available")
                        .font(.system(size: 11, weight: .semibold))
                    if let version = updateChecker.latestVersion {
                        Text("v\(version)")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
    
    private var headerSection: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(L10n.headerTitle)
                    .font(.system(size: 13, weight: .semibold))
                Text("v\(UpdateChecker.shared.currentVersion)")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            if monitor.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            } else if let last = monitor.lastRefresh {
                Text(Formatters.fullTime(last))
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var usageSection: some View {
        VStack(spacing: 16) {
            UsageRow(
                label: L10n.fiveHourLabel,
                percent: monitor.fiveHourPercent,
                resetsAt: monitor.fiveHourResetsAt,
                timeRemaining: monitor.fiveHourTimeRemaining,
                status: monitor.fiveHourStatus
            )
            
            UsageRow(
                label: L10n.weeklyLabel,
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
        .padding(.vertical, 8)
    }
    
    private var footerSection: some View {
        HStack(spacing: 8) {
            Button(action: {
                Task { await monitor.refresh() }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11))
                    Text("Refresh")
                        .font(.system(size: 11))
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            
            Spacer()
            
            if accountStore.isEnabled && accountStore.accounts.count > 1 {
                accountSwitcher
                Spacer()
            }
            
            Button(action: { NSApplication.shared.terminate(nil) }) {
                Text(L10n.quit)
                    .font(.system(size: 11))
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
    
    private var accountSwitcher: some View {
        let binding = Binding<String>(
            get: { accountStore.activeLabel ?? accountStore.accounts.first?.label ?? "" },
            set: { accountStore.setActive($0) }
        )
        return Picker("Account", selection: binding) {
            ForEach(accountStore.accounts) { account in
                Text(String(account.label.prefix(1)).uppercased())
                    .tag(account.label)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        .fixedSize()
    }
}

struct UsageRow: View {
    let label: String
    let percent: Double
    let resetsAt: Date?
    let timeRemaining: TimeInterval?
    let status: UsageStatus
    
    var body: some View {
        VStack(spacing: 4) {
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
                    Text(Formatters.resetDescription(resetDate))
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }
}
