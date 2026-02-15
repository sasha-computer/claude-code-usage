import AppKit

/// Shows a standard macOS "Software Update Available" alert.
/// Matches the native macOS update dialog pattern with app icon,
/// version info, release notes, and standard button layout.
@MainActor
enum UpdateAlert {
    
    static func show(
        currentVersion: String,
        newVersion: String,
        releaseNotes: String?,
        onInstall: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onLater: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "A new version of Claude Code Usage is available!"
        alert.informativeText = "Version \(newVersion) is available — you have \(currentVersion). Would you like to install it now?"
        alert.alertStyle = .informational
        
        // Set the app icon
        if let icon = NSApp.applicationIconImage {
            alert.icon = icon
        }
        
        // Buttons are added in order: rightmost first (default action)
        // Standard macOS layout: [Skip This Version] [Remind Me Later] [Install Update]
        alert.addButton(withTitle: "Install Update")
        alert.addButton(withTitle: "Remind Me Later")
        alert.addButton(withTitle: "Skip This Version")
        
        // Release notes as scrollable accessory view
        if let notes = releaseNotes, !notes.isEmpty {
            let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 400, height: 140))
            scrollView.hasVerticalScroller = true
            scrollView.borderType = .bezelBorder
            
            let textView = NSTextView(frame: scrollView.contentView.bounds)
            textView.isEditable = false
            textView.isSelectable = true
            textView.font = .systemFont(ofSize: 11)
            textView.textColor = .labelColor
            textView.backgroundColor = .controlBackgroundColor
            textView.textContainerInset = NSSize(width: 8, height: 8)
            textView.autoresizingMask = [.width]
            
            // Strip markdown formatting for clean display
            textView.string = cleanMarkdown(notes)
            
            scrollView.documentView = textView
            alert.accessoryView = scrollView
        }
        
        // Show the alert and handle response
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            onInstall()
        case .alertSecondButtonReturn:
            onLater()
        case .alertThirdButtonReturn:
            onSkip()
        default:
            onLater()
        }
    }
    
    /// Shows a progress alert while installing the update.
    static func showInstalling() -> NSAlert {
        let alert = NSAlert()
        alert.messageText = "Installing update..."
        alert.informativeText = "Downloading and installing. The app will relaunch automatically."
        alert.alertStyle = .informational
        if let icon = NSApp.applicationIconImage {
            alert.icon = icon
        }
        
        let indicator = NSProgressIndicator(frame: NSRect(x: 0, y: 0, width: 300, height: 20))
        indicator.style = .bar
        indicator.isIndeterminate = true
        indicator.startAnimation(nil)
        alert.accessoryView = indicator
        
        // No actionable buttons - just a cancel
        alert.addButton(withTitle: "Cancel")
        
        return alert
    }
    
    /// Shows an error alert for failed updates, with a fallback to browser download.
    static func showError(_ message: String, downloadURL: URL?) {
        let alert = NSAlert()
        alert.messageText = "Update Failed"
        alert.informativeText = message + (downloadURL != nil ? "\n\nYou can download the update manually instead." : "")
        alert.alertStyle = .warning
        if let icon = NSApp.applicationIconImage {
            alert.icon = icon
        }
        
        if downloadURL != nil {
            alert.addButton(withTitle: "Download Manually")
            alert.addButton(withTitle: "OK")
        } else {
            alert.addButton(withTitle: "OK")
        }
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn, let url = downloadURL {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Shows a "you're up to date" alert for manual check-for-updates.
    static func showUpToDate(currentVersion: String) {
        let alert = NSAlert()
        alert.messageText = "You're up to date!"
        alert.informativeText = "Claude Code Usage \(currentVersion) is currently the newest version available."
        alert.alertStyle = .informational
        if let icon = NSApp.applicationIconImage {
            alert.icon = icon
        }
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Private
    
    private static func cleanMarkdown(_ text: String) -> String {
        var result = text
        // Strip common markdown patterns for plain text display
        // Headers: ## Title -> Title
        result = result.replacingOccurrences(
            of: #"^#{1,6}\s+"#, with: "", options: .regularExpression, range: nil
        )
        // Bold: **text** -> text
        result = result.replacingOccurrences(of: "**", with: "")
        // Inline code: `text` -> text
        result = result.replacingOccurrences(
            of: #"`([^`]+)`"#, with: "$1", options: .regularExpression
        )
        // Links: [text](url) -> text
        result = result.replacingOccurrences(
            of: #"\[([^\]]+)\]\([^\)]+\)"#, with: "$1", options: .regularExpression
        )
        // List items: - item -> • item
        result = result.replacingOccurrences(
            of: #"^[-*]\s+"#, with: "• ", options: .regularExpression
        )
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
