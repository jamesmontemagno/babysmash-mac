//
//  AccessibilitySettings.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI

/// Comprehensive accessibility settings for BabySmash
struct AccessibilitySettings: Codable, Equatable {
    // MARK: - Visual Accessibility
    
    /// High contrast mode for better visibility
    var highContrastMode: Bool = false
    
    /// Large elements mode for easier visibility
    var largeElementsMode: Bool = false
    
    /// Color blindness support mode
    var colorBlindnessMode: ColorBlindnessMode = .none
    
    /// Show patterns on shapes in addition to colors (helps distinguish shapes)
    var showPatterns: Bool = false
    
    /// Minimum shape size when large elements mode is enabled
    var minimumShapeSize: CGFloat = 300
    
    // MARK: - Motion Accessibility
    
    /// Reduce or disable animations
    var reduceMotion: Bool = false
    
    /// Animation speed multiplier
    var animationSpeed: AnimationSpeed = .normal
    
    /// Disable rotation effects specifically
    var disableRotation: Bool = false
    
    // MARK: - Audio Accessibility
    
    /// Show visual indicators when sounds play (flash border)
    var visualSoundIndicators: Bool = false
    
    /// Show text captions for sounds and speech
    var showCaptions: Bool = false
    
    /// Volume boost for better audibility
    var volumeBoost: Bool = false
    
    // MARK: - Motor Accessibility
    
    /// Enable switch control mode
    var switchControlEnabled: Bool = false
    
    /// Auto-play mode (shapes appear automatically)
    var autoPlayMode: Bool = false
    
    /// Interval between auto-played shapes in seconds
    var autoPlayInterval: TimeInterval = 3.0
    
    /// Voice control enabled
    var voiceControlEnabled: Bool = false
    
    // MARK: - Cognitive Accessibility
    
    /// Simplified mode with fewer stimuli
    var simplifiedMode: Bool = false
    
    /// Maximum simultaneous shapes in simplified mode
    var maxSimultaneousShapes: Int = 5
    
    /// Predictable mode with consistent positions
    var predictableMode: Bool = false
    
    /// Focus mode to limit to specific content types
    var focusMode: FocusMode = .all
    
    // MARK: - Photosensitivity
    
    /// Safe mode for photosensitive users (no flashing)
    var photosensitivitySafeMode: Bool = false
    
    /// Maximum animation speed for photosensitivity safety
    var maxAnimationSpeed: Double = 1.0
    
    // MARK: - Enums
    
    enum ColorBlindnessMode: String, Codable, CaseIterable, Identifiable {
        case none = "None"
        case deuteranopia = "Deuteranopia"    // Green-blind (most common)
        case protanopia = "Protanopia"        // Red-blind
        case tritanopia = "Tritanopia"        // Blue-blind
        case monochromacy = "Monochromacy"    // Total color blindness
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .deuteranopia: return "Deuteranopia (Green-blind)"
            case .protanopia: return "Protanopia (Red-blind)"
            case .tritanopia: return "Tritanopia (Blue-blind)"
            case .monochromacy: return "Monochromacy (Grayscale)"
            }
        }
        
        var localizedName: LocalizedStringResource {
            switch self {
            case .none: return L10n.ColorBlindnessModeNames.none
            case .deuteranopia: return L10n.ColorBlindnessModeNames.deuteranopia
            case .protanopia: return L10n.ColorBlindnessModeNames.protanopia
            case .tritanopia: return L10n.ColorBlindnessModeNames.tritanopia
            case .monochromacy: return L10n.ColorBlindnessModeNames.monochromacy
            }
        }
    }
    
    enum AnimationSpeed: String, Codable, CaseIterable, Identifiable {
        case slow = "Slow"
        case normal = "Normal"
        case fast = "Fast"
        case none = "None"
        
        var id: String { rawValue }
        
        var multiplier: Double {
            switch self {
            case .slow: return 2.0      // Slower = longer duration
            case .normal: return 1.0
            case .fast: return 0.5      // Faster = shorter duration
            case .none: return 0        // No animation
            }
        }
        
        var localizedName: LocalizedStringResource {
            switch self {
            case .slow: return L10n.AnimationSpeedNames.slow
            case .normal: return L10n.AnimationSpeedNames.normal
            case .fast: return L10n.AnimationSpeedNames.fast
            case .none: return L10n.AnimationSpeedNames.none
            }
        }
    }
    
    enum FocusMode: String, Codable, CaseIterable, Identifiable {
        case all = "All"
        case lettersOnly = "Letters Only"
        case numbersOnly = "Numbers Only"
        case shapesOnly = "Shapes Only"
        
        var id: String { rawValue }
        
        var displayName: String { rawValue }
        
        var localizedName: LocalizedStringResource {
            switch self {
            case .all: return L10n.FocusModeNames.all
            case .lettersOnly: return L10n.FocusModeNames.lettersOnly
            case .numbersOnly: return L10n.FocusModeNames.numbersOnly
            case .shapesOnly: return L10n.FocusModeNames.shapesOnly
            }
        }
    }
}
