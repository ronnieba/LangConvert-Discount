import AppKit
import Carbon

/// Manages clipboard operations with safety (preserves original clipboard contents)
public final class ClipboardManager {
    
    public static let shared = ClipboardManager()
    
    private let pasteboard = NSPasteboard.general
    
    private init() {}
    
    // MARK: - Public API
    
    /// Perform conversion on selected or all text
    /// - Returns: true if conversion was performed, false otherwise
    @discardableResult
    public func performConversion() -> Bool {
        guard Settings.shared.isEnabled else { return false }
        
        let savedItems = saveClipboard()
        
        clearClipboard()
        
        simulateCopy()
        
        usleep(100_000)
        
        var text = getText()
        
        if text.isEmpty {
            simulateSelectAll()
            usleep(150_000)
            simulateCopy()
            usleep(100_000)
            text = getText()
        }
        
        guard !text.isEmpty else {
            restoreClipboard(savedItems)
            return false
        }
        
        let settings = Settings.shared
        let converted = ConversionService.shared.convert(
            text,
            convertUppercase: settings.convertUppercase,
            smartTitleCase: settings.smartTitleCase
        )
        
        setText(converted)
        
        usleep(50_000)
        
        simulatePaste()
        
        usleep(200_000)
        
        restoreClipboard(savedItems)
        
        return true
    }
    
    // MARK: - Clipboard Operations
    
    private func saveClipboard() -> [NSPasteboard.PasteboardType: Data] {
        var items: [NSPasteboard.PasteboardType: Data] = [:]
        
        for type in pasteboard.types ?? [] {
            if let data = pasteboard.data(forType: type) {
                items[type] = data
            }
        }
        
        return items
    }
    
    private func restoreClipboard(_ items: [NSPasteboard.PasteboardType: Data]) {
        pasteboard.clearContents()
        
        for (type, data) in items {
            pasteboard.setData(data, forType: type)
        }
    }
    
    private func clearClipboard() {
        pasteboard.clearContents()
    }
    
    private func getText() -> String {
        return pasteboard.string(forType: .string) ?? ""
    }
    
    private func setText(_ text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
    
    // MARK: - Key Simulation
    
    private func simulateCopy() {
        postKeyEvent(keyCode: 8, modifiers: .maskCommand)
    }
    
    private func simulatePaste() {
        postKeyEvent(keyCode: 9, modifiers: .maskCommand)
    }
    
    private func simulateSelectAll() {
        postKeyEvent(keyCode: 0, modifiers: .maskCommand)
    }
    
    private func postKeyEvent(keyCode: CGKeyCode, modifiers: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        
        guard let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else {
            return
        }
        
        keyDown.flags = modifiers
        keyUp.flags = modifiers
        
        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
    }
}
