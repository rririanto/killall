import AppKit
import Combine
import SwiftUI

public final class StatusBarController: NSObject, NSPopoverDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var preferencesWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private let state: AppState
    
    public init(state: AppState) {
        self.state = state
        super.init()
        setupStatusItem()
        setupPopover()
        setupStateObservation()
        setupGlobalHotkeys()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(toggleHUD)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateStatusItemAppearance()
    }
    
    private func setupPopover() {
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 300, height: 380)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        
        let contentView = MenuBarHUDView(
            state: state,
            onOpenSettings: { [weak self] in
                self?.openPreferences()
            },
            onQuitApp: {
                NSApp.terminate(nil)
            },
            onDismiss: { [weak self] in
                self?.hideHUD()
            }
        )
        
        popover.contentViewController = NSHostingController(rootView: contentView)
        self.popover = popover
    }
    
    private func setupStateObservation() {
        state.$totalRunningCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)
        
        state.$showAppCountInMenuBar
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateStatusItemAppearance()
            }
            .store(in: &cancellables)
    }
    
    private func updateStatusItemAppearance() {
        guard let button = statusItem.button else { return }
        
        let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        let icon = NSImage(systemSymbolName: "xmark.app", accessibilityDescription: "QuiteAll")?.withSymbolConfiguration(config)
        icon?.isTemplate = true
        button.image = icon
        button.imagePosition = .imageLeading
        
        if state.showAppCountInMenuBar && state.totalRunningCount > 0 {
            button.title = " \(state.totalRunningCount)"
            button.font = .monospacedDigitSystemFont(ofSize: 10, weight: .medium)
        } else {
            button.title = ""
        }
    }
    
    @objc public func toggleHUD() {
        guard let button = statusItem.button else { return }
        
        if popover.isShown {
            hideHUD()
        } else {
            showHUD(anchoredTo: button)
        }
    }
    
    public func showHUD(anchoredTo button: NSStatusBarButton) {
        state.isHUDVisible = true
        state.startMetricsTimer()
        
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        if let window = popover.contentViewController?.view.window {
            window.makeKey()
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func hideHUD() {
        if popover.isShown {
            popover.performClose(nil)
        }
        state.isHUDVisible = false
        state.stopMetricsTimer()
    }
    
    public func popoverDidClose(_ notification: Notification) {
        state.isHUDVisible = false
        state.stopMetricsTimer()
    }
    
    public func openPreferences() {
        hideHUD()
        
        if let existing = preferencesWindow {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        
        let prefView = PreferencesView(state: state)
        let hosting = NSHostingView(rootView: prefView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "QuiteAll Settings"
        window.contentView = hosting
        window.isReleasedWhenClosed = false
        
        self.preferencesWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    private func setupGlobalHotkeys() {
        // ⌥⌘Q (Option + Command + Q) -> Toggle HUD
        HotKeyManager.shared.register(
            action: .toggleHUD,
            keyCode: 12, // Q key
            modifiers: HotKeyManager.modCmdOption
        ) { [weak self] in
            self?.toggleHUD()
        }
        
        // ⌥⇧⌘Q (Option + Shift + Command + Q) -> Force Quit All
        HotKeyManager.shared.register(
            action: .forceQuitAll,
            keyCode: 12, // Q key
            modifiers: HotKeyManager.modCmdOptionShift
        ) { [weak self] in
            self?.state.quitAll(force: true)
        }
        
        // ⌥⌘O (Option + Command + O) -> Quit Others (Keep Active App)
        HotKeyManager.shared.register(
            action: .quitOthers,
            keyCode: 31, // O key
            modifiers: HotKeyManager.modCmdOption
        ) { [weak self] in
            self?.state.quitOthers(force: false)
        }
    }
}
