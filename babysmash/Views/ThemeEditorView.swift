//
//  ThemeEditorView.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI

/// A view for editing theme properties
struct ThemeEditorView: View {
    @Binding var theme: BabySmashTheme
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var themeManager = ThemeManager.shared
    
    @State private var showColorPicker = false
    @State private var editingColorIndex: Int?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(theme.isBuiltIn ? "Duplicate Theme" : "Edit Theme")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                Button("Save") {
                    saveTheme()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(.ultraThinMaterial)
            
            // Scrollable form content
            Form {
                Section("Basic") {
                    TextField("Theme Name", text: $theme.name)
                    
                    Picker("Background Style", selection: $theme.backgroundStyle) {
                        ForEach(BabySmashTheme.BackgroundStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    
                    ColorPicker("Background Color", selection: backgroundColorBinding)
                    
                    if theme.backgroundStyle != .solid && theme.backgroundStyle != .starfield {
                        VStack(alignment: .leading) {
                            Text("Gradient Colors")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            HStack {
                                ForEach(Array((theme.backgroundGradientColors ?? []).enumerated()), id: \.offset) { index, color in
                                    ColorPicker("", selection: gradientColorBinding(at: index))
                                        .labelsHidden()
                                }
                                
                                Button {
                                    var colors = theme.backgroundGradientColors ?? []
                                    colors.append(CodableColor(.white))
                                    theme.backgroundGradientColors = colors
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                
                Section("Color Palette") {
                    ForEach(Array(theme.palette.enumerated()), id: \.offset) { index, color in
                        HStack {
                            ColorPicker("Color \(index + 1)", selection: paletteBinding(at: index))
                            
                            Spacer()
                            
                            Button(role: .destructive) {
                                theme.palette.remove(at: index)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .disabled(theme.palette.count <= 1)
                        }
                    }
                    
                    Button {
                        theme.palette.append(CodableColor(.white))
                    } label: {
                        Label("Add Color", systemImage: "plus.circle.fill")
                    }
                }
                
                Section("Shapes") {
                    ForEach(ShapeType.allCases) { shape in
                        Toggle(shape.displayName, isOn: shapeBinding(for: shape))
                    }
                    
                    Picker("Shape Style", selection: $theme.shapeStyle) {
                        ForEach(BabySmashTheme.ShapeStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Size Range: \(Int(theme.minShapeSize)) - \(Int(theme.maxShapeSize))")
                        HStack {
                            Text("Min")
                                .font(.caption)
                            Slider(value: $theme.minShapeSize, in: 50...200, step: 10)
                            Text("Max")
                                .font(.caption)
                            Slider(value: $theme.maxShapeSize, in: 200...500, step: 10)
                        }
                    }
                }
                
                Section("Effects") {
                    Toggle("Enable Shadow", isOn: $theme.shadowEnabled)
                    if theme.shadowEnabled {
                        HStack {
                            Text("Shadow Radius: \(Int(theme.shadowRadius))")
                            Slider(value: $theme.shadowRadius, in: 0...30, step: 1)
                        }
                        HStack {
                            Text("Shadow Opacity: \(Int(theme.shadowOpacity * 100))%")
                            Slider(value: $theme.shadowOpacity, in: 0...1, step: 0.1)
                        }
                    }
                    
                    Toggle("Enable Glow", isOn: $theme.glowEnabled)
                    if theme.glowEnabled {
                        HStack {
                            Text("Glow Radius: \(Int(theme.glowRadius))")
                            Slider(value: $theme.glowRadius, in: 0...30, step: 1)
                        }
                    }
                }
                
                Section("Face Overlay") {
                    Picker("Face Style", selection: $theme.faceStyle) {
                        ForEach(BabySmashTheme.FaceStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            
            // Sticky live preview at bottom
            VStack(spacing: 0) {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Live Preview")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(theme.name.isEmpty ? "Untitled Theme" : theme.name)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    ThemePreviewView(theme: theme)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                        .padding(.bottom, 12)
                }
                .background(.ultraThinMaterial)
            }
        }
        .frame(minWidth: 550, minHeight: 750)
    }
    
    // MARK: - Bindings
    
    private var backgroundColorBinding: Binding<Color> {
        Binding(
            get: { theme.backgroundColor.color },
            set: { theme.backgroundColor = CodableColor($0) }
        )
    }
    
    private func gradientColorBinding(at index: Int) -> Binding<Color> {
        Binding(
            get: {
                guard let colors = theme.backgroundGradientColors, index < colors.count else {
                    return .white
                }
                return colors[index].color
            },
            set: { newColor in
                var colors = theme.backgroundGradientColors ?? []
                if index < colors.count {
                    colors[index] = CodableColor(newColor)
                    theme.backgroundGradientColors = colors
                }
            }
        )
    }
    
    private func paletteBinding(at index: Int) -> Binding<Color> {
        Binding(
            get: { theme.palette[index].color },
            set: { theme.palette[index] = CodableColor($0) }
        )
    }
    
    private func shapeBinding(for shape: ShapeType) -> Binding<Bool> {
        Binding(
            get: { theme.enabledShapes.contains(shape.rawValue) },
            set: { enabled in
                if enabled {
                    theme.enabledShapes.insert(shape.rawValue)
                } else if theme.enabledShapes.count > 1 {
                    theme.enabledShapes.remove(shape.rawValue)
                }
            }
        )
    }
    
    // MARK: - Actions
    
    private func saveTheme() {
        var themeToSave = theme
        
        // If duplicating a built-in theme, create a new ID
        if theme.isBuiltIn {
            themeToSave.id = UUID()
            themeToSave.isBuiltIn = false
        }
        
        themeManager.saveCustomTheme(themeToSave)
        themeManager.selectTheme(themeToSave)
        dismiss()
    }
}

/// A preview view showing sample shapes with theme styling
struct ThemePreviewView: View {
    let theme: BabySmashTheme
    
    private var previewShapes: [(ShapeType, Color, CGPoint)] {
        let shapes = Array(theme.enabledShapeTypes.prefix(4))
        let colors = theme.palette.map { $0.color }
        
        return [
            (shapes.indices.contains(0) ? shapes[0] : .circle, colors.indices.contains(0) ? colors[0] : .red, CGPoint(x: 80, y: 60)),
            (shapes.indices.contains(1) ? shapes[1] : .star, colors.indices.contains(1) ? colors[1] : .blue, CGPoint(x: 200, y: 80)),
            (shapes.indices.contains(2) ? shapes[2] : .heart, colors.indices.contains(2) ? colors[2] : .green, CGPoint(x: 320, y: 55)),
            (shapes.indices.contains(3) ? shapes[3] : .triangle, colors.indices.contains(3) ? colors[3] : .orange, CGPoint(x: 440, y: 75))
        ]
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ThemedBackground(theme: theme)
                
                // Sample shapes scattered across preview
                ForEach(Array(previewShapes.enumerated()), id: \.offset) { index, item in
                    let (shape, color, basePos) = item
                    let xScale = geometry.size.width / 520
                    let yScale = geometry.size.height / 140
                    
                    previewShapeView(shape, color: color)
                        .position(x: basePos.x * xScale, y: basePos.y * yScale)
                }
                
                // Sample letter
                Text("B")
                    .font(.custom(theme.fontName, size: 55).weight(.heavy))
                    .foregroundStyle(getTextStyle())
                    .shadow(
                        color: theme.shadowEnabled ? (theme.palette.last?.color ?? .purple).opacity(theme.shadowOpacity) : .clear,
                        radius: theme.shadowRadius,
                        x: 3,
                        y: 3
                    )
                    .overlay {
                        if theme.glowEnabled {
                            Text("B")
                                .font(.custom(theme.fontName, size: 55).weight(.heavy))
                                .foregroundStyle(theme.palette.last?.color ?? .purple)
                                .blur(radius: theme.glowRadius / 2)
                        }
                    }
                    .position(x: geometry.size.width * 0.85, y: geometry.size.height * 0.5)
            }
        }
    }
    
    private func getTextStyle() -> AnyShapeStyle {
        let color = theme.palette.last?.color ?? .purple
        switch theme.shapeStyle {
        case .gradient:
            return AnyShapeStyle(color.gradient)
        default:
            return AnyShapeStyle(color)
        }
    }
    
    @ViewBuilder
    private func previewShapeView(_ shape: ShapeType, color: Color) -> some View {
        let size: CGFloat = 50
        
        shapeContent(shape)
            .fill(getPreviewShapeStyle(color))
            .frame(width: size, height: size)
            .overlay {
                if theme.shapeStyle == .outlined || theme.shapeStyle == .filledWithOutline {
                    shapeContent(shape)
                        .stroke(color, lineWidth: 2)
                }
            }
            .shadow(
                color: theme.shadowEnabled ? color.opacity(theme.shadowOpacity) : .clear,
                radius: theme.shadowRadius,
                x: 3,
                y: 3
            )
            .overlay {
                if theme.glowEnabled {
                    shapeContent(shape)
                        .stroke(color, lineWidth: 2)
                        .blur(radius: theme.glowRadius / 3)
                }
            }
            .overlay {
                if theme.faceStyle != .none {
                    miniKawaiiFace(size: size)
                }
            }
    }
    
    private func shapeContent(_ type: ShapeType) -> AnyShape {
        switch type {
        case .circle:
            return AnyShape(Circle())
        case .oval:
            return AnyShape(Ellipse())
        case .rectangle:
            return AnyShape(RoundedRectangle(cornerRadius: 8))
        case .square:
            return AnyShape(RoundedRectangle(cornerRadius: 6))
        case .triangle:
            return AnyShape(TriangleShape())
        case .hexagon:
            return AnyShape(HexagonShape())
        case .trapezoid:
            return AnyShape(TrapezoidShape())
        case .star:
            return AnyShape(StarShape())
        case .heart:
            return AnyShape(HeartShape())
        }
    }
    
    private func miniKawaiiFace(size: CGFloat) -> some View {
        VStack(spacing: size * 0.02) {
            // Eyes
            HStack(spacing: size * 0.12) {
                Circle()
                    .fill(.black)
                    .frame(width: size * 0.08, height: size * 0.08)
                Circle()
                    .fill(.black)
                    .frame(width: size * 0.08, height: size * 0.08)
            }
            // Smile
            Arc(startAngle: .degrees(0), endAngle: .degrees(180), clockwise: false)
                .stroke(.black, lineWidth: 1.5)
                .frame(width: size * 0.15, height: size * 0.08)
        }
        .offset(y: -size * 0.03)
    }

    private func getPreviewShapeStyle(_ color: Color) -> AnyShapeStyle {
        switch theme.shapeStyle {
        case .filled, .filledWithOutline:
            return AnyShapeStyle(color)
        case .gradient:
            return AnyShapeStyle(color.gradient)
        case .outlined:
            return AnyShapeStyle(color.opacity(0.3))
        }
    }
}

#Preview {
    ThemeEditorView(theme: .constant(.classic))
}
