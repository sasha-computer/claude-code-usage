import Foundation
import AppKit
import Combine

@MainActor
final class UpdateChecker: ObservableObject {
    
    static let shared = UpdateChecker()
    
    @Published var updateAvailable = false
    @Published var latestVersion: String?
    @Published var releaseNotes: String?
    @Published var downloadURL: URL?
    @Published var isChecking = false
    
    private let repoOwner = "sasha-computer"
    private let repoName = "claude-code-usage"
    private let checkInterval: TimeInterval = 24 * 3600 // Daily
    private var timer: Timer?
    
    var checkAutomatically: Bool {
        get { UserDefaults.standard.object(forKey: "checkForUpdatesAutomatically") as? Bool ?? true }
        set {
            UserDefaults.standard.set(newValue, forKey: "checkForUpdatesAutomatically")
            if newValue { schedulePeriodicCheck() } else { timer?.invalidate(); timer = nil }
        }
    }
    
    var skippedVersion: String? {
        get { UserDefaults.standard.string(forKey: "skippedVersion") }
        set { UserDefaults.standard.set(newValue, forKey: "skippedVersion") }
    }
    
    var lastCheckDate: Date? {
        get { UserDefaults.standard.object(forKey: "lastUpdateCheck") as? Date }
        set { UserDefaults.standard.set(newValue, forKey: "lastUpdateCheck") }
    }
    
    var currentVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
    }
    
    private init() {}
    
    func startIfEnabled() {
        guard checkAutomatically else { return }
        // Check on launch after a short delay so the UI is ready
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s
            await checkForUpdates(userInitiated: false)
        }
        schedulePeriodicCheck()
    }
    
    func checkForUpdates(userInitiated: Bool) async {
        guard !isChecking else { return }
        isChecking = true
        defer { isChecking = false }
        
        guard let release = await fetchLatestRelease() else { return }
        
        lastCheckDate = Date()
        
        let remote = release.version
        guard isNewer(remote: remote, local: currentVersion) else {
            if userInitiated {
                updateAvailable = false
                latestVersion = nil
            }
            return
        }
        
        // If the user skipped this version and this isn't a manual check, don't nag
        if !userInitiated, skippedVersion == remote { return }
        
        latestVersion = remote
        releaseNotes = release.body
        downloadURL = release.downloadURL ?? release.htmlURL
        updateAvailable = true
    }
    
    func skipVersion() {
        if let version = latestVersion {
            skippedVersion = version
        }
        dismiss()
    }
    
    func dismiss() {
        updateAvailable = false
    }
    
    func openDownload() {
        if let url = downloadURL {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Private
    
    private func schedulePeriodicCheck() {
        timer?.invalidate()
        let t = Timer.scheduledTimer(withTimeInterval: checkInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.checkForUpdates(userInitiated: false)
            }
        }
        t.tolerance = 300 // 5 min tolerance for energy efficiency
        timer = t
    }
    
    private struct GitHubRelease {
        let version: String
        let body: String?
        let htmlURL: URL?
        let downloadURL: URL?
    }
    
    private func fetchLatestRelease() async -> GitHubRelease? {
        let url = URL(string: "https://api.github.com/repos/\(repoOwner)/\(repoName)/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 15
        
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse,
              http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        
        guard let tagName = json["tag_name"] as? String else { return nil }
        let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
        let body = json["body"] as? String
        let htmlURLString = json["html_url"] as? String
        let htmlURL = htmlURLString.flatMap { URL(string: $0) }
        
        // Find .dmg asset download URL
        var dmgURL: URL? = nil
        if let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                if let name = asset["name"] as? String, name.hasSuffix(".dmg"),
                   let urlStr = asset["browser_download_url"] as? String {
                    dmgURL = URL(string: urlStr)
                    break
                }
            }
        }
        
        return GitHubRelease(version: version, body: body, htmlURL: htmlURL, downloadURL: dmgURL)
    }
    
    private func isNewer(remote: String, local: String) -> Bool {
        let r = remote.split(separator: ".").compactMap { Int($0) }
        let l = local.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(r.count, l.count) {
            let rv = i < r.count ? r[i] : 0
            let lv = i < l.count ? l[i] : 0
            if rv > lv { return true }
            if rv < lv { return false }
        }
        return false
    }
}
