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
}
