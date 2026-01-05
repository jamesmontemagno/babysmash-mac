//
//  AccessibilityManager.swift
//  babysmash
//
//  Created by James Montemagno on 1/5/26.
//

import Cocoa

/// Manages accessibility permissions required for system key blocking.
class AccessibilityManager {
    
    /// Checks if accessibility permission is currently granted.
    /// - Returns: `true` if the app is trusted for accessibility, `false` otherwise.
    static func isAccessibilityEnabled() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Checks accessibility permission and optionally prompts the user.
    /// - Parameter prompt: If `true`, shows the system prompt to enable accessibility.
    /// - Returns: `true` if already trusted, `false` otherwise (even if prompt was shown).
    static func checkAndRequestPermission(prompt: Bool = true) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }
    
    /// Opens System Preferences/Settings to the Accessibility pane.
    static func openAccessibilityPreferences() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
}
