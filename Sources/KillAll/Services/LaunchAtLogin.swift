import Foundation
import ServiceManagement

public enum LaunchAtLoginStatus {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

public final class LaunchAtLogin {
    public static let shared = LaunchAtLogin()
    
    public var statusProvider: (() -> LaunchAtLoginStatus)? = nil
    public var registerHandler: (() throws -> Void)? = nil
    public var unregisterHandler: (() throws -> Void)? = nil
    
    public var isEnabled: Bool {
        if let provider = statusProvider {
            return provider() == .enabled
        }
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    @discardableResult
    public func setEnabled(_ enable: Bool) -> Bool {
        if let register = registerHandler, let unregister = unregisterHandler {
            do {
                if enable {
                    if !isEnabled {
                        try register()
                    }
                } else {
                    if isEnabled {
                        try unregister()
                    }
                }
                return true
            } catch {
                print("Failed to update LaunchAtLogin: \(error)")
                return false
            }
        }
        
        if #available(macOS 13.0, *) {
            do {
                if enable {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                return true
            } catch {
                print("Failed to update LaunchAtLogin: \(error)")
                return false
            }
        }
        return false
    }
}

