//
//  ShapeType.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

enum ShapeType: String, CaseIterable, Identifiable {
    case circle
    case oval
    case rectangle
    case square
    case triangle
    case hexagon
    case trapezoid
    case star
    case heart
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .circle: return L10n.ShapeNames.circle
        case .oval: return L10n.ShapeNames.oval
        case .rectangle: return L10n.ShapeNames.rectangle
        case .square: return L10n.ShapeNames.square
        case .triangle: return L10n.ShapeNames.triangle
        case .hexagon: return L10n.ShapeNames.hexagon
        case .trapezoid: return L10n.ShapeNames.trapezoid
        case .star: return L10n.ShapeNames.star
        case .heart: return L10n.ShapeNames.heart
        }
    }
    
    static var random: ShapeType {
        allCases.randomElement()!
    }
}
