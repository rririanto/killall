import AppKit
import Combine
import Foundation
import SwiftUI

public final class AppState: ObservableObject {
    public static let shared = AppState()
    
    // MARK: - Published State
    @Published public var apps: [AppItem] = []
    @Published public var searchText: String = ""
    @Published public var selectedFilter: FilterCategory = .all
    @Published public var sortOption: SortOption = .nameAsc
    @Published public var isOptionKeyPressed: Bool = false
    @Published public var reclaimedMemoryMessage: String? = nil
    @Published public var isHUDVisible: Bool = false
    @Published public var totalRunningCount: Int = 0
    @Published public var totalRAMBytes: UInt64 = 0
    
    // MARK: - Preferences (UserDefaults)
    @Published public var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published public var hapticsEnabled: Bool {
        didSet { UserDefaults.standard.set(hapticsEnabled, forKey: "hapticsEnabled") }
    }
    @Published public var showBackgroundApps: Bool {
        didSet { UserDefaults.standard.set(showBackgroundApps, forKey: "showBackgroundApps") }
    }
    @Published public var showAppCountInMenuBar: Bool {
        didSet { UserDefaults.standard.set(showAppCountInMenuBar, forKey: "showAppCountInMenuBar") }
    }
    @Published public var groupBackgroundApps: Bool {
        didSet { UserDefaults.standard.set(groupBackgroundApps, forKey: "groupBackgroundApps") }
    }
    @Published public var skipMusicApps: Bool {
        didSet { UserDefaults.standard.set(skipMusicApps, forKey: "skipMusicApps") }
    }
    @Published public var autoQuitInactiveEnabled: Bool {
        didSet { UserDefaults.standard.set(autoQuitInactiveEnabled, forKey: "autoQuitInactiveEnabled") }
    }
    @Published public var autoQuitInactiveMinutes: Int {
        didSet { UserDefaults.standard.set(autoQuitInactiveMinutes, forKey: "autoQuitInactiveMinutes") }
    }
    
    @Published public var protectedBundleIDs: Set<String> = []
    
    // MARK: - Internals
    private var metricsTimer: Timer?
    private var optionKeyMonitor: Any?
    private var workspaceCancellables = Set<AnyCancellable>()
    private var messageDismissWorkItem: DispatchWorkItem?
    
    private init() {
        let defaults = UserDefaults.standard
        self.soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        self.hapticsEnabled = defaults.object(forKey: "hapticsEnabled") as? Bool ?? true
        self.showBackgroundApps = defaults.object(forKey: "showBackgroundApps") as? Bool ?? false
        self.showAppCountInMenuBar = defaults.object(forKey: "showAppCountInMenuBar") as? Bool ?? true
        self.groupBackgroundApps = defaults.object(forKey: "groupBackgroundApps") as? Bool ?? true
        self.skipMusicApps = defaults.object(forKey: "skipMusicApps") as? Bool ?? true
        self.autoQuitInactiveEnabled = defaults.object(forKey: "autoQuitInactiveEnabled") as? Bool ?? false
        self.autoQuitInactiveMinutes = defaults.object(forKey: "autoQuitInactiveMinutes") as? Int ?? 60
        
        loadProtectedIDs()
        setupWorkspaceObservers()
        setupOptionKeyMonitor()
        refreshApps()
        updateInactivityWatchdog()
    }
    
    // MARK: - Filtered and Sorted Applications
    public var filteredAndSortedApps: [AppItem] {
        var result = apps
        
        // 1. Text Search filter
        if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = searchText.lowercased()
            result = result.filter { app in
                app.name.lowercased().contains(query) ||
                (app.bundleIdentifier?.lowercased().contains(query) ?? false)
            }
        }
        
        // 2. Category filter
        switch selectedFilter {
        case .all:
            break
        case .dock:
            result = result.filter { !$0.isBackground }
        case .background:
            result = result.filter { $0.isBackground }
        case .resourceHogs:
            result = result.filter { $0.cpuPercent >= 5.0 || $0.memoryBytes >= 500 * 1024 * 1024 }
        case .protected:
            result = result.filter { $0.isProtected }
        }
        
        // 3. Sorting
        switch sortOption {
        case .nameAsc:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDesc:
            result.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .cpuDesc:
            result.sort { $0.cpuPercent > $1.cpuPercent }
        case .memoryDesc:
            result.sort { $0.memoryBytes > $1.memoryBytes }
        case .recent:
            result.sort { ($0.launchDate ?? .distantPast) > ($1.launchDate ?? .distantPast) }
        }
        
