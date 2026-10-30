import XCTest
import AppKit
@testable import KillAll

final class KillAllTests: XCTestCase {
    func testFilterCategories() {
        XCTAssertEqual(FilterCategory.allCases.count, 5)
        XCTAssertEqual(FilterCategory.all.title, "All")
        XCTAssertEqual(FilterCategory.dock.title, "Dock Apps")
        XCTAssertEqual(FilterCategory.background.title, "Background")
        XCTAssertEqual(FilterCategory.resourceHogs.title, "High Usage")
        XCTAssertEqual(FilterCategory.protected.title, "Protected")
    }
    
    func testSortOptions() {
        XCTAssertEqual(SortOption.allCases.count, 5)
        XCTAssertEqual(SortOption.nameAsc.id, "nameAsc")
        XCTAssertEqual(SortOption.nameDesc.id, "nameDesc")
        XCTAssertEqual(SortOption.cpuDesc.id, "cpuDesc")
        XCTAssertEqual(SortOption.memoryDesc.id, "memoryDesc")
        XCTAssertEqual(SortOption.recent.id, "recent")
    }
    
    func testAppPolicy() {
        XCTAssertEqual(AppPolicy.standard.displayName, "Standard")
        XCTAssertEqual(AppPolicy.protected.displayName, "Protected")
        XCTAssertEqual(AppPolicy.alwaysQuit.displayName, "Always Quit")
    }
    
    func testDefaultProtectedAppsContainFinderAndDock() {
        XCTAssertTrue(AppManager.defaultProtectedBundleIDs.contains("com.apple.finder"))
        XCTAssertTrue(AppManager.defaultProtectedBundleIDs.contains("com.apple.dock"))
        XCTAssertTrue(AppManager.defaultProtectedBundleIDs.contains("com.apple.controlcenter"))
    }
    
    func testMediaBundleIDs() {
        XCTAssertTrue(AppManager.mediaBundleIDs.contains("com.spotify.client"))
        XCTAssertTrue(AppManager.mediaBundleIDs.contains("com.apple.Music"))
    }
    
    func testProcessMonitorForSelfAndInvalidPID() {
        let monitor = ProcessMonitor.shared
        let myPID = ProcessInfo.processInfo.processIdentifier
        let myMetrics = monitor.metrics(for: myPID)
        
        // Current process should have non-zero resident memory
        XCTAssertGreaterThan(myMetrics.memoryBytes, 0)
        
        // Invalid PID should return 0 memory and 0 cpu
        let invalidMetrics = monitor.metrics(for: 99999999)
        XCTAssertEqual(invalidMetrics.memoryBytes, 0)
        XCTAssertEqual(invalidMetrics.cpuPercent, 0.0)
        
        // Removal should succeed without crash
        monitor.remove(pid: myPID)
    }
    
    func testAppStateRAMFormatting() {
        let state = AppState.shared
        state.totalRAMBytes = 512 * 1024 * 1024 // 512 MB
        XCTAssertEqual(state.totalRAMFormatted, "512 MB")
        
        state.totalRAMBytes = 2 * 1024 * 1024 * 1024 // 2 GB
        XCTAssertEqual(state.totalRAMFormatted, "2.0 GB")
    }
    
    func testAppStateSelectionAndProtection() {
        let state = AppState.shared
        state.protectedBundleIDs = ["com.test.app"]
        XCTAssertTrue(state.protectedBundleIDs.contains("com.test.app"))
        
        state.toggleSelectAll()
        // Ensure no protected apps get selected
        for app in state.apps where app.isProtected {
            XCTAssertFalse(app.isSelected)
        }
    }
    
