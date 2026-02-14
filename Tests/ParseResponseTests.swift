import XCTest
@testable import ClaudeCodeUsage

final class ParseResponseTests: XCTestCase {
    
    let api = ClaudeUsageAPI()
    
    func testParsesValidUsageResponse() {
        let json = """
        {
            "five_hour": {
                "utilization": 42.5,
                "resets_at": "2026-02-14T18:00:00Z"
            },
            "seven_day": {
                "utilization": 15.3,
                "resets_at": "2026-02-20T00:00:00Z"
            }
        }
        """.data(using: .utf8)!
        
        let result = api.parseResponse(json)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fiveHourPercent, 42.5)
        XCTAssertEqual(result?.weeklyPercent, 15.3)
        XCTAssertNotNil(result?.fiveHourResetsAt)
        XCTAssertNotNil(result?.weeklyResetsAt)
    }
    
    func testReturnsNilForInvalidJSON() {
        let json = "not json".data(using: .utf8)!
        XCTAssertNil(api.parseResponse(json))
    }
    
    func testReturnsNilWhenNoUtilizationPresent() {
        let json = """
        {
            "five_hour": {},
            "seven_day": {}
        }
        """.data(using: .utf8)!
        XCTAssertNil(api.parseResponse(json))
    }
    
    func testClampsValuesAbove100() {
        let json = """
        {
            "five_hour": { "utilization": 150.0 },
            "seven_day": { "utilization": -20.0 }
        }
        """.data(using: .utf8)!
        
        let result = api.parseResponse(json)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.fiveHourPercent, 100.0)
        XCTAssertEqual(result?.weeklyPercent, 0.0)
    }
    
    func testParsesFractionalSecondsInDates() {
        let json = """
        {
            "five_hour": {
                "utilization": 10.0,
                "resets_at": "2026-02-14T18:00:00.123Z"
            },
            "seven_day": {
                "utilization": 5.0
            }
        }
        """.data(using: .utf8)!
        
        let result = api.parseResponse(json)
        XCTAssertNotNil(result?.fiveHourResetsAt)
        XCTAssertNil(result?.weeklyResetsAt)
    }
}
