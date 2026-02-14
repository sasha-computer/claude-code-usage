import XCTest
@testable import ClaudeCodeUsage

final class LanguageTests: XCTestCase {
    
    func testNextLanguageCycles() {
        XCTAssertEqual(Language.ko.next, .en)
        XCTAssertEqual(Language.en.next, .ko)
    }
    
    func testLanguageLabels() {
        XCTAssertEqual(Language.ko.label, "KO")
        XCTAssertEqual(Language.en.label, "EN")
    }
}
