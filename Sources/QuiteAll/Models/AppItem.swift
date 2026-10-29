import AppKit
import Foundation

public struct AppItem: Identifiable, Equatable, Hashable {
    public let id: pid_t
    public let name: String
    public let bundleIdentifier: String?
    public let icon: NSImage
    public let url: URL?
    public let activationPolicy: NSApplication.ActivationPolicy
    public var isActive: Bool
    public var isHidden: Bool
    public let launchDate: Date?
    
    // Live metrics
    public var cpuPercent: Double
    public var memoryBytes: UInt64
    
    // User state
    public var isProtected: Bool
    public var isSelected: Bool
    public var isTerminating: Bool
    
    public init(
        runningApp: NSRunningApplication,
        cpuPercent: Double = 0.0,
        memoryBytes: UInt64 = 0,
        isProtected: Bool = false,
        isSelected: Bool = false
    ) {
        self.id = runningApp.processIdentifier
        self.name = runningApp.localizedName ?? "Unknown Process"
        self.bundleIdentifier = runningApp.bundleIdentifier
        self.icon = runningApp.icon ?? NSWorkspace.shared.icon(for: .application)
        self.url = runningApp.bundleURL
        self.activationPolicy = runningApp.activationPolicy
        self.isActive = runningApp.isActive
        self.isHidden = runningApp.isHidden
        self.launchDate = runningApp.launchDate
        self.cpuPercent = cpuPercent
        self.memoryBytes = memoryBytes
        self.isProtected = isProtected
        self.isSelected = isSelected
        self.isTerminating = false
    }
    
    public var isBackground: Bool {
        activationPolicy != .regular
    }
    
    public var formattedMemory: String {
        let kb = Double(memoryBytes) / 1024.0
        let mb = kb / 1024.0
        let gb = mb / 1024.0
        
        if gb >= 1.0 {
            return String(format: "%.1f GB", gb)
        } else if mb >= 1.0 {
            return String(format: "%.0f MB", mb)
        } else {
            return String(format: "%.0f KB", kb)
        }
    }
    
    public var formattedCPU: String {
        return String(format: "%.1f%%", cpuPercent)
    }
    
    public static func == (lhs: AppItem, rhs: AppItem) -> Bool {
        lhs.id == rhs.id &&
        lhs.cpuPercent == rhs.cpuPercent &&
        lhs.memoryBytes == rhs.memoryBytes &&
        lhs.isProtected == rhs.isProtected &&
        lhs.isSelected == rhs.isSelected &&
        lhs.isActive == rhs.isActive &&
        lhs.isTerminating == rhs.isTerminating
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
