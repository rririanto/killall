import AppKit
import SwiftUI

public final class FloatingHUDWindow: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.nonactivatingPanel, .borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.animationBehavior = .utilityWindow
        self.isMovableByWindowBackground = false
    }
    
    public override var canBecomeKey: Bool {
        return true
    }
    
    public override var canBecomeMain: Bool {
        return false
    }
    
    public var onDismiss: (() -> Void)?
    
    public override func cancelOperation(_ sender: Any?) {
        // Pressing Escape closes the HUD cleanly
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            self.orderOut(nil)
        }
    }
}
