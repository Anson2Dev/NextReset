import XCTest
@testable import TokenParkCore

final class QuotaHeadroomTests: XCTestCase {
    func testBudgetRelativePaceAndBoundaries() {
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:100,pace:89),.comfortable)
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:100,pace:90),.balanced)
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:100,pace:110),.balanced)
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:100,pace:111),.tight)
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:0,pace:1),.tight)
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:0,pace:0),.balanced)
    }
    func testMissingOrInvalidDataIsNeverComfortable() {
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:nil,pace:10),.unknown)
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:10,pace:nil),.unknown)
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:10,pace:.nan),.unknown)
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:.infinity,pace:10),.unknown)
        XCTAssertEqual(QuotaHeadroom.evaluate(budget:10,pace:-1),.unknown)
    }
}
