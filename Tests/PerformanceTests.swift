import XCTest
@testable import ClaudeCodeUsage

final class PerformanceTests: XCTestCase {
    
    // MARK: - Formatters
    
    func testPercentagePerformance() {
        measure {
            for i in 0..<10_000 {
                _ = Formatters.percentage(Double(i % 100))
            }
        }
    }
    
    func testTimeRemainingPerformance() {
        measure {
            for i in 0..<10_000 {
                _ = Formatters.timeRemaining(TimeInterval(i))
            }
        }
    }
    
    func testRelativeTimePerformance() {
        let dates = (0..<1_000).map { Date().addingTimeInterval(-Double($0) * 60) }
        measure {
            for date in dates {
                _ = Formatters.relativeTime(date)
            }
        }
    }
    
    func testResetDescriptionPerformance() {
        let dates = (1...1_000).map { Date().addingTimeInterval(Double($0) * 3600) }
        measure {
            for date in dates {
                _ = Formatters.resetDescription(date)
            }
        }
    }
    
    // MARK: - UsageStatus
    
    func testUsageStatusFromPerformance() {
        measure {
            for i in 0..<100_000 {
                _ = UsageStatus.from(percent: Double(i % 101))
            }
        }
    }
    
    // MARK: - API Response Parsing
    
    private let validJSON = """
    {
        "five_hour": {
            "utilization": 42.5,
            "resets_at": "2026-02-14T18:00:00.123Z"
        },
        "seven_day": {
            "utilization": 15.3,
            "resets_at": "2026-02-20T00:00:00Z"
        }
    }
    """.data(using: .utf8)!
    
    func testParseResponsePerformance() {
        let api = ClaudeUsageAPI()
        measure {
            for _ in 0..<1_000 {
                _ = api.parseResponse(validJSON)
            }
        }
    }
}
