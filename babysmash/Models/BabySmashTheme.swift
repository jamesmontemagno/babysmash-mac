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
    
    static let rainbow = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000008")!,
        name: "Rainbow",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.1, green: 0.1, blue: 0.15),
        backgroundStyle: .animatedGradient,
        backgroundGradientColors: [
            CodableColor(red: 0.15, green: 0.1, blue: 0.2),
            CodableColor(red: 0.1, green: 0.15, blue: 0.2),
            CodableColor(red: 0.1, green: 0.1, blue: 0.2)
        ],
        palette: [
            CodableColor(red: 1.0, green: 0.2, blue: 0.2),    // Red
            CodableColor(red: 1.0, green: 0.6, blue: 0.2),    // Orange
            CodableColor(red: 1.0, green: 1.0, blue: 0.2),    // Yellow
            CodableColor(red: 0.2, green: 1.0, blue: 0.4),    // Green
            CodableColor(red: 0.2, green: 0.6, blue: 1.0),    // Blue
            CodableColor(red: 0.6, green: 0.3, blue: 1.0),    // Indigo
            CodableColor(red: 0.9, green: 0.4, blue: 1.0),    // Violet
        ],
        enabledShapes: Set(ShapeType.allCases.map { $0.rawValue }),
        shapeStyle: .gradient,
        minShapeSize: 150,
        maxShapeSize: 320,
        shadowEnabled: true,
        shadowRadius: 20,
        shadowOpacity: 0.6,
        glowEnabled: true,
        glowRadius: 10,
        fontName: "SF Pro Rounded",
        faceStyle: .simple
    )
    
    static let dinosaur = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000009")!,
        name: "Dinosaur",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.15, green: 0.25, blue: 0.1),
        backgroundStyle: .linearGradient,
        backgroundGradientColors: [
            CodableColor(red: 0.1, green: 0.2, blue: 0.05),
            CodableColor(red: 0.2, green: 0.3, blue: 0.1),
            CodableColor(red: 0.15, green: 0.25, blue: 0.08)
        ],
        palette: [
            CodableColor(red: 0.4, green: 0.8, blue: 0.3),    // Bright green
            CodableColor(red: 0.6, green: 0.5, blue: 0.3),    // Brown
            CodableColor(red: 1.0, green: 0.7, blue: 0.2),    // Orange-gold
            CodableColor(red: 0.3, green: 0.6, blue: 0.4),    // Forest green
            CodableColor(red: 0.8, green: 0.4, blue: 0.2),    // Rust
            CodableColor(red: 0.5, green: 0.7, blue: 0.3),    // Lime
        ],
        enabledShapes: Set([ShapeType.triangle.rawValue, ShapeType.oval.rawValue, ShapeType.hexagon.rawValue, ShapeType.star.rawValue]),
        shapeStyle: .filledWithOutline,
        minShapeSize: 180,
        maxShapeSize: 350,
        shadowEnabled: true,
        shadowRadius: 15,
        shadowOpacity: 0.5,
        glowEnabled: false,
        glowRadius: 0,
        fontName: "Marker Felt",
        faceStyle: .simple
    )
    
    static let princess = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000000A")!,
        name: "Princess",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.95, green: 0.85, blue: 0.95),
        backgroundStyle: .radialGradient,
        backgroundGradientColors: [
            CodableColor(red: 1.0, green: 0.9, blue: 1.0),
            CodableColor(red: 0.95, green: 0.8, blue: 0.95),
            CodableColor(red: 0.9, green: 0.75, blue: 0.9)
        ],
        palette: [
            CodableColor(red: 1.0, green: 0.4, blue: 0.7),    // Pink
            CodableColor(red: 0.8, green: 0.5, blue: 1.0),    // Lavender
            CodableColor(red: 1.0, green: 0.85, blue: 0.3),   // Gold
            CodableColor(red: 0.6, green: 0.9, blue: 1.0),    // Sky blue
            CodableColor(red: 1.0, green: 0.6, blue: 0.8),    // Rose
            CodableColor(red: 0.9, green: 0.7, blue: 1.0),    // Light purple
        ],
        enabledShapes: Set([ShapeType.heart.rawValue, ShapeType.star.rawValue, ShapeType.circle.rawValue, ShapeType.oval.rawValue]),
        shapeStyle: .gradient,
        minShapeSize: 140,
        maxShapeSize: 300,
        shadowEnabled: true,
        shadowRadius: 15,
        shadowOpacity: 0.4,
        glowEnabled: true,
        glowRadius: 8,
        fontName: "SF Pro Rounded",
        faceStyle: .kawaii
    )
    
    static let superhero = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000000B")!,
        name: "Superhero",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.05, green: 0.05, blue: 0.15),
        backgroundStyle: .radialGradient,
        backgroundGradientColors: [
            CodableColor(red: 0.1, green: 0.05, blue: 0.2),
            CodableColor(red: 0.05, green: 0.05, blue: 0.15),
            CodableColor(red: 0.02, green: 0.02, blue: 0.1)
        ],
        palette: [
            CodableColor(red: 1.0, green: 0.2, blue: 0.2),    // Red
            CodableColor(red: 0.2, green: 0.4, blue: 1.0),    // Blue
            CodableColor(red: 1.0, green: 0.85, blue: 0.1),   // Gold/Yellow
            CodableColor(red: 0.1, green: 0.1, blue: 0.1),    // Black
            CodableColor(red: 0.9, green: 0.9, blue: 0.9),    // Silver
        ],
        enabledShapes: Set([ShapeType.star.rawValue, ShapeType.hexagon.rawValue, ShapeType.triangle.rawValue, ShapeType.square.rawValue]),
        shapeStyle: .filledWithOutline,
        minShapeSize: 180,
        maxShapeSize: 350,
        shadowEnabled: true,
        shadowRadius: 25,
        shadowOpacity: 0.7,
        glowEnabled: true,
        glowRadius: 15,
        fontName: "SF Pro",
        faceStyle: .none
    )
    
    static let farm = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000000C")!,
        name: "Farm",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.5, green: 0.8, blue: 0.95),
        backgroundStyle: .linearGradient,
        backgroundGradientColors: [
            CodableColor(red: 0.5, green: 0.8, blue: 0.95),   // Sky blue
            CodableColor(red: 0.6, green: 0.85, blue: 0.5),   // Light green
            CodableColor(red: 0.4, green: 0.7, blue: 0.3)     // Grass green
        ],
        palette: [
            CodableColor(red: 0.9, green: 0.3, blue: 0.2),    // Barn red
            CodableColor(red: 1.0, green: 0.9, blue: 0.5),    // Hay yellow
            CodableColor(red: 0.6, green: 0.4, blue: 0.2),    // Brown
            CodableColor(red: 1.0, green: 1.0, blue: 1.0),    // White
            CodableColor(red: 0.3, green: 0.6, blue: 0.3),    // Green
            CodableColor(red: 1.0, green: 0.6, blue: 0.4),    // Peach/pig pink
        ],
        enabledShapes: Set(ShapeType.allCases.map { $0.rawValue }),
        shapeStyle: .filled,
        minShapeSize: 150,
        maxShapeSize: 300,
        shadowEnabled: true,
        shadowRadius: 10,
        shadowOpacity: 0.3,
        glowEnabled: false,
        glowRadius: 0,
        fontName: "Chalkboard SE",
        faceStyle: .simple
    )
    
    static let underwater = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000000D")!,
        name: "Underwater",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.0, green: 0.15, blue: 0.3),
        backgroundStyle: .animatedGradient,
        backgroundGradientColors: [
            CodableColor(red: 0.0, green: 0.2, blue: 0.4),
            CodableColor(red: 0.0, green: 0.15, blue: 0.35),
            CodableColor(red: 0.0, green: 0.1, blue: 0.25)
        ],
        palette: [
            CodableColor(red: 0.3, green: 0.9, blue: 0.9),    // Aqua
            CodableColor(red: 1.0, green: 0.5, blue: 0.3),    // Clownfish orange
            CodableColor(red: 0.9, green: 0.9, blue: 0.3),    // Yellow fish
            CodableColor(red: 0.8, green: 0.3, blue: 0.8),    // Purple
            CodableColor(red: 0.3, green: 1.0, blue: 0.5),    // Sea green
            CodableColor(red: 1.0, green: 0.4, blue: 0.6),    // Coral pink
        ],
        enabledShapes: Set([ShapeType.circle.rawValue, ShapeType.oval.rawValue, ShapeType.heart.rawValue, ShapeType.star.rawValue]),
        shapeStyle: .gradient,
        minShapeSize: 120,
        maxShapeSize: 280,
        shadowEnabled: true,
        shadowRadius: 15,
        shadowOpacity: 0.5,
        glowEnabled: true,
        glowRadius: 10,
        fontName: "SF Pro Rounded",
        faceStyle: .kawaii
    )
    
    static let circus = BabySmashTheme(
        id: UUID(uuidString: "00000000-0000-0000-0000-00000000000E")!,
        name: "Circus",
        isBuiltIn: true,
        backgroundColor: CodableColor(red: 0.15, green: 0.1, blue: 0.2),
        backgroundStyle: .radialGradient,
        backgroundGradientColors: [
            CodableColor(red: 0.25, green: 0.1, blue: 0.15),
            CodableColor(red: 0.15, green: 0.1, blue: 0.2),
            CodableColor(red: 0.1, green: 0.05, blue: 0.15)
        ],
        palette: [
            CodableColor(red: 1.0, green: 0.2, blue: 0.2),    // Circus red
            CodableColor(red: 1.0, green: 0.85, blue: 0.2),   // Gold
            CodableColor(red: 1.0, green: 1.0, blue: 1.0),    // White
            CodableColor(red: 0.2, green: 0.6, blue: 1.0),    // Blue
            CodableColor(red: 1.0, green: 0.5, blue: 0.0),    // Orange
        ],
        enabledShapes: Set([ShapeType.star.rawValue, ShapeType.circle.rawValue, ShapeType.triangle.rawValue, ShapeType.hexagon.rawValue]),
        shapeStyle: .filledWithOutline,
        minShapeSize: 150,
        maxShapeSize: 320,
        shadowEnabled: true,
        shadowRadius: 20,
        shadowOpacity: 0.6,
        glowEnabled: true,
        glowRadius: 12,
        fontName: "American Typewriter",
        faceStyle: .simple
    )
    
    /// All built-in themes
    static let allBuiltIn: [BabySmashTheme] = [
        .classic, .pastel, .highContrast, .space, .nightMode, .ocean, .candy,
        .rainbow, .dinosaur, .princess, .superhero, .farm, .underwater, .circus
    ]
}
