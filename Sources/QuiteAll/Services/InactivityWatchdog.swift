import AppKit
import Foundation
import UserNotifications

public protocol WatchdogTargetApp {
    var pid: pid_t { get }
    var bundleIdentifier: String? { get }
    var localizedName: String? { get }
    var launchDate: Date? { get }
    var activationPolicy: NSApplication.ActivationPolicy { get }
    func terminate() -> Bool
}

extension NSRunningApplication: WatchdogTargetApp {
    public var pid: pid_t { processIdentifier }
}

public struct MockWatchdogApp: WatchdogTargetApp {
    public var pid: pid_t
    public var bundleIdentifier: String?
    public var localizedName: String?
    public var launchDate: Date?
    public var activationPolicy: NSApplication.ActivationPolicy
    public var onTerminate: (() -> Void)?
    
    public init(
        pid: pid_t,
        bundleIdentifier: String? = nil,
        localizedName: String? = nil,
        launchDate: Date? = nil,
        activationPolicy: NSApplication.ActivationPolicy = .regular,
        onTerminate: (() -> Void)? = nil
    ) {
        self.pid = pid
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
        self.launchDate = launchDate
        self.activationPolicy = activationPolicy
        self.onTerminate = onTerminate
    }
    
    public func terminate() -> Bool {
        onTerminate?()
        return true
    }
}

public final class InactivityWatchdog {
    public static let shared = InactivityWatchdog()
    
    private var lastActiveDates: [pid_t: Date] = [:]
    private var timer: Timer?
    private let lock = NSLock()
    private var protectedIDs: Set<String> = []
    
    public var isRunning: Bool {
        timer != nil
    }
    
    public var shouldProtect: ((String) -> Bool)? = nil
    public var appsProvider: (() -> [WatchdogTargetApp])? = nil
    public var frontmostPIDProvider: (() -> pid_t?)? = nil
    public var dateProvider: () -> Date = { Date() }
    
    private init() {
        setupObservers()
    }
    
    private func setupObservers() {
        let center = NSWorkspace.shared.notificationCenter
        center.addObserver(
            self,
            selector: #selector(handleAppActivated(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleAppDeactivated(_:)),
            name: NSWorkspace.didDeactivateApplicationNotification,
            object: nil
        )
        center.addObserver(
            self,
            selector: #selector(handleAppTerminated(_:)),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )
    }
    
    @objc private func handleAppActivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        recordActivity(pid: app.processIdentifier, date: dateProvider())
    }
    
    @objc private func handleAppDeactivated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        // When an app deactivates, its countdown starts from that moment
        recordActivity(pid: app.processIdentifier, date: dateProvider())
    }
    
    @objc private func handleAppTerminated(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
            return
        }
        lock.lock()
        lastActiveDates.removeValue(forKey: app.processIdentifier)
        lock.unlock()
    }
    
    public func recordActivity(pid: pid_t, date: Date = Date()) {
        lock.lock()
        lastActiveDates[pid] = date
        lock.unlock()
    }
    
    public func lastActiveDate(for pid: pid_t) -> Date? {
        lock.lock()
        defer { lock.unlock() }
        return lastActiveDates[pid]
    }
    
    public func updateProtectedIDs(_ ids: Set<String>) {
        lock.lock()
        defer { lock.unlock() }
        self.protectedIDs = ids
    }
    
    public func resetForTesting() {
        lock.lock()
        lastActiveDates.removeAll()
        protectedIDs.removeAll()
        lock.unlock()
        shouldProtect = nil
        appsProvider = nil
        frontmostPIDProvider = nil
        dateProvider = { Date() }
    }
    
    public func start(
        intervalMinutes: Int,
        protectedIDs: Set<String>,
        shouldProtect: ((String) -> Bool)? = nil,
        onAutoQuit: @escaping (String) -> Void
    ) {
        stop()
        guard intervalMinutes > 0 else { return }
        
        self.protectedIDs = protectedIDs
        self.shouldProtect = shouldProtect
        
        let intervalSeconds = TimeInterval(intervalMinutes * 60)
        let now = dateProvider()
        
        // Populate initial dates
        let apps: [WatchdogTargetApp] = appsProvider?() ?? NSWorkspace.shared.runningApplications
        lock.lock()
        for app in apps {
            if lastActiveDates[app.pid] == nil {
                lastActiveDates[app.pid] = app.launchDate ?? now
            }
        }
        lock.unlock()
        
        // Timer checks every 60 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.checkInactiveApps(
                thresholdSeconds: intervalSeconds,
                now: self.dateProvider(),
                onAutoQuit: onAutoQuit
            )
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
    }
    
    @discardableResult
    public func checkInactiveApps(
        thresholdSeconds: TimeInterval,
        now: Date = Date(),
        protectedIDs: Set<String>? = nil,
        onAutoQuit: ((String) -> Void)? = nil
    ) -> [String] {
        let currentProtected = protectedIDs ?? self.protectedIDs
        let frontmostPID = frontmostPIDProvider?() ?? NSWorkspace.shared.frontmostApplication?.processIdentifier
        let apps: [WatchdogTargetApp] = appsProvider?() ?? NSWorkspace.shared.runningApplications
        
        lock.lock()
        defer { lock.unlock() }
        
        var terminatedNames: [String] = []
        
        for app in apps {
            let pid = app.pid
            
            // 1. Frontmost app is never terminated; renew its active date
            if let fPID = frontmostPID, pid == fPID {
                lastActiveDates[pid] = now
                continue
            }
            
            let bundleID = app.bundleIdentifier ?? ""
            
            // 2. User-protected and default system services are never terminated
            if currentProtected.contains(bundleID) || AppManager.defaultProtectedBundleIDs.contains(bundleID) {
                continue
            }
            
            // 3. Custom policy protection (e.g. music apps actively playing)
            if let policy = shouldProtect, policy(bundleID) {
                continue
            }
            
            // 4. Only auto-quit regular applications (ignore background helpers / daemons)
            if app.activationPolicy != .regular {
                continue
            }
            
            let lastActive = lastActiveDates[pid] ?? app.launchDate ?? now
            let elapsed = now.timeIntervalSince(lastActive)
            
            if elapsed >= thresholdSeconds {
                let appName = app.localizedName ?? "Application"
                _ = app.terminate()
                lastActiveDates.removeValue(forKey: pid)
                terminatedNames.append(appName)
                if let onAutoQuit = onAutoQuit {
                    if Thread.isMainThread {
                        onAutoQuit(appName)
                    } else {
                        DispatchQueue.main.async {
                            onAutoQuit(appName)
                        }
                    }
                }
            }
        }
        
        return terminatedNames
    }
}

