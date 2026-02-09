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
        
        button.image = nil
        button.title = ""
        
        let fiveH = Int(usageMonitor.fiveHourPercent.rounded())
        let weekly = Int(usageMonitor.weeklyPercent.rounded())
        
        let line1 = "\(fiveH)%[5h]"
        let line2 = "\(weekly)%[Wk]"
        
        let font = NSFont.monospacedDigitSystemFont(ofSize: 9, weight: .medium)
        let menuBarHeight: CGFloat = NSStatusBar.system.thickness
        
        let textField1 = NSTextField(labelWithString: line1)
        textField1.font = font
        textField1.alignment = .center
        textField1.textColor = .headerTextColor
        textField1.sizeToFit()
        
        let textField2 = NSTextField(labelWithString: line2)
        textField2.font = font
        textField2.alignment = .center
        textField2.textColor = .headerTextColor
        textField2.sizeToFit()
        
        let maxWidth = max(textField1.frame.width, textField2.frame.width) + 4
        let lineHeight: CGFloat = 11
        let totalTextHeight = lineHeight * 2
        let topPadding = (menuBarHeight - totalTextHeight) / 2
        
        let container = NSView(frame: NSRect(x: 0, y: 0, width: maxWidth, height: menuBarHeight))
        
        textField1.frame = NSRect(x: 0, y: menuBarHeight - topPadding - lineHeight, width: maxWidth, height: lineHeight)
        textField2.frame = NSRect(x: 0, y: menuBarHeight - topPadding - lineHeight * 2, width: maxWidth, height: lineHeight)
        
        container.addSubview(textField1)
        container.addSubview(textField2)
        
        button.subviews.forEach { $0.removeFromSuperview() }
        button.addSubview(container)
        button.frame = NSRect(x: button.frame.origin.x, y: button.frame.origin.y, width: maxWidth, height: menuBarHeight)
        statusItem.length = maxWidth
    }
}
