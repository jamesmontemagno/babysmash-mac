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
    @AppStorage("fontFamily") private var fontFamily: String = "SF Pro Rounded"
    @AppStorage("backgroundColor") private var backgroundColor: String = "black"
    @AppStorage("customBackgroundRed") private var customBackgroundRed: Double = 0.0
    @AppStorage("customBackgroundGreen") private var customBackgroundGreen: Double = 0.0
    @AppStorage("customBackgroundBlue") private var customBackgroundBlue: Double = 0.0
    @AppStorage("blockSystemKeys") private var blockSystemKeys: Bool = false
    @AppStorage("displayMode") private var displayMode: String = "all"
    @AppStorage("selectedDisplayIndex") private var selectedDisplayIndex: Int = 0
    
    // State for accessibility permission alert
    @State private var showAccessibilityAlert: Bool = false
    
    // Observe multi-monitor manager for screen changes
    @ObservedObject private var multiMonitorManager = MultiMonitorManager.shared
    
    // Computed property for custom color binding
    private var customColor: Binding<Color> {
        Binding(
            get: {
                Color(red: customBackgroundRed, green: customBackgroundGreen, blue: customBackgroundBlue)
            },
            set: { newColor in
                if let components = NSColor(newColor).usingColorSpace(.deviceRGB) {
                    customBackgroundRed = Double(components.redComponent)
                    customBackgroundGreen = Double(components.greenComponent)
                    customBackgroundBlue = Double(components.blueComponent)
                }
            }
        )
    }
    
    // Available system fonts for letter display
    private let availableFonts = [
        "SF Pro Rounded",
        "SF Pro",
        "Helvetica Neue",
        "Arial Rounded MT Bold",
        "Comic Sans MS",
        "Marker Felt",
        "Chalkboard SE",
        "Papyrus",
        "American Typewriter",
        "Noteworthy",
        "Futura"
    ]
    
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
                
                Section("Appearance") {
                    Picker("Background Color", selection: $backgroundColor) {
                        ForEach(GameViewModel.BackgroundColor.allCases, id: \.rawValue) { bg in
                            HStack {
                                if bg == .custom {
                                    Image(systemName: "paintpalette")
                                        .frame(width: 16, height: 16)
                                } else {
                                    Circle()
                                        .fill(bg.color ?? .clear)
                                        .frame(width: 16, height: 16)
                                        .overlay(Circle().stroke(Color.gray, lineWidth: 1))
                                }
                                Text(bg.displayName)
                            }
                            .tag(bg.rawValue)
                        }
                    }
                    
                    if backgroundColor == "custom" {
                        ColorPicker("Custom Color", selection: customColor, supportsOpacity: false)
                    }
                    
                    Picker("Font", selection: $fontFamily) {
                        ForEach(availableFonts, id: \.self) { font in
                            Text(font)
                                .font(.custom(font, size: 14))
                                .tag(font)
                        }
                    }
                    
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
                        Text("Blocks Cmd+Tab, Cmd+Q, Mission Control, and other system shortcuts")
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
    }
}

#Preview {
    SettingsView()
}
