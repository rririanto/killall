import Foundation
import ServiceManagement

public final class LaunchAtLogin {
    public static let shared = LaunchAtLogin()
    
    public var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        }
        return false
    }
    
    @discardableResult
    public func setEnabled(_ enable: Bool) -> Bool {
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
