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
    @AppStorage("fadeEnabled") var fadeEnabled: Bool = true
    @AppStorage("fadeAfter") var fadeAfter: Double = 10.0
    @AppStorage("showFaces") var showFaces: Bool = true
    @AppStorage("mouseDrawEnabled") var mouseDrawEnabled: Bool = true
    @AppStorage("clicklessMouseDraw") var clicklessMouseDraw: Bool = false
    @AppStorage("forceUppercase") var forceUppercase: Bool = true
    @AppStorage("maxFigures") var maxFigures: Int = 50
    @AppStorage("cursorType") var cursorType: CursorType = .hand
    @AppStorage("fontFamily") var fontFamily: String = "SF Pro Rounded"
    @AppStorage("backgroundColor") var backgroundColor: String = "black"
    @AppStorage("customBackgroundRed") var customBackgroundRed: Double = 0.0
    @AppStorage("customBackgroundGreen") var customBackgroundGreen: Double = 0.0
    @AppStorage("customBackgroundBlue") var customBackgroundBlue: Double = 0.0
    @AppStorage("blockSystemKeys") var blockSystemKeys: Bool = false
    @AppStorage("displayMode") var displayMode: String = "all"
    @AppStorage("selectedDisplayIndex") var selectedDisplayIndex: Int = 0
    
    enum SoundMode: String, CaseIterable {
        case laughter = "Laughter"
        case speech = "Speech"
        case off = "Off"
    }
    
    enum CursorType: String, CaseIterable {
        case hand = "Hand"
        case arrow = "Arrow"
        case none = "Hidden"
    }
    
    enum BackgroundColor: String, CaseIterable {
        case black = "black"
        case darkGray = "darkGray"
        case navy = "navy"
        case darkGreen = "darkGreen"
        case purple = "purple"
        case brown = "brown"
        case white = "white"
        case custom = "custom"
        
        var displayName: String {
            switch self {
            case .black: return "Black"
            case .darkGray: return "Dark Gray"
            case .navy: return "Navy"
            case .darkGreen: return "Dark Green"
            case .purple: return "Purple"
            case .brown: return "Brown"
            case .white: return "White"
            case .custom: return "Custom..."
            }
        }
        
        var color: Color? {
            switch self {
            case .black: return .black
            case .darkGray: return Color(white: 0.15)
            case .navy: return Color(red: 0.0, green: 0.0, blue: 0.3)
            case .darkGreen: return Color(red: 0.0, green: 0.2, blue: 0.0)
            case .purple: return Color(red: 0.2, green: 0.0, blue: 0.3)
            case .brown: return Color(red: 0.2, green: 0.1, blue: 0.05)
            case .white: return .white
            case .custom: return nil // Custom uses separate RGB values
            }
        }
    }
    
    // MARK: - Internal State
    
    /// Screen sizes keyed by screen index.
    private var screenSizes: [Int: CGSize] = [:]
    
    /// Fallback screen size for backwards compatibility.
    private(set) var screenSize: CGSize = .zero
    
    private let keyboardMonitor = KeyboardMonitor()
    private let mouseDrawingManager = MouseDrawingManager()
    private let multiMonitorManager = MultiMonitorManager.shared
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
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.fadeOldFigures()
            }
        }
    }
    
    // MARK: - Multi-Monitor Support
    
    /// Returns figures that should be displayed on the specified screen.
    /// - Parameter screenIndex: The index of the screen.
    /// - Returns: Array of figures for this screen.
    func figuresForScreen(_ screenIndex: Int) -> [Figure] {
        return figures.filter { $0.screenIndex == screenIndex }
    }
    
    /// Returns drawing trails that should be displayed on the specified screen.
    /// - Parameter screenIndex: The index of the screen.
    /// - Returns: Array of drawing trails for this screen.
    func drawingTrailsForScreen(_ screenIndex: Int) -> [DrawingTrail] {
        return drawingTrails.filter { $0.screenIndex == screenIndex }
    }
    
    /// Sets the screen size for a specific screen.
    /// - Parameters:
    ///   - size: The size of the screen.
    ///   - screenIndex: The index of the screen.
    func setScreenSize(_ size: CGSize, forScreen screenIndex: Int = 0) {
        screenSizes[screenIndex] = size
        // Keep backwards compatibility with single screen
        if screenIndex == 0 {
            screenSize = size
        }
    }
    
    /// Gets the screen size for a specific screen.
    /// - Parameter screenIndex: The index of the screen.
    /// - Returns: The size of the screen, or a default size if not found.
    func getScreenSize(forScreen screenIndex: Int) -> CGSize {
        return screenSizes[screenIndex] ?? screenSize
    }
    
    /// Returns a random screen index from the active screens.
    private func randomScreenIndex() -> Int {
        let mode = MultiMonitorManager.DisplayMode(rawValue: displayMode) ?? .all
        let screens = multiMonitorManager.screensForMode(mode, selectedIndex: selectedDisplayIndex)
        return Int.random(in: 0..<max(1, screens.count))
    }
    
    // MARK: - Public Methods
    
    func startKeyboardMonitoring() {
        keyboardMonitor.startMonitoring()
        
        // Start system key blocking if enabled
        if blockSystemKeys {
            startSystemKeyBlocking()
        }
    }
    
    func stopKeyboardMonitoring() {
        keyboardMonitor.stopMonitoring()
        stopSystemKeyBlocking()
    }
    
    /// Starts blocking system keys if accessibility permission is granted.
    /// - Returns: `true` if blocking started, `false` if permission denied.
    @discardableResult
    func startSystemKeyBlocking() -> Bool {
        return SystemKeyBlocker.shared.startBlocking()
    }
    
    /// Stops blocking system keys.
    func stopSystemKeyBlocking() {
        SystemKeyBlocker.shared.stopBlocking()
    }
    
    func playStartupSound() {
        SoundManager.shared.play(.startup)
    }
    
    /// Handles tap events with screen index for multi-monitor support.
    func handleTap(at location: CGPoint, in size: CGSize, screenIndex: Int = 0) {
        setScreenSize(size, forScreen: screenIndex)
        addRandomShape(at: location, screenIndex: screenIndex)
    }
    
    /// Handles mouse drag events with screen index for multi-monitor support.
    func handleMouseDrag(at location: CGPoint, in size: CGSize, isDragging: Bool, screenIndex: Int = 0) {
        guard mouseDrawEnabled else { return }
        // Only draw if clickless mode is on OR we're actively dragging (mouse button down)
        guard clicklessMouseDraw || isDragging else { return }
        setScreenSize(size, forScreen: screenIndex)
        mouseDrawingManager.addPoint(at: location, screenIndex: screenIndex)
    }
    
    /// Handles mouse move events with screen index for multi-monitor support.
    func handleMouseMove(at location: CGPoint, in size: CGSize, screenIndex: Int = 0) {
        guard mouseDrawEnabled && clicklessMouseDraw else { return }
        setScreenSize(size, forScreen: screenIndex)
        mouseDrawingManager.addPoint(at: location, screenIndex: screenIndex)
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
        
        // Pick a random screen for keyboard-generated figures
        let targetScreenIndex = randomScreenIndex()
        let targetScreenSize = getScreenSize(forScreen: targetScreenIndex)
        
        // Generate random position on the target screen
        let position = randomPosition(in: targetScreenSize)
        
        if keyEvent.isLetter || keyEvent.isNumber {
            let displayChar = forceUppercase ? Character(character.uppercased()) : character
            addLetterFigure(displayChar, at: position, screenIndex: targetScreenIndex)
            
            // Check for word completion
            if keyEvent.isLetter {
                if let word = WordFinder.shared.addLetter(displayChar) {
                    announceWord(word)
                }
            }
        } else {
            addRandomShape(at: position, screenIndex: targetScreenIndex)
        }
        
        playSound(for: character)
    }
    
    private func addLetterFigure(_ character: Character, at position: CGPoint, screenIndex: Int = 0) {
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
            animationStyle: .random,
            fontFamily: fontFamily,
            screenIndex: screenIndex
        )
        
        addFigure(figure)
    }
    
    private func addRandomShape(at position: CGPoint, screenIndex: Int = 0) {
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
            animationStyle: .random,
            fontFamily: fontFamily,
            screenIndex: screenIndex
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
    
    private func randomPosition(in size: CGSize) -> CGPoint {
        let padding: CGFloat = 150
        let effectiveWidth = max(padding * 2 + 1, size.width)
        let effectiveHeight = max(padding * 2 + 1, size.height)
        let x = CGFloat.random(in: padding...(effectiveWidth - padding))
        let y = CGFloat.random(in: padding...(effectiveHeight - padding))
        return CGPoint(x: x, y: y)
    }
    
    private func fadeOldFigures() {
        guard fadeEnabled else { return }
        
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
