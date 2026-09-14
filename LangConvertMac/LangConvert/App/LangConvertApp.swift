import SwiftUI
import AppKit

@main
struct LangConvertApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        SwiftUI.Settings {
            PreferencesView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusBarController: StatusBarController?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusBarController = StatusBarController()
        
        checkAccessibilityPermission()
        
        registerHotkey()
        
        NSApp.setActivationPolicy(.accessory)
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        HotkeyManager.shared.refreshAccessibilityStatus()
        HotkeyManager.shared.reregister()
        
        NotificationCenter.default.post(name: .accessibilityPermissionChanged, object: nil)
    }
    
    private func checkAccessibilityPermission() {
        if !HotkeyManager.hasAccessibilityPermission {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.showAccessibilityAlert()
            }
        }
    }
    
    private func showAccessibilityAlert() {
        let settings = Settings.shared
        
        let alert = NSAlert()
        alert.messageText = settings.localized(.accessibilityRequired)
        alert.informativeText = settings.localized(.accessibilityMessage)
        alert.alertStyle = .warning
        alert.addButton(withTitle: settings.localized(.openSystemPreferences))
        alert.addButton(withTitle: settings.localized(.cancel))
        
        NSApp.activate(ignoringOtherApps: true)
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            HotkeyManager.openAccessibilityPreferences()
        }
    }
    
    private func registerHotkey() {
        HotkeyManager.shared.register {
            ClipboardManager.shared.performConversion()
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }
}