        // 4. Optional grouping: place background apps at the bottom
        if groupBackgroundApps && selectedFilter == .all {
            result.sort { a, b in
                if a.isBackground == b.isBackground {
                    return false
                }
                return !a.isBackground && b.isBackground
            }
        }
        
        return result
    }
    
    public var selectedCount: Int {
        apps.filter { $0.isSelected && !$0.isProtected }.count
    }
    
    public var quitableCount: Int {
        apps.filter { !$0.isProtected }.count
    }
    
    public var totalRAMFormatted: String {
        let gb = Double(totalRAMBytes) / (1024.0 * 1024.0 * 1024.0)
        let mb = Double(totalRAMBytes) / (1024.0 * 1024.0)
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        } else {
            return String(format: "%.0f MB", mb)
        }
    }
    
    // MARK: - Actions
    
    public func refreshApps() {
        let fetched = AppManager.shared.fetchRunningApps(
            showBackground: showBackgroundApps,
            protectedIDs: protectedBundleIDs,
            skipMusicApps: skipMusicApps
        )
        
        // Preserve selection states where appropriate
        let currentSelections = Set(apps.filter { $0.isSelected }.map { $0.id })
        
        var totalBytes: UInt64 = 0
        let updatedApps = fetched.map { app -> AppItem in
            totalBytes += app.memoryBytes
            var mutable = app
            if currentSelections.contains(app.id) {
                mutable.isSelected = true
            }
            return mutable
        }
        
        DispatchQueue.main.async {
            self.apps = updatedApps
            self.totalRunningCount = updatedApps.count
            self.totalRAMBytes = totalBytes
        }
    }
    
    public func toggleSelect(app: AppItem) {
        if let idx = apps.firstIndex(where: { $0.id == app.id }) {
            apps[idx].isSelected.toggle()
        }
    }
    
    public func toggleSelectAll() {
        let isFiltered = !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedFilter != .all
        let targetApps = isFiltered
            ? filteredAndSortedApps.filter { !$0.isProtected }
            : apps.filter { !$0.isProtected }
        
        guard !targetApps.isEmpty else { return }
        
        let allSelected = targetApps.allSatisfy { $0.isSelected }
        let targetIDs = Set(targetApps.map { $0.id })
        
        for idx in apps.indices {
            if targetIDs.contains(apps[idx].id) && !apps[idx].isProtected {
                apps[idx].isSelected = !allSelected
            }
        }
    }
    
    public func toggleProtection(app: AppItem) {
        guard let bundleID = app.bundleIdentifier else { return }
        if protectedBundleIDs.contains(bundleID) {
            protectedBundleIDs.remove(bundleID)
        } else {
            protectedBundleIDs.insert(bundleID)
        }
        saveProtectedIDs()
        
        if let idx = apps.firstIndex(where: { $0.id == app.id }) {
            let isProt = protectedBundleIDs.contains(bundleID)
            apps[idx].isProtected = isProt
            if isProt {
                apps[idx].isSelected = false
            }
        }
    }
    
    public func quit(app: AppItem) {
        let reclaimed = app.memoryBytes
        SoundService.shared.playQuitSingle(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        AppManager.shared.quit(app: app)
        markTerminating(pid: app.id)
        showReclaimMessage(bytes: reclaimed)
    }
    
    public func forceQuit(app: AppItem) {
        let reclaimed = app.memoryBytes
        SoundService.shared.playQuitSingle(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        AppManager.shared.forceQuit(app: app)
        markTerminating(pid: app.id)
        showReclaimMessage(bytes: reclaimed)
    }
    
    public func restart(app: AppItem) {
        SoundService.shared.playRelaunch(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        AppManager.shared.restart(app: app) {
            self.refreshApps()
        }
        markTerminating(pid: app.id)
    }
    
    public func quitSelected(force: Bool = false) {
        let targets = apps.filter { $0.isSelected && !$0.isProtected }
        guard !targets.isEmpty else { return }
        
        SoundService.shared.playQuitAll(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        let reclaimed = AppManager.shared.quitBatch(apps: targets, force: force)
        for t in targets {
            markTerminating(pid: t.id)
        }
        showReclaimMessage(bytes: reclaimed)
    }
    
    public func quitAll(force: Bool = false) {
        let targets = apps.filter { !$0.isProtected }
        guard !targets.isEmpty else { return }
        
        SoundService.shared.playQuitAll(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        let reclaimed = AppManager.shared.quitBatch(apps: targets, force: force)
        for t in targets {
            markTerminating(pid: t.id)
        }
        showReclaimMessage(bytes: reclaimed)
    }
    
    public func quitOthers(force: Bool = false) {
        SoundService.shared.playQuitAll(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        let reclaimed = AppManager.shared.quitOthers(allApps: apps, force: force)
        showReclaimMessage(bytes: reclaimed)
        refreshApps()
    }
    
    public func freeMemoryQuickAction() {
        // Find top 3 memory-consuming unprotected apps
        let hogs = apps.filter { !$0.isProtected }.sorted { $0.memoryBytes > $1.memoryBytes }.prefix(3)
        guard !hogs.isEmpty else { return }
        
        SoundService.shared.playQuitAll(soundEnabled: soundEnabled, hapticsEnabled: hapticsEnabled)
        let reclaimed = AppManager.shared.quitBatch(apps: Array(hogs), force: false)
        for h in hogs {
            markTerminating(pid: h.id)
        }
        showReclaimMessage(bytes: reclaimed, prefix: "Memory Boost: Reclaimed ")
    }
    
    // MARK: - Visual Reclaim Message
    
    private func showReclaimMessage(bytes: UInt64, prefix: String = "✨ Reclaimed ") {
        guard bytes > 0 else { return }
        let mb = Double(bytes) / (1024.0 * 1024.0)
        let gb = mb / 1024.0
        let formatted = gb >= 1.0 ? String(format: "%.1f GB", gb) : String(format: "%.0f MB", mb)
        
        messageDismissWorkItem?.cancel()
        reclaimedMemoryMessage = "\(prefix)\(formatted) RAM"
        
        let workItem = DispatchWorkItem { [weak self] in
            withAnimation(.spring()) {
                self?.reclaimedMemoryMessage = nil
            }
        }
        messageDismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: workItem)
    }
    
    private func markTerminating(pid: pid_t) {
        if let idx = apps.firstIndex(where: { $0.id == pid }) {
            apps[idx].isTerminating = true
        }
    }
    
    // MARK: - Background Metrics Polling
    
    public func startMetricsTimer() {
        stopMetricsTimer()
        // Refresh immediately, then every 1.2 seconds while HUD is open
        refreshApps()
        metricsTimer = Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { [weak self] _ in
            self?.refreshApps()
        }
    }
    
    public func stopMetricsTimer() {
        metricsTimer?.invalidate()
        metricsTimer = nil
    }
    
    // MARK: - Option Key Reactive Modifier
    
    private func setupOptionKeyMonitor() {
        optionKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            let isOption = event.modifierFlags.contains(.option)
            DispatchQueue.main.async {
                self?.isOptionKeyPressed = isOption
            }
            return event
        }
    }
    
    // MARK: - Workspace Notifications
    
    private func setupWorkspaceObservers() {
        let center = NSWorkspace.shared.notificationCenter
        
        center.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshApps() }
            .store(in: &workspaceCancellables)
        
        center.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notif in
                if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    ProcessMonitor.shared.remove(pid: app.processIdentifier)
                }
                self?.refreshApps()
            }
            .store(in: &workspaceCancellables)
        
        center.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.refreshApps() }
            .store(in: &workspaceCancellables)
    }
    
    // MARK: - Persistence & Watchdog
    
    private func loadProtectedIDs() {
        if let saved = UserDefaults.standard.stringArray(forKey: "protectedBundleIDs") {
            protectedBundleIDs = Set(saved)
        } else {
            // Default initial protected apps
            protectedBundleIDs = AppManager.defaultProtectedBundleIDs
            saveProtectedIDs()
        }
    }
    
    public func saveProtectedIDs() {
        UserDefaults.standard.set(Array(protectedBundleIDs), forKey: "protectedBundleIDs")
    }
    
    public func updateInactivityWatchdog() {
        if autoQuitInactiveEnabled {
            InactivityWatchdog.shared.start(
                intervalMinutes: autoQuitInactiveMinutes,
                protectedIDs: protectedBundleIDs
            ) { [weak self] appName in
                self?.showReclaimMessage(bytes: 0, prefix: "Auto-closed inactive \(appName)")
                self?.refreshApps()
            }
        } else {
            InactivityWatchdog.shared.stop()
        }
    }
}
