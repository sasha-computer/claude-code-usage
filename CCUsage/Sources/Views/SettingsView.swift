import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: UsageMonitor
    
    var body: some View {
        Form {
            Section(L10n.settingsCurrentUsage) {
                LabeledContent(L10n.settingsFiveHourUsage, value: Formatters.percentage(monitor.fiveHourPercent))
                LabeledContent(L10n.settingsWeeklyUsage, value: Formatters.percentage(monitor.weeklyPercent))
                
                if let reset = monitor.fiveHourResetsAt {
                    LabeledContent(L10n.settingsFiveHourResets, value: Formatters.fullTime(reset))
                }
                if let reset = monitor.weeklyResetsAt {
                    LabeledContent(L10n.settingsWeeklyResets, value: Formatters.fullTime(reset))
                }
            }
            
            Section(L10n.settingsInfo) {
                LabeledContent(L10n.settingsDataSource, value: "Anthropic OAuth API")
                LabeledContent(L10n.settingsRefreshInterval, value: "30s")
                LabeledContent(L10n.settingsAuth, value: "macOS Keychain")
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 300)
        .navigationTitle(L10n.settingsTitle)
    }
}
