import Foundation
import SwiftUI
import ServiceManagement

/// Supported UI languages
public enum AppLanguage: String, CaseIterable, Codable {
    case english = "English"
    case hebrew = "Hebrew"
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .hebrew: return "עברית"
        }
    }
}

/// Global application settings stored in UserDefaults
public final class Settings: ObservableObject {
    
    public static let shared = Settings()
    
    private let defaults = UserDefaults.standard
    
    // MARK: - Published Properties
    
    @Published public var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.isEnabled) }
    }
    
    @Published public var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: Keys.language) }
    }
    
    @Published public var convertUppercase: Bool {
        didSet { defaults.set(convertUppercase, forKey: Keys.convertUppercase) }
    }
    
    @Published public var smartTitleCase: Bool {
        didSet { defaults.set(smartTitleCase, forKey: Keys.smartTitleCase) }
    }
    
    @Published public var hotkeyKeyCode: UInt32 {
        didSet { defaults.set(hotkeyKeyCode, forKey: Keys.hotkeyKeyCode) }
    }
    
    @Published public var hotkeyModifiers: UInt32 {
        didSet { defaults.set(hotkeyModifiers, forKey: Keys.hotkeyModifiers) }
    }
    
    @Published public var openAtLogin: Bool {
        didSet {
            defaults.set(openAtLogin, forKey: Keys.openAtLogin)
            updateLoginItem()
        }
    }
    
    // MARK: - Keys
    
    private enum Keys {
        static let isEnabled = "isEnabled"
        static let language = "language"
        static let convertUppercase = "convertUppercase"
        static let smartTitleCase = "smartTitleCase"
        static let hotkeyKeyCode = "hotkeyKeyCode"
        static let hotkeyModifiers = "hotkeyModifiers"
        static let openAtLogin = "openAtLogin"
    }
    
    // MARK: - Default Hotkey: ⌃⌥1 (Control+Option+1)
    // Key code 18 = "1", Modifiers: Control (0x1000) + Option (0x0800)
    
    private static let defaultKeyCode: UInt32 = 18
    private static let defaultModifiers: UInt32 = 0x1800 // Control + Option
    
    // MARK: - Initialization
    
    private init() {
        self.isEnabled = defaults.object(forKey: Keys.isEnabled) as? Bool ?? true
        
        let langRaw = defaults.string(forKey: Keys.language) ?? AppLanguage.english.rawValue
        self.language = AppLanguage(rawValue: langRaw) ?? .english
        
        self.convertUppercase = defaults.object(forKey: Keys.convertUppercase) as? Bool ?? false
        self.smartTitleCase = defaults.object(forKey: Keys.smartTitleCase) as? Bool ?? false
        
        let storedKeyCode = UInt32(defaults.integer(forKey: Keys.hotkeyKeyCode))
        self.hotkeyKeyCode = storedKeyCode == 0 ? Self.defaultKeyCode : storedKeyCode
        
        let storedModifiers = UInt32(defaults.integer(forKey: Keys.hotkeyModifiers))
        self.hotkeyModifiers = storedModifiers == 0 ? Self.defaultModifiers : storedModifiers
        
        self.openAtLogin = defaults.object(forKey: Keys.openAtLogin) as? Bool ?? false
    }
    
    // MARK: - Login Item Management
    
    private func updateLoginItem() {
        if #available(macOS 13.0, *) {
            do {
                if openAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("Failed to update login item: \(error)")
            }
        }
    }
    
    // MARK: - Hotkey Display String
    
    public var hotkeyDisplayString: String {
        var parts: [String] = []
        
        if hotkeyModifiers & 0x1000 != 0 { parts.append("⌃") }
        if hotkeyModifiers & 0x0800 != 0 { parts.append("⌥") }
        if hotkeyModifiers & 0x0100 != 0 { parts.append("⇧") }
        if hotkeyModifiers & 0x0200 != 0 { parts.append("⌘") }
        
        if let keyString = keyCodeToString(hotkeyKeyCode) {
            parts.append(keyString)
        }
        
        return parts.joined()
    }
    
    private func keyCodeToString(_ keyCode: UInt32) -> String? {
        let keyMap: [UInt32: String] = [
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X",
            8: "C", 9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R",
            16: "Y", 17: "T", 18: "1", 19: "2", 20: "3", 21: "4", 22: "6",
            23: "5", 24: "=", 25: "9", 26: "7", 27: "-", 28: "8", 29: "0",
            30: "]", 31: "O", 32: "U", 33: "[", 34: "I", 35: "P", 36: "↩",
            37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\", 43: ",",
            44: "/", 45: "N", 46: "M", 47: ".", 48: "⇥", 49: "Space",
            50: "`", 51: "⌫", 53: "⎋",
            96: "F5", 97: "F6", 98: "F7", 99: "F3", 100: "F8", 101: "F9",
            103: "F11", 105: "F13", 107: "F14", 109: "F10", 111: "F12",
            113: "F15", 118: "F4", 119: "F2", 120: "F1", 122: "F1", 123: "←",
            124: "→", 125: "↓", 126: "↑"
        ]
        return keyMap[keyCode]
    }
    
    // MARK: - Localized Strings
    
    public func localized(_ key: LocalizedKey) -> String {
        switch language {
        case .english:
            return key.english
        case .hebrew:
            return key.hebrew
        }
    }
}

