//
//  PerformanceTestView.swift
//  babysmash
//
//  Created by James Montemagno on 1/5/26.
//

import SwiftUI

/// Onboarding view that runs a performance benchmark to determine optimal settings
struct PerformanceTestView: View {
    let onComplete: (PerformanceMonitor.PerformanceMode) -> Void
    
    @State private var testState: TestState = .ready
    @State private var testProgress: Double = 0
    @State private var testShapes: [TestShape] = []
    @State private var frameCount: Int = 0
    @State private var droppedFrames: Int = 0
    @State private var recommendedMode: PerformanceMonitor.PerformanceMode = .auto
    @State private var timer: Timer?
    @State private var startTime: Date?
    
    @State private var titleOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var buttonOpacity: Double = 0
    
    private let testDuration: TimeInterval = 5.0
    private let targetFrameRate: Double = 60.0
    private let maxShapesPhase1 = 15
    private let maxShapesPhase2 = 25
    private let maxShapesPhase3 = 38
    private let maxShapesFinal = 50
    
    enum TestState {
        case ready
        case running
        case complete
    }
    
    struct TestShape: Identifiable {
        let id = UUID()
        var position: CGPoint
        var size: CGFloat
        var color: Color
        var rotation: Angle
        var velocity: CGPoint
        var shapeType: Int // 0 = circle, 1 = star, 2 = heart, 3 = rectangle
        var scale: CGFloat
        var glowIntensity: Double
    }
    
    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.08, green: 0.08, blue: 0.12),
                    Color(red: 0.05, green: 0.05, blue: 0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Test shapes during benchmark - only show when actively running
            if testState == .running && !testShapes.isEmpty {
                ForEach(testShapes) { shape in
                    shapeView(for: shape)
                        .frame(width: shape.size, height: shape.size)
                        .scaleEffect(shape.scale)
                        .rotationEffect(shape.rotation)
                        .shadow(color: shape.color.opacity(0.5), radius: 8)
                        .position(shape.position)
                }
            }
            
            VStack(spacing: 32) {
                Spacer()
                
                // Title section
                VStack(spacing: 16) {
                    Text(testState == .complete ? "✅" : "⚡️")
                        .font(.system(size: 60))
                    
                    Text(titleText)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.cyan, .blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .multilineTextAlignment(.center)
                    
                    Text(subtitleText)
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .opacity(titleOpacity)
                
                Spacer()
                
                // Content section
                VStack(spacing: 24) {
                    switch testState {
                    case .ready:
                        readyContent
                    case .running:
                        runningContent
                    case .complete:
                        completeContent
                    }
                }
                .padding(.vertical, 32)
                .padding(.horizontal, 48)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.3), radius: 30, x: 0, y: 15)
                )
                .frame(maxWidth: 500)
                .opacity(contentOpacity)
                
                Spacer()
                
                // Action button
                Button(action: handleButtonTap) {
                    HStack(spacing: 12) {
                        Text(buttonText)
                            .font(.system(size: 20, weight: .semibold, design: .rounded))
                        Image(systemName: buttonIcon)
                            .font(.system(size: 22))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 36)
                    .padding(.vertical, 16)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: buttonColors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: buttonColors[0].opacity(0.5), radius: 15, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
                .opacity(buttonOpacity)
                .disabled(testState == .running)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            cleanupTimer()
        }
    }
    
    // MARK: - Shape View Builder
    
    @ViewBuilder
    private func shapeView(for shape: TestShape) -> some View {
        switch shape.shapeType {
        case 0:
            Circle()
                .fill(
                    RadialGradient(
                        colors: [shape.color, shape.color.opacity(0.6)],
                        center: .center,
                        startRadius: 0,
                        endRadius: shape.size / 2
                    )
                )
                .overlay(
                    Circle()
                        .stroke(shape.color.opacity(0.8), lineWidth: 2)
                )
        case 1:
            StarShape()
                .fill(
                    LinearGradient(
                        colors: [shape.color, shape.color.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    StarShape()
                        .stroke(shape.color.opacity(0.9), lineWidth: 2)
                )
        case 2:
            HeartShape()
                .fill(
                    LinearGradient(
                        colors: [shape.color, shape.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    HeartShape()
                        .stroke(shape.color.opacity(0.8), lineWidth: 2)
                )
        default:
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [shape.color.opacity(0.9), shape.color],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(shape.color.opacity(0.7), lineWidth: 2)
                )
        }
    }
    
    // MARK: - Content Views
    
    private var readyContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            infoRow(icon: "speedometer", text: L10n.Onboarding.Performance.infoTest)
            infoRow(icon: "gearshape.2", text: L10n.Onboarding.Performance.infoOptimize)
            infoRow(icon: "clock", text: L10n.Onboarding.Performance.infoDuration)
        }
    }
    
    private var runningContent: some View {
        VStack(spacing: 20) {
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.white.opacity(0.2))
                    
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * testProgress)
                }
            }
            .frame(height: 12)
            
            Text(L10n.Onboarding.Performance.testing)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.8))
            
            Text("\(Int(testProgress * 100))%")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
        }
        .padding(.vertical, 8)
    }
    
    private var completeContent: some View {
        VStack(spacing: 20) {
            // Result
            HStack(spacing: 16) {
                Image(systemName: resultIcon)
                    .font(.system(size: 40))
                    .foregroundStyle(resultColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Onboarding.Performance.recommended)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.6))
                    
                    Text(recommendedMode.localizedName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(resultColor.opacity(0.2))
            )
            
            Text(resultDescription)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
        }
    }
    
    private func infoRow(icon: String, text: LocalizedStringResource) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(.cyan)
                .frame(width: 32)
            
            Text(text)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.white.opacity(0.9))
        }
    }
    
    // MARK: - Computed Properties
    
    private var titleText: String {
        switch testState {
        case .ready:
            return String(localized: L10n.Onboarding.Performance.title)
        case .running:
            return String(localized: L10n.Onboarding.Performance.runningTitle)
        case .complete:
            return String(localized: L10n.Onboarding.Performance.completeTitle)
        }
    }
    
    private var subtitleText: String {
        switch testState {
        case .ready:
            return String(localized: L10n.Onboarding.Performance.subtitle)
        case .running:
            return String(localized: L10n.Onboarding.Performance.runningSubtitle)
        case .complete:
            return String(localized: L10n.Onboarding.Performance.completeSubtitle)
        }
    }
    
    private var buttonText: String {
        switch testState {
        case .ready:
            return String(localized: L10n.Onboarding.Performance.startTest)
        case .running:
            return String(localized: L10n.Onboarding.Performance.testing)
        case .complete:
            return String(localized: L10n.Onboarding.Performance.continueButton)
        }
    }
    
    private var buttonIcon: String {
        switch testState {
        case .ready: return "play.circle.fill"
        case .running: return "hourglass"
        case .complete: return "arrow.right.circle.fill"
        }
    }
    
    private var buttonColors: [Color] {
        switch testState {
        case .ready: return [.cyan, .blue]
        case .running: return [.gray, .gray]
        case .complete: return [.green, .cyan]
        }
    }
    
    private var resultIcon: String {
        switch recommendedMode {
        case .high, .auto: return "hare.fill"
        case .balanced: return "tortoise.fill"
        case .low: return "leaf.fill"
        }
    }
    
    private var resultColor: Color {
        switch recommendedMode {
        case .high, .auto: return .green
        case .balanced: return .orange
        case .low: return .yellow
        }
    }
    
    private var resultDescription: String {
        switch recommendedMode {
        case .high, .auto:
            return String(localized: L10n.Onboarding.Performance.resultHigh)
        case .balanced:
            return String(localized: L10n.Onboarding.Performance.resultBalanced)
        case .low:
            return String(localized: L10n.Onboarding.Performance.resultLow)
        }
    }
    
    // MARK: - Actions
    
    private func handleButtonTap() {
        switch testState {
        case .ready:
            startTest()
        case .running:
            break
        case .complete:
            // Ensure timer is fully stopped before transitioning
            cleanupTimer()
            // Defer completion to next run loop to avoid layout conflicts
            let mode = recommendedMode
            DispatchQueue.main.async {
                onComplete(mode)
            }
        }
    }
    
    private func cleanupTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func startTest() {
        testState = .running
        testProgress = 0
        frameCount = 0
        droppedFrames = 0
        testShapes = []
        startTime = Date()
        
        // Generate initial shapes
        for _ in 0..<15 {
            addRandomShape()
        }
        
        // Start animation timer (target 60fps)
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            updateTest()
        }
    }
    
    private func updateTest() {
        guard let start = startTime else { return }
        
        let elapsed = Date().timeIntervalSince(start)
        testProgress = min(1.0, elapsed / testDuration)
        frameCount += 1
        
        // Update shape positions
        for i in testShapes.indices {
            // Movement
            testShapes[i].position.x += testShapes[i].velocity.x
            testShapes[i].position.y += testShapes[i].velocity.y
            
            // Rotation
            testShapes[i].rotation += .degrees(2 + Double(i % 3))
            
            // Gentle pulsing scale effect
            let pulsePhase = elapsed * 2 + Double(i) * 0.2
            testShapes[i].scale = 1.0 + 0.1 * sin(pulsePhase)
            
            // Bounce off edges
            let screenWidth = NSScreen.main?.frame.width ?? 1200
            let screenHeight = NSScreen.main?.frame.height ?? 800
            
            if testShapes[i].position.x < 50 || testShapes[i].position.x > screenWidth - 50 {
                testShapes[i].velocity.x *= -1
            }
            if testShapes[i].position.y < 50 || testShapes[i].position.y > screenHeight - 50 {
                testShapes[i].velocity.y *= -1
            }
        }
        
        // Gradually add more shapes as test progresses
        // Phase 1: Ramp up to 30 shapes
        if testProgress > 0.15 && testShapes.count < maxShapesPhase1 {
            addRandomShape()
        }
        // Phase 2: Ramp up to 50 shapes
        if testProgress > 0.35 && testShapes.count < maxShapesPhase2 {
            addRandomShape()
        }
        // Phase 3: Ramp up to 75 shapes  
        if testProgress > 0.55 && testShapes.count < maxShapesPhase3 {
            addRandomShape()
        }
        // Final phase: Push to 100 shapes
        if testProgress > 0.75 && testShapes.count < maxShapesFinal {
            addRandomShape()
        }
        
        // Check for frame drops using timestamp comparison
        let expectedFrames = Int(elapsed * targetFrameRate)
        let frameLag = expectedFrames - frameCount
        if frameLag > 3 {
            droppedFrames += frameLag
        }
        
        // End test
        if elapsed >= testDuration {
            finishTest()
        }
    }
    
    private func addRandomShape() {
        let screenWidth = NSScreen.main?.frame.width ?? 1200
        let screenHeight = NSScreen.main?.frame.height ?? 800
        
        let shape = TestShape(
            position: CGPoint(
                x: CGFloat.random(in: 80...(screenWidth - 80)),
                y: CGFloat.random(in: 80...(screenHeight - 80))
            ),
            size: CGFloat.random(in: 50...120),
            color: Color.randomBabySmash,
            rotation: .degrees(Double.random(in: 0...360)),
            velocity: CGPoint(
                x: CGFloat.random(in: -3...3),
                y: CGFloat.random(in: -3...3)
            ),
            shapeType: Int.random(in: 0...3),
            scale: 1.0,
            glowIntensity: 0.3
        )
        testShapes.append(shape)
    }
    
    private func finishTest() {
        cleanupTimer()
        
        // Calculate performance score based on dropped frames and final shape count
        let expectedFrames = Int(testDuration * targetFrameRate)
        let frameDropRatio = Double(droppedFrames) / Double(expectedFrames)
        let shapeHandlingRatio = Double(testShapes.count) / Double(maxShapesFinal)
        
        // Combined score: lower is better
        // If we handled all shapes with few drops, score is low
        let performanceScore = frameDropRatio - (shapeHandlingRatio * 0.1)
        
        // Determine recommended mode based on performance
        // More strict thresholds for the intense test
        if performanceScore < 0.08 && testShapes.count >= maxShapesPhase3 {
            recommendedMode = .high
        } else if performanceScore < 0.20 && testShapes.count >= maxShapesPhase2 {
            recommendedMode = .balanced
        } else {
            recommendedMode = .low
        }
        
        // Clear shapes first without animation to avoid layout issues
        testShapes = []
        
        // Then animate state change on next run loop
        DispatchQueue.main.async {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.testState = .complete
            }
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
            titleOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            contentOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.7)) {
            buttonOpacity = 1.0
        }
    }
}

#Preview {
    PerformanceTestView(onComplete: { _ in })
}
