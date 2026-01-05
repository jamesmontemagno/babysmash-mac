//
//  ThemeManager.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import SwiftUI

/// Manages theme selection and persistence for BabySmash
class ThemeManager: ObservableObject {
    /// Singleton instance for app-wide access
    static let shared = ThemeManager()
    
    /// The currently selected theme
    @Published var currentTheme: BabySmashTheme
    
    /// User-created custom themes
    @Published var customThemes: [BabySmashTheme] = []
    
    /// Storage key for selected theme ID
    @AppStorage("selectedThemeID") private var selectedThemeID: String = ""
    
    private init() {
        // Load custom themes first
        customThemes = Self.loadCustomThemes()
        
        // Load saved theme or default to classic
        if let saved = customThemes.first(where: { $0.id.uuidString == selectedThemeID }) {
            currentTheme = saved
        } else if let builtIn = BabySmashTheme.allBuiltIn.first(where: { $0.id.uuidString == selectedThemeID }) {
            currentTheme = builtIn
        } else {
            currentTheme = .classic
        }
    }
    
    /// Selects a theme as the current theme
    func selectTheme(_ theme: BabySmashTheme) {
        currentTheme = theme
        selectedThemeID = theme.id.uuidString
        
        // Post notification for views to update
        NotificationCenter.default.post(name: .themeDidChange, object: theme)
    }
    
    /// Saves a custom theme (creates new or updates existing)
    func saveCustomTheme(_ theme: BabySmashTheme) {
        var mutableTheme = theme
        mutableTheme.isBuiltIn = false
        
        if let index = customThemes.firstIndex(where: { $0.id == theme.id }) {
            customThemes[index] = mutableTheme
        } else {
            customThemes.append(mutableTheme)
        }
        Self.saveCustomThemes(customThemes)
        
        // If this is the current theme, update it
        if currentTheme.id == theme.id {
            currentTheme = mutableTheme
        }
    }
    
    /// Deletes a custom theme
    func deleteCustomTheme(_ theme: BabySmashTheme) {
        customThemes.removeAll { $0.id == theme.id }
        Self.saveCustomThemes(customThemes)
        
        // If deleted theme was current, switch to classic
        if currentTheme.id == theme.id {
            selectTheme(.classic)
        }
    }
    
    /// Duplicates a theme with a new name
    func duplicateTheme(_ theme: BabySmashTheme, newName: String) -> BabySmashTheme {
        var newTheme = theme
        newTheme.id = UUID()
        newTheme.name = newName
        newTheme.isBuiltIn = false
        saveCustomTheme(newTheme)
        return newTheme
    }
    
    /// Returns all available themes (built-in + custom)
    var allThemes: [BabySmashTheme] {
        BabySmashTheme.allBuiltIn + customThemes
    }
    
    // MARK: - Persistence
    
    private static func saveCustomThemes(_ themes: [BabySmashTheme]) {
        guard let data = try? JSONEncoder().encode(themes) else { return }
        UserDefaults.standard.set(data, forKey: "customThemes")
    }
    
    private static func loadCustomThemes() -> [BabySmashTheme] {
        guard let data = UserDefaults.standard.data(forKey: "customThemes"),
              let themes = try? JSONDecoder().decode([BabySmashTheme].self, from: data) else {
            return []
        }
        return themes
    }
    
    // MARK: - Theme Color Selection
    
    /// Returns a random color from the current theme's palette
    func randomColor() -> Color {
        currentTheme.randomColor()
    }
    
    /// Returns a random enabled shape type from the current theme
    func randomEnabledShape() -> ShapeType {
        currentTheme.randomEnabledShape()
    }
    
    /// Returns a random size within the current theme's range
    func randomSize() -> CGFloat {
        currentTheme.randomSize()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when the theme changes
    static let themeDidChange = Notification.Name("themeDidChange")
}
