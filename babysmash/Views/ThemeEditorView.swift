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
                
                Section("Preview") {
                    ThemePreviewView(theme: theme)
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .formStyle(.grouped)
        }
        .frame(minWidth: 550, minHeight: 700)
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
    
    var body: some View {
        ZStack {
            ThemedBackground(theme: theme)
            
            HStack(spacing: 30) {
                // Sample shapes
                ForEach(Array(theme.enabledShapeTypes.prefix(3)), id: \.self) { shape in
                    previewShape(shape)
                }
                
                // Sample letter
                Text("A")
                    .font(.system(size: 50, weight: .heavy, design: .rounded))
                    .foregroundStyle(theme.palette.last?.color.gradient ?? Color.blue.gradient)
                    .shadow(
                        color: theme.shadowEnabled ? .black.opacity(theme.shadowOpacity) : .clear,
                        radius: theme.shadowRadius
                    )
            }
        }
    }
    
    @ViewBuilder
    private func previewShape(_ shape: ShapeType) -> some View {
        let color = theme.palette.first?.color ?? .red
        
        Circle()
            .fill(getPreviewShapeStyle(color))
            .frame(width: 50, height: 50)
            .shadow(
                color: theme.shadowEnabled ? color.opacity(theme.shadowOpacity) : .clear,
                radius: theme.shadowRadius
            )
            .overlay {
                if theme.glowEnabled {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .blur(radius: theme.glowRadius / 3)
                }
            }
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
