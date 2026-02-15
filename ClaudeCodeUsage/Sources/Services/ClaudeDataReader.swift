import Foundation

struct RateLimits {
    let fiveHourPercent: Double
    let weeklyPercent: Double
    let fiveHourResetsAt: Date?
    let weeklyResetsAt: Date?
}

enum UsageFetchError: Error {
    case noCredentials
    case tokenRefreshFailed
    case apiCallFailed
    case parseFailed
    
    var localizedMessage: String {
        switch self {
        case .noCredentials:
            return L10n.errorNotLoggedIn
        case .tokenRefreshFailed:
            return L10n.errorTokenExpired
        case .apiCallFailed:
            return L10n.errorConnectionFailed
        case .parseFailed:
            return L10n.errorParseFailed
        }
    }
}

final class ClaudeUsageAPI {
    
    private let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let tokenRefreshURL = URL(string: "https://platform.claude.com/v1/oauth/token")!
    private let oauthClientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    
    /// In-memory cache of the most recent valid credentials.
    /// Survives keychain write failures so the app keeps working until restart.
    private var cachedCreds: OAuthCreds?
    
    func fetchUsage() async -> Result<RateLimits, UsageFetchError> {
        guard var creds = getCredentials() else { return .failure(.noCredentials) }
        
        if !isTokenValid(creds) {
            guard let refreshToken = creds.refreshToken,
                  let refreshed = await refreshAccessToken(refreshToken) else { return .failure(.tokenRefreshFailed) }
            creds = refreshed
            cachedCreds = refreshed
            // Write refreshed tokens back so Claude Code stays authenticated
            saveCredentials(creds)
        }
        
        guard let data = await callAPI(accessToken: creds.accessToken) else { return .failure(.apiCallFailed) }
        guard let limits = parseResponse(data) else { return .failure(.parseFailed) }
        return .success(limits)
    }
    
    private struct OAuthCreds {
        let accessToken: String
        let expiresAt: TimeInterval?
        let refreshToken: String?
    }
    
    private func getCredentials() -> OAuthCreds? {
        // Prefer in-memory cache (survives keychain write failures)
        if let cached = cachedCreds, isTokenValid(cached) { return cached }
        if let kc = readKeychain() { return kc }
        if let file = readCredentialsFile() { return file }
        // Last resort: return cached creds even if expired (we can try to refresh)
        return cachedCreds
    }
    
