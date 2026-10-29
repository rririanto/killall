import AppKit
import Foundation

public final class AppManager {
    public static let shared = AppManager()
    
    // Default system protected apps (cannot be terminated or protected by default)
    public static let defaultProtectedBundleIDs: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.SystemUIServer",
        "com.apple.WindowManager",
        "com.apple.controlcenter",
        "com.apple.notificationcenterui",
        "com.apple.loginwindow"
    ]
    
    // Popular media apps to protect when "Skip Music Apps" is enabled
    public static let mediaBundleIDs: Set<String> = [
        "com.apple.Music",
        "com.spotify.client",
        "com.tidal.desktop",
        "com.apple.podcasts",
        "org.videolan.vlc",
        "com.amazon.music"
    ]
    
    private init() {}
    
    /// Get all running applications filtered according to settings
    public func fetchRunningApps(
        showBackground: Bool,
        protectedIDs: Set<String>,
        skipMusicApps: Bool
    ) -> [AppItem] {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications
        
        var result: [AppItem] = []
        
        for app in apps {
            // Exclude QuiteAll itself
            if app.processIdentifier == currentPID {
                continue
            }
            
            // Check activation policy
            if !showBackground && app.activationPolicy != .regular {
                continue
            }
            
            // Background daemons without name or prohibited policy
            if app.activationPolicy == .prohibited {
                continue
            }
            
            let bundleID = app.bundleIdentifier ?? ""
            var isProtected = protectedIDs.contains(bundleID) || AppManager.defaultProtectedBundleIDs.contains(bundleID)
            
            if skipMusicApps && AppManager.mediaBundleIDs.contains(bundleID) {
                isProtected = true
            }
            
            let metrics = ProcessMonitor.shared.metrics(for: app.processIdentifier)
            
            let item = AppItem(
                runningApp: app,
                cpuPercent: metrics.cpuPercent,
                memoryBytes: metrics.memoryBytes,
                isProtected: isProtected,
                isSelected: !isProtected // by default select apps that are not protected
            )
            result.append(item)
        }
        
        return result
    }
    
    /// Quits a single application gracefully
    @discardableResult
    public func quit(app: AppItem) -> Bool {
        // Handle Finder specifically
        if app.bundleIdentifier == "com.apple.finder" {
            closeFinderWindows()
            return true
        }
        
        guard let runningApp = NSRunningApplication(processIdentifier: app.id) else {
            return false
        }
        
        let success = runningApp.terminate()
        ProcessMonitor.shared.remove(pid: app.id)
        return success
    }
    
    /// Force quits a single application immediately
    @discardableResult
    public func forceQuit(app: AppItem) -> Bool {
        if app.bundleIdentifier == "com.apple.finder" {
            closeFinderWindows()
            return true
        }
        
        guard let runningApp = NSRunningApplication(processIdentifier: app.id) else {
            return false
        }
        
        let success = runningApp.forceTerminate()
        ProcessMonitor.shared.remove(pid: app.id)
        return success
    }
    
    /// Restarts / relaunches an application
    public func restart(app: AppItem, completion: (() -> Void)? = nil) {
        guard let bundleURL = app.url else { return }
        let pid = app.id
        
        // Terminate first
        quit(app: app)
        
        // Wait asynchronously until the process exits, then relaunch
        DispatchQueue.global(qos: .userInitiated).async {
            var attempts = 0
            while attempts < 30 {
                if NSRunningApplication(processIdentifier: pid) == nil {
                    break
                }
                Thread.sleep(forTimeInterval: 0.1)
                attempts += 1
            }
            
            // Relaunch app
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, _ in
                DispatchQueue.main.async {
                    completion?()
                }
            }
        }
    }
    
    /// Quits an array of applications (optionally force-quits)
    /// Returns the total resident memory reclaimed in bytes
    public func quitBatch(apps: [AppItem], force: Bool) -> UInt64 {
        var reclaimedBytes: UInt64 = 0
        for app in apps {
            if app.isProtected { continue }
            reclaimedBytes += app.memoryBytes
            if force {
                forceQuit(app: app)
            } else {
                quit(app: app)
            }
        }
        return reclaimedBytes
    }
    
    /// Quits all applications except the currently frontmost active application
    public func quitOthers(allApps: [AppItem], force: Bool) -> UInt64 {
        let frontmostPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let appsToQuit = allApps.filter { $0.id != frontmostPID && !$0.isProtected }
        return quitBatch(apps: appsToQuit, force: force)
    }
    
    /// AppleScript to gracefully close Finder windows without killing Finder
    private func closeFinderWindows() {
        let script = "tell application \"Finder\" to close every window"
        if let appleScript = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            appleScript.executeAndReturnError(&errorInfo)
        }
    }
    
    /// AppleScript to empty Trash if requested
    public func emptyTrash() {
        let script = "tell application \"Finder\" to empty the trash"
        if let appleScript = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            appleScript.executeAndReturnError(&errorInfo)
        }
    }
    
    /// Reveal application bundle in Finder
    public func revealInFinder(app: AppItem) {
        if let url = app.url {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
    
    /// Toggle hide / unhide
    public func toggleHide(app: AppItem) {
        guard let runningApp = NSRunningApplication(processIdentifier: app.id) else { return }
        if runningApp.isHidden {
            runningApp.unhide()
        } else {
            runningApp.hide()
        }
    }
}
