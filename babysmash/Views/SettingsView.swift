//
//  SettingsView.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("soundMode") private var soundMode: GameViewModel.SoundMode = .laughter
    @AppStorage("fadeEnabled") private var fadeEnabled: Bool = true
    @AppStorage("fadeAfter") private var fadeAfter: Double = 10.0
    @AppStorage("showFaces") private var showFaces: Bool = true
    @AppStorage("mouseDrawEnabled") private var mouseDrawEnabled: Bool = true
    @AppStorage("clicklessMouseDraw") private var clicklessMouseDraw: Bool = false
    @AppStorage("forceUppercase") private var forceUppercase: Bool = true
    @AppStorage("maxFigures") private var maxFigures: Int = 50
    @AppStorage("cursorType") private var cursorType: GameViewModel.CursorType = .hand
    @AppStorage("blockSystemKeys") private var blockSystemKeys: Bool = false
    @AppStorage("displayMode") private var displayMode: String = "all"
    @AppStorage("selectedDisplayIndex") private var selectedDisplayIndex: Int = 0
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    // Language settings
    @AppStorage("speechLanguage") private var speechLanguage: String = "en"
    @AppStorage("secondaryLanguage") private var secondaryLanguage: String = ""
    @AppStorage("alternateSpeechLanguages") private var alternateSpeechLanguages: Bool = false
    
    // State for accessibility permission alert
    @State private var showAccessibilityAlert: Bool = false
    @State private var showResetConfirmation: Bool = false
    
    // Theme editor state
    @State private var showThemeEditor = false
    @State private var editingTheme: BabySmashTheme = .classic
    
    // Observe multi-monitor manager for screen changes
    @ObservedObject private var multiMonitorManager = MultiMonitorManager.shared
    
    // Theme manager for theme selection
    @ObservedObject private var themeManager = ThemeManager.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Form {
                Section("Display") {
                    Picker("Multi-Monitor Mode", selection: $displayMode) {
                        ForEach(MultiMonitorManager.DisplayMode.allCases, id: \.rawValue) { mode in
                            Text(mode.displayName).tag(mode.rawValue)
                        }
                    }
                    .onChange(of: displayMode) { _, _ in
                        // Notify app to recreate windows
                        NotificationCenter.default.post(name: .displayModeChanged, object: nil)
                    }
                    
                    if displayMode == MultiMonitorManager.DisplayMode.selected.rawValue {
                        Picker("Active Display", selection: $selectedDisplayIndex) {
                            ForEach(multiMonitorManager.screens) { screen in
                                Text(screen.localizedName).tag(screen.id)
                            }
                        }
                        .onChange(of: selectedDisplayIndex) { _, _ in
                            // Notify app to recreate windows
                            NotificationCenter.default.post(name: .displayModeChanged, object: nil)
                        }
                    }
                    
                    Text("\(multiMonitorManager.screenCount) display(s) detected")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section("Sound") {
                    Picker("Sound Mode", selection: $soundMode) {
                        ForEach(GameViewModel.SoundMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text("Laughter plays random giggle sounds. Speech reads letters and shape names aloud.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                languageSection
                
                themeSection
                
                Section("Appearance") {
                    Picker("Cursor", selection: $cursorType) {
                        ForEach(GameViewModel.CursorType.allCases, id: \.self) { cursor in
                            Text(cursor.rawValue).tag(cursor)
                        }
                    }
                    
                    Toggle("Show Faces on Shapes", isOn: $showFaces)
                    Toggle("Force Uppercase Letters", isOn: $forceUppercase)
                }
                
                Section("Mouse Drawing") {
                    Toggle("Enable Mouse Drawing", isOn: $mouseDrawEnabled)
                    
                    if mouseDrawEnabled {
                        Toggle("Clickless Mouse Drawing", isOn: $clicklessMouseDraw)
                        
                        Text("When enabled, drawing happens as you move the mouse without clicking.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Fade Away") {
                    Toggle("Fade Shapes Away", isOn: $fadeEnabled)
                    
                    if fadeEnabled {
                        VStack(alignment: .leading) {
                            Text("Fade After: \(Int(fadeAfter)) seconds")
                            Slider(value: $fadeAfter, in: 5...30, step: 1)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Start Removing After: \(maxFigures) shapes")
                        Slider(value: Binding(
                            get: { Double(maxFigures) },
                            set: { maxFigures = Int($0) }
                        ), in: 10...100, step: 5)
                    }
                }
                
                Section("Baby Safety") {
                    Toggle("Block System Keys", isOn: $blockSystemKeys)
                        .onChange(of: blockSystemKeys) { _, newValue in
                            if newValue {
                                if !AccessibilityManager.isAccessibilityEnabled() {
                                    showAccessibilityAlert = true
                                    blockSystemKeys = false
                                } else {
                                    SystemKeyBlocker.shared.startBlocking()
                                }
                            } else {
                                SystemKeyBlocker.shared.stopBlocking()
                            }
                        }
                    
                    if blockSystemKeys {
                        Text("Blocks Cmd+Tab, Cmd+Q, Cmd+Space (Spotlight), Mission Control, and other system shortcuts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text("Emergency exit: ⌥⌘ Esc (Force Quit)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("Keyboard Shortcuts") {
                    HStack {
                        Text("Open Settings")
                        Spacer()
                        Text("⌥ + S")
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("BabySmash for macOS")
                        Spacer()
                        Text("Version 1.0")
                            .foregroundStyle(.secondary)
                    }
                    
                    Link("Original BabySmash by Scott Hanselman",
                         destination: URL(string: "https://github.com/shanselman/babysmash")!)
                        .font(.caption)
                }
                
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Reset to Defaults")
                        }
                        .frame(maxWidth: .infinity)
                    }
                } header: {
                    Text("Reset")
                } footer: {
                    Text("Resets all settings to default values and restarts onboarding on next launch.")
                        .font(.caption)
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 500, minHeight: 700)
        .alert("Accessibility Permission Required", isPresented: $showAccessibilityAlert) {
            Button("Open System Settings") {
                AccessibilityManager.openAccessibilityPreferences()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("BabySmash needs Accessibility permission to block system keyboard shortcuts, preventing babies from accidentally switching apps or triggering system functions.\n\n1. Open System Settings\n2. Find BabySmash in the list\n3. Enable the checkbox\n4. Toggle this setting again")
        }
        .alert("Reset to Defaults?", isPresented: $showResetConfirmation) {
            Button("Reset", role: .destructive) {
                resetToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all settings to their default values and restart the onboarding experience on next launch. The app will quit after resetting.")
        }
        .sheet(isPresented: $showThemeEditor) {
            ThemeEditorView(theme: $editingTheme)
        }
    }
    
    // MARK: - Reset to Defaults
    
    private func resetToDefaults() {
        // Reset all AppStorage values to defaults
        soundMode = .laughter
        fadeEnabled = true
        fadeAfter = 10.0
        showFaces = true
        mouseDrawEnabled = true
        clicklessMouseDraw = false
        forceUppercase = true
        maxFigures = 50
        cursorType = .hand
        blockSystemKeys = false
        displayMode = "all"
        selectedDisplayIndex = 0
        hasCompletedOnboarding = false
        
        // Reset language settings
        speechLanguage = "en"
        secondaryLanguage = ""
        alternateSpeechLanguages = false
        
        // Stop system key blocking if it was enabled
        SystemKeyBlocker.shared.stopBlocking()
        
        // Clear theme manager custom themes
        ThemeManager.shared.resetToDefault()
        
        // Quit the app so user can restart and see onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }
    
    // MARK: - Language Section
    
    private var languageSection: some View {
        Section("Language") {
            Picker("Speech Language", selection: $speechLanguage) {
                ForEach(LocalizedSpeechService.availableLanguages, id: \.code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
            
            Toggle("Bilingual Mode", isOn: Binding(
                get: { !secondaryLanguage.isEmpty },
                set: { enabled in
                    if enabled {
                        // Default to Spanish if not already set
                        secondaryLanguage = speechLanguage == "es" ? "en" : "es"
                    } else {
                        secondaryLanguage = ""
                        alternateSpeechLanguages = false
                    }
                }
            ))
            
            if !secondaryLanguage.isEmpty {
                Picker("Secondary Language", selection: $secondaryLanguage) {
                    ForEach(LocalizedSpeechService.availableLanguages.filter { $0.code != speechLanguage }, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                
                Toggle("Alternate Between Languages", isOn: $alternateSpeechLanguages)
                
                Text("When enabled, speech alternates between primary and secondary languages.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text("Changes how letters, numbers, and shapes are pronounced.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        Section("Theme") {
            Picker("Theme", selection: Binding(
                get: { themeManager.currentTheme },
                set: { themeManager.selectTheme($0) }
            )) {
                Section("Built-in") {
                    ForEach(BabySmashTheme.allBuiltIn) { theme in
                        Text(theme.name).tag(theme)
                    }
                }
                
                if !themeManager.customThemes.isEmpty {
                    Section("Custom") {
                        ForEach(themeManager.customThemes) { theme in
                            Text(theme.name).tag(theme)
                        }
                    }
                }
            }
            
            // Theme preview
            ThemePreviewView(theme: themeManager.currentTheme)
                .frame(height: 100)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            Button("Edit Theme...") {
                if themeManager.currentTheme.isBuiltIn {
                    // Duplicate for editing
                    var copy = themeManager.currentTheme
                    copy.id = UUID()
                    copy.name = "\(themeManager.currentTheme.name) Copy"
                    copy.isBuiltIn = false
                    editingTheme = copy
                } else {
                    editingTheme = themeManager.currentTheme
                }
                showThemeEditor = true
            }
            
            Button("Create New Theme...") {
                var newTheme = BabySmashTheme.classic
                newTheme.id = UUID()
                newTheme.name = "New Theme"
                newTheme.isBuiltIn = false
                editingTheme = newTheme
                showThemeEditor = true
            }
            
            if !themeManager.currentTheme.isBuiltIn {
                Button("Delete Theme", role: .destructive) {
                    themeManager.deleteCustomTheme(themeManager.currentTheme)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
