import AppKit
import Carbon

/// Manages global hotkey registration and handling
public final class HotkeyManager {
    
    public static let shared = HotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var hotkeyCallback: (() -> Void)?
    
    private init() {}
    
    // MARK: - Public API
    
    /// Register the global hotkey with the specified callback
    public func register(callback: @escaping () -> Void) {
        hotkeyCallback = callback
        
        let settings = Settings.shared
        registerHotkey(keyCode: settings.hotkeyKeyCode, modifiers: settings.hotkeyModifiers)
    }
    
    /// Update the registered hotkey
    public func updateHotkey(keyCode: UInt32, modifiers: UInt32) {
        unregisterHotkey()
        
        let settings = Settings.shared
        settings.hotkeyKeyCode = keyCode
        settings.hotkeyModifiers = modifiers
        
        registerHotkey(keyCode: keyCode, modifiers: modifiers)
    }
    
    /// Unregister the current hotkey
    public func unregister() {
        unregisterHotkey()
        hotkeyCallback = nil
    }
    
    // MARK: - Accessibility Check
    
    /// Check if accessibility permission is granted
    public static var hasAccessibilityPermission: Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Request accessibility permission (shows system prompt)
    public static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }
    
    /// Open System Preferences to Accessibility pane
    public static func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    // MARK: - Private Implementation
    
    private func registerHotkey(keyCode: UInt32, modifiers: UInt32) {
        unregisterHotkey()
        
        let carbonModifiers = convertToCarbonModifiers(modifiers)
        
        var gMyHotKeyID = EventHotKeyID()
        gMyHotKeyID.signature = OSType(fourCharCode("LCNV"))
        gMyHotKeyID.id = 1
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        let handlerBlock: EventHandlerUPP = { _, event, _ -> OSStatus in
            HotkeyManager.shared.handleHotkey()
            return noErr
        }
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            handlerBlock,
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            gMyHotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
    
    private func unregisterHotkey() {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
            hotKeyRef = nil
        }
        
        if let handler = eventHandler {
            RemoveEventHandler(handler)
            eventHandler = nil
        }
    }
    
    private func handleHotkey() {
        hotkeyCallback?()
    }
    
    private func convertToCarbonModifiers(_ modifiers: UInt32) -> UInt32 {
        var carbon: UInt32 = 0
        
        if modifiers & 0x1000 != 0 { carbon |= UInt32(controlKey) }
        if modifiers & 0x0800 != 0 { carbon |= UInt32(optionKey) }
        if modifiers & 0x0100 != 0 { carbon |= UInt32(shiftKey) }
        if modifiers & 0x0200 != 0 { carbon |= UInt32(cmdKey) }
        
        return carbon
    }
}

// MARK: - Helper

private func fourCharCode(_ string: String) -> FourCharCode {
    var result: FourCharCode = 0
    for char in string.utf8 {
        result = (result << 8) | FourCharCode(char)
    }
    return result
}
