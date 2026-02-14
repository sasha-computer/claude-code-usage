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
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let usageMonitor = UsageMonitor()
    let updateChecker = UpdateChecker.shared
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellable: AnyCancellable?
    private var updateCancellable: AnyCancellable?
    private var eventMonitor: Any?
    
    private let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        popover = NSPopover()
        popover.contentSize = NSSize(width: 280, height: 260)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView().environmentObject(usageMonitor)
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
            
            return event
        }
        
        // Reactive status bar updates
        cancellable = usageMonitor.$fiveHourPercent
            .combineLatest(usageMonitor.$weeklyPercent)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .map { (Int($0.rounded()), Int($1.rounded())) }
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] fiveH, weekly in
                self?.updateStatusButton(fiveH: fiveH, weekly: weekly)
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
            onDownload: { [weak self] in self?.updateChecker.openDownload() },
            onSkip: { [weak self] in self?.updateChecker.skipVersion() },
            onLater: { [weak self] in self?.updateChecker.dismiss() }
        )
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
    
    private func updateStatusButton(fiveH: Int, weekly: Int) {
        guard let button = statusItem.button else { return }
        
        let fiveHColor = statusColor(for: Double(fiveH))
        let weeklyColor = statusColor(for: Double(weekly))
        let dimAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        
        let text = NSMutableAttributedString()
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
