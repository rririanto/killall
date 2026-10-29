import XCTest
import AppKit
@testable import QuiteAll

final class QuiteAllTests: XCTestCase {
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
}






