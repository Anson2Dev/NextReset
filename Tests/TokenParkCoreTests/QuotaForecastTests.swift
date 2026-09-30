import XCTest
@testable import TokenParkCore

final class QuotaForecastTests: XCTestCase {
    func testSlowBalancedAndFastPaces() throws {
        let slow=try XCTUnwrap(QuotaForecast(total:134,days:3,pace:32))
        XCTAssertEqual(slow.remainingAtReset,38)
        XCTAssertEqual(slow.endFraction,1)
        XCTAssertFalse(slow.runsOutEarly)
        let balanced=try XCTUnwrap(QuotaForecast(total:120,days:3,pace:40))
        XCTAssertEqual(balanced.remainingAtReset,0)
        XCTAssertEqual(balanced.endFraction,1)
        XCTAssertFalse(balanced.runsOutEarly)
        let fast=try XCTUnwrap(QuotaForecast(total:120,days:3,pace:80))
        XCTAssertEqual(fast.remainingAtReset,0)
        XCTAssertEqual(fast.endFraction,0.5)
        XCTAssertTrue(fast.runsOutEarly)
    }
    func testIdealFinishDoesNotReportFloatingPointNoiseAsEarly() throws {
        let forecast=try XCTUnwrap(QuotaForecast(total:134,days:3,pace:(134.0/3).nextUp))
        XCTAssertFalse(forecast.runsOutEarly)
        XCTAssertTrue(try XCTUnwrap(QuotaForecast(total:134,days:3,pace:45)).runsOutEarly)
    }
    func testUnknownZeroAndInvalidValues() throws {
        XCTAssertNil(QuotaForecast(total:134,days:0,pace:32))
        XCTAssertNil(QuotaForecast(total:.infinity,days:3,pace:32))
        XCTAssertNil(QuotaForecast(total:-1,days:3,pace:32))
        let unknown=try XCTUnwrap(QuotaForecast(total:134,days:3,pace:nil))
        XCTAssertNil(unknown.remainingAtReset)
        XCTAssertNil(unknown.endFraction)
        XCTAssertEqual(QuotaForecast(total:134,days:3,pace:0)?.remainingAtReset,134)
        XCTAssertEqual(QuotaForecast(total:0,days:3,pace:32)?.endFraction,0)
        XCTAssertNil(QuotaForecast(total:134,days:3,pace:.nan)?.pace)
        XCTAssertNil(QuotaForecast(total:134,days:3,pace:-2)?.pace)
    }
}