    func testSearchFilterByNameAndBundleID() {
        let state = AppState.shared
        let app1 = AppItem(id: 101, name: "Safari", bundleIdentifier: "com.apple.Safari")
        let app2 = AppItem(id: 102, name: "Xcode", bundleIdentifier: "com.apple.dt.Xcode")
        let app3 = AppItem(id: 103, name: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap")
        
        state.apps = [app1, app2, app3]
        state.selectedFilter = .all
        
        // 1. Filter by name (case-insensitive)
        state.searchText = "xcode"
        XCTAssertEqual(state.filteredAndSortedApps.count, 1)
        XCTAssertEqual(state.filteredAndSortedApps.first?.name, "Xcode")
        
        // 2. Filter by bundle ID
        state.searchText = "apple"
        XCTAssertEqual(state.filteredAndSortedApps.count, 2)
        XCTAssertTrue(state.filteredAndSortedApps.contains(where: { $0.name == "Safari" }))
        XCTAssertTrue(state.filteredAndSortedApps.contains(where: { $0.name == "Xcode" }))
        
        // 3. Clear filter returns all items
        state.searchText = ""
        XCTAssertEqual(state.filteredAndSortedApps.count, 3)
    }
    
    func testToggleSelectAllTogglesAllNonProtected() {
        let state = AppState.shared
        let app1 = AppItem(id: 201, name: "App One", bundleIdentifier: "com.test.one", isProtected: false, isSelected: false)
        let app2 = AppItem(id: 202, name: "App Two", bundleIdentifier: "com.test.two", isProtected: false, isSelected: false)
        let app3 = AppItem(id: 203, name: "Protected App", bundleIdentifier: "com.test.protected", isProtected: true, isSelected: false)
        
        state.apps = [app1, app2, app3]
        XCTAssertEqual(state.quitableCount, 2)
        XCTAssertEqual(state.selectedCount, 0)
        
        // First toggle: all non-protected should be selected
        state.toggleSelectAll()
        XCTAssertEqual(state.selectedCount, 2)
        XCTAssertTrue(state.apps.first(where: { $0.id == 201 })?.isSelected == true)
        XCTAssertTrue(state.apps.first(where: { $0.id == 202 })?.isSelected == true)
        XCTAssertFalse(state.apps.first(where: { $0.id == 203 })?.isSelected == true)
        
        // Second toggle: all should be deselected
        state.toggleSelectAll()
        XCTAssertEqual(state.selectedCount, 0)
        XCTAssertFalse(state.apps.first(where: { $0.id == 201 })?.isSelected == true)
        XCTAssertFalse(state.apps.first(where: { $0.id == 202 })?.isSelected == true)
    }
    
    func testToggleSelectAllWithSearchFilter() {
        let state = AppState.shared
        let app1 = AppItem(id: 401, name: "Discord", bundleIdentifier: "com.discord", isProtected: false, isSelected: false)
        let app2 = AppItem(id: 402, name: "Spotify", bundleIdentifier: "com.spotify.client", isProtected: false, isSelected: false)
        let app3 = AppItem(id: 403, name: "Slack", bundleIdentifier: "com.tinyspeck.slackmacgap", isProtected: false, isSelected: false)
        
        state.apps = [app1, app2, app3]
        state.selectedFilter = .all
        state.searchText = "spot"
        
        // When filtered to Spotify, toggleSelectAll should only select Spotify
        state.toggleSelectAll()
        XCTAssertTrue(state.apps.first(where: { $0.id == 402 })?.isSelected == true)
        XCTAssertFalse(state.apps.first(where: { $0.id == 401 })?.isSelected == true)
        XCTAssertFalse(state.apps.first(where: { $0.id == 403 })?.isSelected == true)
        
        // Reset search filter
        state.searchText = ""
    }
    
    func testMenuBarBadgeRunningCount() {
        let state = AppState.shared
        XCTAssertTrue(state.showAppCountInMenuBar)
        
        let app1 = AppItem(id: 301, name: "Terminal", bundleIdentifier: "com.apple.Terminal", isProtected: false)
        let app2 = AppItem(id: 302, name: "Finder", bundleIdentifier: "com.apple.finder", isProtected: true)
        
        state.apps = [app1, app2]
        state.totalRunningCount = state.apps.count
        
        XCTAssertEqual(state.totalRunningCount, 2)
        XCTAssertEqual(state.quitableCount, 1)
    }
    
    func testAppItemFormattedCPUAndMemory() {
        let item = AppItem(
            id: 501,
            name: "HeavyApp",
            cpuPercent: 55.4,
            memoryBytes: 1536 * 1024 * 1024 // 1.5 GB
        )
        XCTAssertEqual(item.formattedCPU, "55.4%")
        XCTAssertEqual(item.formattedMemory, "1.5 GB")
        
        let smallItem = AppItem(
            id: 502,
            name: "SmallApp",
            cpuPercent: 0.2,
            memoryBytes: 50 * 1024 * 1024 // 50 MB
        )
        XCTAssertEqual(smallItem.formattedCPU, "0.2%")
        XCTAssertEqual(smallItem.formattedMemory, "50 MB")
    }
    
    func testActionButtonTitleDynamicSelectionAndOptionModifier() {
        let state = AppState.shared
        let app1 = AppItem(id: 601, name: "AppOne", bundleIdentifier: "com.test.app1", isProtected: false, isSelected: true)
        let app2 = AppItem(id: 602, name: "AppTwo", bundleIdentifier: "com.test.app2", isProtected: false, isSelected: true)
        let protectedApp = AppItem(id: 603, name: "ProtApp", bundleIdentifier: "com.test.prot", isProtected: true, isSelected: false)
        
        state.apps = [app1, app2, protectedApp]
        state.isOptionKeyPressed = false
        
        // Both quitable apps are selected -> "Quit All"
        XCTAssertEqual(state.selectedCount, 2)
        XCTAssertEqual(state.quitableCount, 2)
        XCTAssertEqual(state.actionButtonTitle, "Quit All")
        XCTAssertFalse(state.isActionButtonDisabled)
        
        // Hold Option key -> "Force Quit All"
        state.isOptionKeyPressed = true
        XCTAssertEqual(state.actionButtonTitle, "Force Quit All")
        
        // Select only 1 app without Option -> "Quit Selected (1)"
        state.isOptionKeyPressed = false
        state.apps[0].isSelected = true
        state.apps[1].isSelected = false
        XCTAssertEqual(state.selectedCount, 1)
        XCTAssertEqual(state.actionButtonTitle, "Quit Selected (1)")
        XCTAssertFalse(state.isActionButtonDisabled)
        
        // Select only 1 app with Option -> "Force Quit Selected (1)"
        state.isOptionKeyPressed = true
        XCTAssertEqual(state.actionButtonTitle, "Force Quit Selected (1)")
        
        // 0 apps selected -> button is disabled
        state.isOptionKeyPressed = false
        state.apps[0].isSelected = false
        XCTAssertEqual(state.selectedCount, 0)
        XCTAssertTrue(state.isActionButtonDisabled)
    }
    
    func testQuitBatchDispatchesGracefulVsForceTermination() {
        let manager = AppManager.shared
        defer { manager.terminationHandler = nil }
        
        var terminatedCalls: [(id: pid_t, force: Bool)] = []
        manager.terminationHandler = { app, force in
            terminatedCalls.append((id: app.id, force: force))
            return true
        }
        
        let app1 = AppItem(id: 701, name: "NormalApp", memoryBytes: 500 * 1024 * 1024, isProtected: false)
        let app2 = AppItem(id: 702, name: "ProtectedApp", memoryBytes: 200 * 1024 * 1024, isProtected: true)
        let app3 = AppItem(id: 703, name: "AnotherApp", memoryBytes: 300 * 1024 * 1024, isProtected: false)
        
        // 1. Graceful Batch Quit
        let reclaimedGraceful = manager.quitBatch(apps: [app1, app2, app3], force: false)
        XCTAssertEqual(reclaimedGraceful, (500 + 300) * 1024 * 1024)
        XCTAssertEqual(terminatedCalls.count, 2)
        XCTAssertEqual(terminatedCalls[0].id, 701)
        XCTAssertFalse(terminatedCalls[0].force)
        XCTAssertEqual(terminatedCalls[1].id, 703)
        XCTAssertFalse(terminatedCalls[1].force)
        
        // 2. Force Batch Quit (SIGKILL dispatch)
        terminatedCalls.removeAll()
        let reclaimedForce = manager.quitBatch(apps: [app1, app2, app3], force: true)
        XCTAssertEqual(reclaimedForce, (500 + 300) * 1024 * 1024)
        XCTAssertEqual(terminatedCalls.count, 2)
        XCTAssertEqual(terminatedCalls[0].id, 701)
        XCTAssertTrue(terminatedCalls[0].force)
        XCTAssertEqual(terminatedCalls[1].id, 703)
        XCTAssertTrue(terminatedCalls[1].force)
    }
    
    func testQuitOthersPreservesFrontmostAppAndProtectedApps() {
        let manager = AppManager.shared
        defer { manager.terminationHandler = nil }
        
        var terminatedIDs: [pid_t] = []
        manager.terminationHandler = { app, _ in
            terminatedIDs.append(app.id)
            return true
        }
        
        let frontmostApp = AppItem(id: 801, name: "Xcode", isActive: true, memoryBytes: 800 * 1024 * 1024, isProtected: false)
        let protectedApp = AppItem(id: 802, name: "Finder", isActive: false, memoryBytes: 150 * 1024 * 1024, isProtected: true)
        let quitableApp1 = AppItem(id: 803, name: "Slack", isActive: false, memoryBytes: 400 * 1024 * 1024, isProtected: false)
        let quitableApp2 = AppItem(id: 804, name: "Chrome", isActive: false, memoryBytes: 600 * 1024 * 1024, isProtected: false)
        
        let allApps = [frontmostApp, protectedApp, quitableApp1, quitableApp2]
        
        // 1. Explicit preservingPID preserves that app and skips protected apps
        let reclaimed = manager.quitOthers(allApps: allApps, force: false, preservingPID: 801)
        XCTAssertEqual(reclaimed, (400 + 600) * 1024 * 1024)
        XCTAssertEqual(terminatedIDs.count, 2)
        XCTAssertTrue(terminatedIDs.contains(803))
        XCTAssertTrue(terminatedIDs.contains(804))
        XCTAssertFalse(terminatedIDs.contains(801)) // Frontmost preserved!
        XCTAssertFalse(terminatedIDs.contains(802)) // Protected preserved!
        
        // 2. Without preservingPID, falls back to active app
        terminatedIDs.removeAll()
        let reclaimedFallback = manager.quitOthers(allApps: allApps, force: false, preservingPID: nil)
        XCTAssertEqual(reclaimedFallback, (400 + 600) * 1024 * 1024)
        XCTAssertEqual(terminatedIDs.count, 2)
        XCTAssertFalse(terminatedIDs.contains(801))
        XCTAssertFalse(terminatedIDs.contains(802))
    }
    
    func testRestartApplicationTerminatesAndRelaunches() {
        let manager = AppManager.shared
        defer {
            manager.terminationHandler = nil
            manager.appLauncher = nil
        }
        
        var terminatedPID: pid_t?
        manager.terminationHandler = { app, _ in
            terminatedPID = app.id
            return true
        }
        
        var relaunchedURL: URL?
        let expectation = expectation(description: "Relaunch completes")
        manager.appLauncher = { url, completion in
            relaunchedURL = url
            completion(true)
        }
        
        let testURL = URL(fileURLWithPath: "/Applications/Calculator.app")
        let app = AppItem(
            id: 9999,
            name: "Calculator",
            bundleIdentifier: "com.apple.calculator",
            url: testURL
        )
        
        manager.restart(app: app) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(terminatedPID, 9999)
        XCTAssertEqual(relaunchedURL, testURL)
    }
    
    func testAppStateTerminationActionDispatchAndSelectionIsolation() {
        let state = AppState.shared
        let originalSound = state.soundEnabled
        let originalHaptics = state.hapticsEnabled
        state.soundEnabled = false
        state.hapticsEnabled = false
        let manager = AppManager.shared
        defer {
            manager.terminationHandler = nil
            state.soundEnabled = originalSound
            state.hapticsEnabled = originalHaptics
        }
        
        var terminatedCalls: [(id: pid_t, force: Bool)] = []
        manager.terminationHandler = { app, force in
            terminatedCalls.append((id: app.id, force: force))
            return true
        }
        
        let app1 = AppItem(id: 1001, name: "SelectedUnprotected", memoryBytes: 400 * 1024 * 1024, isProtected: false, isSelected: true)
        let app2 = AppItem(id: 1002, name: "UnselectedUnprotected", memoryBytes: 300 * 1024 * 1024, isProtected: false, isSelected: false)
        let app3 = AppItem(id: 1003, name: "SelectedProtected", memoryBytes: 200 * 1024 * 1024, isProtected: true, isSelected: true)
        
        state.apps = [app1, app2, app3]
        
        // 1. quitSelected(force: false) -> only app1 terminated, app2 & app3 untouched
        state.quitSelected(force: false)
        XCTAssertEqual(terminatedCalls.count, 1)
        XCTAssertEqual(terminatedCalls.first?.id, 1001)
        XCTAssertFalse(terminatedCalls.first?.force ?? true)
        XCTAssertTrue(state.apps.first(where: { $0.id == 1001 })?.isTerminating == true)
        XCTAssertFalse(state.apps.first(where: { $0.id == 1002 })?.isTerminating == true)
        XCTAssertFalse(state.apps.first(where: { $0.id == 1003 })?.isTerminating == true)
        XCTAssertTrue(state.reclaimedMemoryMessage?.contains("400 MB") == true)
        
        // 2. quitAll(force: true) -> app1 and app2 terminated with force, app3 protected
        terminatedCalls.removeAll()
        state.apps = [app1, app2, app3]
        state.quitAll(force: true)
        XCTAssertEqual(terminatedCalls.count, 2)
        XCTAssertTrue(terminatedCalls.contains(where: { $0.id == 1001 && $0.force == true }))
        XCTAssertTrue(terminatedCalls.contains(where: { $0.id == 1002 && $0.force == true }))
        XCTAssertFalse(terminatedCalls.contains(where: { $0.id == 1003 }))
        XCTAssertTrue(state.reclaimedMemoryMessage?.contains("700 MB") == true)
    }
    
    func testDefaultProtectionInvariantsAndPersistence() {
        let state = AppState.shared
        
        // 1. Critical system apps must be in default protected set and identified as permanent
        XCTAssertTrue(AppManager.isPermanentlyProtected(bundleID: "com.apple.finder"))
        XCTAssertTrue(AppManager.isPermanentlyProtected(bundleID: "com.apple.dock"))
        XCTAssertTrue(AppManager.isPermanentlyProtected(bundleID: "com.apple.controlcenter"))
        XCTAssertFalse(AppManager.isPermanentlyProtected(bundleID: "com.google.Chrome"))
        
        // 2. Toggling protection on a permanent system app must never unprotect it
        let finderApp = AppItem(id: 1101, name: "Finder", bundleIdentifier: "com.apple.finder", isProtected: true, isSelected: false)
        state.apps = [finderApp]
        state.toggleProtection(app: finderApp)
        XCTAssertTrue(state.apps.first?.isProtected == true)
        XCTAssertTrue(state.protectedBundleIDs.contains("com.apple.finder"))
        
        // 3. Toggling protection on a regular app protects and deselects it
        let chromeApp = AppItem(id: 1102, name: "Chrome", bundleIdentifier: "com.google.Chrome", isProtected: false, isSelected: true)
        state.apps = [chromeApp]
        state.toggleProtection(app: chromeApp)
        XCTAssertTrue(state.apps.first?.isProtected == true)
        XCTAssertFalse(state.apps.first?.isSelected == true)
        XCTAssertTrue(state.protectedBundleIDs.contains("com.google.Chrome"))
        
        // 4. Persistence across reload: reload maintains user-protected and permanent system apps
        state.loadProtectedIDs()
        XCTAssertTrue(state.protectedBundleIDs.contains("com.google.Chrome"))
        XCTAssertTrue(state.protectedBundleIDs.contains("com.apple.finder"))
        XCTAssertTrue(state.protectedBundleIDs.contains("com.apple.dock"))
        XCTAssertTrue(state.protectedBundleIDs.contains("com.apple.controlcenter"))
        
        // 5. Unprotecting a custom app restores unshielded state and persists
        state.toggleProtection(app: state.apps[0])
        XCTAssertFalse(state.apps.first?.isProtected == true)
        XCTAssertFalse(state.protectedBundleIDs.contains("com.google.Chrome"))
    }
    
    func testSmartMediaDetectionAndProtection() {
        let detector = SmartMediaDetector.shared
        defer { detector.playbackStateChecker = nil }
        
        // 1. Identification of supported media bundle IDs
        XCTAssertTrue(detector.isMediaApp(bundleID: "com.spotify.client"))
        XCTAssertTrue(detector.isMediaApp(bundleID: "com.apple.Music"))
        XCTAssertTrue(detector.isMediaApp(bundleID: "com.tidal.desktop"))
        XCTAssertTrue(detector.isMediaApp(bundleID: "org.videolan.vlc"))
        XCTAssertFalse(detector.isMediaApp(bundleID: "com.apple.Safari"))
        XCTAssertFalse(detector.isMediaApp(bundleID: "com.apple.Terminal"))
        
        // 2. Playback state detection with injectable checker
        var queriedBundleIDs: [String] = []
        detector.playbackStateChecker = { bundleID in
            queriedBundleIDs.append(bundleID)
            return bundleID == "com.spotify.client"
        }
        
        XCTAssertTrue(detector.isActivelyPlaying(bundleID: "com.spotify.client"))
        XCTAssertFalse(detector.isActivelyPlaying(bundleID: "com.apple.Music"))
        XCTAssertFalse(detector.isActivelyPlaying(bundleID: "com.apple.Safari")) // Not a media app, checker not called
        XCTAssertEqual(queriedBundleIDs, ["com.spotify.client", "com.apple.Music"])
        
        // 3. AppManager policy calculation for media apps
        let manager = AppManager.shared
        
        // Case A: Skip music apps enabled -> media apps are protected
        let spotifyShouldProtect = manager.shouldProtect(
            bundleID: "com.spotify.client",
            userProtectedIDs: [],
            skipMusicApps: true
        )
        XCTAssertTrue(spotifyShouldProtect)
        
        // Case B: Skip music apps disabled, active playback detected -> protected
        let activePlaybackShouldProtect = manager.shouldProtect(
            bundleID: "com.spotify.client",
            userProtectedIDs: [],
            skipMusicApps: false
        )
        XCTAssertTrue(activePlaybackShouldProtect)
        
        // Case C: Skip music apps disabled, paused music player -> NOT protected
        let pausedShouldProtect = manager.shouldProtect(
            bundleID: "com.apple.Music",
            userProtectedIDs: [],
            skipMusicApps: false
        )
        XCTAssertFalse(pausedShouldProtect)
    }
    
    func testProtectionExclusionFromBulkTerminationAndSelection() {
        let state = AppState.shared
        let manager = AppManager.shared
        defer { manager.terminationHandler = nil }
        
        var terminatedIDs: [pid_t] = []
        manager.terminationHandler = { app, _ in
            terminatedIDs.append(app.id)
            return true
        }
        
        let sysProtectedApp = AppItem(id: 1201, name: "Dock", bundleIdentifier: "com.apple.dock", isProtected: true, isSelected: false)
        let userProtectedApp = AppItem(id: 1202, name: "Music", bundleIdentifier: "com.apple.Music", isProtected: true, isSelected: false)
        let standardApp1 = AppItem(id: 1203, name: "VSCode", bundleIdentifier: "com.microsoft.VSCode", isProtected: false, isSelected: false)
        let standardApp2 = AppItem(id: 1204, name: "Firefox", bundleIdentifier: "org.mozilla.firefox", isProtected: false, isSelected: false)
        
        state.apps = [sysProtectedApp, userProtectedApp, standardApp1, standardApp2]
        
        // 1. toggleSelect on protected apps must not select them
        state.toggleSelect(app: sysProtectedApp)
        XCTAssertFalse(state.apps.first(where: { $0.id == 1201 })?.isSelected == true)
        state.toggleSelect(app: userProtectedApp)
        XCTAssertFalse(state.apps.first(where: { $0.id == 1202 })?.isSelected == true)
        
        // 2. toggleSelect on regular app works
        state.toggleSelect(app: standardApp1)
        XCTAssertTrue(state.apps.first(where: { $0.id == 1203 })?.isSelected == true)
        
        // 3. quitableCount strictly ignores protected apps
        XCTAssertEqual(state.quitableCount, 2)
        XCTAssertEqual(state.selectedCount, 1)
        
        // 4. toggleSelectAll only selects non-protected apps
        state.toggleSelectAll()
        XCTAssertEqual(state.selectedCount, 2)
        XCTAssertFalse(state.apps.first(where: { $0.id == 1201 })?.isSelected == true)
        XCTAssertFalse(state.apps.first(where: { $0.id == 1202 })?.isSelected == true)
        XCTAssertTrue(state.apps.first(where: { $0.id == 1203 })?.isSelected == true)
        XCTAssertTrue(state.apps.first(where: { $0.id == 1204 })?.isSelected == true)
        
        // 5. quitSelected strictly excludes protected apps
        terminatedIDs.removeAll()
        state.quitSelected(force: false)
        XCTAssertEqual(terminatedIDs.count, 2)
        XCTAssertTrue(terminatedIDs.contains(1203))
        XCTAssertTrue(terminatedIDs.contains(1204))
        XCTAssertFalse(terminatedIDs.contains(1201))
        XCTAssertFalse(terminatedIDs.contains(1202))
        
        // 6. quitAll strictly excludes protected apps
        terminatedIDs.removeAll()
        state.apps = [sysProtectedApp, userProtectedApp, standardApp1, standardApp2]
        state.quitAll(force: true)
        XCTAssertEqual(terminatedIDs.count, 2)
        XCTAssertTrue(terminatedIDs.contains(1203))
        XCTAssertTrue(terminatedIDs.contains(1204))
        XCTAssertFalse(terminatedIDs.contains(1201))
        XCTAssertFalse(terminatedIDs.contains(1202))
        
        // 7. addProtectedBundleID and removeProtectedBundleID with permanent protection guard
        state.addProtectedBundleID("com.custom.app")
        XCTAssertTrue(state.protectedBundleIDs.contains("com.custom.app"))
        state.removeProtectedBundleID("com.custom.app")
        XCTAssertFalse(state.protectedBundleIDs.contains("com.custom.app"))
        
        // Permanent system apps cannot be removed via removeProtectedBundleID
        state.removeProtectedBundleID("com.apple.finder")
        XCTAssertTrue(state.protectedBundleIDs.contains("com.apple.finder"))
    }
    
    // MARK: - Inactivity Watchdog Tests
    
    func testInactivityWatchdogTimerMechanics() {
        let watchdog = InactivityWatchdog.shared
        defer {
            watchdog.stop()
            watchdog.resetForTesting()
        }
        
        XCTAssertFalse(watchdog.isRunning)
        
        // 1. Starting with interval 0 does not run
        watchdog.start(intervalMinutes: 0, protectedIDs: []) { _ in }
        XCTAssertFalse(watchdog.isRunning)
        
        // 2. Starting with positive interval sets isRunning
        watchdog.start(intervalMinutes: 15, protectedIDs: []) { _ in }
        XCTAssertTrue(watchdog.isRunning)
        
        // 3. Stop resets isRunning
        watchdog.stop()
        XCTAssertFalse(watchdog.isRunning)
        
        // 4. Threshold evaluation: idle app terminated, active app preserved
        let now = Date()
        var terminatedPIDs: [pid_t] = []
        
        let idleApp = MockWatchdogApp(
            pid: 2001,
            bundleIdentifier: "com.test.idle",
            localizedName: "IdleApp",
            launchDate: now.addingTimeInterval(-1800), // 30 mins ago
            activationPolicy: .regular
        ) {
            terminatedPIDs.append(2001)
        }
        
        let freshApp = MockWatchdogApp(
            pid: 2002,
            bundleIdentifier: "com.test.fresh",
            localizedName: "FreshApp",
            launchDate: now.addingTimeInterval(-300), // 5 mins ago
            activationPolicy: .regular
        ) {
            terminatedPIDs.append(2002)
        }
        
        watchdog.appsProvider = { [idleApp, freshApp] }
        watchdog.frontmostPIDProvider = { nil }
        watchdog.recordActivity(pid: 2001, date: now.addingTimeInterval(-1800))
        watchdog.recordActivity(pid: 2002, date: now.addingTimeInterval(-300))
        
        var autoQuitReported: [String] = []
        let terminatedNames = watchdog.checkInactiveApps(
            thresholdSeconds: 900, // 15 mins
            now: now,
            protectedIDs: []
        ) { name in
            autoQuitReported.append(name)
        }
        
        XCTAssertEqual(terminatedNames, ["IdleApp"])
        XCTAssertEqual(terminatedPIDs, [2001])
        XCTAssertEqual(autoQuitReported, ["IdleApp"])
    }
    
    func testInactivityWatchdogExcludesProtectedAndFrontmostApps() {
        let watchdog = InactivityWatchdog.shared
        defer {
            watchdog.stop()
            watchdog.resetForTesting()
        }
        
        let now = Date()
        var terminatedPIDs: [pid_t] = []
        
        let frontmostApp = MockWatchdogApp(
            pid: 2101,
            bundleIdentifier: "com.test.frontmost",
            localizedName: "FrontmostApp",
            launchDate: now.addingTimeInterval(-3600), // 1 hr ago
            activationPolicy: .regular
        ) {
            terminatedPIDs.append(2101)
        }
        
        let userProtectedApp = MockWatchdogApp(
            pid: 2102,
            bundleIdentifier: "com.test.userprotected",
            localizedName: "ProtectedApp",
            launchDate: now.addingTimeInterval(-3600),
            activationPolicy: .regular
        ) {
            terminatedPIDs.append(2102)
        }
        
        let defaultSystemApp = MockWatchdogApp(
            pid: 2103,
            bundleIdentifier: "com.apple.finder",
            localizedName: "Finder",
            launchDate: now.addingTimeInterval(-3600),
            activationPolicy: .regular
        ) {
            terminatedPIDs.append(2103)
        }
        
        let regularIdleApp = MockWatchdogApp(
            pid: 2104,
            bundleIdentifier: "com.test.regular",
            localizedName: "RegularApp",
            launchDate: now.addingTimeInterval(-3600),
            activationPolicy: .regular
        ) {
            terminatedPIDs.append(2104)
        }
        
        watchdog.appsProvider = { [frontmostApp, userProtectedApp, defaultSystemApp, regularIdleApp] }
        watchdog.frontmostPIDProvider = { 2101 } // 2101 is frontmost
        watchdog.recordActivity(pid: 2101, date: now.addingTimeInterval(-3600))
        watchdog.recordActivity(pid: 2102, date: now.addingTimeInterval(-3600))
        watchdog.recordActivity(pid: 2103, date: now.addingTimeInterval(-3600))
        watchdog.recordActivity(pid: 2104, date: now.addingTimeInterval(-3600))
        
        let terminatedNames = watchdog.checkInactiveApps(
            thresholdSeconds: 900, // 15 mins
            now: now,
            protectedIDs: ["com.test.userprotected"]
        )
        
        // Only regularIdleApp should be terminated; frontmost, userProtected, finder must survive
        XCTAssertEqual(terminatedNames, ["RegularApp"])
        XCTAssertEqual(terminatedPIDs, [2104])
        // Frontmost app activity timestamp must have been refreshed to now
        XCTAssertEqual(watchdog.lastActiveDate(for: 2101), now)
    }
    
    func testInactivityWatchdogRespectsPolicyAndActivationPolicy() {
        let watchdog = InactivityWatchdog.shared
        defer {
            watchdog.stop()
            watchdog.resetForTesting()
        }
        
        let now = Date()
        var terminatedPIDs: [pid_t] = []
        
        let backgroundApp = MockWatchdogApp(
            pid: 2201,
            bundleIdentifier: "com.test.daemon",
            localizedName: "Daemon",
            launchDate: now.addingTimeInterval(-3600),
            activationPolicy: .accessory // Non-regular
        ) {
            terminatedPIDs.append(2201)
        }
        
        let musicApp = MockWatchdogApp(
            pid: 2202,
            bundleIdentifier: "com.spotify.client",
            localizedName: "Spotify",
            launchDate: now.addingTimeInterval(-3600),
            activationPolicy: .regular
        ) {
            terminatedPIDs.append(2202)
        }
        
        watchdog.appsProvider = { [backgroundApp, musicApp] }
        watchdog.frontmostPIDProvider = { nil }
        watchdog.shouldProtect = { bundleID in
            bundleID == "com.spotify.client" // Smart protection policy
        }
        watchdog.recordActivity(pid: 2201, date: now.addingTimeInterval(-3600))
        watchdog.recordActivity(pid: 2202, date: now.addingTimeInterval(-3600))
        
        let terminatedNames = watchdog.checkInactiveApps(
            thresholdSeconds: 900,
            now: now,
            protectedIDs: []
        )
        
        XCTAssertTrue(terminatedNames.isEmpty)
        XCTAssertTrue(terminatedPIDs.isEmpty)
    }
    
    // MARK: - Carbon HotKeys & HUD Keyboard Navigation Tests
    
    func testHotKeyManagerRegistrationAndTrigger() {
        let manager = HotKeyManager.shared
        defer { manager.unregisterAll() }
        
        manager.unregisterAll()
        XCTAssertFalse(manager.isRegistered(action: .toggleHUD))
        XCTAssertFalse(manager.isRegistered(action: .forceQuitAll))
        XCTAssertFalse(manager.isRegistered(action: .quitOthers))
        
        var toggledHUDCount = 0
        manager.register(
            action: .toggleHUD,
            keyCode: 12, // Q key
            modifiers: HotKeyManager.modCmdOption
        ) {
            toggledHUDCount += 1
        }
        
        XCTAssertTrue(manager.isRegistered(action: .toggleHUD))
        let binding = manager.registeredBinding(action: .toggleHUD)
        XCTAssertNotNil(binding)
        XCTAssertEqual(binding?.keyCode, 12)
        XCTAssertEqual(binding?.modifiers, HotKeyManager.modCmdOption)
        
        // Trigger action callback directly
        manager.trigger(action: .toggleHUD)
        XCTAssertEqual(toggledHUDCount, 1)
        
        // Register Force Quit All (⌥⇧⌘Q)
        var forceQuitCount = 0
        manager.register(
            action: .forceQuitAll,
            keyCode: 12,
            modifiers: HotKeyManager.modCmdOptionShift
        ) {
            forceQuitCount += 1
        }
        XCTAssertTrue(manager.isRegistered(action: .forceQuitAll))
        let forceBinding = manager.registeredBinding(action: .forceQuitAll)
        XCTAssertEqual(forceBinding?.keyCode, 12)
        XCTAssertEqual(forceBinding?.modifiers, HotKeyManager.modCmdOptionShift)
        
        manager.trigger(action: .forceQuitAll)
        XCTAssertEqual(forceQuitCount, 1)
        
        // Register Quit Others (⌥⌘O)
        manager.register(
            action: .quitOthers,
            keyCode: 31, // O key
            modifiers: HotKeyManager.modCmdOption
        ) {}
        XCTAssertTrue(manager.isRegistered(action: .quitOthers))
        
        // Unregister single action
        manager.unregister(action: .toggleHUD)
        XCTAssertFalse(manager.isRegistered(action: .toggleHUD))
        XCTAssertTrue(manager.isRegistered(action: .forceQuitAll))
        
        // Unregister all
        manager.unregisterAll()
        XCTAssertFalse(manager.isRegistered(action: .forceQuitAll))
        XCTAssertFalse(manager.isRegistered(action: .quitOthers))
    }
    
    func testHUDKeyboardNavigationArrowSelectionAndSpaceToggle() {
        // Arrow navigation clamping
        let count = 4
        var index = 0
        
        // Down arrow navigates forward and clamps at count - 1
        index = HUDNavigationState.handleArrowNavigation(currentIndex: index, totalCount: count, isUp: false)
        XCTAssertEqual(index, 1)
        index = HUDNavigationState.handleArrowNavigation(currentIndex: index, totalCount: count, isUp: false)
        XCTAssertEqual(index, 2)
        index = HUDNavigationState.handleArrowNavigation(currentIndex: index, totalCount: count, isUp: false)
        XCTAssertEqual(index, 3)
        index = HUDNavigationState.handleArrowNavigation(currentIndex: index, totalCount: count, isUp: false)
        XCTAssertEqual(index, 3) // Clamped
        
        // Up arrow navigates backwards and clamps at 0
        index = HUDNavigationState.handleArrowNavigation(currentIndex: index, totalCount: count, isUp: true)
        XCTAssertEqual(index, 2)
        index = HUDNavigationState.handleArrowNavigation(currentIndex: index, totalCount: count, isUp: true)
        XCTAssertEqual(index, 1)
        index = HUDNavigationState.handleArrowNavigation(currentIndex: index, totalCount: count, isUp: true)
        XCTAssertEqual(index, 0)
        index = HUDNavigationState.handleArrowNavigation(currentIndex: index, totalCount: count, isUp: true)
        XCTAssertEqual(index, 0) // Clamped
        
        // Empty list handles gracefully
        XCTAssertEqual(HUDNavigationState.handleArrowNavigation(currentIndex: 0, totalCount: 0, isUp: false), 0)
        XCTAssertEqual(HUDNavigationState.handleArrowNavigation(currentIndex: 0, totalCount: 0, isUp: true), 0)
        
        // Space key toggles selection of highlighted item
        let state = AppState.shared
        let app1 = AppItem(id: 3001, name: "App1", bundleIdentifier: "com.test.app1", isProtected: false, isSelected: false)
        let app2 = AppItem(id: 3002, name: "App2", bundleIdentifier: "com.test.app2", isProtected: false, isSelected: false)
        state.apps = [app1, app2]
        
        // Highlighted item 0 (app1) toggles with space
        state.toggleSelect(app: state.apps[0])
        XCTAssertTrue(state.apps[0].isSelected)
        XCTAssertFalse(state.apps[1].isSelected)
        
        // Toggle off
        state.toggleSelect(app: state.apps[0])
        XCTAssertFalse(state.apps[0].isSelected)
    }
    
    func testHUDEscapeKeyDismissalPolicy() {
        var dismissed = false
        var clearedSearch = false
        
        let onDismiss = { dismissed = true }
        let onClearSearch = { clearedSearch = true }
        
        // When search text is empty: pressing Esc triggers onDismiss
        HUDNavigationState.handleEscapeKey(
            hasSearchText: false,
            clearSearch: onClearSearch,
            dismiss: onDismiss
        )
        XCTAssertTrue(dismissed)
        XCTAssertFalse(clearedSearch)
        
        // Reset
        dismissed = false
        clearedSearch = false
        
        // When search text is NOT empty: pressing Esc clears search and does NOT dismiss
        HUDNavigationState.handleEscapeKey(
            hasSearchText: true,
            clearSearch: onClearSearch,
            dismiss: onDismiss
        )
        XCTAssertFalse(dismissed)
        XCTAssertTrue(clearedSearch)
    }
    
    // MARK: - Audio Effects & Haptic Feedback Tests
    
    func testSoundServiceAudioAndHapticsDispatch() {
        let soundService = SoundService.shared
        defer {
            soundService.soundPlayer = nil
            soundService.hapticPerformer = nil
        }
        
        var playedSounds: [String] = []
        var performedHaptics: [NSHapticFeedbackManager.FeedbackPattern] = []
        
        soundService.soundPlayer = { sound in
            playedSounds.append(sound)
        }
        soundService.hapticPerformer = { pattern in
            performedHaptics.append(pattern)
        }
        
        // 1. Both enabled: playQuitSingle triggers "quit-single" and .generic haptic
        soundService.playQuitSingle(soundEnabled: true, hapticsEnabled: true)
        XCTAssertEqual(playedSounds, ["quit-single"])
        XCTAssertEqual(performedHaptics, [.generic])
        
        // 2. Sound disabled, haptics enabled
        playedSounds.removeAll()
        performedHaptics.removeAll()
        soundService.playQuitSingle(soundEnabled: false, hapticsEnabled: true)
        XCTAssertTrue(playedSounds.isEmpty)
        XCTAssertEqual(performedHaptics, [.generic])
        
        // 3. Sound enabled, haptics disabled
        playedSounds.removeAll()
        performedHaptics.removeAll()
        soundService.playQuitSingle(soundEnabled: true, hapticsEnabled: false)
        XCTAssertEqual(playedSounds, ["quit-single"])
        XCTAssertTrue(performedHaptics.isEmpty)
        
        // 4. PlayQuitAll triggers "quit-all" and .levelChange
        playedSounds.removeAll()
        performedHaptics.removeAll()
        soundService.playQuitAll(soundEnabled: true, hapticsEnabled: true)
        XCTAssertEqual(playedSounds, ["quit-all"])
        XCTAssertEqual(performedHaptics, [.levelChange])
        
        // 5. PlayRelaunch triggers "relaunch" and .alignment
        playedSounds.removeAll()
        performedHaptics.removeAll()
        soundService.playRelaunch(soundEnabled: true, hapticsEnabled: true)
        XCTAssertEqual(playedSounds, ["relaunch"])
        XCTAssertEqual(performedHaptics, [.alignment])
    }
    
    func testAppStateTerminationInvokesSoundAndHaptics() {
        let state = AppState.shared
        let soundService = SoundService.shared
        let originalSound = state.soundEnabled
        let originalHaptics = state.hapticsEnabled
        defer {
            soundService.soundPlayer = nil
            soundService.hapticPerformer = nil
            AppManager.shared.terminationHandler = nil
            state.soundEnabled = originalSound
            state.hapticsEnabled = originalHaptics
        }
        
        state.soundEnabled = true
        state.hapticsEnabled = true
        AppManager.shared.terminationHandler = { _, _ in true }
        
        var playedSounds: [String] = []
        var performedHaptics: [NSHapticFeedbackManager.FeedbackPattern] = []
        soundService.soundPlayer = { playedSounds.append($0) }
        soundService.hapticPerformer = { performedHaptics.append($0) }
        
        let app = AppItem(id: 4001, name: "QuitTarget", isProtected: false)
        state.apps = [app]
        
        // Single Quit triggers single sound & generic haptic
        state.quit(app: app)
        XCTAssertEqual(playedSounds, ["quit-single"])
        XCTAssertEqual(performedHaptics, [.generic])
        
        // Quit All triggers quit-all sound & levelChange haptic
        playedSounds.removeAll()
        performedHaptics.removeAll()
        state.apps = [app]
        state.quitAll(force: false)
        XCTAssertEqual(playedSounds, ["quit-all"])
        XCTAssertEqual(performedHaptics, [.levelChange])
    }
    
    // MARK: - Launch at Login & Settings Persistence Tests
    
    func testLaunchAtLoginStatusAndRegistration() {
        let launcher = LaunchAtLogin.shared
        defer {
            launcher.statusProvider = nil
            launcher.registerHandler = nil
            launcher.unregisterHandler = nil
        }
        
        var simulatedStatus: LaunchAtLoginStatus = .notRegistered
        launcher.statusProvider = { simulatedStatus }
        
        var registerCalled = false
        launcher.registerHandler = {
            registerCalled = true
            simulatedStatus = .enabled
        }
        
        var unregisterCalled = false
        launcher.unregisterHandler = {
            unregisterCalled = true
            simulatedStatus = .notRegistered
        }
        
        // 1. Initial status not registered -> isEnabled is false
        XCTAssertFalse(launcher.isEnabled)
        
        // 2. setEnabled(true) registers and updates status
        let enableResult = launcher.setEnabled(true)
        XCTAssertTrue(enableResult)
        XCTAssertTrue(registerCalled)
        XCTAssertTrue(launcher.isEnabled)
        
        // 3. setEnabled(true) again when already enabled does not re-register
        registerCalled = false
        let enableAgainResult = launcher.setEnabled(true)
        XCTAssertTrue(enableAgainResult)
        XCTAssertFalse(registerCalled)
        
        // 4. setEnabled(false) unregisters
        let disableResult = launcher.setEnabled(false)
        XCTAssertTrue(disableResult)
        XCTAssertTrue(unregisterCalled)
        XCTAssertFalse(launcher.isEnabled)
        
        // 5. Handling registration errors gracefully
        struct TestRegistrationError: Error {}
        launcher.registerHandler = {
            throw TestRegistrationError()
        }
        let failResult = launcher.setEnabled(true)
        XCTAssertFalse(failResult)
    }
    
    func testSettingsPersistenceAcrossReload() {
        let state = AppState.shared
        let defaults = UserDefaults.standard
        
        // Save original settings
        let origSound = state.soundEnabled
        let origHaptics = state.hapticsEnabled
        let origAutoQuit = state.autoQuitInactiveEnabled
        let origAutoMinutes = state.autoQuitInactiveMinutes
        let origShowBg = state.showBackgroundApps
        let origShowCount = state.showAppCountInMenuBar
        let origGroupBg = state.groupBackgroundApps
        let origSkipMusic = state.skipMusicApps
        
        defer {
            state.soundEnabled = origSound
            state.hapticsEnabled = origHaptics
            state.autoQuitInactiveEnabled = origAutoQuit
            state.autoQuitInactiveMinutes = origAutoMinutes
            state.showBackgroundApps = origShowBg
            state.showAppCountInMenuBar = origShowCount
            state.groupBackgroundApps = origGroupBg
            state.skipMusicApps = origSkipMusic
            state.updateInactivityWatchdog()
        }
        
        // 1. Mutate settings
        state.soundEnabled = false
        state.hapticsEnabled = false
        state.autoQuitInactiveMinutes = 30
        state.showBackgroundApps = true
        state.showAppCountInMenuBar = false
        state.groupBackgroundApps = false
        state.skipMusicApps = false
        state.autoQuitInactiveEnabled = true
        state.updateInactivityWatchdog()
        
        // 2. Verify UserDefaults persistence
        XCTAssertEqual(defaults.bool(forKey: "soundEnabled"), false)
        XCTAssertEqual(defaults.bool(forKey: "hapticsEnabled"), false)
        XCTAssertEqual(defaults.integer(forKey: "autoQuitInactiveMinutes"), 30)
        XCTAssertEqual(defaults.bool(forKey: "showBackgroundApps"), true)
        XCTAssertEqual(defaults.bool(forKey: "showAppCountInMenuBar"), false)
        XCTAssertEqual(defaults.bool(forKey: "groupBackgroundApps"), false)
        XCTAssertEqual(defaults.bool(forKey: "skipMusicApps"), false)
        XCTAssertEqual(defaults.bool(forKey: "autoQuitInactiveEnabled"), true)
        
        // 3. Verify Watchdog started
        XCTAssertTrue(InactivityWatchdog.shared.isRunning)
        
        // 4. Disable auto-quit and verify Watchdog stopped
        state.autoQuitInactiveEnabled = false
        state.updateInactivityWatchdog()
        XCTAssertFalse(InactivityWatchdog.shared.isRunning)
        XCTAssertEqual(defaults.bool(forKey: "autoQuitInactiveEnabled"), false)
    }
}













