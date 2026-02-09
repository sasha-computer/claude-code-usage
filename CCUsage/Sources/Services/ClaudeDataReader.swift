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
            return "Claude Code에 로그인하세요 (claude login)"
        case .tokenRefreshFailed:
            return "인증 만료 — claude login으로 재로그인하세요"
        case .apiCallFailed:
            return "API 연결 실패 — 네트워크를 확인하세요"
        case .parseFailed:
            return "API 응답을 처리할 수 없습니다"
        }
    }
}

final class ClaudeUsageAPI {
    
    private let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let tokenRefreshURL = URL(string: "https://platform.claude.com/v1/oauth/token")!
    private let oauthClientId = "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
    
    func fetchUsage() async -> Result<RateLimits, UsageFetchError> {
        guard var creds = getCredentials() else { return .failure(.noCredentials) }
        
        if !isTokenValid(creds) {
            guard let refreshToken = creds.refreshToken,
                  let refreshed = await refreshAccessToken(refreshToken) else { return .failure(.tokenRefreshFailed) }
            creds = refreshed
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
        if let kc = readKeychain() { return kc }
        return readCredentialsFile()
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
    
    private func parseResponse(_ data: Data) -> RateLimits? {
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
