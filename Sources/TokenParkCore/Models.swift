import Foundation

package struct LimitWindow: Codable { package let usedPercent: Double; package let windowDurationMins: Int?; package let resetsAt: Double? }
package struct LimitBucket: Codable { package let primary: LimitWindow?; package let secondary: LimitWindow?; package let planType: String? }
package struct Credit: Codable, Identifiable { package let id: String; package let status: String; package let expiresAt: Double?; package var expiry: Date? { expiresAt.map(Date.init(timeIntervalSince1970:)) } }
package struct Credits: Codable { package let availableCount: Int; package let credits: [Credit]? }
package struct LimitResponse: Codable {
    package let rateLimits: LimitBucket?
    package let rateLimitsByLimitId: [String: LimitBucket]?
    package let rateLimitResetCredits: Credits?
    package let accountId: String?
    package var bucket: LimitBucket? { rateLimitsByLimitId?["codex"] ?? rateLimits }
    package var window: LimitWindow? {
        let windows = [bucket?.primary, bucket?.secondary].compactMap { $0 }
        return windows.first(where: { $0.windowDurationMins == 10080 }) ?? windows.first
    }
}
package struct Sample: Codable {
    package init(date: Date, used: Double, reset: Double, count: Int?, account: String) { self.date=date; self.used=used; self.reset=reset; self.count=count; self.account=account }
 package let date: Date; package let used: Double; package let reset: Double; package let count: Int?; package let account: String }
package struct Cache: Codable {
    package init(snapshot:LimitResponse, updated:Date, samples:[Sample]) { self.snapshot=snapshot; self.updated=updated; self.samples=samples }
 package let snapshot: LimitResponse; package let updated: Date; package let samples: [Sample] }
package struct Plan {
    package static func daily(left: Double, coupons: Int, days: Double) -> Double? {
        guard days.isFinite, days > 0, left.isFinite, (0...100).contains(left), coupons >= 0 else { return nil }
        let total = left + Double(coupons)*100
        return total / days
    }
    package static func observed(_ samples: [Sample], now: Date) -> Double? {
        let recent = samples.filter { now.timeIntervalSince($0.date) >= 0 && now.timeIntervalSince($0.date) <= 86400 }.sorted { $0.date < $1.date }
        guard recent.count >= 2 else { return nil }
        var seconds = 0.0, used = 0.0
        for (a,b) in zip(recent,recent.dropFirst()) {
            let dt = b.date.timeIntervalSince(a.date)
            guard dt > 0, dt <= 3600, a.account == b.account,
                  abs(a.reset-b.reset)<60, a.count == b.count, b.used >= a.used else { continue }
            seconds += dt; used += b.used-a.used
        }
        guard seconds >= 1800 else { return nil }
        return used / seconds * 86400
    }
}
