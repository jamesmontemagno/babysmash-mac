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
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black
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
                        viewModel.handleMouseDrag(at: value.location, in: geometry.size)
                    }
                    .onEnded { _ in
                        viewModel.handleMouseDragEnded()
                    }
            )
            .onTapGesture { location in
                viewModel.handleTap(at: location, in: geometry.size)
            }
            .onAppear {
                viewModel.screenSize = geometry.size
                viewModel.startKeyboardMonitoring()
                viewModel.playStartupSound()
            }
            .onDisappear {
                viewModel.stopKeyboardMonitoring()
            }
        }
        .ignoresSafeArea()
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .onReceive(NotificationCenter.default.publisher(for: .showSettings)) { _ in
            showSettings = true
        }
    }
}

#Preview {
    MainGameView()
}
