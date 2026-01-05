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
        Section(L10n.Accessibility.Visual.sectionTitle) {
            Toggle(L10n.Accessibility.Visual.highContrastMode, isOn: $accessibilityManager.settings.highContrastMode)
            
            Toggle(L10n.Accessibility.Visual.largeElements, isOn: $accessibilityManager.settings.largeElementsMode)
            
            if accessibilityManager.settings.largeElementsMode {
                HStack {
                    Text(L10n.Accessibility.Visual.minimumSize(Int(accessibilityManager.settings.minimumShapeSize)))
                    Spacer()
                    Slider(
                        value: $accessibilityManager.settings.minimumShapeSize,
                        in: 200...500,
                        step: 50
                    )
                    .frame(width: 200)
                }
            }
            
            Picker(L10n.Accessibility.Visual.colorBlindnessMode, selection: $accessibilityManager.settings.colorBlindnessMode) {
                ForEach(AccessibilitySettings.ColorBlindnessMode.allCases) { mode in
                    Text(mode.localizedName).tag(mode)
                }
            }
            
            if accessibilityManager.settings.colorBlindnessMode != .none {
                Toggle(L10n.Accessibility.Visual.showPatternsOnShapes, isOn: $accessibilityManager.settings.showPatterns)
                
                Text(L10n.Accessibility.Visual.patternsDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Motion Section
    
    private var motionSection: some View {
        Section(L10n.Accessibility.Motion.sectionTitle) {
            Toggle(L10n.Accessibility.Motion.reduceMotion, isOn: $accessibilityManager.settings.reduceMotion)
            
            if !accessibilityManager.settings.reduceMotion {
                Picker(L10n.Accessibility.Motion.animationSpeed, selection: $accessibilityManager.settings.animationSpeed) {
                    ForEach(AccessibilitySettings.AnimationSpeed.allCases) { speed in
                        Text(speed.localizedName).tag(speed)
                    }
                }
                
                Toggle(L10n.Accessibility.Motion.disableRotationEffects, isOn: $accessibilityManager.settings.disableRotation)
            }
            
            if accessibilityManager.systemReduceMotion {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundStyle(.blue)
                    Text(L10n.Accessibility.Motion.systemReduceMotionEnabled)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    // MARK: - Audio Section
    
    private var audioSection: some View {
        Section(L10n.Accessibility.Audio.sectionTitle) {
            Toggle(L10n.Accessibility.Audio.visualSoundIndicators, isOn: $accessibilityManager.settings.visualSoundIndicators)
            
            Text(L10n.Accessibility.Audio.flashesDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Toggle(L10n.Accessibility.Audio.showCaptions, isOn: $accessibilityManager.settings.showCaptions)
            
            Text(L10n.Accessibility.Audio.captionsDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Toggle(L10n.Accessibility.Audio.volumeBoost, isOn: $accessibilityManager.settings.volumeBoost)
        }
    }
    
    // MARK: - Motor Section
    
    private var motorSection: some View {
        Section(L10n.Accessibility.Motor.sectionTitle) {
            Toggle(L10n.Accessibility.Motor.autoPlayMode, isOn: $accessibilityManager.settings.autoPlayMode)
            
            if accessibilityManager.settings.autoPlayMode {
                HStack {
                    Text(L10n.Accessibility.Motor.interval(Int(accessibilityManager.settings.autoPlayInterval)))
                    Spacer()
                    Slider(
                        value: $accessibilityManager.settings.autoPlayInterval,
                        in: 1...10,
                        step: 1
                    )
                    .frame(width: 200)
                }
                
                Text(L10n.Accessibility.Motor.autoPlayDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Toggle(L10n.Accessibility.Motor.switchControlMode, isOn: $accessibilityManager.settings.switchControlEnabled)
            
            Text(L10n.Accessibility.Motor.switchControlDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Cognitive Section
    
    private var cognitiveSection: some View {
        Section(L10n.Accessibility.Cognitive.sectionTitle) {
            Toggle(L10n.Accessibility.Cognitive.simplifiedMode, isOn: $accessibilityManager.settings.simplifiedMode)
            
            if accessibilityManager.settings.simplifiedMode {
                HStack {
                    Text(L10n.Accessibility.Cognitive.maxShapes(accessibilityManager.settings.maxSimultaneousShapes))
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
                
                Text(L10n.Accessibility.Cognitive.maxShapesDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Toggle(L10n.Accessibility.Cognitive.predictableMode, isOn: $accessibilityManager.settings.predictableMode)
            
            Text(L10n.Accessibility.Cognitive.predictableModeDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Picker(L10n.Accessibility.Cognitive.focus, selection: $accessibilityManager.settings.focusMode) {
                ForEach(AccessibilitySettings.FocusMode.allCases) { mode in
                    Text(mode.localizedName).tag(mode)
                }
            }
            
            Text(L10n.Accessibility.Cognitive.focusDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Photosensitivity Section
    
    private var photosensitivitySection: some View {
        Section(L10n.Accessibility.Photosensitivity.sectionTitle) {
            Toggle(L10n.Accessibility.Photosensitivity.safeMode, isOn: $accessibilityManager.settings.photosensitivitySafeMode)
            
            Text(L10n.Accessibility.Photosensitivity.safeModeDescription)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - System Info Section
    
    private var systemInfoSection: some View {
        Section(L10n.Accessibility.System.sectionTitle) {
            HStack {
                Text(L10n.Accessibility.System.voiceOver)
                Spacer()
                Text(accessibilityManager.isVoiceOverRunning ? L10n.Common.running : L10n.Common.off)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text(L10n.Accessibility.System.systemReduceMotion)
                Spacer()
                Text(accessibilityManager.systemReduceMotion ? L10n.Common.on : L10n.Common.off)
                    .foregroundStyle(.secondary)
            }
            
            HStack {
                Text(L10n.Accessibility.System.systemIncreaseContrast)
                Spacer()
                Text(accessibilityManager.systemIncreaseContrast ? L10n.Common.on : L10n.Common.off)
                    .foregroundStyle(.secondary)
            }
            
            Button(L10n.Accessibility.System.resetAccessibilitySettings) {
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
