//
//  BabySmashTheme.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI

/// A theme configuration for BabySmash visual customization
struct BabySmashTheme: Codable, Identifiable, Equatable, Hashable {
    var id: UUID
    var name: String
    var isBuiltIn: Bool
    
    // Background
    var backgroundColor: CodableColor
    var backgroundStyle: BackgroundStyle
    var backgroundGradientColors: [CodableColor]?
    
    // Colors for shapes/letters
    var palette: [CodableColor]
    
    // Shapes
    var enabledShapes: Set<String>  // Using String for Codable compatibility with ShapeType.rawValue
    var shapeStyle: ShapeStyle
    var minShapeSize: CGFloat
    var maxShapeSize: CGFloat
    
    // Effects
    var shadowEnabled: Bool
    var shadowRadius: CGFloat
    var shadowOpacity: Double
    var glowEnabled: Bool
    var glowRadius: CGFloat
    
    // Typography
    var fontName: String
    
    // Face overlay
    var faceStyle: FaceStyle
    
    enum BackgroundStyle: String, Codable, CaseIterable {
        case solid
        case linearGradient
        case radialGradient
        case animatedGradient
        case starfield
        
        var displayName: String {
            switch self {
            case .solid: return "Solid Color"
            case .linearGradient: return "Linear Gradient"
            case .radialGradient: return "Radial Gradient"
            case .animatedGradient: return "Animated Gradient"
            case .starfield: return "Starfield"
            }
        }
    }
    
    enum ShapeStyle: String, Codable, CaseIterable {
        case filled
        case outlined
        case filledWithOutline
        case gradient
        
        var displayName: String {
            switch self {
            case .filled: return "Filled"
            case .outlined: return "Outlined"
            case .filledWithOutline: return "Filled + Outline"
            case .gradient: return "Gradient"
            }
        }
    }
    
    enum FaceStyle: String, Codable, CaseIterable {
        case none
        case simple       // Two dots and a curve
        case kawaii       // Cute anime style
        
        var displayName: String {
            switch self {
            case .none: return "None"
            case .simple: return "Simple"
            case .kawaii: return "Kawaii"
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Returns a set of ShapeType based on enabled shapes
    var enabledShapeTypes: Set<ShapeType> {
        Set(enabledShapes.compactMap { ShapeType(rawValue: $0) })
    }
    
    /// Sets enabled shapes from a set of ShapeType
    mutating func setEnabledShapes(_ shapes: Set<ShapeType>) {
        enabledShapes = Set(shapes.map { $0.rawValue })
    }
    
    /// Returns a random color from the theme palette
    func randomColor() -> Color {
        guard !palette.isEmpty else { return .white }
        return palette.randomElement()!.color
    }
    
    /// Returns a random enabled shape type
    func randomEnabledShape() -> ShapeType {
        let types = enabledShapeTypes
        guard !types.isEmpty else { return .circle }
        return types.randomElement()!
    }
    
    /// Returns a random size within the theme's range
    func randomSize() -> CGFloat {
        CGFloat.random(in: minShapeSize...maxShapeSize)
    }
    
    // Hashable conformance (for use in Picker)
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: BabySmashTheme, rhs: BabySmashTheme) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Built-in Themes

extension BabySmashTheme {
    static let classic = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Classic",
        isBuiltIn: true,
        backgroundColor: .black,
        backgroundStyle: .solid,
        backgroundGradientColors: nil,
        palette: [.red, .blue, .yellow, .green, .purple, .pink, .orange, .cyan, .mint],
        enabledShapes: Set(ShapeType.allCases.map { $0.rawValue }),
        shapeStyle: .gradient,
        minShapeSize: 150,
        maxShapeSize: 300,
        shadowEnabled: true,
        shadowRadius: 15,
        shadowOpacity: 0.5,
        glowEnabled: false,
        glowRadius: 0,
        fontName: "SF Pro Rounded",
        faceStyle: .simple
    )
    
    static let pastel = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Pastel",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.95, green: 0.95, blue: 0.95),
        backgroundStyle: .solid,
        backgroundGradientColors: nil,
        palette: [
            CodableColor(red: 1.0, green: 0.8, blue: 0.8),    // Light pink
            CodableColor(red: 0.8, green: 0.9, blue: 1.0),    // Light blue
            CodableColor(red: 1.0, green: 1.0, blue: 0.8),    // Light yellow
            CodableColor(red: 0.8, green: 1.0, blue: 0.8),    // Light green
            CodableColor(red: 0.9, green: 0.8, blue: 1.0),    // Light purple
            CodableColor(red: 1.0, green: 0.9, blue: 0.8),    // Light peach
        ],
        enabledShapes: Set(ShapeType.allCases.map { $0.rawValue }),
        shapeStyle: .filled,
        minShapeSize: 150,
        maxShapeSize: 280,
        shadowEnabled: true,
        shadowRadius: 10,
        shadowOpacity: 0.2,
        glowEnabled: false,
        glowRadius: 0,
        fontName: "SF Pro Rounded",
        faceStyle: .kawaii
    )
    
