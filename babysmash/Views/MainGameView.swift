//
//  MainGameView.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

struct MainGameView: View {
    /// The view model - can be injected for multi-monitor support or created locally.
    @ObservedObject var viewModel: GameViewModel
    
    /// The screen index for this view (used in multi-monitor setups).
    let screenIndex: Int
    
    /// Whether this is the main window (handles intro and settings).
    let isMainWindow: Bool
    
    @State private var showSettings = false
    @State private var showIntro = true
    @State private var showThemePicker = false
    @AppStorage("cursorType") private var cursorType: GameViewModel.CursorType = .hand
    @AppStorage("clicklessMouseDraw") private var clicklessMouseDraw: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var accessibilityManager = AccessibilitySettingsManager.shared
    
    /// Initializer with injected view model for multi-monitor support.
    init(viewModel: GameViewModel, screenIndex: Int = 0, isMainWindow: Bool = true) {
        self.viewModel = viewModel
        self.screenIndex = screenIndex
        self.isMainWindow = isMainWindow
    }
    
    var body: some View {
        ZStack {
            // Main game view
            gameView
            
            // Accessibility overlays (sound indicator and captions)
            AccessibilitySoundOverlay()
            
            // Switch control overlay
            if accessibilityManager.settings.switchControlEnabled {
                SwitchControlOverlay()
            }
            
            // Theme picker (shown after intro on first launch, only on main window)
            if isMainWindow && showThemePicker {
                ThemePickerView(onThemeSelected: { _ in
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showThemePicker = false
                        hasCompletedOnboarding = true
                    }
                })
                .transition(.opacity)
                .zIndex(101)
            }
            
            // Intro overlay (shown on launch, only on main window)
            if isMainWindow && showIntro {
                IntroView(onDismiss: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showIntro = false
                        // Show theme picker if this is first launch
                        if !hasCompletedOnboarding {
                            showThemePicker = true
                        }
                    }
                })
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            // Only show settings from main window to avoid duplicate dialogs
            if isMainWindow {
                showSettings = true
            }
        }
    }
    
    private var gameView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background - use themed background
                ThemedBackground(theme: themeManager.currentTheme)
                
                // Mouse drawing trails - filter to show only trails for this screen
                ForEach(viewModel.drawingTrailsForScreen(screenIndex)) { trail in
                    Circle()
                        .fill(trail.color)
                        .frame(width: trail.size, height: trail.size)
                        .position(trail.position)
                        .opacity(trail.opacity)
                }
                
                // Main figures - filter to show only figures for this screen
                ForEach(viewModel.figuresForScreen(screenIndex)) { figure in
                    FigureView(figure: figure)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        viewModel.handleMouseDrag(at: value.location, in: geometry.size, isDragging: true, screenIndex: screenIndex)
                    }
                    .onEnded { _ in
                        viewModel.handleMouseDragEnded()
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    viewModel.handleMouseMove(at: location, in: geometry.size, screenIndex: screenIndex)
                case .ended:
                    break
                }
            }
            .onTapGesture { location in
                viewModel.handleTap(at: location, in: geometry.size, screenIndex: screenIndex)
            }
            .onAppear {
                viewModel.setScreenSize(geometry.size, forScreen: screenIndex)
                // Only start monitoring and play sounds from main window
                if isMainWindow {
                    viewModel.startKeyboardMonitoring()
                    viewModel.playStartupSound()
                }
            }
            .onDisappear {
                if isMainWindow {
                    viewModel.stopKeyboardMonitoring()
                }
            }
        }
        .ignoresSafeArea()
        .cursor(cursorForType)
    }
    
    private var cursorForType: NSCursor {
        switch cursorType {
        case .hand:
            return .pointingHand
        case .arrow:
            return .arrow
        case .none:
            return .init(image: NSImage(), hotSpot: .zero)
        }
    }
}

// Custom cursor modifier
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}

#Preview {
    MainGameView(viewModel: GameViewModel(), screenIndex: 0, isMainWindow: true)
}
