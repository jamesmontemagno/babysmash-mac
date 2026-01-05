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
}
