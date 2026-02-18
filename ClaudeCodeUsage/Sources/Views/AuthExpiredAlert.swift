import AppKit

/// Shows a native macOS alert when the Claude Code OAuth token has expired
/// and all automatic recovery attempts have failed.
@MainActor
enum AuthExpiredAlert {
    
    static func show(
        onReauthenticate: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        let alert = NSAlert()
        alert.messageText = "Claude Code login expired"
        alert.informativeText = "Your authentication token has expired and could not be refreshed automatically.\n\nClick Re-authenticate to open Claude Code login in your browser, or run \"claude login\" in your terminal."
        alert.alertStyle = .warning
        
        if let icon = NSApp.applicationIconImage {
            alert.icon = icon
        }
        
        alert.addButton(withTitle: "Re-authenticate")
        alert.addButton(withTitle: "Dismiss")
        
        let response = alert.runModal()
        
        switch response {
        case .alertFirstButtonReturn:
            onReauthenticate()
        default:
            onDismiss()
        }
    }
    
    /// Launches `claude login` which triggers the browser-based OAuth flow.
    static func launchClaudeLogin() {
        let claudePath = findClaudeCLI()
        
        guard let path = claudePath else {
            // Fallback: show a hint if we can't find the CLI
            let fallback = NSAlert()
            fallback.messageText = "Could not find Claude Code CLI"
            fallback.informativeText = "Please open your terminal and run:\n\nclaude login"
            fallback.alertStyle = .informational
            fallback.addButton(withTitle: "OK")
            fallback.runModal()
            return
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: path)
        task.arguments = ["login"]
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
        } catch {
            // If launch fails, tell the user to do it manually
            let fallback = NSAlert()
            fallback.messageText = "Could not launch Claude Code"
            fallback.informativeText = "Please open your terminal and run:\n\nclaude login"
            fallback.alertStyle = .informational
            fallback.addButton(withTitle: "OK")
            fallback.runModal()
        }
    }
    
    // MARK: - Private
    
    private static func findClaudeCLI() -> String? {
        // Check common locations
        let candidates = [
            "/usr/local/bin/claude",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/.claude/local/claude",
            "\(FileManager.default.homeDirectoryForCurrentUser.path)/.local/bin/claude",
        ]
        
        for path in candidates {
            if FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        }
        
        // Try `which claude` as a fallback
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = ["claude"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else { return nil }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            if let path = path, !path.isEmpty { return path }
        } catch {}
        
        return nil
    }
}
