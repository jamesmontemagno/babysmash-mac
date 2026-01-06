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
    @AppStorage("blockSystemKeys") var blockSystemKeys: Bool = false
    @AppStorage("displayMode") var displayMode: String = "all"
    @AppStorage("selectedDisplayIndex") var selectedDisplayIndex: Int = 0
    
    enum SoundMode: String, CaseIterable {
        case laughter = "Laughter"
        case speech = "Speech"
        case off = "Off"
        
        var localizedName: LocalizedStringResource {
            switch self {
            case .laughter: return L10n.SoundModeNames.laughter
            case .speech: return L10n.SoundModeNames.speech
            case .off: return L10n.SoundModeNames.off
            }
        }
    }
    
    enum CursorType: String, CaseIterable {
        case hand = "Hand"
        case arrow = "Arrow"
        case none = "Hidden"
        
        var localizedName: LocalizedStringResource {
            switch self {
            case .hand: return L10n.CursorTypeNames.hand
            case .arrow: return L10n.CursorTypeNames.arrow
            case .none: return L10n.CursorTypeNames.hidden
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
    private let themeManager = ThemeManager.shared
    private let accessibilityManager = AccessibilitySettingsManager.shared
    private let autoPlayManager = AutoPlayManager.shared
    private var cancellables = Set<AnyCancellable>()
    private var fadeTimer: Timer?
    
    /// Predictable position index for accessibility predictable mode
    private var predictablePositionIndex: Int = 0
    
    init() {
        setupSubscriptions()
        startFadeTimer()
        setupAutoPlay()
        setupSwitchControl()
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
        
        // Observe accessibility settings changes for auto-play
        accessibilityManager.$settings
            .sink { [weak self] settings in
                self?.handleAccessibilitySettingsChanged(settings)
            }
            .store(in: &cancellables)
    }
    
    private func startFadeTimer() {
        // Use longer interval to reduce UI updates - fade is gradual anyway
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.fadeOldFigures()
            }
        }
    }
    
    private func setupAutoPlay() {
        autoPlayManager.onTick = { [weak self] in
            Task { @MainActor [weak self] in
                self?.generateAutoPlayShape()
            }
        }
    }
    
    private func setupSwitchControl() {
        SwitchControlManager.shared.onActionSelected = { [weak self] action in
            Task { @MainActor [weak self] in
                self?.handleSwitchAction(action)
            }
        }
    }
    
    private func handleAccessibilitySettingsChanged(_ settings: AccessibilitySettings) {
        // Handle auto-play mode
        if settings.autoPlayMode && !autoPlayManager.isRunning {
            autoPlayManager.setInterval(settings.autoPlayInterval)
            autoPlayManager.start()
        } else if !settings.autoPlayMode && autoPlayManager.isRunning {
            autoPlayManager.stop()
        } else if settings.autoPlayMode {
            autoPlayManager.setInterval(settings.autoPlayInterval)
        }
        
        // Handle switch control mode
        if settings.switchControlEnabled && !SwitchControlManager.shared.isScanning {
            SwitchControlManager.shared.startScanning()
        } else if !settings.switchControlEnabled && SwitchControlManager.shared.isScanning {
            SwitchControlManager.shared.stopScanning()
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
        
        // Start auto-play if enabled
        if accessibilityManager.settings.autoPlayMode {
            autoPlayManager.setInterval(accessibilityManager.settings.autoPlayInterval)
            autoPlayManager.start()
        }
        
        // Start switch control if enabled
        if accessibilityManager.settings.switchControlEnabled {
            SwitchControlManager.shared.startScanning()
        }
    }
    
    func stopKeyboardMonitoring() {
        keyboardMonitor.stopMonitoring()
        stopSystemKeyBlocking()
        autoPlayManager.stop()
        SwitchControlManager.shared.stopScanning()
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
        accessibilityManager.triggerSoundIndicator(caption: "🎵 Welcome!")
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
            accessibilityManager.triggerSoundIndicator(caption: "🔊 Rising")
        } else if deltaY < 0 {
            SoundManager.shared.play(.falling)
            accessibilityManager.triggerSoundIndicator(caption: "🔊 Falling")
        }
    }
    
    /// Clears all figures from the screen
    func clearScreen() {
        figures.removeAll()
    }
    
    // MARK: - Auto-Play and Switch Control
    
    private func generateAutoPlayShape() {
        let targetScreenIndex = randomScreenIndex()
        let targetScreenSize = getScreenSize(forScreen: targetScreenIndex)
        let position = getPosition(in: targetScreenSize)
        
        // Generate a random element based on focus mode
        let focusMode = accessibilityManager.settings.focusMode
        switch focusMode {
        case .all:
            // Random choice between shape, letter, number
            let choice = Int.random(in: 0..<3)
            if choice == 0 {
                addRandomShape(at: position, screenIndex: targetScreenIndex)
            } else if choice == 1 {
                let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
                if let letter = letters.randomElement() {
                    addLetterFigure(letter, at: position, screenIndex: targetScreenIndex)
                    playSound(for: letter)
                }
            } else {
                let numbers = "0123456789"
                if let number = numbers.randomElement() {
                    addLetterFigure(number, at: position, screenIndex: targetScreenIndex)
                    playSound(for: number)
                }
            }
        case .lettersOnly:
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            if let letter = letters.randomElement() {
                addLetterFigure(letter, at: position, screenIndex: targetScreenIndex)
                playSound(for: letter)
            }
        case .numbersOnly:
            let numbers = "0123456789"
            if let number = numbers.randomElement() {
                addLetterFigure(number, at: position, screenIndex: targetScreenIndex)
                playSound(for: number)
            }
        case .shapesOnly:
            addRandomShape(at: position, screenIndex: targetScreenIndex)
        }
    }
    
    private func handleSwitchAction(_ action: SwitchControlManager.SwitchAction) {
        let targetScreenIndex = randomScreenIndex()
        let targetScreenSize = getScreenSize(forScreen: targetScreenIndex)
        let position = getPosition(in: targetScreenSize)
        
        switch action {
        case .showRandomShape:
            addRandomShape(at: position, screenIndex: targetScreenIndex)
        case .showRandomLetter:
            let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
            if let letter = letters.randomElement() {
                addLetterFigure(letter, at: position, screenIndex: targetScreenIndex)
                playSound(for: letter)
            }
        case .showRandomNumber:
            let numbers = "0123456789"
            if let number = numbers.randomElement() {
                addLetterFigure(number, at: position, screenIndex: targetScreenIndex)
                playSound(for: number)
            }
        case .clearScreen:
            clearScreen()
        }
    }
    
    // MARK: - Private Methods
    
    private func handleKeyPress(_ keyEvent: KeyboardMonitor.KeyEvent) {
        guard let character = keyEvent.displayCharacter else { return }
        
        // Check focus mode restrictions
        let focusMode = accessibilityManager.settings.focusMode
        if focusMode == .shapesOnly && (keyEvent.isLetter || keyEvent.isNumber) {
            // In shapes-only mode, generate shapes for letter/number keys too
            let targetScreenIndex = randomScreenIndex()
            let targetScreenSize = getScreenSize(forScreen: targetScreenIndex)
            let position = getPosition(in: targetScreenSize)
            addRandomShape(at: position, screenIndex: targetScreenIndex)
            playSound(for: character)
            return
        }
        
        // Pick a random screen for keyboard-generated figures
        let targetScreenIndex = randomScreenIndex()
        let targetScreenSize = getScreenSize(forScreen: targetScreenIndex)
        
        // Generate position based on accessibility settings
        let position = getPosition(in: targetScreenSize)
        
        if keyEvent.isLetter || keyEvent.isNumber {
            // Check if we should skip based on focus mode
            if focusMode == .lettersOnly && keyEvent.isNumber {
                return
            }
            if focusMode == .numbersOnly && keyEvent.isLetter {
                return
            }
            
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
    
    /// Gets position for a new figure, respecting accessibility settings
    private func getPosition(in size: CGSize) -> CGPoint {
        if accessibilityManager.settings.predictableMode {
            return predictablePosition(in: size)
        }
        return randomPosition(in: size)
    }
    
    private func addLetterFigure(_ character: Character, at position: CGPoint, screenIndex: Int = 0) {
        let theme = themeManager.currentTheme
        let settings = accessibilityManager.settings
        
        // Determine color based on color blindness mode
        let color: Color
        if settings.colorBlindnessMode != .none {
            color = Color.randomColorFor(settings.colorBlindnessMode)
        } else if settings.highContrastMode {
            color = Color.highContrastColors.randomElement() ?? .white
        } else {
            color = theme.randomColor()
        }
        
        // Determine size based on large elements mode
        let size: CGFloat
        if settings.largeElementsMode {
            let minSize = max(settings.minimumShapeSize, 300)
            size = CGFloat.random(in: minSize...(minSize + 100))
        } else {
            size = theme.randomSize()
        }
        
        // Determine animation style based on reduce motion
        let animationStyle: Figure.AnimationStyle
        if accessibilityManager.effectiveReduceMotion {
            animationStyle = .none
        } else if settings.disableRotation {
            // Avoid rotation-based animations
            animationStyle = [Figure.AnimationStyle.jiggle, .throb, .snap, .none].randomElement() ?? .none
        } else {
            animationStyle = .random
        }
        
        let figure = Figure(
            shapeType: nil,
            character: character,
            color: color,
            position: position,
            size: size,
            createdAt: Date(),
            scale: 1.0,
            rotation: .zero,
            opacity: 1.0,
            showFace: false,
            animationStyle: animationStyle,
            fontFamily: theme.fontName,
            screenIndex: screenIndex
        )
        
        addFigure(figure)
    }
    
    private func addRandomShape(at position: CGPoint, screenIndex: Int = 0) {
        let theme = themeManager.currentTheme
        let settings = accessibilityManager.settings
        let shapeType = theme.randomEnabledShape()
        
        // Determine color based on color blindness mode
        let color: Color
        if settings.colorBlindnessMode != .none {
            color = Color.randomColorFor(settings.colorBlindnessMode)
        } else if settings.highContrastMode {
            color = Color.highContrastColors.randomElement() ?? .white
        } else {
            color = theme.randomColor()
        }
        
        // Determine size based on large elements mode
        let size: CGFloat
        if settings.largeElementsMode {
            let minSize = max(settings.minimumShapeSize, 300)
            size = CGFloat.random(in: minSize...(minSize + 100))
        } else {
            size = theme.randomSize()
        }
        
        // Determine if face should be shown based on theme and settings
        let shouldShowFace: Bool
        switch theme.faceStyle {
        case .none:
            shouldShowFace = false
        case .simple, .kawaii:
            shouldShowFace = showFaces
        }
        
        // Determine animation style based on reduce motion
        let animationStyle: Figure.AnimationStyle
        if accessibilityManager.effectiveReduceMotion {
            animationStyle = .none
        } else if settings.disableRotation {
            // Avoid rotation-based animations
            animationStyle = [Figure.AnimationStyle.jiggle, .throb, .snap, .none].randomElement() ?? .none
        } else {
            animationStyle = .random
        }
        
        let figure = Figure(
            shapeType: shapeType,
            character: nil,
            color: color,
            position: position,
            size: size,
            createdAt: Date(),
            scale: 1.0,
            rotation: .zero,
            opacity: 1.0,
            showFace: shouldShowFace,
            animationStyle: animationStyle,
            fontFamily: theme.fontName,
            screenIndex: screenIndex
        )
        
        addFigure(figure)
        
        // Speak the shape and color, and trigger accessibility indicators
        if soundMode == .speech {
            SpeechService.shared.speakShapeWithColor(shape: shapeType, color: color)
            accessibilityManager.triggerSoundIndicator(caption: "\(shapeType.displayName) - \(color.name)")
        } else if soundMode == .laughter {
            accessibilityManager.triggerSoundIndicator(caption: "😄 Giggle!")
        }
    }
    
    private func addFigure(_ figure: Figure) {
        figures.append(figure)
        
        // Use effective max figures based on accessibility settings
        let effectiveMax = accessibilityManager.settings.simplifiedMode
            ? accessibilityManager.settings.maxSimultaneousShapes
            : maxFigures
        
        // Limit total figures
        if figures.count > effectiveMax {
            figures.removeFirst(figures.count - effectiveMax)
        }
    }
    
    private func playSound(for character: Character) {
        switch soundMode {
        case .laughter:
            SoundManager.shared.playRandomLaughter()
            accessibilityManager.triggerSoundIndicator(caption: "😄 Giggle!")
        case .speech:
            SpeechService.shared.speakLetter(character)
            accessibilityManager.triggerSoundIndicator(caption: String(character).uppercased())
        case .off:
            break
        }
    }
    
    private func announceWord(_ word: String) {
        SpeechService.shared.speakWord(word)
        accessibilityManager.triggerSoundIndicator(caption: "📚 \(word)")
    }
    
    private func randomPosition(in size: CGSize) -> CGPoint {
        let padding: CGFloat = 150
        // Ensure minimum valid range by requiring at least padding on each side plus 1 point
        let minValidDimension = padding * 2 + 1
        let effectiveWidth = max(minValidDimension, size.width)
        let effectiveHeight = max(minValidDimension, size.height)
        let x = CGFloat.random(in: padding...(effectiveWidth - padding))
        let y = CGFloat.random(in: padding...(effectiveHeight - padding))
        return CGPoint(x: x, y: y)
    }
    
    /// Returns a predictable position for accessibility mode
    private func predictablePosition(in size: CGSize) -> CGPoint {
        let positions: [CGPoint] = [
            CGPoint(x: size.width * 0.25, y: size.height * 0.25),
            CGPoint(x: size.width * 0.75, y: size.height * 0.25),
            CGPoint(x: size.width * 0.5, y: size.height * 0.5),
            CGPoint(x: size.width * 0.25, y: size.height * 0.75),
            CGPoint(x: size.width * 0.75, y: size.height * 0.75),
        ]
        
        let position = positions[predictablePositionIndex % positions.count]
        predictablePositionIndex += 1
        return position
    }
    
    private func fadeOldFigures() {
        guard fadeEnabled else { return }
        
        let now = Date()
        let fadeDuration = 1.0 // Faster fade duration (was 2.0)
        
        // Only update if there are figures to process
        guard !figures.isEmpty else { return }
        
        // Check if any figures need updating before modifying array
        var needsUpdate = false
        for figure in figures {
            let age = now.timeIntervalSince(figure.createdAt)
            if age > fadeAfter {
                needsUpdate = true
                break
            }
        }
        
        guard needsUpdate else { return }
        
        // Batch update - only create new array when needed
        figures = figures.compactMap { figure in
            let age = now.timeIntervalSince(figure.createdAt)
            if age > fadeAfter + fadeDuration { return nil } // Remove after fade
            
            if age > fadeAfter {
                var updated = figure
                updated.opacity = max(0, 1.0 - (age - fadeAfter) / fadeDuration)
                return updated
            }
            return figure
        }
    }
    
    deinit {
        fadeTimer?.invalidate()
    }
}
