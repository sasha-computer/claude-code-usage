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
    private var cancellables = Set<AnyCancellable>()
    
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
        
        // Update the menu bar label whenever usage data changes
        usageMonitor.$fiveHourPercent
            .combineLatest(usageMonitor.$weeklyPercent)
            .receive(on: RunLoop.main)
            .sink { [weak self] _, _ in
                self?.updateStatusButton()
            }
            .store(in: &cancellables)
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
