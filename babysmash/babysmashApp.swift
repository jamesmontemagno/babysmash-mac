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
    
    init() {
        // Initialize SparkleController for manual update checks
        _ = SparkleController.shared
    }
    
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
    
    /// Debug mode: Set to true to disable kiosk mode during development
    /// This allows normal window behavior, dock, menu bar, and app switching
    #if DEBUG
    private let debugDisableKioskMode = true
    #else
    private let debugDisableKioskMode = true
    #endif
    
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
        
        let window = KioskWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        // Use custom hosting view that prevents constraint loops
        let hostingView = StableHostingView(rootView: contentView)
        hostingView.translatesAutoresizingMaskIntoConstraints = true
        hostingView.autoresizingMask = [.width, .height]
        window.contentView = hostingView
        window.isOpaque = true
        window.backgroundColor = .black
        window.hasShadow = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        
        // Kiosk mode: cover entire screen including menu bar (unless debug mode)
        if !debugDisableKioskMode {
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.maximumWindow)))
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        } else {
            // Debug mode: normal window level, allow interaction with other apps
            window.level = .normal
            window.collectionBehavior = []
        }
        
        // Set window to cover entire screen (including menu bar area)
        window.setFrame(screen.frame, display: true)
        window.makeKeyAndOrderFront(nil)
        
        // Hide the dock and menu bar when our window is active (unless debug mode)
        if !debugDisableKioskMode {
            NSApp.presentationOptions = [.hideDock, .hideMenuBar, .disableProcessSwitching]
        }
        
        return window
    }
    
    /// Closes all game windows.
    private func closeAllGameWindows() {
        // Restore normal presentation (show dock and menu bar) only if we changed it
        if !debugDisableKioskMode {
            NSApp.presentationOptions = []
        }
        
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

// MARK: - Kiosk Window

/// A borderless window that stays on top and blocks clicks from reaching other apps.
class KioskWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
    
    /// Prevents the window from being moved
    override func performDrag(with event: NSEvent) {
        // Don't allow dragging
    }
    
    /// Prevent constraint update loops
    override func updateConstraintsIfNeeded() {
        // Batch constraint updates to prevent infinite loops
        NSAnimationContext.runAnimationGroup { context in
            context.allowsImplicitAnimation = false
            super.updateConstraintsIfNeeded()
        }
    }
}

/// Custom NSHostingView that prevents constraint update loops
class StableHostingView<Content: View>: NSHostingView<Content> {
    private var isUpdatingConstraints = false
    
    override func updateConstraints() {
        guard !isUpdatingConstraints else { return }
        isUpdatingConstraints = true
        super.updateConstraints()
        isUpdatingConstraints = false
    }
    
    override func layout() {
        // Disable implicit animations during layout to prevent loops
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        super.layout()
        CATransaction.commit()
    }
}
