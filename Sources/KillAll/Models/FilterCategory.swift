import Foundation

public enum FilterCategory: String, CaseIterable, Identifiable {
    case all
    case dock
    case background
    case resourceHogs
    case protected
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .all: return "All"
        case .dock: return "Dock Apps"
        case .background: return "Background"
        case .resourceHogs: return "High Usage"
        case .protected: return "Protected"
        }
    }
    
    public var icon: String {
        switch self {
        case .all: return "square.grid.2x2"
        case .dock: return "macwindow"
        case .background: return "gearshape.2"
        case .resourceHogs: return "flame"
        case .protected: return "shield.fill"
        }
    }
}
