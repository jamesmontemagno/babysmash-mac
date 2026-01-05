//
//  AccessibilitySettingsManager.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI
import Combine

/// Manages accessibility settings and observes system accessibility state
class AccessibilitySettingsManager: ObservableObject {
    static let shared = AccessibilitySettingsManager()
    
    @Published var settings = AccessibilitySettings()
    
    // MARK: - System Accessibility State
    
    @Published var isVoiceOverRunning: Bool = false
    @Published var systemReduceMotion: Bool = false
    @Published var systemIncreaseContrast: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Current Caption (for visual sound indicators)
    
    @Published var currentCaption: String = ""
    @Published var showSoundIndicator: Bool = false
    
    private init() {
        loadSettings()
        observeSystemAccessibility()
    }
    
    // MARK: - System Accessibility Observation
    
    private func observeSystemAccessibility() {
        // Check initial system accessibility state
        updateSystemAccessibilityState()
        
        // Observe workspace notifications for accessibility changes
        NotificationCenter.default.publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .sink { [weak self] _ in
                self?.updateSystemAccessibilityState()
            }
            .store(in: &cancellables)
    }
    
    private func updateSystemAccessibilityState() {
        let workspace = NSWorkspace.shared
        systemReduceMotion = workspace.accessibilityDisplayShouldReduceMotion
        systemIncreaseContrast = workspace.accessibilityDisplayShouldIncreaseContrast
        isVoiceOverRunning = NSWorkspace.shared.isVoiceOverEnabled
    }
    
    // MARK: - Computed Properties
    
    /// Returns true if motion should be reduced (either user setting or system setting)
    var effectiveReduceMotion: Bool {
        settings.reduceMotion || systemReduceMotion || settings.photosensitivitySafeMode
    }
    
    /// Returns true if high contrast should be used (either user setting or system setting)
    var effectiveHighContrast: Bool {
        settings.highContrastMode || systemIncreaseContrast
    }
    
    /// Returns the effective animation speed considering all settings
    var effectiveAnimationSpeed: AccessibilitySettings.AnimationSpeed {
        if effectiveReduceMotion || settings.animationSpeed == .none {
            return .none
        }
        return settings.animationSpeed
    }
    
    /// Returns the effective minimum shape size
    var effectiveMinimumShapeSize: CGFloat {
        if settings.largeElementsMode {
            return max(settings.minimumShapeSize, 300)
        }
        return 150 // Default minimum
    }
    
    /// Returns the effective maximum shapes count
    var effectiveMaxShapes: Int {
        if settings.simplifiedMode {
            return settings.maxSimultaneousShapes
        }
        return 50 // Default max
    }
    
    // MARK: - Sound Indicator Methods
    
    /// Shows a visual sound indicator and optionally a caption
    func triggerSoundIndicator(caption: String? = nil) {
        guard settings.visualSoundIndicators || settings.showCaptions else { return }
        
        if settings.visualSoundIndicators {
            showSoundIndicator = true
            
            // Auto-dismiss after a short duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.showSoundIndicator = false
            }
        }
        
        if settings.showCaptions, let caption = caption {
            currentCaption = caption
            
            // Auto-dismiss caption after longer duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                if self?.currentCaption == caption {
                    self?.currentCaption = ""
                }
            }
        }
    }
    
    // MARK: - Persistence
    
    private static let settingsKey = "accessibilitySettings"
    
    private func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: Self.settingsKey),
           let decoded = try? JSONDecoder().decode(AccessibilitySettings.self, from: data) {
            settings = decoded
        }
    }
    
    func saveSettings() {
        if let encoded = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(encoded, forKey: Self.settingsKey)
        }
    }
    
    /// Resets all accessibility settings to defaults
    func resetToDefaults() {
        settings = AccessibilitySettings()
        saveSettings()
    }
}

// MARK: - NSWorkspace Extension

extension NSWorkspace {
    /// Returns true if VoiceOver is currently running
    /// Uses a more reliable method by checking for the VoiceOver process
    var isVoiceOverEnabled: Bool {
        // VoiceOver is running if the VoiceOver process exists
        // We can check this via the accessibility API's voiceOverEnabled flag
        // or by checking if the com.apple.VoiceOver bundle is loaded
        
        // For macOS 10.15+, we can use the accessibility API
        // This is a simplified check - VoiceOver running typically means
        // accessibility features are actively being used
        let runningApps = NSWorkspace.shared.runningApplications
        return runningApps.contains { $0.bundleIdentifier == "com.apple.VoiceOver" }
    }
}
