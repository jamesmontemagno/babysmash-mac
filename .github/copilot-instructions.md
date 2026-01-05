# BabySmash macOS - Copilot Instructions

## Project Overview
BabySmash is a macOS SwiftUI app (macOS 14+) that displays colorful shapes, letters, and sounds when babies press keys or interact with the mouse. Inspired by Scott Hanselman's original Windows app.

## Architecture

### MVVM Pattern
- **View** → **ViewModel** → **Services** (singleton managers)
- `GameViewModel` is the central `@MainActor` `ObservableObject` managing all game state
- Services (`SoundManager`, `SpeechService`, `WordFinder`, `KeyboardMonitor`, `MouseDrawingManager`) are singletons accessed via `.shared`

### Data Flow
```
KeyboardMonitor (NSEvent) → GameViewModel → Figure model → FigureView
MouseDrawingManager → DrawingTrail model → MainGameView (renders trails)
```

### Key Components
| Component | Location | Purpose |
|-----------|----------|---------|
| `GameViewModel` | [ViewModels/GameViewModel.swift](src/babysmash/ViewModels/GameViewModel.swift) | Central state, input handling, figure lifecycle |
| `Figure` | [Models/Figure.swift](src/babysmash/Models/Figure.swift) | Shape/letter data with animation style |
| `FigureView` | [Views/FigureView.swift](src/babysmash/Views/FigureView.swift) | Renders figures with animations |
| `KeyboardMonitor` | [Services/KeyboardMonitor.swift](src/babysmash/Services/KeyboardMonitor.swift) | Low-level `NSEvent` keyboard capture |

## Conventions

### Settings Persistence
Use `@AppStorage` for user preferences - settings sync automatically between `GameViewModel` and `SettingsView`:
```swift
@AppStorage("soundMode") var soundMode: SoundMode = .laughter
```

### Custom Shapes
Add new shapes in `Views/Shapes/` implementing SwiftUI's `Shape` protocol. Register in `ShapeType` enum and handle in `FigureView.shapeContent()`.

### Animation Effects
Custom animations live in `ViewModifiers/` as `ViewModifier` implementations. Add new styles to `Figure.AnimationStyle` enum and handle in `FigureView.animationModifier`.

### Color Palette
Use `Color.randomBabySmash` from `Extensions/Color+Random.swift` - curated bright, child-friendly colors.

### Sound Assets
Place `.wav` files in the bundle, register in `SoundManager.Sound` enum. Laughter sounds are grouped for random playback.

## Build & Run

```bash
# Open in Xcode
open src/babysmash.xcodeproj

# Build via command line
xcodebuild -project src/babysmash.xcodeproj -scheme babysmash -configuration Debug build
```

**Requirements**: Xcode 16+, macOS 14+ SDK

## Communication Patterns

### Inter-component Events
Uses `NotificationCenter` for cross-component communication:
```swift
// Trigger settings from anywhere
NotificationCenter.default.post(name: .showSettings, object: nil)
```

### Combine Subscriptions
`GameViewModel` subscribes to service publishers (`KeyboardMonitor.$lastKeyPressed`, `MouseDrawingManager.$trails`) using Combine.

## Important Details

- **Keyboard events are consumed** - `NSEvent.addLocalMonitorForEvents` returns `nil` to prevent key propagation
- **Figures auto-fade** - Timer in `GameViewModel.fadeOldFigures()` manages opacity based on `fadeAfter` setting
- **Word detection** - `WordFinder` matches typed letters against `Resources/Words.txt` dictionary
- **Settings shortcut** - Option+S opens settings (handled in `KeyboardMonitor`)
- **Window style** - Uses `.hiddenTitleBar` for immersive fullscreen experience
