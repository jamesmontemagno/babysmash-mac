//
//  Color+Random.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

extension Color {
    static let babySmashColors: [Color] = [
        .red, .blue, .yellow, .green, .purple, .pink, .orange, .cyan, .mint
    ]
    
    static var randomBabySmash: Color {
        babySmashColors.randomElement()!
    }
    
    static func randomGradient() -> LinearGradient {
        let baseColor = randomBabySmash
        return LinearGradient(
            colors: [baseColor.opacity(0.7), baseColor, baseColor.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var name: String {
        switch self {
        case .red: return "Red"
        case .blue: return "Blue"
        case .yellow: return "Yellow"
        case .green: return "Green"
        case .purple: return "Purple"
        case .pink: return "Pink"
        case .orange: return "Orange"
        case .cyan: return "Cyan"
        case .mint: return "Mint"
        default: return "Colorful"
        }
    }
    
    // MARK: - Color Blindness Safe Palettes
    
    /// Deuteranopia-safe palette (green-blind friendly)
    /// These colors are distinguishable for people with deuteranopia
    static let deuteranopiaSafe: [Color] = [
        Color(red: 0.0, green: 0.45, blue: 0.70),   // Blue
        Color(red: 0.90, green: 0.60, blue: 0.0),   // Orange
        Color(red: 0.80, green: 0.40, blue: 0.70),  // Purple
        Color(red: 0.95, green: 0.90, blue: 0.25),  // Yellow
        Color(red: 0.0, green: 0.0, blue: 0.0),     // Black
        Color(red: 1.0, green: 1.0, blue: 1.0),     // White
    ]
    
    /// Protanopia-safe palette (red-blind friendly)
    /// These colors are distinguishable for people with protanopia
    static let protanopiaSafe: [Color] = [
        Color(red: 0.0, green: 0.45, blue: 0.70),   // Blue
        Color(red: 0.95, green: 0.90, blue: 0.25),  // Yellow
        Color(red: 0.35, green: 0.70, blue: 0.90),  // Sky blue
        Color(red: 0.0, green: 0.60, blue: 0.50),   // Teal
        Color(red: 0.0, green: 0.0, blue: 0.0),     // Black
    ]
    
    /// Tritanopia-safe palette (blue-blind friendly)
    /// These colors are distinguishable for people with tritanopia
    static let tritanopiaSafe: [Color] = [
        Color(red: 0.80, green: 0.0, blue: 0.0),    // Red
        Color(red: 0.0, green: 0.60, blue: 0.0),    // Green
        Color(red: 0.90, green: 0.60, blue: 0.0),   // Orange
        Color(red: 0.60, green: 0.0, blue: 0.40),   // Magenta
        Color(red: 0.0, green: 0.0, blue: 0.0),     // Black
    ]
    
    /// Monochromacy palette (grayscale for total color blindness)
    static let monochromacySafe: [Color] = [
        .black,
        Color(red: 0.25, green: 0.25, blue: 0.25),  // Dark gray
        Color(red: 0.5, green: 0.5, blue: 0.5),     // Medium gray
        Color(red: 0.75, green: 0.75, blue: 0.75),  // Light gray
        .white,
    ]
    
    /// High contrast palette for maximum visibility
    static let highContrastColors: [Color] = [
        .black,
        .white,
        Color(red: 1.0, green: 0.0, blue: 0.0),     // Pure red
        Color(red: 0.0, green: 0.0, blue: 1.0),     // Pure blue
        Color(red: 1.0, green: 1.0, blue: 0.0),     // Pure yellow
    ]
    
    /// Returns the appropriate color palette for a given color blindness mode
    static func paletteFor(_ mode: AccessibilitySettings.ColorBlindnessMode) -> [Color] {
        switch mode {
        case .none:
            return babySmashColors
        case .deuteranopia:
            return deuteranopiaSafe
        case .protanopia:
            return protanopiaSafe
        case .tritanopia:
            return tritanopiaSafe
        case .monochromacy:
            return monochromacySafe
        }
    }
    
    /// Returns a random color from the palette appropriate for the given color blindness mode
    static func randomColorFor(_ mode: AccessibilitySettings.ColorBlindnessMode) -> Color {
        paletteFor(mode).randomElement() ?? .white
    }
}
