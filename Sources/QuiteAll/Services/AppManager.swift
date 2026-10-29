import AppKit
import Darwin
import Foundation

public final class AppManager {
    public static let shared = AppManager()
    
    /// Injectable termination handler for testing and isolation
    public var terminationHandler: ((_ app: AppItem, _ force: Bool) -> Bool)?
    
    /// Injectable application launcher for testing relaunch functionality
    public var appLauncher: ((_ url: URL, _ completion: @escaping (Bool) -> Void) -> Void)?
    
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
    
    /// Returns true if the bundle ID belongs to permanently shielded macOS services
    public static func isPermanentlyProtected(bundleID: String?) -> Bool {
        guard let bundleID = bundleID else { return false }
        return defaultProtectedBundleIDs.contains(bundleID)
    }
    
    // Popular media apps to protect when "Skip Music Apps" is enabled
    public static var mediaBundleIDs: Set<String> {
        SmartMediaDetector.supportedMediaBundleIDs
    }
    
    /// Evaluates whether an application should be shielded from termination
    public func shouldProtect(
        bundleID: String?,
        userProtectedIDs: Set<String>,
        skipMusicApps: Bool
    ) -> Bool {
        guard let bundleID = bundleID else { return false }
        
        // 1. Essential system services (Finder, Dock, Control Center) are permanently shielded
        if AppManager.isPermanentlyProtected(bundleID: bundleID) {
            return true
        }
        
        // 2. User custom whitelisted apps
        if userProtectedIDs.contains(bundleID) {
            return true
        }
        
        // 3. Smart media player protection
        if SmartMediaDetector.shared.isMediaApp(bundleID: bundleID) {
            if skipMusicApps {
                return true
            }
            if SmartMediaDetector.shared.isActivelyPlaying(bundleID: bundleID) {
                return true
            }
        }
        
        return false
    }
    
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
            
            let bundleID = app.bundleIdentifier
            let isProtected = shouldProtect(
                bundleID: bundleID,
                userProtectedIDs: protectedIDs,
                skipMusicApps: skipMusicApps
            )
            
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
        
        if let customHandler = terminationHandler {
            return customHandler(app, false)
        }
        
        guard let runningApp = NSRunningApplication(processIdentifier: app.id) else {
            return false
        }
        
        let success = runningApp.terminate()
        ProcessMonitor.shared.remove(pid: app.id)
        return success
    }
    
    /// Force quits a single application immediately via SIGKILL
    @discardableResult
    public func forceQuit(app: AppItem) -> Bool {
        if app.bundleIdentifier == "com.apple.finder" {
            closeFinderWindows()
            return true
        }
        
        if let customHandler = terminationHandler {
            return customHandler(app, true)
        }
        
        if let runningApp = NSRunningApplication(processIdentifier: app.id) {
            _ = runningApp.forceTerminate()
        }
        
        // Dispatch direct POSIX SIGKILL to immediately terminate unresponsive tasks
        let killResult = Darwin.kill(app.id, SIGKILL)
        ProcessMonitor.shared.remove(pid: app.id)
        return killResult == 0
    }

    
    /// Restarts / relaunches an application
    public func restart(app: AppItem, completion: (() -> Void)? = nil) {
        let bundleURL = app.url ?? (app.bundleIdentifier.flatMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) })
        guard let targetURL = bundleURL else {
            completion?()
            return
        }
        let pid = app.id
        
        // Terminate first
        quit(app: app)
        
        // If an injectable app launcher is configured (e.g. for testing), invoke it directly
        if let customLauncher = appLauncher {
            customLauncher(targetURL) { _ in
                DispatchQueue.main.async {
                    completion?()
                }
            }
            return
        }
        
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
            
            // Relaunch app via system workspace APIs
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: targetURL, configuration: configuration) { _, _ in
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
    
    /// Quits all applications except the frontmost/preserved application and protected apps
    public func quitOthers(allApps: [AppItem], force: Bool = false, preservingPID: pid_t? = nil) -> UInt64 {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        
        let targetPreservedPID: pid_t? = {
            if let preservingPID = preservingPID {
                return preservingPID
            }
            if let frontmost = NSWorkspace.shared.frontmostApplication,
               frontmost.processIdentifier != currentPID,
               allApps.contains(where: { $0.id == frontmost.processIdentifier }) {
                return frontmost.processIdentifier
            }
            return allApps.first(where: { $0.isActive })?.id
        }()
        
        let appsToQuit = allApps.filter { app in
            if let targetPreservedPID = targetPreservedPID, app.id == targetPreservedPID {
                return false
            }
            return !app.isProtected
        }
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
