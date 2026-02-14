import XCTest
@testable import ClaudeCodeUsage

final class FormattersTests: XCTestCase {
    
    func testPercentageFormatsWithOneDecimalAndPercentSign() {
        XCTAssertEqual(Formatters.percentage(42.567), "42.6%")
        XCTAssertEqual(Formatters.percentage(0), "0.0%")
        XCTAssertEqual(Formatters.percentage(100), "100.0%")
    }
    
    func testTimeRemainingReturnsNowForZeroOrNegative() {
        XCTAssertEqual(Formatters.timeRemaining(0), "now")
        XCTAssertEqual(Formatters.timeRemaining(-100), "now")
    }
    
    func testTimeRemainingShowsMinutesOnlyUnderOneHour() {
        XCTAssertEqual(Formatters.timeRemaining(300), "5m")
        XCTAssertEqual(Formatters.timeRemaining(59 * 60), "59m")
    }
    
    func testTimeRemainingShowsHoursAndMinutes() {
        XCTAssertEqual(Formatters.timeRemaining(3600), "1h 0m")
        XCTAssertEqual(Formatters.timeRemaining(3600 + 30 * 60), "1h 30m")
        XCTAssertEqual(Formatters.timeRemaining(5 * 3600 + 15 * 60), "5h 15m")
    }
}
