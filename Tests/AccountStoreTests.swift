import XCTest
@testable import ClaudeCodeUsage

@MainActor
final class AccountStoreTests: XCTestCase {
    
    // MARK: - JSON Parsing: Valid
    
    func testParsesMultipleAccounts() {
        let json = """
        {
            "accounts": [
                {"label": "personal", "accessToken": "tok-1", "refreshToken": "ref-1", "expiresAt": 9999999999999},
                {"label": "work", "accessToken": "tok-2", "refreshToken": "ref-2", "expiresAt": 9999999999999}
            ],
            "activeLabel": "work"
        }
        """.data(using: .utf8)!
        
        let result = AccountStore.parseJSON(json)
        guard case .success(let parsed) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }
        
        XCTAssertEqual(parsed.accounts.count, 2)
        XCTAssertEqual(parsed.accounts[0].label, "personal")
        XCTAssertEqual(parsed.accounts[0].accessToken, "tok-1")
        XCTAssertEqual(parsed.accounts[1].label, "work")
        XCTAssertEqual(parsed.accounts[1].accessToken, "tok-2")
        XCTAssertEqual(parsed.activeLabel, "work")
    }
    
    func testParsesSingleAccount() {
        let json = """
        {
            "accounts": [
                {"label": "solo", "accessToken": "tok-solo", "expiresAt": 9999999999999}
            ]
        }
        """.data(using: .utf8)!
        
        let result = AccountStore.parseJSON(json)
        guard case .success(let parsed) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertEqual(parsed.accounts.count, 1)
        XCTAssertEqual(parsed.accounts[0].label, "solo")
        XCTAssertNil(parsed.activeLabel)
    }
    
    func testHandlesOptionalExpiresAt() {
        let json = """
        {
            "accounts": [
                {"label": "no-expiry", "accessToken": "tok-1"},
                {"label": "with-expiry", "accessToken": "tok-2", "expiresAt": 1700000000000}
            ]
        }
        """.data(using: .utf8)!
        
        let result = AccountStore.parseJSON(json)
        guard case .success(let parsed) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertNil(parsed.accounts[0].expiresAt)
        XCTAssertEqual(parsed.accounts[1].expiresAt, 1700000000000)
    }
    
    func testIgnoresExtraFieldsInAccountObjects() {
        let json = """
        {
            "accounts": [
                {
                    "label": "personal",
                    "accessToken": "tok-1",
                    "refreshToken": "ref-1",
                    "expiresAt": 9999999999999,
                    "lastUsed": 1234567890,
                    "rateLimitedUntil": null,
                    "fallbackTo": ["work"]
                }
            ]
        }
        """.data(using: .utf8)!
        
        let result = AccountStore.parseJSON(json)
        guard case .success(let parsed) = result else {
            XCTFail("Expected success")
            return
        }
        XCTAssertEqual(parsed.accounts.count, 1)
        XCTAssertEqual(parsed.accounts[0].label, "personal")
    }
    
    // MARK: - JSON Parsing: Failures
    
    func testFailsOnInvalidJSON() {
        let json = "not json at all".data(using: .utf8)!
        let result = AccountStore.parseJSON(json)
        guard case .failure = result else {
            XCTFail("Expected failure")
            return
        }
    }
    
    func testFailsOnMissingAccountsKey() {
        let json = """
        {"activeLabel": "personal"}
        """.data(using: .utf8)!
        
        let result = AccountStore.parseJSON(json)
        guard case .failure = result else {
            XCTFail("Expected failure")
            return
        }
    }
    
    func testFailsOnEmptyAccountsArray() {
        let json = """
        {"accounts": []}
        """.data(using: .utf8)!
        
        let result = AccountStore.parseJSON(json)
        guard case .failure = result else {
            XCTFail("Expected failure")
            return
        }
    }
    
    func testSkipsAccountsMissingRequiredFields() {
        let json = """
        {
            "accounts": [
                {"label": "good", "accessToken": "tok-good"},
                {"label": "no-token"},
                {"accessToken": "no-label"},
                {"label": "also-good", "accessToken": "tok-also"}
            ]
        }
        """.data(using: .utf8)!
        
        let result = AccountStore.parseJSON(json)
        guard case .success(let parsed) = result else {
            XCTFail("Expected success")
            return
        }
        
        XCTAssertEqual(parsed.accounts.count, 2)
        XCTAssertEqual(parsed.accounts[0].label, "good")
        XCTAssertEqual(parsed.accounts[1].label, "also-good")
    }
    
    func testFailsWhenAllAccountsMissingRequiredFields() {
        let json = """
        {
            "accounts": [
                {"label": "no-token"},
                {"accessToken": "no-label"}
            ]
        }
        """.data(using: .utf8)!
        
        let result = AccountStore.parseJSON(json)
        guard case .failure = result else {
            XCTFail("Expected failure when no valid accounts")
            return
        }
    }
    
    // MARK: - Token Expiry
    
    func testTokenExpiredWhenExpiresAtInPast() {
        let pastMs = (Date().timeIntervalSince1970 - 60) * 1000
        let account = MCCAccount(label: "test", accessToken: "tok", expiresAt: pastMs)
        XCTAssertTrue(account.isTokenExpired)
    }
    
    func testTokenNotExpiredWhenExpiresAtInFuture() {
        let futureMs = (Date().timeIntervalSince1970 + 3600) * 1000
        let account = MCCAccount(label: "test", accessToken: "tok", expiresAt: futureMs)
        XCTAssertFalse(account.isTokenExpired)
    }
    
    func testTokenNotExpiredWhenNoExpiresAt() {
        let account = MCCAccount(label: "test", accessToken: "tok", expiresAt: nil)
        XCTAssertFalse(account.isTokenExpired)
    }
    
    // MARK: - File Access
    
    func testFailsWhenFileDoesNotExist() {
        let bogusPath = URL(fileURLWithPath: "/tmp/nonexistent-mcc-test-\(UUID().uuidString).json")
        let result = AccountStore.parseFile(at: bogusPath)
        guard case .failure(let error) = result else {
            XCTFail("Expected failure")
            return
        }
        XCTAssertTrue(error.message.lowercased().contains("not found"))
    }
    
    func testParsesValidFile() throws {
        let tmpFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("mcc-test-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tmpFile) }
        
        let json = """
        {
            "accounts": [
                {"label": "personal", "accessToken": "tok-1", "expiresAt": 9999999999999}
            ],
            "activeLabel": "personal"
        }
        """
        try json.write(to: tmpFile, atomically: true, encoding: .utf8)
        
        let result = AccountStore.parseFile(at: tmpFile)
        guard case .success(let parsed) = result else {
            XCTFail("Expected success, got \(result)")
            return
        }
        XCTAssertEqual(parsed.accounts.count, 1)
        XCTAssertEqual(parsed.accounts[0].label, "personal")
        XCTAssertEqual(parsed.activeLabel, "personal")
    }
    
    func testHandlesCorruptedFile() throws {
        let tmpFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("mcc-test-corrupt-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tmpFile) }
        
        try "{{{{not valid json".write(to: tmpFile, atomically: true, encoding: .utf8)
        
        let result = AccountStore.parseFile(at: tmpFile)
        guard case .failure = result else {
            XCTFail("Expected failure for corrupt file")
            return
        }
    }
    
    // MARK: - MCCAccount Equatable
    
    func testAccountEquality() {
        let a = MCCAccount(label: "personal", accessToken: "tok-1", expiresAt: 1000)
        let b = MCCAccount(label: "personal", accessToken: "tok-1", expiresAt: 1000)
        let c = MCCAccount(label: "work", accessToken: "tok-2", expiresAt: 2000)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }
}
