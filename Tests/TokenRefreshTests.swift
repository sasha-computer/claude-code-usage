import XCTest
@testable import ClaudeCodeUsage

final class TokenRefreshTests: XCTestCase {
    
    // MARK: - Pre-emptive refresh (shouldRefreshPreemptively)
    
    func testTokenAtFullLifetimeNeedsPreemptiveRefresh() {
        // Token expired 1 second ago
        let expiredMs = (Date().timeIntervalSince1970 - 1) * 1000
        XCTAssertTrue(ClaudeUsageAPI.shouldRefreshPreemptively(expiresAt: expiredMs))
    }
    
    func testTokenAt90PercentLifetimeNeedsPreemptiveRefresh() {
        // Token expires in 6 minutes (10% of 1 hour left -- past the 80% threshold)
        let soonMs = (Date().timeIntervalSince1970 + 360) * 1000
        XCTAssertTrue(ClaudeUsageAPI.shouldRefreshPreemptively(expiresAt: soonMs))
    }
    
    func testTokenAt50PercentLifetimeDoesNotNeedPreemptiveRefresh() {
        // Token expires in 2 hours -- well within comfort zone
        let laterMs = (Date().timeIntervalSince1970 + 7200) * 1000
        XCTAssertFalse(ClaudeUsageAPI.shouldRefreshPreemptively(expiresAt: laterMs))
    }
    
    func testTokenWithNoExpiryDoesNotNeedPreemptiveRefresh() {
        XCTAssertFalse(ClaudeUsageAPI.shouldRefreshPreemptively(expiresAt: nil))
    }
    
    // MARK: - Keychain re-read after refresh failure
    
    func testKeychainReReadDetectsUpdatedToken() {
        // Simulates: refresh fails, but Claude Code already refreshed and wrote
        // a new token to keychain. The app should detect the new token.
        let oldToken = "sk-ant-old-expired"
        let newToken = "sk-ant-new-valid"
        let freshExpiry = (Date().timeIntervalSince1970 + 3600) * 1000
        
        let result = ClaudeUsageAPI.isKeychainTokenNewer(
            cachedAccessToken: oldToken,
            keychainAccessToken: newToken,
            keychainExpiresAt: freshExpiry
        )
        XCTAssertTrue(result, "Should detect that keychain has a different, valid token")
    }
    
    func testKeychainReReadIgnoresSameExpiredToken() {
        // Same token in keychain as in cache -- no recovery possible
        let sameToken = "sk-ant-same-expired"
        let expiredMs = (Date().timeIntervalSince1970 - 60) * 1000
        
        let result = ClaudeUsageAPI.isKeychainTokenNewer(
            cachedAccessToken: sameToken,
            keychainAccessToken: sameToken,
            keychainExpiresAt: expiredMs
        )
        XCTAssertFalse(result, "Same expired token is not newer")
    }
    
    func testKeychainReReadIgnoresNilToken() {
        let result = ClaudeUsageAPI.isKeychainTokenNewer(
            cachedAccessToken: "sk-ant-old",
            keychainAccessToken: nil,
            keychainExpiresAt: nil
        )
        XCTAssertFalse(result, "No keychain token is not newer")
    }
    
    // MARK: - Error messages guide the user correctly
    
    func testTokenExpiredErrorSuggestsLogin() {
        let msg = UsageFetchError.tokenRefreshFailed.localizedMessage
        XCTAssertTrue(msg.contains("claude login"), "Error should tell user to run claude login")
    }
    
    func testRecoveringStateShowsRefreshMessage() {
        let msg = UsageFetchError.recovering.localizedMessage
        XCTAssertTrue(msg.lowercased().contains("refresh"),
                       "Should indicate we're refreshing")
    }
    
    func testAutoLoginCommandIsCorrect() {
        XCTAssertEqual(ClaudeUsageAPI.claudeLoginCommand, "claude login")
    }
    
    // MARK: - Pre-emptive refresh boundary
    
    func testPreemptiveRefreshJustInsideMargin() {
        // Token expires 1 second inside the margin -- should trigger refresh
        let marginMs = ClaudeUsageAPI.preemptiveRefreshMarginSeconds * 1000
        let insideMs = Date().timeIntervalSince1970 * 1000 + marginMs - 1000
        XCTAssertTrue(ClaudeUsageAPI.shouldRefreshPreemptively(expiresAt: insideMs))
    }
    
    func testPreemptiveRefreshJustPastMargin() {
        // Token expires 1 second past the margin -- should NOT trigger
        let marginMs = ClaudeUsageAPI.preemptiveRefreshMarginSeconds * 1000
        let pastMs = Date().timeIntervalSince1970 * 1000 + marginMs + 1000
        XCTAssertFalse(ClaudeUsageAPI.shouldRefreshPreemptively(expiresAt: pastMs))
    }
}
