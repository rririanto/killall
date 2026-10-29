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
}

