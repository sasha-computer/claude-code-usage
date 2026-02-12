import SwiftUI
import AppKit

@main
struct CCUsageApp: App {
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
    private var updateTimer: Timer?
    
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
            updateStatusButton()
        }
        
        updateTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateStatusButton()
            }
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
    
    private func updateStatusButton() {
        guard let button = statusItem.button else { return }
        
        button.subviews.forEach { $0.removeFromSuperview() }
        button.image = nil
        
        let fiveH = Int(usageMonitor.fiveHourPercent.rounded())
        let weekly = Int(usageMonitor.weeklyPercent.rounded())
        
        let fiveHColor = statusColor(for: usageMonitor.fiveHourPercent)
        let weeklyColor = statusColor(for: usageMonitor.weeklyPercent)
        
        let text = NSMutableAttributedString()
        let font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        let dimAttrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.labelColor]
        
        text.append(NSAttributedString(string: "5h ", attributes: dimAttrs))
        text.append(NSAttributedString(string: "\(fiveH)%", attributes: [.font: font, .foregroundColor: fiveHColor]))
        text.append(NSAttributedString(string: "  ", attributes: dimAttrs))
        text.append(NSAttributedString(string: "7d ", attributes: dimAttrs))
        text.append(NSAttributedString(string: "\(weekly)%", attributes: [.font: font, .foregroundColor: weeklyColor]))
        
        button.attributedTitle = text
        statusItem.length = NSStatusItem.variableLength
    }
    
    private func statusColor(for percent: Double) -> NSColor {
        if percent >= 90 { return .systemRed }
        if percent >= 70 { return .systemOrange }
        return .labelColor
    }
}