// MARK: - Localized Keys

public enum LocalizedKey {
    case appTitle
    case developedFor
    case version
    case author
    case statusEnabled
    case statusDisabled
    case tip
    case selectHotkey
    case updateHotkey
    case convertUppercase
    case smartTitleCase
    case openAtLogin
    case showPreferences
    case hidePreferences
    case enable
    case disable
    case quit
    case accessibilityRequired
    case accessibilityMessage
    case openSystemPreferences
    case cancel
    case hotkeyUpdated
    
    var english: String {
        switch self {
        case .appTitle: return "LangConvert"
        case .developedFor: return "Developed for Discount Bank"
        case .version: return "Version 1.0 - macOS Edition"
        case .author: return "Ben-Avi Ronnie"
        case .statusEnabled: return "Status: Running"
        case .statusDisabled: return "Status: Disabled"
        case .tip: return "Tip: Select text to convert only selection"
        case .selectHotkey: return "Select Hotkey:"
        case .updateHotkey: return "Update Hotkey"
        case .convertUppercase: return "Convert Uppercase (Caps Lock)"
        case .smartTitleCase: return "Smart Title/Prefix Mode"
        case .openAtLogin: return "Open at Login"
        case .showPreferences: return "Show Preferences"
        case .hidePreferences: return "Hide"
        case .enable: return "Enable"
        case .disable: return "Disable"
        case .quit: return "Quit"
        case .accessibilityRequired: return "Accessibility Permission Required"
        case .accessibilityMessage: return "LangConvert needs Accessibility permission to:\n• Register global hotkeys\n• Simulate copy/paste commands\n\nPlease enable it in System Preferences → Security & Privacy → Privacy → Accessibility"
        case .openSystemPreferences: return "Open System Preferences"
        case .cancel: return "Cancel"
        case .hotkeyUpdated: return "Hotkey updated!"
        }
    }
    
    var hebrew: String {
        switch self {
        case .appTitle: return "LangConvert"
        case .developedFor: return "פותח עבור בנק דיסקונט"
        case .version: return "גרסה 1.0 - מהדורת macOS"
        case .author: return "בן-אבי רוני"
        case .statusEnabled: return "סטטוס: פעיל"
        case .statusDisabled: return "סטטוס: לא פעיל"
        case .tip: return "טיפ: סמן טקסט כדי להמיר רק אותו"
        case .selectHotkey: return "בחר קיצור מקשים:"
        case .updateHotkey: return "עדכן קיצור"
        case .convertUppercase: return "המר אותיות רישיות (Caps Lock)"
        case .smartTitleCase: return "מצב חכם לתחיליות"
        case .openAtLogin: return "הפעל עם המחשב"
        case .showPreferences: return "הצג העדפות"
        case .hidePreferences: return "הסתר"
        case .enable: return "הפעל"
        case .disable: return "השבת"
        case .quit: return "יציאה"
        case .accessibilityRequired: return "נדרשת הרשאת נגישות"
        case .accessibilityMessage: return "LangConvert צריך הרשאת נגישות כדי:\n• לרשום קיצורי מקשים גלובליים\n• לבצע העתקה והדבקה\n\nאנא הפעל בהגדרות מערכת → פרטיות ואבטחה → נגישות"
        case .openSystemPreferences: return "פתח הגדרות מערכת"
        case .cancel: return "ביטול"
        case .hotkeyUpdated: return "הקיצור עודכן!"
        }
    }
}
