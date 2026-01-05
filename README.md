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
   open src/babysmash.xcodeproj
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

## Credits

- Original BabySmash by [Scott Hanselman](https://github.com/shanselman/babysmash)
- macOS port by [James Montemagno](https://github.com/jamesmontemagno)

## License

This project is open source. See the original [BabySmash repository](https://github.com/shanselman/babysmash) for license details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
