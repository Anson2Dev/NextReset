import Foundation

/// A forecast of the selected plan's spendable pool, not the account's refill ledger.
package struct QuotaForecast {
    package let total: Double
    package let days: Double
    package let pace: Double?

    package init?(total: Double, days: Double, pace: Double?) {
        guard total.isFinite, total >= 0, days.isFinite, days > 0 else { return nil }
        self.total = total
        self.days = days
        self.pace = pace.flatMap { $0.isFinite && $0 >= 0 ? $0 : nil }
    }

    package var idealPace: Double { total / days }
    package var remainingAtReset: Double? { pace.map { max(0, total - $0 * days) } }
    /// Where the observed line ends on the time axis; stop at zero instead of going negative.
    package var endFraction: Double? {
        pace.map { rate in
            guard rate > 0 else { return 1 }
            return min(1, total / rate / days)
        }
    }
    // Ignore sub-second rounding differences in sampled pace at the ideal finish.
    package var runsOutEarly: Bool { endFraction.map { (1 - $0) * days * 86400 > 1 } ?? false }
}
