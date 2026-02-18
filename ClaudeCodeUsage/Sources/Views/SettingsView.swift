import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var monitor: UsageMonitor
    @EnvironmentObject var accountStore: AccountStore
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
            
            Section(L10n.mccSectionTitle) {
                Toggle(L10n.mccToggle, isOn: $accountStore.isEnabled)
                
                if accountStore.isEnabled {
                    if let error = accountStore.fileError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(.orange)
                            Text(error)
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }
                    } else if !accountStore.accounts.isEmpty {
                        ForEach(accountStore.accounts) { account in
                            HStack {
                                Circle()
                                    .fill(account.label.caseInsensitiveCompare(
                                        accountStore.activeAccount?.label ?? ""
                                    ) == .orderedSame ? Color.green : Color.clear)
                                    .overlay(
                                        Circle().stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                    )
                                    .frame(width: 8, height: 8)
                                Text(account.label)
                                    .font(.system(size: 12))
                                Spacer()
                                Text(account.isTokenExpired ? L10n.mccTokenExpired : L10n.mccTokenValid)
                                    .font(.system(size: 10))
                                    .foregroundStyle(account.isTokenExpired ? .orange : .green)
                            }
                        }
                    }
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
        .frame(width: 380, height: 460)
        .navigationTitle(L10n.settingsTitle)
    }
    
    private func checkNow() async {
        await updateChecker.checkForUpdates(userInitiated: true)
        if updateChecker.updateAvailable, let version = updateChecker.latestVersion {
            UpdateAlert.show(
                currentVersion: updateChecker.currentVersion,
                newVersion: version,
                releaseNotes: updateChecker.releaseNotes,
                onInstall: {
                    let alert = UpdateAlert.showInstalling()
                    Task {
                        await updateChecker.installUpdate()
                        NSApp.stopModal()
                        if let error = updateChecker.updateError {
                            UpdateAlert.showError(error, downloadURL: updateChecker.downloadURL)
                        }
                    }
                    alert.runModal()
                },
                onSkip: { updateChecker.skipVersion() },
                onLater: { updateChecker.dismiss() }
            )
        } else {
            UpdateAlert.showUpToDate(currentVersion: updateChecker.currentVersion)
        }
    }
}
