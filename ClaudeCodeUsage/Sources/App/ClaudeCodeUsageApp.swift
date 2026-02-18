import SwiftUI
import AppKit
import Combine

@main
struct ClaudeCodeUsageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            SettingsView()
                .environmentObject(appDelegate.usageMonitor)
                .environmentObject(appDelegate.accountStore)
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let accountStore: AccountStore
    let usageMonitor: UsageMonitor
    let updateChecker = UpdateChecker.shared

    override init() {
        let store = AccountStore()
        self.accountStore = store
        self.usageMonitor = UsageMonitor(accountStore: store)
        super.init()
    }

    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellable: AnyCancellable?
    private var updateCancellable: AnyCancellable?
    private var authErrorCancellable: AnyCancellable?
    private var eventMonitor: Any?
    
    /// Tracks the last time we showed the auth-expired alert so we don't spam the user.
    /// The refresh timer fires every 30s, but we only show the alert once per 4 hours.
    private var lastAuthAlertShown: Date?
    private let authAlertCooldown: TimeInterval = 4 * 60 * 60  // 4 hours
    
    private let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 260)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(usageMonitor)
                .environmentObject(accountStore)
        )
        
        if let button = statusItem.button {
            button.action = #selector(togglePopover(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Right-click context menu on status item
        let menu = NSMenu()
        menu.addItem(withTitle: "Refresh", action: #selector(refreshUsage), keyEquivalent: "r")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        menu.addItem(.separator())
        menu.addItem(withTitle: "Quit Claude Code Usage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        statusItem.menu = nil // We handle left-click manually, right-click via menu
        
        // Global keyboard shortcuts when popover is visible
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            
            // Only handle shortcuts when popover is shown
            guard self.popover.isShown else { return event }
            
            if event.modifierFlags.contains(.command) {
                switch event.charactersIgnoringModifiers {
                case "r":
                    self.refreshUsage()
                    return nil
                case ",":
                    self.openSettings()
                    return nil
                case "q":
                    NSApplication.shared.terminate(nil)
                    return nil
                case "w":
                    self.popover.performClose(nil)
                    return nil
                default:
                    break
                }
            }
            
            // Esc closes popover
            if event.keyCode == 53 {
                self.popover.performClose(nil)
                return nil
            }
            
            // Account switching via letter keys when MCC is active
            if self.accountStore.isEnabled && self.accountStore.accounts.count > 1,
               !event.modifierFlags.contains(.command),
               let char = event.charactersIgnoringModifiers?.lowercased() {
                let matched = self.accountStore.accounts.first {
                    String($0.label.prefix(1)).lowercased() == char
                }
                if let matched = matched, matched.label != self.accountStore.activeAccount?.label {
                    self.accountStore.setActive(matched.label)
                    return nil
                }
            }
            
            return event
        }
        
        // Reactive status bar updates
        let usagePub = usageMonitor.$fiveHourPercent
            .combineLatest(usageMonitor.$weeklyPercent)
        let combinedPub = usagePub
            .combineLatest(usageMonitor.$activeAccountLabel)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)

        cancellable = combinedPub
            .sink { [weak self] pair, label in
                let fiveH = Int(pair.0.rounded())
                let weekly = Int(pair.1.rounded())
                self?.updateStatusButton(fiveH: fiveH, weekly: weekly, accountLabel: label)
            }
        
        // Auto-check for updates on launch
        updateChecker.startIfEnabled()
        
        // Show the native update alert when an update is found (auto-check only)
        updateCancellable = updateChecker.$updateAvailable
            .dropFirst() // Skip initial value
            .filter { $0 }
            .sink { [weak self] _ in
                self?.showUpdateAlert()
            }
        
        // Show auth-expired alert when token refresh fails
        authErrorCancellable = usageMonitor.$error
            .compactMap { $0 }
            .filter { $0 == .tokenRefreshFailed || $0 == .noCredentials }
            .sink { [weak self] _ in
                self?.showAuthExpiredAlertIfNeeded()
            }
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        let event = NSApp.currentEvent
        
        // Right-click: show context menu
        if event?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: "Refresh", action: #selector(refreshUsage), keyEquivalent: "r")
            menu.addItem(withTitle: "Check for Updates...", action: #selector(checkForUpdates), keyEquivalent: "u")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Quit Claude Code Usage", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
            statusItem.menu = menu
            button.performClick(nil)
            // Clear menu so left-click goes back to popover
            DispatchQueue.main.async { self.statusItem.menu = nil }
            return
        }
        
        // Left-click: toggle popover
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    @objc private func refreshUsage() {
        Task { await usageMonitor.refresh() }
    }
    
    @objc private func checkForUpdates() {
        Task {
            await updateChecker.checkForUpdates(userInitiated: true)
            if updateChecker.updateAvailable {
                showUpdateAlert()
            } else {
                UpdateAlert.showUpToDate(currentVersion: updateChecker.currentVersion)
            }
        }
    }
    
    private func showUpdateAlert() {
        guard let version = updateChecker.latestVersion else { return }
        popover.performClose(nil)
        UpdateAlert.show(
            currentVersion: updateChecker.currentVersion,
            newVersion: version,
            releaseNotes: updateChecker.releaseNotes,
            onInstall: { [weak self] in self?.performInstallUpdate() },
            onSkip: { [weak self] in self?.updateChecker.skipVersion() },
            onLater: { [weak self] in self?.updateChecker.dismiss() }
        )
    }
    
    private func showAuthExpiredAlertIfNeeded() {
        // Throttle: only show once per cooldown period
        if let last = lastAuthAlertShown, Date().timeIntervalSince(last) < authAlertCooldown {
            return
        }
        lastAuthAlertShown = Date()
        
        popover.performClose(nil)
        AuthExpiredAlert.show(
            onReauthenticate: {
                AuthExpiredAlert.launchClaudeLogin()
            },
            onDismiss: {
                // Nothing to do -- the next successful refresh will clear the error
            }
        )
    }
    
    private func performInstallUpdate() {
        // Show progress alert on a background run loop so we can do async work
        let alert = UpdateAlert.showInstalling()
        
        Task {
            await updateChecker.installUpdate()
            
            // If we get here, the update failed (successful update relaunches)
            // Dismiss the progress alert
            NSApp.stopModal()
            
            if let error = updateChecker.updateError {
                UpdateAlert.showError(error, downloadURL: updateChecker.downloadURL)
            }
        }
        
        // Run modal blocks until stopModal() or the app quits
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            // User clicked Cancel
            // The download is already in progress but we can't easily cancel URLSession.download
            // Just dismiss - if it finishes it'll still try to install
        }
    }
    
    @objc private func openSettings() {
        popover.performClose(nil)
        // Open the Settings window
        if #available(macOS 14.0, *) {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.activate(ignoringOtherApps: true)
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
    
    private func updateStatusButton(fiveH: Int, weekly: Int, accountLabel: String? = nil) {
        guard let button = statusItem.button else { return }
        
        let fiveHColor = statusColor(for: Double(fiveH))
        let weeklyColor = statusColor(for: Double(weekly))
        let dimAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        
        let text = NSMutableAttributedString()
        
        if let label = accountLabel {
            let initial = String(label.prefix(1)).uppercased()
            text.append(NSAttributedString(string: "\(initial) ", attributes: [
                .font: font,
                .foregroundColor: NSColor.secondaryLabelColor,
            ]))
        }
        
        text.append(NSAttributedString(string: "5h ", attributes: dimAttrs))
        text.append(NSAttributedString(string: "\(fiveH)%", attributes: [.font: font, .foregroundColor: fiveHColor]))
        text.append(NSAttributedString(string: "  ", attributes: dimAttrs))
        text.append(NSAttributedString(string: "7d ", attributes: dimAttrs))
        text.append(NSAttributedString(string: "\(weekly)%", attributes: [.font: font, .foregroundColor: weeklyColor]))
        
        button.attributedTitle = text
    }
    
    private func statusColor(for percent: Double) -> NSColor {
        if percent >= 90 { return .systemRed }
        if percent >= 70 { return .systemOrange }
        return .labelColor
    }
}
