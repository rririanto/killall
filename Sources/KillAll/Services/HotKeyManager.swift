import Carbon
import AppKit
import Foundation

public final class HotKeyManager {
    public static let shared = HotKeyManager()
    
    public enum Action: UInt32 {
        case toggleHUD = 1
        case quitAll = 2
        case forceQuitAll = 3
        case quitOthers = 4
    }
    
    private var hotKeyRefs: [Action: EventHotKeyRef] = [:]
    private var actionHandlers: [Action: () -> Void] = [:]
    private var registeredBindings: [Action: (keyCode: UInt32, modifiers: UInt32)] = [:]
    private var eventHandlerInstalled = false
    private var eventHandlerRef: EventHandlerRef?
    
    public static let modCmdOption: UInt32 = UInt32(cmdKey | optionKey)
    public static let modCmdOptionShift: UInt32 = UInt32(cmdKey | optionKey | shiftKey)
    
    private init() {}
    
    public func isRegistered(action: Action) -> Bool {
        actionHandlers[action] != nil
    }
    
    public func registeredBinding(action: Action) -> (keyCode: UInt32, modifiers: UInt32)? {
        registeredBindings[action]
    }
    
    public func trigger(action: Action) {
        actionHandlers[action]?()
    }
    
    public func register(action: Action, keyCode: UInt32, modifiers: UInt32, handler: @escaping () -> Void) {
        installHandlerIfNeeded()
        unregister(action: action)
        
        actionHandlers[action] = handler
        registeredBindings[action] = (keyCode, modifiers)
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x4B414C4C), id: action.rawValue) // 'KALL'
        var hotKeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            keyCode,
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if status == noErr, let ref = hotKeyRef {
            hotKeyRefs[action] = ref
        } else {
            print("Failed to register hotkey for action \(action): \(status)")
        }
    }
    
    public func unregister(action: Action) {
        if let ref = hotKeyRefs.removeValue(forKey: action) {
            UnregisterEventHotKey(ref)
        }
        actionHandlers.removeValue(forKey: action)
        registeredBindings.removeValue(forKey: action)
    }
    
    public func unregisterAll() {
        let allActions = Array(actionHandlers.keys)
        for action in allActions {
            unregister(action: action)
        }
    }
    
    private func installHandlerIfNeeded() {
        guard !eventHandlerInstalled else { return }
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let handlerBlock: EventHandlerUPP = { _, event, _ -> OSStatus in
            var hotKeyID = EventHotKeyID()
            let status = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            
            if status == noErr, let action = Action(rawValue: hotKeyID.id) {
                DispatchQueue.main.async {
                    HotKeyManager.shared.actionHandlers[action]?()
                }
                return noErr
            }
            return OSStatus(eventNotHandledErr)
        }
        
        InstallEventHandler(GetApplicationEventTarget(), handlerBlock, 1, &eventType, nil, &eventHandlerRef)
        eventHandlerInstalled = true
    }
}
