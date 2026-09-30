import Foundation

public enum QuotaHeadroom: String {
    case comfortable, balanced, tight, unknown

    public static func evaluate(budget: Double?, pace: Double?) -> Self {
        guard let budget, let pace, budget.isFinite, pace.isFinite,
              budget >= 0, pace >= 0 else { return .unknown }
        if budget == 0 { return pace > 0 ? .tight : .balanced }
        if pace < budget * 0.9 { return .comfortable }
        if pace > budget * 1.1 { return .tight }
        return .balanced
    }

    public var label: String {
        switch self {
        case .comfortable: return "Comfortable quota headroom"
        case .balanced: return "Balanced quota headroom"
        case .tight: return "Tight quota headroom"
        case .unknown: return "Quota headroom unknown"
        }
    }
}
