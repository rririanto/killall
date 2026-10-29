import AppKit
import Foundation

public final class SoundService {
    public static let shared = SoundService()
    
    private var quitSingleSound: NSSound?
    private var quitAllSound: NSSound?
    
    public init() {
        if let singleURL = Bundle.main.url(forResource: "quit-single", withExtension: "aiff") {
            quitSingleSound = NSSound(contentsOf: singleURL, byReference: true)
        }
        if let allURL = Bundle.main.url(forResource: "quit-all", withExtension: "aiff") {
            quitAllSound = NSSound(contentsOf: allURL, byReference: true)
        }
    }
    
    public func playQuitSingle(soundEnabled: Bool = true, hapticsEnabled: Bool = true) {
        if hapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .default)
        }
        guard soundEnabled else { return }
        if let sound = quitSingleSound {
            sound.stop()
            sound.play()
        } else if let sysSound = NSSound(named: "Pop") {
            sysSound.play()
        }
    }
    
    public func playQuitAll(soundEnabled: Bool = true, hapticsEnabled: Bool = true) {
        if hapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        }
        guard soundEnabled else { return }
        if let sound = quitAllSound {
            sound.stop()
            sound.play()
        } else if let sysSound = NSSound(named: "Purr") ?? NSSound(named: "Blow") {
            sysSound.play()
        }
    }
    
    public func playRelaunch(soundEnabled: Bool = true, hapticsEnabled: Bool = true) {
        if hapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .default)
        }
        guard soundEnabled else { return }
        if let sysSound = NSSound(named: "Tink") {
            sysSound.play()
        }
    }
}
