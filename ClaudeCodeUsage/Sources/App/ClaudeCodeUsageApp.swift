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
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellable: AnyCancellable?
    
    // Cache: avoid rebuilding attributed string when values haven't changed
    private var lastFiveH: Int = -1
    private var lastWeekly: Int = -1
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
        }
        
        // Single pipeline: debounce rapid successive publishes, deduplicate, update
        cancellable = usageMonitor.$fiveHourPercent
            .combineLatest(usageMonitor.$weeklyPercent)
            .debounce(for: .milliseconds(100), scheduler: RunLoop.main)
            .map { (Int($0.rounded()), Int($1.rounded())) }
            .removeDuplicates { $0 == $1 }
            .sink { [weak self] fiveH, weekly in
                self?.updateStatusButton(fiveH: fiveH, weekly: weekly)
            }
    }
    
    @objc private func togglePopover(_ sender: AnyObject?) {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            popover.performClose(sender)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
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
