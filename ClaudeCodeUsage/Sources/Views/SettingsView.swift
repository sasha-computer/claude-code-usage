import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @ObservedObject var updateChecker = UpdateChecker.shared
    @State private var checkAutomatically: Bool = UpdateChecker.shared.checkAutomatically
    
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
            
            Section(L10n.settingsUpdates) {
                Toggle(L10n.settingsCheckAutomatically, isOn: $checkAutomatically)
                    .onChange(of: checkAutomatically) { _, newValue in
                        updateChecker.checkAutomatically = newValue
                    }
                
                HStack {
                    if updateChecker.isChecking {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 16, height: 16)
                        Text("Checking...")
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    } else if updateChecker.updateAvailable, let version = updateChecker.latestVersion {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Version \(version) available")
                            .font(.system(size: 12))
                    } else {
                        Text(L10n.settingsUpToDate(updateChecker.currentVersion))
                            .font(.system(size: 12))
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(L10n.settingsCheckNow) {
                        Task { await checkNow() }
                    }
                    .disabled(updateChecker.isChecking)
                }
                
                if let lastCheck = updateChecker.lastCheckDate {
                    LabeledContent(L10n.settingsLastChecked, value: Formatters.relativeTime(lastCheck))
                }
            }
            
            Section(L10n.settingsInfo) {
                LabeledContent(L10n.settingsVersion, value: updateChecker.currentVersion)
                LabeledContent(L10n.settingsDataSource, value: "Anthropic OAuth API")
                LabeledContent(L10n.settingsRefreshInterval, value: "30s")
                LabeledContent(L10n.settingsAuth, value: "macOS Keychain")
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 360)
        .navigationTitle(L10n.settingsTitle)
    }
    
    private func checkNow() async {
        await updateChecker.checkForUpdates(userInitiated: true)
        if updateChecker.updateAvailable, let version = updateChecker.latestVersion {
            UpdateAlert.show(
                currentVersion: updateChecker.currentVersion,
                newVersion: version,
                releaseNotes: updateChecker.releaseNotes,
                onDownload: { updateChecker.openDownload() },
                onSkip: { updateChecker.skipVersion() },
                onLater: { updateChecker.dismiss() }
            )
        } else {
            UpdateAlert.showUpToDate(currentVersion: updateChecker.currentVersion)
        }
    }
}
