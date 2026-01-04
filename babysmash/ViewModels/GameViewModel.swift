//
//  GameViewModel.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published State
    @Published var figures: [Figure] = []
    @Published var drawingTrails: [DrawingTrail] = []
    
    // MARK: - Settings
    @AppStorage("soundMode") var soundMode: SoundMode = .laughter
    @AppStorage("fadeAfter") var fadeAfter: Double = 10.0
    @AppStorage("showFaces") var showFaces: Bool = true
    @AppStorage("mouseDrawEnabled") var mouseDrawEnabled: Bool = true
    @AppStorage("forceUppercase") var forceUppercase: Bool = true
    @AppStorage("maxFigures") var maxFigures: Int = 50
    
    enum SoundMode: String, CaseIterable {
        case laughter = "Laughter"
        case speech = "Speech"
        case off = "Off"
    }
    
    // MARK: - Internal State
    var screenSize: CGSize = .zero
    
    private let keyboardMonitor = KeyboardMonitor()
    private let mouseDrawingManager = MouseDrawingManager()
    private var cancellables = Set<AnyCancellable>()
    private var fadeTimer: Timer?
    
    init() {
        setupSubscriptions()
        startFadeTimer()
    }
    
    // MARK: - Setup
    
    private func setupSubscriptions() {
        keyboardMonitor.$lastKeyPressed
            .compactMap { $0 }
            .sink { [weak self] keyEvent in
                self?.handleKeyPress(keyEvent)
            }
            .store(in: &cancellables)
        
        mouseDrawingManager.$trails
            .assign(to: &$drawingTrails)
    }
    
    private func startFadeTimer() {
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.fadeOldFigures()
            }
        }
    }
    
    // MARK: - Public Methods
    
    func startKeyboardMonitoring() {
        keyboardMonitor.startMonitoring()
    }
    
    func stopKeyboardMonitoring() {
        keyboardMonitor.stopMonitoring()
    }
    
    func playStartupSound() {
        SoundManager.shared.play(.startup)
    }
    
    func handleTap(at location: CGPoint, in size: CGSize) {
        screenSize = size
        addRandomShape(at: location)
    }
    
    func handleMouseDrag(at location: CGPoint, in size: CGSize) {
        guard mouseDrawEnabled else { return }
        screenSize = size
        mouseDrawingManager.addPoint(at: location)
    }
    
    func handleMouseDragEnded() {
        mouseDrawingManager.endDrawing()
    }
    
    func handleScrollWheel(deltaY: CGFloat) {
        if deltaY > 0 {
            SoundManager.shared.play(.rising)
        } else if deltaY < 0 {
            SoundManager.shared.play(.falling)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleKeyPress(_ keyEvent: KeyboardMonitor.KeyEvent) {
        guard let character = keyEvent.displayCharacter else { return }
        
        // Generate random position
        let position = randomPosition()
        
        if keyEvent.isLetter || keyEvent.isNumber {
            let displayChar = forceUppercase ? Character(character.uppercased()) : character
            addLetterFigure(displayChar, at: position)
            
            // Check for word completion
            if keyEvent.isLetter {
                if let word = WordFinder.shared.addLetter(displayChar) {
                    announceWord(word)
                }
            }
        } else {
            addRandomShape(at: position)
        }
        
        playSound(for: character)
    }
    
    private func addLetterFigure(_ character: Character, at position: CGPoint) {
        let figure = Figure(
            shapeType: nil,
            character: character,
            color: Color.randomBabySmash,
            position: position,
            size: CGFloat.random(in: 150...300),
            createdAt: Date(),
            scale: 1.0,
            rotation: .zero,
            opacity: 1.0,
            showFace: false,
            animationStyle: .random
        )
        
        addFigure(figure)
    }
    
    private func addRandomShape(at position: CGPoint) {
        let shapeType = ShapeType.random
        let color = Color.randomBabySmash
        
        let figure = Figure(
            shapeType: shapeType,
            character: nil,
            color: color,
            position: position,
            size: CGFloat.random(in: 150...300),
            createdAt: Date(),
            scale: 1.0,
            rotation: .zero,
            opacity: 1.0,
            showFace: showFaces,
            animationStyle: .random
        )
        
        addFigure(figure)
        
        // Speak the shape and color
        if soundMode == .speech {
            SpeechService.shared.speakShapeWithColor(shape: shapeType, color: color)
        }
    }
    
    private func addFigure(_ figure: Figure) {
        figures.append(figure)
        
        // Limit total figures
        if figures.count > maxFigures {
            figures.removeFirst(figures.count - maxFigures)
        }
    }
    
    private func playSound(for character: Character) {
        switch soundMode {
        case .laughter:
            SoundManager.shared.playRandomLaughter()
        case .speech:
            SpeechService.shared.speakLetter(character)
        case .off:
            break
        }
    }
    
    private func announceWord(_ word: String) {
        SpeechService.shared.speakWord(word)
    }
    
    private func randomPosition() -> CGPoint {
        let padding: CGFloat = 150
        let x = CGFloat.random(in: padding...(screenSize.width - padding))
        let y = CGFloat.random(in: padding...(screenSize.height - padding))
        return CGPoint(x: x, y: y)
    }
    
    private func fadeOldFigures() {
        let now = Date()
        figures = figures.compactMap { figure in
            let age = now.timeIntervalSince(figure.createdAt)
            if age > fadeAfter + 2.0 { return nil } // Remove after fade
            
            var updated = figure
            if age > fadeAfter {
                updated.opacity = max(0, 1.0 - (age - fadeAfter) / 2.0)
            }
            return updated
        }
    }
    
    deinit {
        fadeTimer?.invalidate()
    }
}