    private func readKeychain() -> OAuthCreds? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        task.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        do {
            try task.run()
            task.waitUntilExit()
            guard task.terminationStatus == 0 else { return nil }
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let json = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !json.isEmpty,
                  let jsonData = json.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else { return nil }
            
            let creds = (parsed["claudeAiOauth"] as? [String: Any]) ?? parsed
            guard let accessToken = creds["accessToken"] as? String else { return nil }
            
            return OAuthCreds(
                accessToken: accessToken,
                expiresAt: creds["expiresAt"] as? TimeInterval,
                refreshToken: creds["refreshToken"] as? String
            )
        } catch {
            return nil
        }
    }
    
    private func readCredentialsFile() -> OAuthCreds? {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".claude/.credentials.json")
        guard let data = try? Data(contentsOf: path),
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        
        let creds = (parsed["claudeAiOauth"] as? [String: Any]) ?? parsed
        guard let accessToken = creds["accessToken"] as? String else { return nil }
        
        return OAuthCreds(
            accessToken: accessToken,
            expiresAt: creds["expiresAt"] as? TimeInterval,
            refreshToken: creds["refreshToken"] as? String
        )
    }
    
    private func saveCredentials(_ creds: OAuthCreds) {
        // Read existing keychain JSON, update the OAuth fields, write it back.
        // This keeps Claude Code's session alive after a token refresh.
        //
        // IMPORTANT: We never delete-then-add. The -U flag on add-generic-password
        // atomically updates an existing entry (or creates a new one). A delete-then-add
        // pattern risks losing credentials entirely if the add fails (e.g., keychain
        // locked after sleep).
        
        var updatedJson: String
        
        // Try to read existing keychain entry to preserve other fields
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        task.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice
        
        var existingParsed: [String: Any]?
        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let json = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   !json.isEmpty,
                   let jsonData = json.data(using: .utf8) {
                    existingParsed = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                }
            }
        } catch {
            // Keychain read failed -- we'll build a fresh entry below
        }
        
        if var parsed = existingParsed {
            // Update the claudeAiOauth sub-object (or top-level if flat)
            let key = parsed["claudeAiOauth"] != nil ? "claudeAiOauth" : nil
            var oauthDict = (key.flatMap { parsed[$0] as? [String: Any] }) ?? parsed
            
            oauthDict["accessToken"] = creds.accessToken
            if let expiresAt = creds.expiresAt {
                oauthDict["expiresAt"] = expiresAt
            }
            if let refreshToken = creds.refreshToken {
                oauthDict["refreshToken"] = refreshToken
            }
            
            if let key = key {
                parsed[key] = oauthDict
            } else {
                parsed = oauthDict
            }
            
            guard let data = try? JSONSerialization.data(withJSONObject: parsed),
                  let json = String(data: data, encoding: .utf8) else { return }
            updatedJson = json
        } else {
            // No existing entry (e.g., it was previously lost). Build a fresh one
            // in the format Claude Code expects.
            var oauthDict: [String: Any] = ["accessToken": creds.accessToken]
            if let expiresAt = creds.expiresAt { oauthDict["expiresAt"] = expiresAt }
            if let refreshToken = creds.refreshToken { oauthDict["refreshToken"] = refreshToken }
            let envelope: [String: Any] = ["claudeAiOauth": oauthDict]
            
            guard let data = try? JSONSerialization.data(withJSONObject: envelope),
                  let json = String(data: data, encoding: .utf8) else { return }
            updatedJson = json
        }
        
        // Atomic upsert: -U updates an existing entry or creates a new one.
        // Never delete first -- that's the path to lost credentials.
        let addTask = Process()
        addTask.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        addTask.arguments = ["add-generic-password", "-s", "Claude Code-credentials", "-w", updatedJson, "-U"]
        addTask.standardOutput = FileHandle.nullDevice
        addTask.standardError = FileHandle.nullDevice
        do {
            try addTask.run()
            addTask.waitUntilExit()
        } catch {
            // Keychain write failed. The in-memory cache (cachedCreds) keeps the
            // app working. The old keychain entry is untouched (we never deleted it).
        }
    }
    
    private func isTokenValid(_ creds: OAuthCreds) -> Bool {
        guard let expiresAt = creds.expiresAt else { return true }
        return expiresAt > Date().timeIntervalSince1970 * 1000
    }
    
    private func refreshAccessToken(_ refreshToken: String) async -> OAuthCreds? {
        var request = URLRequest(url: tokenRefreshURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=refresh_token&refresh_token=\(refreshToken)&client_id=\(oauthClientId)"
        request.httpBody = body.data(using: .utf8)
        request.timeoutInterval = 10
        
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = parsed["access_token"] as? String else { return nil }
        
        let expiresIn = parsed["expires_in"] as? Double
        let expiresAt = expiresIn.map { Date().timeIntervalSince1970 * 1000 + $0 * 1000 }
        
        return OAuthCreds(
            accessToken: accessToken,
            expiresAt: expiresAt,
            refreshToken: (parsed["refresh_token"] as? String) ?? refreshToken
        )
    }
    
    private func callAPI(accessToken: String) async -> Data? {
        var request = URLRequest(url: apiURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else { return nil }
        return data
    }
    
    func parseResponse(_ data: Data) -> RateLimits? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        
        let fiveHour = json["five_hour"] as? [String: Any]
        let sevenDay = json["seven_day"] as? [String: Any]
        
        let fiveHourUtil = fiveHour?["utilization"] as? Double
        let weeklyUtil = sevenDay?["utilization"] as? Double
        
        guard fiveHourUtil != nil || weeklyUtil != nil else { return nil }
        
        func clamp(_ v: Double?) -> Double {
            guard let v = v, v.isFinite else { return 0 }
            return min(100, max(0, v))
        }
        
        func parseDate(_ str: String?) -> Date? {
            guard let str = str else { return nil }
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            return f.date(from: str) ?? {
                let f2 = ISO8601DateFormatter()
                f2.formatOptions = [.withInternetDateTime]
                return f2.date(from: str)
            }()
        }
        
        return RateLimits(
            fiveHourPercent: clamp(fiveHourUtil),
            weeklyPercent: clamp(weeklyUtil),
            fiveHourResetsAt: parseDate(fiveHour?["resets_at"] as? String),
            weeklyResetsAt: parseDate(sevenDay?["resets_at"] as? String)
        )
    }
}
