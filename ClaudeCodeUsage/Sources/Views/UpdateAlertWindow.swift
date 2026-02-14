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
        onDownload: @escaping () -> Void,
        onSkip: @escaping () -> Void,
        onLater: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "A new version of Claude Code Usage is available!"
        alert.informativeText = "Version \(newVersion) is available — you have \(currentVersion). Would you like to download it now?"
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
            onDownload()
        case .alertSecondButtonReturn:
            onLater()
        case .alertThirdButtonReturn:
            onSkip()
        default:
            onLater()
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
