//
//  MainGameView.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

struct MainGameView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showSettings = false
    @State private var showIntro = true
    @AppStorage("cursorType") private var cursorType: GameViewModel.CursorType = .hand
    @AppStorage("clicklessMouseDraw") private var clicklessMouseDraw: Bool = false
    @AppStorage("backgroundColor") private var backgroundColor: String = "black"
    @AppStorage("customBackgroundRed") private var customBackgroundRed: Double = 0.0
    @AppStorage("customBackgroundGreen") private var customBackgroundGreen: Double = 0.0
    @AppStorage("customBackgroundBlue") private var customBackgroundBlue: Double = 0.0
    
    var body: some View {
        ZStack {
            // Main game view
            gameView
            
            // Intro overlay (shown on launch)
            if showIntro {
                IntroView(onDismiss: {
                    showIntro = false
                })
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            showSettings = true
        }
    }
    
    private var gameView: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                backgroundColorValue
                    .ignoresSafeArea()
                
                // Mouse drawing trails
                ForEach(viewModel.drawingTrails) { trail in
                    Circle()
                        .fill(trail.color)
                        .frame(width: trail.size, height: trail.size)
                        .position(trail.position)
                        .opacity(trail.opacity)
                }
                
                // Main figures
                ForEach(viewModel.figures) { figure in
                    FigureView(figure: figure)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        viewModel.handleMouseDrag(at: value.location, in: geometry.size, isDragging: true)
                    }
                    .onEnded { _ in
                        viewModel.handleMouseDragEnded()
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    viewModel.handleMouseMove(at: location, in: geometry.size)
                case .ended:
                    break
                }
            }
            .onTapGesture { location in
                viewModel.handleTap(at: location, in: geometry.size)
            }
            .onAppear {
                viewModel.setScreenSize(geometry.size)
                viewModel.startKeyboardMonitoring()
                viewModel.playStartupSound()
            }
            .onDisappear {
                viewModel.stopKeyboardMonitoring()
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
    
    private var backgroundColorValue: Color {
        if backgroundColor == "custom" {
            return Color(red: customBackgroundRed, green: customBackgroundGreen, blue: customBackgroundBlue)
        }
        return GameViewModel.BackgroundColor(rawValue: backgroundColor)?.color ?? .black
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
    MainGameView()
}
