//
//  babysmashApp.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI
import AppKit

@main
struct babysmashApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // Settings window - separate from game windows
        Settings {
            SettingsView()
        }
    }
}

/// AppDelegate manages multi-monitor windows for BabySmash.
class AppDelegate: NSObject, NSApplicationDelegate {
    /// All game windows (one per active screen).
    private var gameWindows: [NSWindow] = []
    
    /// Shared game state across all windows.
    let sharedViewModel = GameViewModel()
    
    /// Reference to multi-monitor manager.
    private let multiMonitorManager = MultiMonitorManager.shared
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create windows for all screens based on current settings
        createGameWindows()
        
        // Monitor for screen configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenConfigurationChanged),
            name: .screenConfigurationChanged,
            object: nil
        )
        
        // Monitor for display mode setting changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(displayModeChanged),
            name: .displayModeChanged,
            object: nil
        )
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        sharedViewModel.stopKeyboardMonitoring()
        closeAllGameWindows()
    }
    
    /// Called when screen configuration changes (monitors added/removed).
    @objc private func screenConfigurationChanged() {
        // Recreate windows to match new screen configuration
        recreateGameWindows()
    }
    
    /// Called when display mode setting changes.
    @objc private func displayModeChanged() {
        recreateGameWindows()
    }
    
    /// Recreates all game windows based on current settings.
    private func recreateGameWindows() {
        closeAllGameWindows()
        createGameWindows()
    }
    
    /// Creates game windows for active screens based on display mode.
    private func createGameWindows() {
        let mode = MultiMonitorManager.DisplayMode(rawValue: UserDefaults.standard.string(forKey: "displayMode") ?? "all") ?? .all
        let selectedIndex = UserDefaults.standard.integer(forKey: "selectedDisplayIndex")
        
        let screens = multiMonitorManager.screensForMode(mode, selectedIndex: selectedIndex)
        
        for (index, screen) in screens.enumerated() {
            let window = createFullScreenWindow(for: screen, screenIndex: index, isMainWindow: index == 0)
            gameWindows.append(window)
        }
    }
    
    /// Creates a full-screen game window for a specific screen.
    private func createFullScreenWindow(for screen: NSScreen, screenIndex: Int, isMainWindow: Bool) -> NSWindow {
        let contentView = MainGameView(
            viewModel: sharedViewModel,
            screenIndex: screenIndex,
            isMainWindow: isMainWindow
        )
        
        let window = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        window.contentView = NSHostingView(rootView: contentView)
        window.level = .normal
        window.isOpaque = true
        window.backgroundColor = .black
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenPrimary]
        window.hasShadow = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        // Set window to cover entire screen
        window.setFrame(screen.frame, display: true)
        window.makeKeyAndOrderFront(nil)
        
        return window
    }
    
    /// Closes all game windows.
    private func closeAllGameWindows() {
        for window in gameWindows {
            window.close()
        }
        gameWindows.removeAll()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    /// Posted when display mode setting changes.
    static let displayModeChanged = Notification.Name("displayModeChanged")
}
