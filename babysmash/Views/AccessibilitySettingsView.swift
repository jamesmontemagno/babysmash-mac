//
//  AccessibilitySettingsView.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI

/// Settings view for all accessibility features
struct AccessibilitySettingsView: View {
    @ObservedObject private var accessibilityManager = AccessibilitySettingsManager.shared
    
    var body: some View {
        Form {
            // Visual Accessibility
            visualSection
            
            // Motion Accessibility
            motionSection
            
            // Audio Accessibility
            audioSection
            
            // Motor Accessibility
            motorSection
            
            // Cognitive Accessibility
            cognitiveSection
            
            // Photosensitivity
            photosensitivitySection
            
            // System Information
            systemInfoSection
        }
        .formStyle(.grouped)
        .onChange(of: accessibilityManager.settings) { _, _ in
            accessibilityManager.saveSettings()
        }
    }
    
    // MARK: - Visual Section
    
    private var visualSection: some View {
        Section("Visual") {
            Toggle("High Contrast Mode", isOn: $accessibilityManager.settings.highContrastMode)
            
            Toggle("Large Elements", isOn: $accessibilityManager.settings.largeElementsMode)
            
            if accessibilityManager.settings.largeElementsMode {
                HStack {
                    Text("Minimum Size: \(Int(accessibilityManager.settings.minimumShapeSize))")
                    Spacer()
                    Slider(
                        value: $accessibilityManager.settings.minimumShapeSize,
                        in: 200...500,
                        step: 50
                    )
                    .frame(width: 200)
                }
            }
            
            Picker("Color Blindness Mode", selection: $accessibilityManager.settings.colorBlindnessMode) {
                ForEach(AccessibilitySettings.ColorBlindnessMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            
            if accessibilityManager.settings.colorBlindnessMode != .none {
                Toggle("Show Patterns on Shapes", isOn: $accessibilityManager.settings.showPatterns)
                
                Text("Patterns help distinguish shapes beyond color alone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Motion Section
    
    private var motionSection: some View {
        Section("Motion") {
            Toggle("Reduce Motion", isOn: $accessibilityManager.settings.reduceMotion)
            
            if !accessibilityManager.settings.reduceMotion {
                Picker("Animation Speed", selection: $accessibilityManager.settings.animationSpeed) {
                    ForEach(AccessibilitySettings.AnimationSpeed.allCases) { speed in
                        Text(speed.rawValue).tag(speed)
                    }
                }
                
                Toggle("Disable Rotation Effects", isOn: $accessibilityManager.settings.disableRotation)
            }
            
            if accessibilityManager.systemReduceMotion {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text("System Reduce Motion is enabled")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Audio Section
    
    private var audioSection: some View {
        Section("Audio") {
            Toggle("Visual Sound Indicators", isOn: $accessibilityManager.settings.visualSoundIndicators)
            
            Text("Flashes the screen border when sounds play.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Toggle("Show Captions", isOn: $accessibilityManager.settings.showCaptions)
            
            Text("Shows text describing sounds and speech.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Toggle("Volume Boost", isOn: $accessibilityManager.settings.volumeBoost)
        }
    }
    
    // MARK: - Motor Section
    
    private var motorSection: some View {
        Section("Motor") {
            Toggle("Auto-Play Mode", isOn: $accessibilityManager.settings.autoPlayMode)
            
            if accessibilityManager.settings.autoPlayMode {
                HStack {
                    Text("Interval: \(Int(accessibilityManager.settings.autoPlayInterval))s")
                    Spacer()
                    Slider(
                        value: $accessibilityManager.settings.autoPlayInterval,
                        in: 1...10,
                        step: 1
                    )
                    .frame(width: 200)
                }
                
                Text("Shapes appear automatically at this interval.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Toggle("Switch Control Mode", isOn: $accessibilityManager.settings.switchControlEnabled)
            
            Text("Enables scanning through actions for single-switch input.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Cognitive Section
    
    private var cognitiveSection: some View {
        Section("Cognitive") {
            Toggle("Simplified Mode", isOn: $accessibilityManager.settings.simplifiedMode)
            
            if accessibilityManager.settings.simplifiedMode {
                HStack {
                    Text("Max Shapes: \(accessibilityManager.settings.maxSimultaneousShapes)")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { Double(accessibilityManager.settings.maxSimultaneousShapes) },
                            set: { accessibilityManager.settings.maxSimultaneousShapes = Int($0) }
                        ),
                        in: 1...20,
                        step: 1
                    )
                    .frame(width: 200)
                }
                
                Text("Limits the number of shapes on screen for reduced complexity.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Toggle("Predictable Mode", isOn: $accessibilityManager.settings.predictableMode)
            
            Text("Shapes appear in consistent positions rather than randomly.")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker("Focus", selection: $accessibilityManager.settings.focusMode) {
                ForEach(AccessibilitySettings.FocusMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            
            Text("Limits content to specific types.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Photosensitivity Section
    
    private var photosensitivitySection: some View {
        Section("Photosensitivity") {
            Toggle("Safe Mode (No Flashing)", isOn: $accessibilityManager.settings.photosensitivitySafeMode)
            
            Text("Disables all rapid visual changes, flashing effects, and ensures gentle transitions only. Recommended for users with photosensitive epilepsy.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - System Info Section
    
    private var systemInfoSection: some View {
        Section("System") {
            HStack {
                Text("VoiceOver")
                Spacer()
                Text(accessibilityManager.isVoiceOverRunning ? "Running" : "Off")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("System Reduce Motion")
                Spacer()
                Text(accessibilityManager.systemReduceMotion ? "On" : "Off")
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text("System Increase Contrast")
                Spacer()
                Text(accessibilityManager.systemIncreaseContrast ? "On" : "Off")
                    .foregroundStyle(.secondary)
            }
            
            Button("Reset Accessibility Settings") {
                accessibilityManager.resetToDefaults()
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AccessibilitySettingsView()
        .frame(width: 500, height: 800)
}
