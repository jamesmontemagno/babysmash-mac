//
//  TrapezoidShape.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

struct TrapezoidShape: Shape {
    let topWidthRatio: CGFloat = 0.6
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let topInset = rect.width * (1 - topWidthRatio) / 2
        
        path.move(to: CGPoint(x: topInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.width - topInset, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
