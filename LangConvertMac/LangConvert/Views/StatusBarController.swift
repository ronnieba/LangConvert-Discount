import AppKit
import SwiftUI
import Combine

/// Manages the menu bar status item and its menu
final class StatusBarController: NSObject, ObservableObject {
    
    private var statusItem: NSStatusItem!
    private var menu: NSMenu!
    private var preferencesWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    
    override init() {
        super.init()
        setupStatusItem()
        setupMenu()
        observeSettings()
    }
    
    // MARK: - Setup
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            updateStatusIcon()
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    
    private func setupMenu() {
        menu = NSMenu()
        updateMenu()
    }
    
    private func observeSettings() {
        Settings.shared.$isEnabled
            .sink { [weak self] _ in
                self?.updateStatusIcon()
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        Settings.shared.$language
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        Settings.shared.$appearance
            .sink { [weak self] _ in
                self?.updateMenu()
                self?.updatePreferencesWindowAppearance()
            }
            .store(in: &cancellables)
    }
    
    private func updatePreferencesWindowAppearance() {
        preferencesWindow?.appearance = Settings.shared.appearance.nsAppearance
    }
    
    // MARK: - Status Icon
    
    private func updateStatusIcon() {
        guard let button = statusItem.button else { return }
        
        let isEnabled = Settings.shared.isEnabled
        let hasAccess = HotkeyManager.hasAccessibilityPermission
        
        let symbolName: String
        if !hasAccess {
            symbolName = "exclamationmark.triangle"
        } else {
            symbolName = "character.textbox"
        }
        
        if let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "LangConvert") {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            let configuredImage = image.withSymbolConfiguration(config)
            configuredImage?.isTemplate = true
            button.image = configuredImage
        }
        
        button.appearsDisabled = !isEnabled || !hasAccess
        
        let settings = Settings.shared
        let hotkeyStr = settings.hotkeyDisplayString
        var tooltipLines: [String] = []
        
        if !hasAccess {
            tooltipLines.append("⚠️ " + settings.localized(.accessibilityRequired))
        }
        
        let status = isEnabled
            ? settings.localized(.statusEnabled)
            : settings.localized(.statusDisabled)
        tooltipLines.append("LangConvert - \(status)")
        tooltipLines.append(hotkeyStr)
        
        button.toolTip = tooltipLines.joined(separator: "\n")
    }
    
    // MARK: - Menu
    
    private func updateMenu() {
        menu.removeAllItems()
        
        let settings = Settings.shared
        let hasAccess = HotkeyManager.hasAccessibilityPermission
        
        if !hasAccess {
            let warningItem = NSMenuItem(title: "⚠️ " + settings.localized(.accessibilityRequired), action: #selector(openAccessibility), keyEquivalent: "")
            warningItem.target = self
            menu.addItem(warningItem)
            
            let hintItem = NSMenuItem(
                title: settings.language == .hebrew
                    ? "לחץ כדי לתקן"
                    : "Click to fix",
                action: #selector(openAccessibility),
                keyEquivalent: ""
            )
            hintItem.target = self
            hintItem.indentationLevel = 1
            menu.addItem(hintItem)
            
            menu.addItem(NSMenuItem.separator())
        }
        
        let statusTitle = settings.isEnabled
            ? settings.localized(.statusEnabled)
            : settings.localized(.statusDisabled)
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        let hotkeyItem = NSMenuItem(title: settings.hotkeyDisplayString, action: nil, keyEquivalent: "")
        hotkeyItem.isEnabled = false
        menu.addItem(hotkeyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let toggleTitle = settings.isEnabled
            ? settings.localized(.disable)
            : settings.localized(.enable)
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleEnabled), keyEquivalent: "")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(title: settings.localized(.showPreferences), action: #selector(showPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        let langItem = NSMenuItem(title: "עברית / English", action: #selector(toggleLanguage), keyEquivalent: "")
        langItem.target = self
        menu.addItem(langItem)
        
        let themeItem = NSMenuItem(title: settings.themeToggleString, action: #selector(toggleTheme), keyEquivalent: "")
        themeItem.target = self
        menu.addItem(themeItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: settings.localized(.quit), action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }
    
    // MARK: - Actions
    
    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        } else {
            statusItem.menu = menu
            statusItem.button?.performClick(nil)
            statusItem.menu = nil
        }
    }
    
    @objc private func toggleEnabled() {
        Settings.shared.isEnabled.toggle()
    }
    
    @objc private func showPreferences() {
        if preferencesWindow == nil {
            let contentView = PreferencesView()
            
            preferencesWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 340, height: 520),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            
            preferencesWindow?.title = "LangConvert"
            preferencesWindow?.contentView = NSHostingView(rootView: contentView)
            preferencesWindow?.center()
            preferencesWindow?.isReleasedWhenClosed = false
        }
        
        preferencesWindow?.appearance = Settings.shared.appearance.nsAppearance
        preferencesWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc private func toggleLanguage() {
        let settings = Settings.shared
        settings.language = settings.language == .english ? .hebrew : .english
    }
    
    @objc private func toggleTheme() {
        Settings.shared.toggleTheme()
    }
    
    @objc private func openAccessibility() {
        HotkeyManager.openAccessibilityPreferences()
    }
    
    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
