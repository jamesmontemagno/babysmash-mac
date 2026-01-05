# BabySmash for macOS 🍼

A macOS port of [Scott Hanselman's BabySmash](https://github.com/shanselman/babysmash) - a fun app that displays colorful shapes, letters, and sounds when babies press keys or interact with the mouse.

![macOS](https://img.shields.io/badge/macOS-14.0+-blue?style=flat-square&logo=apple)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange?style=flat-square&logo=swift)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-purple?style=flat-square)

## Features

- 🎨 **Colorful Shapes** - Circles, stars, hearts, hexagons, triangles, and more appear on screen
- 🔤 **Letters & Numbers** - Typed characters display in bright, child-friendly colors
- 🔊 **Sound Effects** - Laughter sounds, speech synthesis, or silent mode
- 🖱️ **Mouse Drawing** - Drag the mouse to leave colorful trails
- 😊 **Friendly Faces** - Shapes can display cute faces
- 📝 **Word Detection** - Recognizes typed words and speaks them aloud
- ♿ **Accessibility Features** - Comprehensive support for children with special needs
- ⚙️ **Customizable** - Adjust fade timing, sound modes, and more

## Requirements

- macOS 14.0 (Sonoma) or later
- Xcode 16.0 or later

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/jamesmontemagno/babysmash-mac.git
   cd babysmash-mac
   ```

2. Open the project in Xcode:
   ```bash
   open babysmash.xcodeproj
   ```

3. Build and run (⌘R)

## Usage

- **Type any key** to display letters, numbers, or shapes
- **Click anywhere** to create shapes at that location
- **Drag the mouse** to draw colorful trails
- **Option + S** to open Settings

### Settings

| Setting | Description |
|---------|-------------|
| Sound Mode | Choose between Laughter, Speech, or Off |
| Fade After | How long shapes stay on screen (seconds) |
| Show Faces | Display cute faces on shapes |
| Mouse Drawing | Enable/disable mouse trail drawing |
| Force Uppercase | Display all letters in uppercase |
| Max Figures | Maximum number of shapes on screen |
| **Accessibility** | Comprehensive accessibility options (see below) |

## Accessibility Features

BabySmash includes comprehensive accessibility support to make the app inclusive for children with various special needs:

### Visual Accessibility

- **High Contrast Mode** - Bold outlines and simplified fills for better visibility
- **Large Elements Mode** - Configurable minimum shape size (300px+) for easier viewing
- **Color Blindness Support** - Specialized color palettes for:
  - Deuteranopia (green-blind)
  - Protanopia (red-blind)
  - Tritanopia (blue-blind)
  - Monochromacy (total color blindness)
- **Pattern Overlays** - Stripes, dots, crosshatch patterns help distinguish shapes beyond color alone

### Motion Accessibility

- **Reduce Motion** - Respects system preference, disables or reduces animations
- **Animation Speed Control** - Slow, normal, fast, or none
- **Disable Rotation** - Turn off spinning effects independently

### Audio Accessibility

- **Visual Sound Indicators** - Flashing border when sounds play
- **Captions** - Text display for sounds and speech
- **Volume Boost** - Enhanced audio output for better audibility

### Motor Accessibility

- **Auto-Play Mode** - Shapes appear automatically at configurable intervals (no keyboard needed)
- **Switch Control Mode** - Scanning interface for single-switch input devices
- **Reduced Physical Interaction** - Minimal input requirements

### Cognitive Accessibility

- **Simplified Mode** - Limits simultaneous shapes for reduced complexity (configurable 1-20 shapes)
- **Predictable Mode** - Shapes appear in consistent positions rather than randomly
- **Focus Mode** - Filter content to:
  - Letters only
  - Numbers only
  - Shapes only
  - All (default)

### Photosensitivity Protection

- **Safe Mode** - Disables all flashing effects and rapid transitions
- **No Strobing** - Gentle, smooth animations only

### System Integration

- Automatically detects and responds to macOS accessibility settings:
  - VoiceOver support
  - System Reduce Motion preference
  - System Increase Contrast preference

To access accessibility settings, open Settings (Option + S) and select "Accessibility Settings..."

## Architecture

The app follows the MVVM pattern with SwiftUI:

```
KeyboardMonitor (NSEvent) → GameViewModel → Figure model → FigureView
MouseDrawingManager → DrawingTrail model → MainGameView (renders trails)
```

### Key Components

| Component | Purpose |
|-----------|---------|
| `GameViewModel` | Central state management, input handling, figure lifecycle |
| `Figure` | Shape/letter data model with animation style |
| `FigureView` | Renders figures with animations |
| `KeyboardMonitor` | Low-level keyboard capture using NSEvent |
| `MouseDrawingManager` | Handles mouse drawing trails |
| `SoundManager` | Audio playback for laughter and effects |
| `SpeechService` | Text-to-speech for letters and words |
| `WordFinder` | Detects typed words from dictionary |
| `AccessibilitySettingsManager` | Manages accessibility features and system integration |
| `AutoPlayManager` | Automatic shape generation for motor accessibility |
| `SwitchControlManager` | Switch control scanning for single-switch devices |

## Credits

- Original BabySmash by [Scott Hanselman](https://github.com/shanselman/babysmash)
- macOS port by [James Montemagno](https://github.com/jamesmontemagno)

## License

This project is open source. See the original [BabySmash repository](https://github.com/shanselman/babysmash) for license details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
