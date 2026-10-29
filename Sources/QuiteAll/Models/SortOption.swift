import Foundation

public enum SortOption: String, CaseIterable, Identifiable {
    case nameAsc
    case nameDesc
    case cpuDesc
    case memoryDesc
    case recent
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .nameAsc: return "Name (A → Z)"
        case .nameDesc: return "Name (Z → A)"
        case .cpuDesc: return "Highest CPU"
        case .memoryDesc: return "Highest Memory"
        case .recent: return "Recently Launched"
        }
    }
    
    public var icon: String {
        switch self {
        case .nameAsc: return "arrow.up.circle"
        case .nameDesc: return "arrow.down.circle"
        case .cpuDesc: return "cpu"
        case .memoryDesc: return "memorychip"
        case .recent: return "clock"
        }
    }
}
