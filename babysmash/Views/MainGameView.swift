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
    @State private var showPerformanceTest = false
    @State private var showSystemBlockingInfo = false
    @AppStorage("cursorType") private var cursorType: GameViewModel.CursorType = .hand
    @AppStorage("clicklessMouseDraw") private var clicklessMouseDraw: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("blockSystemKeys") private var blockSystemKeys: Bool = false
    
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
            
            // System blocking info (shown after performance test, only on main window)
            if isMainWindow && showSystemBlockingInfo {
                SystemBlockingInfoView(onComplete: {
                    showSystemBlockingInfo = false
                    hasCompletedOnboarding = true
                })
                .zIndex(101)
            }
            
            // Performance test (shown after theme picker, only on main window)
            if isMainWindow && showPerformanceTest {
                PerformanceTestView(onComplete: { recommendedMode in
                    // Apply the recommended performance mode
                    PerformanceMonitor.shared.performanceMode = recommendedMode
                    showPerformanceTest = false
                    // Defer showing next screen to avoid layout conflicts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showSystemBlockingInfo = true
                    }
                })
                .zIndex(102)
            }
            
            // Theme picker (shown after intro on first launch, only on main window)
            if isMainWindow && showThemePicker {
                ThemePickerView(onThemeSelected: { _ in
                    showThemePicker = false
                    // Defer showing next screen to avoid layout conflicts
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showPerformanceTest = true
                    }
                })
                .zIndex(103)
            }
            
            // Intro overlay (shown on launch, only on main window)
            if isMainWindow && showIntro {
                IntroView(onDismiss: {
                    showIntro = false
                    // Show theme picker if this is first launch
                    if !hasCompletedOnboarding {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            showThemePicker = true
                        }
                    }
                })
                .zIndex(104)
            }
            
            // Exit hint overlay - always on top (only on main window, after onboarding complete)
            if isMainWindow && !showIntro && !showThemePicker && !showPerformanceTest && !showSystemBlockingInfo {
                ExitHintOverlay(blockSystemKeys: blockSystemKeys)
                    .zIndex(200)
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
                
                // Mouse drawing trails rendered with Canvas for better performance
                TrailsCanvasView(trails: viewModel.drawingTrailsForScreen(screenIndex))
                
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

// MARK: - Canvas-based Trail Rendering

/// High-performance Canvas view for rendering drawing trails
/// Uses a single draw call for all trails instead of individual SwiftUI views
struct TrailsCanvasView: View {
    let trails: [DrawingTrail]
    
    var body: some View {
        Canvas { context, size in
            for trail in trails {
                let rect = CGRect(
                    x: trail.position.x - trail.size / 2,
                    y: trail.position.y - trail.size / 2,
                    width: trail.size,
                    height: trail.size
                )
                
                context.opacity = trail.opacity
                context.fill(
                    Path(ellipseIn: rect),
                    with: .color(trail.color)
                )
            }
        }
    }
}

// MARK: - Exit Hint Overlay

/// Shows a subtle hint in the corner for how to exit/access settings
/// Small icon always visible, expands on hover to show shortcuts
struct ExitHintOverlay: View {
    let blockSystemKeys: Bool
    
    @State private var isExpanded = false
    
    var body: some View {
        VStack {
            HStack {
                // Hint button in top-left corner
                Button(action: {
                    // Toggle expanded state on click
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.white.opacity(0.6))
                        
                        if isExpanded {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 4) {
                                    Text("⌥S")
                                        .fontWeight(.bold)
                                    Text("Settings")
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                
                                HStack(spacing: 4) {
                                    Text("⌥⌘Q")
                                        .fontWeight(.bold)
                                    Text("Exit")
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                                
                                HStack(spacing: 4) {
                                    Text("Press . x20")
                                        .fontWeight(.bold)
                                    Text("Emergency")
                                        .foregroundStyle(.white.opacity(0.8))
                                }
                            }
                            .font(.system(size: 13))
                            .foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, isExpanded ? 14 : 10)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.black.opacity(isExpanded ? 0.75 : 0.4))
                    )
                }
                .buttonStyle(.plain)
                .onHover { hovering in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        isExpanded = hovering
                    }
                }
                
                Spacer()
            }
            .padding(.leading, 16)
            .padding(.top, 16)
            
            Spacer()
        }
    }
}
