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
    
    // Performance monitor for performance settings
    @ObservedObject private var performanceMonitor = PerformanceMonitor.shared
    
    // Sparkle controller for updates
    @ObservedObject private var sparkleController = SparkleController.shared
    
    /// App version from bundle
    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.1"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(L10n.Settings.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button(L10n.Common.done) {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            Form {
                Section(L10n.Settings.Display.sectionTitle) {
                    Picker(L10n.Settings.Display.multiMonitorMode, selection: $displayMode) {
                        ForEach(MultiMonitorManager.DisplayMode.allCases, id: \.rawValue) { mode in
                            Text(mode.localizedName).tag(mode.rawValue)
                        }
                    }
                    .onChange(of: displayMode) { _, _ in
                        // Notify app to recreate windows
                        NotificationCenter.default.post(name: .displayModeChanged, object: nil)
                    }
                    
                    if displayMode == MultiMonitorManager.DisplayMode.selected.rawValue {
                        Picker(L10n.Settings.Display.activeDisplay, selection: $selectedDisplayIndex) {
                            ForEach(multiMonitorManager.screens) { screen in
                                Text(screen.localizedName).tag(screen.id)
                            }
                        }
                        .onChange(of: selectedDisplayIndex) { _, _ in
                            // Notify app to recreate windows
                            NotificationCenter.default.post(name: .displayModeChanged, object: nil)
                        }
                    }
                    
                    Text(L10n.Settings.Display.displaysDetected(multiMonitorManager.screenCount))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Section(L10n.Settings.Sound.sectionTitle) {
                    Picker(L10n.Settings.Sound.soundMode, selection: $soundMode) {
                        ForEach(GameViewModel.SoundMode.allCases, id: \.self) { mode in
                            Text(mode.localizedName).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    Text(L10n.Settings.Sound.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                languageSection
                
                themeSection
                
                performanceSection
                
                Section(L10n.Settings.Appearance.sectionTitle) {
                    Picker(L10n.Settings.Appearance.cursor, selection: $cursorType) {
                        ForEach(GameViewModel.CursorType.allCases, id: \.self) { cursor in
                            Text(cursor.localizedName).tag(cursor)
                        }
                    }
                    
                    Toggle(L10n.Settings.Appearance.showFacesOnShapes, isOn: $showFaces)
                    Toggle(L10n.Settings.Appearance.forceUppercaseLetters, isOn: $forceUppercase)
                }
                
                Section(L10n.Settings.MouseDrawing.sectionTitle) {
                    Toggle(L10n.Settings.MouseDrawing.enableMouseDrawing, isOn: $mouseDrawEnabled)
                    
                    if mouseDrawEnabled {
                        Toggle(L10n.Settings.MouseDrawing.clicklessMouseDrawing, isOn: $clicklessMouseDraw)
                        
                        Text(L10n.Settings.MouseDrawing.clicklessDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(L10n.Settings.FadeAway.sectionTitle) {
                    Toggle(L10n.Settings.FadeAway.fadeShapesAway, isOn: $fadeEnabled)
                    
                    if fadeEnabled {
                        VStack(alignment: .leading) {
                            Text(L10n.Settings.FadeAway.fadeAfterSeconds(Int(fadeAfter)))
                            Slider(value: $fadeAfter, in: 5...30, step: 1)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text(L10n.Settings.FadeAway.startRemovingAfter(maxFigures))
                        Slider(value: Binding(
                            get: { Double(maxFigures) },
                            set: { maxFigures = Int($0) }
                        ), in: 10...100, step: 5)
                    }
                }
                
                Section(L10n.Settings.BabySafety.sectionTitle) {
                    Toggle(L10n.Settings.BabySafety.blockSystemKeys, isOn: $blockSystemKeys)
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
                        Text(L10n.Settings.BabySafety.blockDescription)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(L10n.Settings.BabySafety.emergencyExit)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Section(L10n.Settings.KeyboardShortcuts.sectionTitle) {
                    HStack {
                        Text(L10n.Settings.KeyboardShortcuts.openSettings)
                        Spacer()
                        Text("⌥ + S")
                            .foregroundStyle(.secondary)
                    }
                }
                
                accessibilitySection
                
                Section(L10n.Settings.About.sectionTitle) {
                    HStack {
                        Text(L10n.Settings.About.appName)
                        Spacer()
                        Text(L10n.Settings.About.version(appVersion))
                            .foregroundStyle(.secondary)
                    }
                    
                    // Check for Updates
                    if sparkleController.canCheckForUpdates {
                        Button {
                            // Use async Task to prevent blocking the UI thread
                            Task { @MainActor in
                                // Brief delay to let button animation complete
                                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                                sparkleController.checkForUpdates()
                            }
                        } label: {
                            Text(L10n.Settings.About.checkForUpdates)
                        }
                    } else {
                        Text(L10n.Settings.About.updatesNotAvailable)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Link(L10n.Settings.About.originalBy,
                         destination: URL(string: "https://github.com/shanselman/babysmash")!)
                        .font(.caption)
                }
                
                Section {
                    Button(role: .destructive) {
                        showResetConfirmation = true
                    } label: {
                        HStack {
                            Image(systemName: "arrow.counterclockwise")
                            Text(L10n.Settings.ResetSection.resetToDefaults)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    Button(role: .destructive) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            NSApplication.shared.terminate(nil)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle")
                            Text(L10n.General.quit)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text(L10n.Settings.ResetSection.sectionTitle)
                } footer: {
                    Text(L10n.Settings.ResetSection.resetFooter)
                        .font(.caption)
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 500, minHeight: 700)
        .alert(L10n.Settings.Alerts.accessibilityPermissionTitle, isPresented: $showAccessibilityAlert) {
            Button(L10n.Settings.Alerts.openSystemSettings) {
                AccessibilityManager.openAccessibilityPreferences()
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Settings.Alerts.accessibilityPermissionMessage)
        }
        .alert(L10n.Settings.Alerts.resetConfirmTitle, isPresented: $showResetConfirmation) {
            Button(L10n.Common.reset, role: .destructive) {
                resetToDefaults()
            }
            Button(L10n.Common.cancel, role: .cancel) {}
        } message: {
            Text(L10n.Settings.Alerts.resetConfirmMessage)
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
        
        // Reset performance settings
        performanceMonitor.performanceMode = .auto
        
        // Stop system key blocking if it was enabled
        SystemKeyBlocker.shared.stopBlocking()
        
        // Clear theme manager custom themes
        ThemeManager.shared.resetToDefault()
        
        // Reset accessibility settings
        AccessibilitySettingsManager.shared.resetToDefaults()
        
        // Quit the app so user can restart and see onboarding
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSApplication.shared.terminate(nil)
        }
    }
    
    // MARK: - Language Section
    
    private var languageSection: some View {
        Section(L10n.Settings.Language.sectionTitle) {
            Picker(L10n.Settings.Language.speechLanguage, selection: $speechLanguage) {
                ForEach(LocalizedSpeechService.availableLanguages, id: \.code) { lang in
                    Text(lang.name).tag(lang.code)
                }
            }
            
            Toggle(L10n.Settings.Language.bilingualMode, isOn: Binding(
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
                Picker(L10n.Settings.Language.secondaryLanguage, selection: $secondaryLanguage) {
                    ForEach(LocalizedSpeechService.availableLanguages.filter { $0.code != speechLanguage }, id: \.code) { lang in
                        Text(lang.name).tag(lang.code)
                    }
                }
                
                Toggle(L10n.Settings.Language.alternateBetweenLanguages, isOn: $alternateSpeechLanguages)
                
                Text(L10n.Settings.Language.alternateDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Text(L10n.Settings.Language.changesDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Theme Section
    
    private var themeSection: some View {
        Section(L10n.Settings.Theme.sectionTitle) {
            Picker(L10n.Settings.Theme.theme, selection: Binding(
                get: { themeManager.currentTheme },
                set: { themeManager.selectTheme($0) }
            )) {
                Section(L10n.Settings.Theme.builtIn) {
                    ForEach(BabySmashTheme.allBuiltIn) { theme in
                        Text(theme.name).tag(theme)
                    }
                }
                
                if !themeManager.customThemes.isEmpty {
                    Section(L10n.Settings.Theme.custom) {
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
            
            Button(L10n.Settings.Theme.editTheme) {
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
            
            Button(L10n.Settings.Theme.createNewTheme) {
                var newTheme = BabySmashTheme.classic
                newTheme.id = UUID()
                newTheme.name = "New Theme"
                newTheme.isBuiltIn = false
                editingTheme = newTheme
                showThemeEditor = true
            }
            
            if !themeManager.currentTheme.isBuiltIn {
                Button(L10n.Settings.Theme.deleteTheme, role: .destructive) {
                    themeManager.deleteCustomTheme(themeManager.currentTheme)
                }
            }
        }
    }
    
    // MARK: - Performance Section
    
    private var performanceSection: some View {
        Section(L10n.Performance.sectionTitle) {
            Picker(L10n.Performance.performanceMode, selection: $performanceMonitor.performanceMode) {
                ForEach(PerformanceMonitor.PerformanceMode.allCases, id: \.self) { mode in
                    Text(mode.localizedName).tag(mode)
                }
            }
            
            // Show description based on selected mode
            Group {
                switch performanceMonitor.performanceMode {
                case .auto:
                    Text(L10n.Performance.autoDescription)
                    if performanceMonitor.performanceMode == .auto {
                        Text(L10n.Performance.currentTier(tierName(performanceMonitor.currentTier)))
                            .foregroundStyle(.secondary)
                    }
                case .high:
                    Text(L10n.Performance.highQualityDescription)
                case .balanced:
                    Text(L10n.Performance.balancedDescription)
                case .low:
                    Text(L10n.Performance.batterySaverDescription)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
    
    private func tierName(_ tier: PerformanceMonitor.PerformanceTier) -> String {
        switch tier {
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    // MARK: - Accessibility Section
    
    @State private var showAccessibilitySettings = false
    
    private var accessibilitySection: some View {
        Section(L10n.Settings.AccessibilitySection.sectionTitle) {
            Button {
                showAccessibilitySettings = true
            } label: {
                HStack {
                    Image(systemName: "accessibility")
                    Text(L10n.Settings.AccessibilitySection.accessibilitySettings)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $showAccessibilitySettings) {
                NavigationStack {
                    AccessibilitySettingsView()
                        .navigationTitle(L10n.Settings.AccessibilitySection.sectionTitle)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(L10n.Common.done) {
                                    showAccessibilitySettings = false
                                }
                            }
                        }
                }
                .frame(minWidth: 500, minHeight: 700)
            }
            
            Text(L10n.Settings.AccessibilitySection.description)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    SettingsView()
}
