import XCTest
@testable import ClaudeCodeUsage

final class UsageStatusTests: XCTestCase {
    
    func testNormalStatusBelow70Percent() {
        XCTAssertEqual(UsageStatus.from(percent: 0), .normal)
        XCTAssertEqual(UsageStatus.from(percent: 50), .normal)
        XCTAssertEqual(UsageStatus.from(percent: 69.9), .normal)
    }
    
    func testWarningStatusAt70To89Percent() {
        XCTAssertEqual(UsageStatus.from(percent: 70), .warning)
        XCTAssertEqual(UsageStatus.from(percent: 80), .warning)
        XCTAssertEqual(UsageStatus.from(percent: 89.9), .warning)
    }
    
    func testCriticalStatusAt90PercentAndAbove() {
        XCTAssertEqual(UsageStatus.from(percent: 90), .critical)
        XCTAssertEqual(UsageStatus.from(percent: 100), .critical)
    }
}
