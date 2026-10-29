import AppKit
import Foundation

public final class SoundService {
    public static let shared = SoundService()
    
    private var quitSingleSound: NSSound?
    private var quitAllSound: NSSound?
    
    public var soundPlayer: ((String) -> Void)? = nil
    public var hapticPerformer: ((NSHapticFeedbackManager.FeedbackPattern) -> Void)? = nil
    
    public init() {
        quitSingleSound = loadSound(named: "quit-single")
        quitAllSound = loadSound(named: "quit-all")
    }
    
    private func loadSound(named name: String) -> NSSound? {
        if let bundleURL = Bundle.main.url(forResource: name, withExtension: "aiff") {
            return NSSound(contentsOf: bundleURL, byReference: true)
        }
        let fallbackPaths = [
            "Resources/Sounds/\(name).aiff",
            "QuiteAll.app/Contents/Resources/\(name).aiff"
        ]
        for path in fallbackPaths {
            if FileManager.default.fileExists(atPath: path) {
                return NSSound(contentsOfFile: path, byReference: true)
            }
        }
        return nil
    }
    
    public func playQuitSingle(soundEnabled: Bool = true, hapticsEnabled: Bool = true) {
        if hapticsEnabled {
            if let performer = hapticPerformer {
                performer(.generic)
            } else {
                NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
            }
        }
        guard soundEnabled else { return }
        if let player = soundPlayer {
            player("quit-single")
            return
        }
        if let sound = quitSingleSound {
            sound.stop()
            sound.play()
        } else if let sysSound = NSSound(named: "Pop") {
            sysSound.play()
        }
    }
    
    public func playQuitAll(soundEnabled: Bool = true, hapticsEnabled: Bool = true) {
        if hapticsEnabled {
            if let performer = hapticPerformer {
                performer(.levelChange)
            } else {
                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
            }
        }
        guard soundEnabled else { return }
        if let player = soundPlayer {
            player("quit-all")
            return
        }
        if let sound = quitAllSound {
            sound.stop()
            sound.play()
        } else if let sysSound = NSSound(named: "Purr") ?? NSSound(named: "Blow") {
            sysSound.play()
        }
    }
    
    public func playRelaunch(soundEnabled: Bool = true, hapticsEnabled: Bool = true) {
        if hapticsEnabled {
            if let performer = hapticPerformer {
                performer(.alignment)
            } else {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
            }
        }
        guard soundEnabled else { return }
        if let player = soundPlayer {
            player("relaunch")
            return
        }
        if let sysSound = NSSound(named: "Tink") {
            sysSound.play()
        }
    }
}

