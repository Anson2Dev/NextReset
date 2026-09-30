import XCTest
@testable import TokenParkCore

final class PlanningTests:XCTestCase {
    let now=Date(timeIntervalSince1970:1_800_000_000)
    func credit(_ id:Int,_ days:Double)->Credit {
        let json="{\"id\":\"test-\(id)\",\"status\":\"available\",\"expiresAt\":\(now.addingTimeInterval(days*86400).timeIntervalSince1970)}"
        return try! JSONDecoder().decode(Credit.self,from:Data(json.utf8))
    }
    func testDailyBudgetAndRepeatedBuffer() {
        XCTAssertEqual(Plan.daily(left:37,buffer:3,coupons:0,days:3)!,34/3.0,accuracy:0.001)
        XCTAssertEqual(Plan.daily(left:37,buffer:3,coupons:1,days:3)!,134/3.0,accuracy:0.001)
        XCTAssertEqual(Plan.daily(left:37,buffer:3,coupons:2,days:3)!,231/3.0,accuracy:0.001)
        XCTAssertEqual(Plan.daily(left:37,buffer:3,coupons:3,days:3)!,328/3.0,accuracy:0.001)
        XCTAssertNil(Plan.daily(left:37,buffer:3,coupons:1,days:0))
        XCTAssertNil(Plan.daily(left:37,buffer:3,coupons:-1,days:3))
        XCTAssertEqual(Plan.daily(left:2,buffer:3,coupons:1,days:1),100)
    }
    func testBestUsesFewestTicketsForExpectedDemand() {
        let cs=[credit(1,4),credit(2,20),credit(3,30)]
        func best(_ pace:Double?)->Recommendation { Plan.recommend(left:37,buffer:3,reset:now.addingTimeInterval(3*86400),now:now,credits:cs,count:3,pace:pace) }
        XCTAssertEqual(best(5).tickets,0)
        XCTAssertEqual(best(20).tickets,1)
        XCTAssertEqual(best(60).tickets,2)
        XCTAssertEqual(best(95).tickets,3)
        XCTAssertEqual(best(nil).tickets,1)
        XCTAssertTrue(best(nil).provisional)
    }
    func testNoFabricatedBestWhenExpiryMissing() {
        let result=Plan.recommend(left:37,buffer:3,reset:now.addingTimeInterval(3*86400),now:now,credits:[],count:3,pace:20)
        XCTAssertNil(result.tickets)
    }
    func testTicketCannotBeRecommendedAfterItsDeadline() {
        let result=Plan.recommend(left:90,buffer:3,reset:now.addingTimeInterval(3*86400),now:now,credits:[credit(1,0.1)],count:1,pace:50)
        XCTAssertEqual(result.tickets,0)
    }
    func testZeroTicketsStillReturnsNoTicket() {
        XCTAssertEqual(Plan.recommend(left:37,buffer:3,reset:now.addingTimeInterval(3*86400),now:now,credits:[],count:0,pace:20).tickets,0)
    }
    func testSamplingExcludesResetAccountAndLongGaps() {
        let first=Sample(date:now.addingTimeInterval(-1800),used:60,reset:100,count:3,account:"a")
        let good=Sample(date:now,used:61,reset:100,count:3,account:"a")
        XCTAssertEqual(Plan.observed([first,good],now:now),48)
        for s in [Sample(date:now,used:0,reset:200,count:2,account:"a"),
                  Sample(date:now,used:61,reset:100,count:3,account:"b"),
                  Sample(date:now.addingTimeInterval(4000),used:61,reset:100,count:3,account:"a")] {
            XCTAssertNil(Plan.observed([first,s],now:s.date))
        }
        XCTAssertNil(Plan.observed([good],now:now))
    }
    func testServiceResponseParsingAndAbsoluteExpiry() throws {
        let json="""
        {"rateLimits":{"primary":{"usedPercent":63,"windowDurationMins":10080,"resetsAt":1791046710}},"rateLimitResetCredits":{"availableCount":1,"credits":[{"id":"synthetic","status":"available","expiresAt":1791174013}]}}
        """
        let response=try JSONDecoder().decode(LimitResponse.self,from:Data(json.utf8))
        XCTAssertEqual(response.window?.usedPercent,63)
        let formatter=ISO8601DateFormatter();formatter.timeZone=TimeZone(secondsFromGMT:8*3600)
        XCTAssertEqual(formatter.string(from:response.rateLimitResetCredits!.credits![0].expiry!),"2026-10-05T12:20:13+08:00")
    }
}
