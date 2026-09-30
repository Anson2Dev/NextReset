import Foundation

package struct Recommendation {
    package init(tickets:Int?, reason:String, provisional:Bool) { self.tickets=tickets; self.reason=reason; self.provisional=provisional }
    package let tickets: Int?
    package let reason: String
    package let provisional: Bool
}
extension Plan {
    /// Best fit among 0...3 tickets, not a global optimization proof.
    /// Expiring tickets are used first, with a one-hour redemption margin.
    package static func recommend(left:Double, reset:Date, now:Date,
                                  credits:[Credit], count:Int?, pace:Double?, windowDays:Double=7) -> Recommendation {
        let days=reset.timeIntervalSince(now)/86400
        guard days>0 else { return .init(tickets:nil,reason:"Refresh after the reset.",provisional:true) }
        guard let count else { return .init(tickets:nil,reason:"Ticket inventory is unavailable.",provisional:true) }
        if count == 0 { return .init(tickets:0,reason:"No reset tickets available.",provisional:false) }
        let known=credits.filter { $0.status=="available" && ($0.expiry ?? .distantPast)>now }.sorted { $0.expiry! < $1.expiry! }
        let maxTickets=min(3,count,known.count)
        guard maxTickets>0 else { return .init(tickets:nil,reason:"Exact ticket expiry is unavailable.",provisional:true) }
        func timely(_ n:Int,rate:Double)->Bool {
            guard n>0 else { return true }; guard rate>0 else { return false }
            for i in 0..<n {
                let spend=left+Double(i)*100
                let redeem=now.addingTimeInterval(spend/rate*86400)
                if redeem >= known[i].expiry!.addingTimeInterval(-3600) { return false }
            }
            return true
        }
        if let pace, pace.isFinite, pace>=0 {
            let feasible=(0...maxTickets).filter { n in
                timely(n,rate:pace) && (daily(left:left,coupons:n,days:days) ?? 0)>=pace
            }
            if let best=feasible.first {
                return .init(tickets:best,reason:"Fewest tickets covering your expected pace.",provisional:false)
            }
            let fallback=(0...maxTickets).last { timely($0,rate:pace) } ?? 0
            return .init(tickets:fallback,reason:"Demand exceeds the available plan, or a ticket expires too soon.",provisional:false)
        }
        // With insufficient history, suggest at most one ticket that cannot wait a full following cycle.
        if known[0].expiry! < reset.addingTimeInterval(windowDays*86400),
           let rate=daily(left:left,coupons:1,days:days),timely(1,rate:rate) {
            return .init(tickets:1,reason:"Estimate: the first ticket expires before the following reset.",provisional:true)
        }
        return .init(tickets:0,reason:"Estimate: preserve tickets while usage history builds.",provisional:true)
    }
}
