import AppKit
import Carbon
import Combine

/// Notification posted when accessibility permission status changes
public extension Notification.Name {
    static let accessibilityPermissionChanged = Notification.Name("LangConvertAccessibilityPermissionChanged")
}

/// Global storage for the hotkey callback (required for C callback)
private var globalHotkeyCallback: (() -> Void)?

/// C-compatible event handler for Carbon hotkey events
private func hotkeyEventHandler(
    nextHandler: EventHandlerCallRef?,
    event: EventRef?,
    userData: UnsafeMutableRawPointer?
) -> OSStatus {
    globalHotkeyCallback?()
    return noErr
}

/// Manages global hotkey registration and handling
public final class HotkeyManager: ObservableObject {
    
    public static let shared = HotkeyManager()
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var accessibilityPollTimer: Timer?
    private var lastKnownAccessibilityState: Bool = false
    
    /// Whether hotkey registration succeeded
    @Published public private(set) var isHotkeyRegistered: Bool = false
    
    /// Last error message if registration failed
    @Published public private(set) var lastError: String?
    
    /// Current accessibility permission state (updated by polling)
    @Published public private(set) var accessibilityGranted: Bool = false
    
    private init() {
        lastKnownAccessibilityState = AXIsProcessTrusted()
        accessibilityGranted = lastKnownAccessibilityState
        startAccessibilityPolling()
    }
    
    deinit {
        stopAccessibilityPolling()
    }
    
    // MARK: - Public API
    
    /// Register the global hotkey with the specified callback
    public func register(callback: @escaping () -> Void) {
        globalHotkeyCallback = callback
        
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
        globalHotkeyCallback = nil
    }
    
    /// Re-register the hotkey (useful after accessibility changes or app activation)
    public func reregister() {
        guard globalHotkeyCallback != nil else { return }
        
        unregisterHotkey()
        let settings = Settings.shared
        registerHotkey(keyCode: settings.hotkeyKeyCode, modifiers: settings.hotkeyModifiers)
    }
    
    // MARK: - Accessibility Polling
    
    private func startAccessibilityPolling() {
        accessibilityPollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkAccessibilityChange()
        }
    }
    
    private func stopAccessibilityPolling() {
        accessibilityPollTimer?.invalidate()
        accessibilityPollTimer = nil
    }
    
    private func checkAccessibilityChange() {
        let currentState = AXIsProcessTrusted()
        
        if currentState != lastKnownAccessibilityState {
            lastKnownAccessibilityState = currentState
            accessibilityGranted = currentState
            
            print("[HotkeyManager] Accessibility state changed: \(currentState)")
            
            NotificationCenter.default.post(name: .accessibilityPermissionChanged, object: nil)
            
            if currentState {
                reregister()
            }
        }
    }
    
    /// Force check accessibility status now
    public func refreshAccessibilityStatus() {
        checkAccessibilityChange()
    }
    
    // MARK: - Accessibility Check
    
    /// Check if accessibility permission is granted (without prompting)
    public static var hasAccessibilityPermission: Bool {
        return AXIsProcessTrusted()
    }
    
    /// Check accessibility with optional prompt
    public static func checkAccessibilityPermission(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Request accessibility permission (shows system prompt)
    public static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
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
        
        lastError = nil
        isHotkeyRegistered = false
        
        let hasAccess = AXIsProcessTrusted()
        accessibilityGranted = hasAccess
        
        if !hasAccess {
            print("[HotkeyManager] WARNING: Accessibility permission not granted (AXIsProcessTrusted=false)")
            print("[HotkeyManager] Attempting hotkey registration anyway (may work on some systems)")
        }
        
        let carbonModifiers = convertToCarbonModifiers(modifiers)
        
        var hotKeyID = EventHotKeyID()
        hotKeyID.signature = fourCharCode("LCNV")
        hotKeyID.id = 1
        
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        
        let handlerStatus = InstallEventHandler(
            GetApplicationEventTarget(),
            hotkeyEventHandler,
            1,
            &eventType,
            nil,
            &eventHandler
        )
        
        if handlerStatus != noErr {
            lastError = "Failed to install event handler (OSStatus: \(handlerStatus))"
            print("[HotkeyManager] ERROR: InstallEventHandler failed with status \(handlerStatus)")
            return
        }
        
        let registerStatus = RegisterEventHotKey(
            keyCode,
            carbonModifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
        
        if registerStatus != noErr {
            lastError = "Failed to register hotkey (OSStatus: \(registerStatus))"
            print("[HotkeyManager] ERROR: RegisterEventHotKey failed with status \(registerStatus)")
            
            if let handler = eventHandler {
                RemoveEventHandler(handler)
                eventHandler = nil
            }
            return
        }
        
        isHotkeyRegistered = true
        
        if hasAccess {
            print("[HotkeyManager] Hotkey registered successfully: keyCode=\(keyCode), modifiers=\(modifiers)")
        } else {
            print("[HotkeyManager] Hotkey registered (AX not confirmed): keyCode=\(keyCode), modifiers=\(modifiers)")
            lastError = "Hotkey registered but accessibility not confirmed"
        }
    }
    
    private func unregisterHotkey() {
        if let ref = hotKeyRef {
            let status = UnregisterEventHotKey(ref)
            if status != noErr {
                print("[HotkeyManager] Warning: UnregisterEventHotKey returned \(status)")
            }
            hotKeyRef = nil
        }
        
        if let handler = eventHandler {
            let status = RemoveEventHandler(handler)
            if status != noErr {
                print("[HotkeyManager] Warning: RemoveEventHandler returned \(status)")
            }
            eventHandler = nil
        }
        
        isHotkeyRegistered = false
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

private func fourCharCode(_ string: String) -> OSType {
    var result: OSType = 0
    for char in string.utf8.prefix(4) {
        result = (result << 8) | OSType(char)
    }
    return result
}