    static let highContrast = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "High Contrast",
        isBuiltIn: true,
        backgroundColor: .black,
        backgroundStyle: .solid,
        backgroundGradientColors: nil,
        palette: [
            .red,
            .green,
            .blue,
            .yellow,
            .white,
        ],
        enabledShapes: Set(ShapeType.allCases.map { $0.rawValue }),
        shapeStyle: .filledWithOutline,
        minShapeSize: 200,
        maxShapeSize: 350,
        shadowEnabled: false,
        shadowRadius: 0,
        shadowOpacity: 0,
        glowEnabled: true,
        glowRadius: 5,
        fontName: "SF Pro",
        faceStyle: .simple
    )
    
    static let space = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
        name: "Space",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.05, green: 0.02, blue: 0.1),
        backgroundStyle: .starfield,
        backgroundGradientColors: nil,
        palette: [
            CodableColor(red: 0.6, green: 0.4, blue: 1.0),    // Purple
            CodableColor(red: 0.4, green: 0.6, blue: 1.0),    // Blue
            CodableColor(red: 1.0, green: 1.0, blue: 1.0),    // White
            CodableColor(red: 1.0, green: 0.8, blue: 0.4),    // Gold
            CodableColor(red: 0.4, green: 1.0, blue: 0.8),    // Teal
        ],
        enabledShapes: Set([ShapeType.star.rawValue, ShapeType.circle.rawValue, ShapeType.oval.rawValue]),
        shapeStyle: .gradient,
        minShapeSize: 100,
        maxShapeSize: 250,
        shadowEnabled: true,
        shadowRadius: 20,
        shadowOpacity: 0.8,
        glowEnabled: true,
        glowRadius: 15,
        fontName: "SF Pro Rounded",
        faceStyle: .none
    )
    
    static let nightMode = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
        name: "Night Mode",
        isBuiltIn: true,
        backgroundColor: .black,
        backgroundStyle: .solid,
        backgroundGradientColors: nil,
        palette: [
            CodableColor(red: 0.6, green: 0.3, blue: 0.2),    // Dim red
            CodableColor(red: 0.6, green: 0.5, blue: 0.3),    // Dim orange
            CodableColor(red: 0.5, green: 0.5, blue: 0.3),    // Dim yellow
        ],
        enabledShapes: Set(ShapeType.allCases.map { $0.rawValue }),
        shapeStyle: .filled,
        minShapeSize: 150,
        maxShapeSize: 280,
        shadowEnabled: false,
        shadowRadius: 0,
        shadowOpacity: 0,
        glowEnabled: false,
        glowRadius: 0,
        fontName: "SF Pro Rounded",
        faceStyle: .simple
    )
    
    static let ocean = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000006")!,
        name: "Ocean",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.0, green: 0.1, blue: 0.2),
        backgroundStyle: .linearGradient,
        backgroundGradientColors: [
            CodableColor(red: 0.0, green: 0.1, blue: 0.3),
            CodableColor(red: 0.0, green: 0.2, blue: 0.4),
            CodableColor(red: 0.0, green: 0.15, blue: 0.35)
        ],
        palette: [
            CodableColor(red: 0.3, green: 0.7, blue: 0.9),    // Light blue
            CodableColor(red: 0.2, green: 0.5, blue: 0.8),    // Ocean blue
            CodableColor(red: 0.4, green: 0.8, blue: 0.6),    // Seafoam
            CodableColor(red: 1.0, green: 1.0, blue: 1.0),    // White
            CodableColor(red: 0.2, green: 0.6, blue: 0.5),    // Teal
        ],
        enabledShapes: Set(ShapeType.allCases.map { $0.rawValue }),
        shapeStyle: .gradient,
        minShapeSize: 150,
        maxShapeSize: 300,
        shadowEnabled: true,
        shadowRadius: 15,
        shadowOpacity: 0.4,
        glowEnabled: false,
        glowRadius: 0,
        fontName: "SF Pro Rounded",
        faceStyle: .simple
    )
    
    static let candy = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000007")!,
        name: "Candy",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 1.0, green: 0.9, blue: 0.95),
        backgroundStyle: .linearGradient,
        backgroundGradientColors: [
            CodableColor(red: 1.0, green: 0.85, blue: 0.9),
            CodableColor(red: 0.95, green: 0.9, blue: 1.0),
            CodableColor(red: 1.0, green: 0.9, blue: 0.95)
        ],
        palette: [
            CodableColor(red: 1.0, green: 0.4, blue: 0.6),    // Hot pink
            CodableColor(red: 0.8, green: 0.4, blue: 1.0),    // Purple
            CodableColor(red: 0.4, green: 0.9, blue: 0.9),    // Teal
            CodableColor(red: 1.0, green: 0.6, blue: 0.8),    // Light pink
            CodableColor(red: 0.6, green: 0.4, blue: 0.9),    // Violet
        ],
        enabledShapes: Set(ShapeType.allCases.map { $0.rawValue }),
        shapeStyle: .gradient,
        minShapeSize: 120,
        maxShapeSize: 280,
        shadowEnabled: true,
        shadowRadius: 12,
        shadowOpacity: 0.3,
        glowEnabled: false,
        glowRadius: 0,
        fontName: "SF Pro Rounded",
        faceStyle: .kawaii
    )
    
    /// All built-in themes
    static let allBuiltIn: [BabySmashTheme] = [
        .classic, .pastel, .highContrast, .space, .nightMode, .ocean, .candy
    ]
}
