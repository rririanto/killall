import AppKit
import Foundation
import UserNotifications

public final class InactivityWatchdog {
    public static let shared = InactivityWatchdog()
    
    private var lastActiveDates: [pid_t: Date] = [:]
    private var timer: Timer?
    private let lock = NSLock()
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleAppActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func handleAppActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        lock.lock()
        lastActiveDates[app.processIdentifier] = Date()
        lock.unlock()
    }
    
    public func start(
        intervalMinutes: Int,
        protectedIDs: Set<String>,
        onAutoQuit: @escaping (String) -> Void
    ) {
        stop()
        guard intervalMinutes > 0 else { return }
        
        let intervalSeconds = TimeInterval(intervalMinutes * 60)
        
        // Populate initial dates
        lock.lock()
        for app in NSWorkspace.shared.runningApplications {
            if lastActiveDates[app.processIdentifier] == nil {
                lastActiveDates[app.processIdentifier] = app.launchDate ?? Date()
            }
        }
        lock.unlock()
        
        // Timer checks every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.checkInactiveApps(
                thresholdSeconds: intervalSeconds,
                protectedIDs: protectedIDs,
                onAutoQuit: onAutoQuit
            )
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkInactiveApps(
        thresholdSeconds: TimeInterval,
        protectedIDs: Set<String>,
        onAutoQuit: @escaping (String) -> Void
    ) {
        let now = Date()
        let frontmostPID = NSWorkspace.shared.frontmostApplication?.processIdentifier
        let apps = NSWorkspace.shared.runningApplications
        
        lock.lock()
        defer { lock.unlock() }
        
        for app in apps {
            let pid = app.processIdentifier
            if pid == frontmostPID {
                lastActiveDates[pid] = now
                continue
            }
            
            let bundleID = app.bundleIdentifier ?? ""
            if protectedIDs.contains(bundleID) || AppManager.defaultProtectedBundleIDs.contains(bundleID) {
                continue
            }
            
            // Only auto-quit regular applications
            if app.activationPolicy != .regular {
                continue
            }
            
            let lastActive = lastActiveDates[pid] ?? app.launchDate ?? now
            let elapsed = now.timeIntervalSince(lastActive)
            
            if elapsed >= thresholdSeconds {
                let appName = app.localizedName ?? "Application"
                app.terminate()
                lastActiveDates.removeValue(forKey: pid)
                DispatchQueue.main.async {
                    onAutoQuit(appName)
                }
            }
        }
    }
}
