import Foundation

public enum AppPolicy: String, Codable, CaseIterable {
    case standard
    case protected // Never Quit / Whitelist
    case alwaysQuit
    
    public var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .protected: return "Protected"
        case .alwaysQuit: return "Always Quit"
        }
    }
}
