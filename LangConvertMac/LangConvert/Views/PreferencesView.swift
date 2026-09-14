import SwiftUI

/// Main preferences window view with Discount Bank branding
struct PreferencesView: View {
    @ObservedObject var settings = Settings.shared
    @State private var showingHotkeyAlert = false
    @Environment(\.colorScheme) var colorScheme
    
    private var isHebrew: Bool {
        settings.language == .hebrew
    }
    
    var body: some View {
        VStack(spacing: 16) {
            logoSection
            headerSection
            
            Divider()
            
            statusSection
            
            Divider()
            
            hotkeySection
            settingsSection
            
            Divider()
            
            buttonsSection
        }
        .padding(20)
        .frame(width: 340)
        .environment(\.layoutDirection, isHebrew ? .rightToLeft : .leftToRight)
        .alert(settings.localized(.hotkeyUpdated), isPresented: $showingHotkeyAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    // MARK: - Logo Section
    
    private var logoSection: some View {
        Group {
            if let image = loadLogo() {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 60)
            } else {
                Image(systemName: "character.textbox")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private func loadLogo() -> NSImage? {
        let logoName = colorScheme == .dark ? "DiscountLogo_Dark" : "DiscountLogo"
        
        if let bundleImage = NSImage(named: logoName) {
            return bundleImage
        }
        
        let paths = [
            Bundle.main.resourcePath.map { "\($0)/\(logoName).png" },
            Bundle.main.bundlePath + "/Contents/Resources/\(logoName).png"
        ].compactMap { $0 }
        
        for path in paths {
            if let image = NSImage(contentsOfFile: path) {
                return image
            }
        }
        
        return nil
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 4) {
            Text(settings.localized(.developedFor))
                .font(.headline)
            
            Text(settings.localized(.version))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(settings.localized(.author))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(settings.isEnabled ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                
                Text(settings.isEnabled
                     ? settings.localized(.statusEnabled)
                     : settings.localized(.statusDisabled))
                    .font(.body)
                    .foregroundColor(settings.isEnabled ? .green : .red)
            }
            
            Text(settings.localized(.tip))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Hotkey Section
    
    private var hotkeySection: some View {
        VStack(spacing: 8) {
            Text(settings.localized(.selectHotkey))
                .font(.subheadline)
            
            HStack {
                Text(settings.hotkeyDisplayString)
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(6)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                
                HotkeyRecorderView { keyCode, modifiers in
                    HotkeyManager.shared.updateHotkey(keyCode: keyCode, modifiers: modifiers)
                    showingHotkeyAlert = true
                }
            }
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(settings.localized(.convertUppercase), isOn: $settings.convertUppercase)
            
            Toggle(settings.localized(.smartTitleCase), isOn: $settings.smartTitleCase)
            
            Toggle(settings.localized(.openAtLogin), isOn: $settings.openAtLogin)
        }
        .toggleStyle(.checkbox)
        .padding(.horizontal)
    }
    
    // MARK: - Buttons Section
    
    private var buttonsSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                Button(action: { settings.isEnabled.toggle() }) {
                    Text(settings.isEnabled
                         ? settings.localized(.disable)
                         : settings.localized(.enable))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                
                Button(action: toggleLanguage) {
                    Text("עברית / English")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            if !HotkeyManager.hasAccessibilityPermission {
                Button(action: {
                    HotkeyManager.openAccessibilityPreferences()
                }) {
                    Label(settings.localized(.openSystemPreferences), systemImage: "lock.shield")
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
    }
    
    private func toggleLanguage() {
        settings.language = settings.language == .english ? .hebrew : .english
    }
}

// MARK: - Hotkey Recorder View

struct HotkeyRecorderView: View {
    let onRecorded: (UInt32, UInt32) -> Void
    @State private var isRecording = false
    
    var body: some View {
        Button(action: { isRecording = true }) {
            Text(isRecording ? "..." : Settings.shared.localized(.updateHotkey))
                .frame(minWidth: 80)
        }
        .buttonStyle(.bordered)
        .keyboardShortcut(.none)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                guard isRecording else { return event }
                
                let modifiers = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
                guard !modifiers.isEmpty else { return event }
                
                var modFlags: UInt32 = 0
                if modifiers.contains(.control) { modFlags |= 0x1000 }
                if modifiers.contains(.option) { modFlags |= 0x0800 }
                if modifiers.contains(.shift) { modFlags |= 0x0100 }
                if modifiers.contains(.command) { modFlags |= 0x0200 }
                
                let keyCode = UInt32(event.keyCode)
                
                isRecording = false
                onRecorded(keyCode, modFlags)
                
                return nil
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PreferencesView()
}
