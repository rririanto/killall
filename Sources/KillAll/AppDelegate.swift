import AppKit
import Foundation

public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusBarController: StatusBarController?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as menu bar accessory app (LSUIElement behavior)
        NSApp.setActivationPolicy(.accessory)
        
        let state = AppState.shared
        statusBarController = StatusBarController(state: state)
    }
    
    public func applicationWillTerminate(_ notification: Notification) {
        HotKeyManager.shared.unregisterAll()
        InactivityWatchdog.shared.stop()
    }
}
