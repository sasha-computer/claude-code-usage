import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: UsageMonitor
    
    var body: some View {
        Form {
            Section("Current Usage") {
                LabeledContent("5-Hour Usage", value: Formatters.percentage(monitor.fiveHourPercent))
                LabeledContent("Weekly Usage", value: Formatters.percentage(monitor.weeklyPercent))
                
                if let reset = monitor.fiveHourResetsAt {
                    LabeledContent("5-Hour Resets At", value: Formatters.fullTime(reset))
                }
                if let reset = monitor.weeklyResetsAt {
                    LabeledContent("Weekly Resets At", value: Formatters.fullTime(reset))
                }
            }
            
            Section("Info") {
                LabeledContent("Data Source", value: "Anthropic OAuth API")
                LabeledContent("Refresh Interval", value: "30s")
                LabeledContent("Auth", value: "macOS Keychain")
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 300)
        .navigationTitle("CCUsage Settings")
    }
}
