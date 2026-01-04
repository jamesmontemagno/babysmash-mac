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
    @AppStorage("fadeAfter") private var fadeAfter: Double = 10.0
    @AppStorage("showFaces") private var showFaces: Bool = true
    @AppStorage("mouseDrawEnabled") private var mouseDrawEnabled: Bool = true
    @AppStorage("forceUppercase") private var forceUppercase: Bool = true
    @AppStorage("maxFigures") private var maxFigures: Int = 50
    
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
                Section("Sound") {
                    Picker("Sound Mode", selection: $soundMode) {
                        ForEach(GameViewModel.SoundMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Display") {
                    Toggle("Show Faces on Shapes", isOn: $showFaces)
                    Toggle("Force Uppercase Letters", isOn: $forceUppercase)
                    Toggle("Enable Mouse Drawing", isOn: $mouseDrawEnabled)
                    
                    VStack(alignment: .leading) {
                        Text("Fade After: \(Int(fadeAfter)) seconds")
                        Slider(value: $fadeAfter, in: 5...30, step: 1)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Max Figures: \(maxFigures)")
                        Slider(value: Binding(
                            get: { Double(maxFigures) },
                            set: { maxFigures = Int($0) }
                        ), in: 10...100, step: 5)
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
                    
                    Text("Based on the original BabySmash by Scott Hanselman")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 450, minHeight: 500)
    }
}

#Preview {
    SettingsView()
}
