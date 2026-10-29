import AppKit
import Foundation

public final class SmartMediaDetector {
    public static let shared = SmartMediaDetector()
    
    /// Supported popular macOS audio & media players
    public static let supportedMediaBundleIDs: Set<String> = [
        "com.apple.Music",
        "com.spotify.client",
        "com.tidal.desktop",
        "com.apple.podcasts",
        "org.videolan.vlc",
        "com.amazon.music"
    ]
    
    /// Injectable playback state checker for unit testing and offline verification
    public var playbackStateChecker: ((_ bundleID: String) -> Bool)?
    
    private init() {}
    
    /// Identifies whether the given bundle ID belongs to a supported media/music application
    public func isMediaApp(bundleID: String?) -> Bool {
        guard let bundleID = bundleID else { return false }
        return SmartMediaDetector.supportedMediaBundleIDs.contains(bundleID)
    }
    
    /// Checks whether the media player is currently actively playing audio
    public func isActivelyPlaying(bundleID: String?) -> Bool {
        guard let bundleID = bundleID, isMediaApp(bundleID: bundleID) else {
            return false
        }
        
        if let customChecker = playbackStateChecker {
            return customChecker(bundleID)
        }
        
        return checkLivePlaybackState(bundleID: bundleID)
    }
    
    private func checkLivePlaybackState(bundleID: String) -> Bool {
        // Query running applications first so AppleScript never accidentally launches a stopped app
        let runningApps = NSWorkspace.shared.runningApplications
        guard runningApps.contains(where: { $0.bundleIdentifier == bundleID }) else {
            return false
        }
        
        switch bundleID {
        case "com.apple.Music":
            return queryAppleScriptPlayback(appName: "Music")
        case "com.spotify.client":
            return queryAppleScriptPlayback(appName: "Spotify")
        default:
            // For other media players without scripting bridges, default to true if running
            return true
        }
    }
    
    private func queryAppleScriptPlayback(appName: String) -> Bool {
        let script = "tell application \"\(appName)\" to get player state as string"
        guard let appleScript = NSAppleScript(source: script) else { return false }
        var errorInfo: NSDictionary?
        let descriptor = appleScript.executeAndReturnError(&errorInfo)
        if errorInfo == nil, let val = descriptor.stringValue?.lowercased() {
            return val.contains("playing")
        }
        return false
    }
}
