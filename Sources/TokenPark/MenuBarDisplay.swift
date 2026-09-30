import Foundation

enum MenuBarDisplay: String, CaseIterable, Identifiable {
    case progress
    case percentage
    case tickets

    var id: String { rawValue }
    var title: String {
        switch self {
        case .progress: return "Progress"
        case .percentage: return "Progress + number"
        case .tickets: return "Progress + number + bank tickets"
        }
    }
}
