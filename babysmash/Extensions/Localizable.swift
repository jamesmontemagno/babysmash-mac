//
//  Localizable.swift
//  babysmash
//
//  Centralized localization strings using LocalizedStringResource
//

import Foundation

/// Centralized localization namespace using the L10n pattern.
/// Usage: `Text(L10n.Settings.title)`
enum L10n {
    // MARK: - Common
    enum Common {
        static let done = LocalizedStringResource(
            "common.done",
            defaultValue: "Done"
        )
        static let cancel = LocalizedStringResource(
            "common.cancel",
            defaultValue: "Cancel"
        )
        static let save = LocalizedStringResource(
            "common.save",
            defaultValue: "Save"
        )
        static let reset = LocalizedStringResource(
            "common.reset",
            defaultValue: "Reset"
        )
        static let on = LocalizedStringResource(
            "common.on",
            defaultValue: "On"
        )
        static let off = LocalizedStringResource(
            "common.off",
            defaultValue: "Off"
        )
        static let running = LocalizedStringResource(
            "common.running",
            defaultValue: "Running"
        )
    }
    
    // MARK: - General
    enum General {
        static let quit = LocalizedStringResource(
            "general.quit",
            defaultValue: "Quit"
        )
    }
    
    // MARK: - Intro View
    enum Intro {
        static let title = LocalizedStringResource(
            "intro.title",
            defaultValue: "BabySmash!"
        )
        static let subtitle = LocalizedStringResource(
            "intro.subtitle",
            defaultValue: "A colorful keyboard adventure for little ones"
        )
        static let howToPlay = LocalizedStringResource(
            "intro.howToPlay",
            defaultValue: "How to Play"
        )
        static let instructionKeyboard = LocalizedStringResource(
            "intro.instruction.keyboard",
            defaultValue: "Press any key to create shapes & letters"
        )
        static let instructionMouse = LocalizedStringResource(
            "intro.instruction.mouse",
            defaultValue: "Click or drag to draw colorful trails"
        )
        static let instructionSound = LocalizedStringResource(
            "intro.instruction.sound",
            defaultValue: "Listen to fun sounds and speech"
        )
        static let instructionSettings = LocalizedStringResource(
            "intro.instruction.settings",
            defaultValue: "Press ⌥S (Option+S) for settings"
        )
        static let clickToStart = LocalizedStringResource(
            "intro.clickToStart",
            defaultValue: "Click anywhere to start!"
        )
    }
    
    // MARK: - Settings View
    enum Settings {
        static let title = LocalizedStringResource(
            "settings.title",
            defaultValue: "Settings"
        )
        
        // Display Section
        enum Display {
            static let sectionTitle = LocalizedStringResource(
                "settings.display.sectionTitle",
                defaultValue: "Display"
            )
            static let multiMonitorMode = LocalizedStringResource(
                "settings.display.multiMonitorMode",
                defaultValue: "Multi-Monitor Mode"
            )
            static let activeDisplay = LocalizedStringResource(
                "settings.display.activeDisplay",
                defaultValue: "Active Display"
            )
            static func displaysDetected(_ count: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "settings.display.displaysDetected",
                    defaultValue: "\(count) display(s) detected"
                )
            }
        }
        
        // Sound Section
        enum Sound {
            static let sectionTitle = LocalizedStringResource(
                "settings.sound.sectionTitle",
                defaultValue: "Sound"
            )
            static let soundMode = LocalizedStringResource(
                "settings.sound.soundMode",
                defaultValue: "Sound Mode"
            )
            static let description = LocalizedStringResource(
                "settings.sound.description",
                defaultValue: "Laughter plays random giggle sounds. Speech reads letters and shape names aloud."
            )
        }
        
        // Language Section
        enum Language {
            static let sectionTitle = LocalizedStringResource(
                "settings.language.sectionTitle",
                defaultValue: "Language"
            )
            static let speechLanguage = LocalizedStringResource(
                "settings.language.speechLanguage",
                defaultValue: "Speech Language"
            )
            static let bilingualMode = LocalizedStringResource(
                "settings.language.bilingualMode",
                defaultValue: "Bilingual Mode"
            )
            static let secondaryLanguage = LocalizedStringResource(
                "settings.language.secondaryLanguage",
                defaultValue: "Secondary Language"
            )
            static let alternateBetweenLanguages = LocalizedStringResource(
                "settings.language.alternateBetweenLanguages",
                defaultValue: "Alternate Between Languages"
            )
            static let alternateDescription = LocalizedStringResource(
                "settings.language.alternateDescription",
                defaultValue: "When enabled, speech alternates between primary and secondary languages."
            )
            static let changesDescription = LocalizedStringResource(
                "settings.language.changesDescription",
                defaultValue: "Changes how letters, numbers, and shapes are pronounced."
            )
        }
        
        // Theme Section
        enum Theme {
            static let sectionTitle = LocalizedStringResource(
                "settings.theme.sectionTitle",
                defaultValue: "Theme"
            )
            static let theme = LocalizedStringResource(
                "settings.theme.theme",
                defaultValue: "Theme"
            )
            static let builtIn = LocalizedStringResource(
                "settings.theme.builtIn",
                defaultValue: "Built-in"
            )
            static let custom = LocalizedStringResource(
                "settings.theme.custom",
                defaultValue: "Custom"
            )
            static let editTheme = LocalizedStringResource(
                "settings.theme.editTheme",
                defaultValue: "Edit Theme..."
            )
            static let createNewTheme = LocalizedStringResource(
                "settings.theme.createNewTheme",
                defaultValue: "Create New Theme..."
            )
            static let deleteTheme = LocalizedStringResource(
                "settings.theme.deleteTheme",
                defaultValue: "Delete Theme"
            )
        }
        
        // Appearance Section
        enum Appearance {
            static let sectionTitle = LocalizedStringResource(
                "settings.appearance.sectionTitle",
                defaultValue: "Appearance"
            )
            static let cursor = LocalizedStringResource(
                "settings.appearance.cursor",
                defaultValue: "Cursor"
            )
            static let showFacesOnShapes = LocalizedStringResource(
                "settings.appearance.showFacesOnShapes",
                defaultValue: "Show Faces on Shapes"
            )
            static let forceUppercaseLetters = LocalizedStringResource(
                "settings.appearance.forceUppercaseLetters",
                defaultValue: "Force Uppercase Letters"
            )
        }
        
        // Mouse Drawing Section
        enum MouseDrawing {
            static let sectionTitle = LocalizedStringResource(
                "settings.mouseDrawing.sectionTitle",
                defaultValue: "Mouse Drawing"
            )
            static let enableMouseDrawing = LocalizedStringResource(
                "settings.mouseDrawing.enableMouseDrawing",
                defaultValue: "Enable Mouse Drawing"
            )
            static let clicklessMouseDrawing = LocalizedStringResource(
                "settings.mouseDrawing.clicklessMouseDrawing",
                defaultValue: "Clickless Mouse Drawing"
            )
            static let clicklessDescription = LocalizedStringResource(
                "settings.mouseDrawing.clicklessDescription",
                defaultValue: "When enabled, drawing happens as you move the mouse without clicking."
            )
        }
        
        // Fade Away Section
        enum FadeAway {
            static let sectionTitle = LocalizedStringResource(
                "settings.fadeAway.sectionTitle",
                defaultValue: "Fade Away"
            )
            static let fadeShapesAway = LocalizedStringResource(
                "settings.fadeAway.fadeShapesAway",
                defaultValue: "Fade Shapes Away"
            )
            static func fadeAfterSeconds(_ seconds: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "settings.fadeAway.fadeAfterSeconds",
                    defaultValue: "Fade After: \(seconds) seconds"
                )
            }
            static func startRemovingAfter(_ count: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "settings.fadeAway.startRemovingAfter",
                    defaultValue: "Start Removing After: \(count) shapes"
                )
            }
        }
        
        // Baby Safety Section
        enum BabySafety {
            static let sectionTitle = LocalizedStringResource(
                "settings.babySafety.sectionTitle",
                defaultValue: "Baby Safety"
            )
            static let blockSystemKeys = LocalizedStringResource(
                "settings.babySafety.blockSystemKeys",
                defaultValue: "Block System Keys"
            )
            static let blockDescription = LocalizedStringResource(
                "settings.babySafety.blockDescription",
                defaultValue: "Blocks Cmd+Tab, Cmd+Q, Cmd+Space (Spotlight), Mission Control, and other system shortcuts"
            )
            static let emergencyExit = LocalizedStringResource(
                "settings.babySafety.emergencyExit",
                defaultValue: "Emergency exit: ⌥⌘ Esc (Force Quit)"
            )
        }
        
        // Keyboard Shortcuts Section
        enum KeyboardShortcuts {
            static let sectionTitle = LocalizedStringResource(
                "settings.keyboardShortcuts.sectionTitle",
                defaultValue: "Keyboard Shortcuts"
            )
            static let openSettings = LocalizedStringResource(
                "settings.keyboardShortcuts.openSettings",
                defaultValue: "Open Settings"
            )
        }
        
        // Accessibility Section
        enum AccessibilitySection {
            static let sectionTitle = LocalizedStringResource(
                "settings.accessibility.sectionTitle",
                defaultValue: "Accessibility"
            )
            static let accessibilitySettings = LocalizedStringResource(
                "settings.accessibility.accessibilitySettings",
                defaultValue: "Accessibility Settings..."
            )
            static let description = LocalizedStringResource(
                "settings.accessibility.description",
                defaultValue: "Visual, audio, motor, and cognitive accessibility options."
            )
        }
        
        // About Section
        enum About {
            static let sectionTitle = LocalizedStringResource(
                "settings.about.sectionTitle",
                defaultValue: "About"
            )
            static let appName = LocalizedStringResource(
                "settings.about.appName",
                defaultValue: "BabySmash for macOS"
            )
            static func version(_ version: String) -> LocalizedStringResource {
                LocalizedStringResource(
                    "settings.about.version",
                    defaultValue: "Version \(version)"
                )
            }
            static let originalBy = LocalizedStringResource(
                "settings.about.originalBy",
                defaultValue: "Original BabySmash by Scott Hanselman"
            )
        }
        
        // Reset Section
        enum ResetSection {
            static let sectionTitle = LocalizedStringResource(
                "settings.reset.sectionTitle",
                defaultValue: "Reset"
            )
            static let resetToDefaults = LocalizedStringResource(
                "settings.reset.resetToDefaults",
                defaultValue: "Reset to Defaults"
            )
            static let resetFooter = LocalizedStringResource(
                "settings.reset.resetFooter",
                defaultValue: "Resets all settings to default values and restarts onboarding on next launch."
            )
        }
        
        // Alerts
        enum Alerts {
            // Accessibility Alert
            static let accessibilityPermissionTitle = LocalizedStringResource(
                "settings.alerts.accessibilityPermission.title",
                defaultValue: "Accessibility Permission Required"
            )
            static let accessibilityPermissionMessage = LocalizedStringResource(
                "settings.alerts.accessibilityPermission.message",
                defaultValue: "BabySmash needs Accessibility permission to block system keyboard shortcuts, preventing babies from accidentally switching apps or triggering system functions.\n\n1. Open System Settings\n2. Find BabySmash in the list\n3. Enable the checkbox\n4. Toggle this setting again"
            )
            static let openSystemSettings = LocalizedStringResource(
                "settings.alerts.accessibilityPermission.openSystemSettings",
                defaultValue: "Open System Settings"
            )
            
            // Reset Alert
            static let resetConfirmTitle = LocalizedStringResource(
                "settings.alerts.resetConfirm.title",
                defaultValue: "Reset to Defaults?"
            )
            static let resetConfirmMessage = LocalizedStringResource(
                "settings.alerts.resetConfirm.message",
                defaultValue: "This will reset all settings to their default values and restart the onboarding experience on next launch. The app will quit after resetting."
            )
        }
    }
    
    // MARK: - Theme Picker View
    enum ThemePicker {
        static let title = LocalizedStringResource(
            "themePicker.title",
            defaultValue: "Choose Your Theme"
        )
        static let subtitle = LocalizedStringResource(
            "themePicker.subtitle",
            defaultValue: "Pick a look for your BabySmash adventure!"
        )
        static func startWith(_ themeName: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "themePicker.startWith",
                defaultValue: "Start with \(themeName)"
            )
        }
    }
    
    // MARK: - Theme Editor View
    enum ThemeEditor {
        static let duplicateTheme = LocalizedStringResource(
            "themeEditor.duplicateTheme",
            defaultValue: "Duplicate Theme"
        )
        static let editTheme = LocalizedStringResource(
            "themeEditor.editTheme",
            defaultValue: "Edit Theme"
        )
        static let livePreview = LocalizedStringResource(
            "themeEditor.livePreview",
            defaultValue: "Live Preview"
        )
        static let untitledTheme = LocalizedStringResource(
            "themeEditor.untitledTheme",
            defaultValue: "Untitled Theme"
        )
        
        // Basic Section
        enum Basic {
            static let sectionTitle = LocalizedStringResource(
                "themeEditor.basic.sectionTitle",
                defaultValue: "Basic"
            )
            static let themeName = LocalizedStringResource(
                "themeEditor.basic.themeName",
                defaultValue: "Theme Name"
            )
            static let backgroundStyle = LocalizedStringResource(
                "themeEditor.basic.backgroundStyle",
                defaultValue: "Background Style"
            )
            static let backgroundColor = LocalizedStringResource(
                "themeEditor.basic.backgroundColor",
                defaultValue: "Background Color"
            )
            static let gradientColors = LocalizedStringResource(
                "themeEditor.basic.gradientColors",
                defaultValue: "Gradient Colors"
            )
        }
        
        // Color Palette Section
        enum ColorPalette {
            static let sectionTitle = LocalizedStringResource(
                "themeEditor.colorPalette.sectionTitle",
                defaultValue: "Color Palette"
            )
            static func color(_ index: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "themeEditor.colorPalette.color",
                    defaultValue: "Color \(index)"
                )
            }
            static let addColor = LocalizedStringResource(
                "themeEditor.colorPalette.addColor",
                defaultValue: "Add Color"
            )
        }
        
        // Shapes Section
        enum Shapes {
            static let sectionTitle = LocalizedStringResource(
                "themeEditor.shapes.sectionTitle",
                defaultValue: "Shapes"
            )
            static let shapeStyle = LocalizedStringResource(
                "themeEditor.shapes.shapeStyle",
                defaultValue: "Shape Style"
            )
            static func sizeRange(_ min: Int, _ max: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "themeEditor.shapes.sizeRange",
                    defaultValue: "Size Range: \(min) - \(max)"
                )
            }
            static let min = LocalizedStringResource(
                "themeEditor.shapes.min",
                defaultValue: "Min"
            )
            static let max = LocalizedStringResource(
                "themeEditor.shapes.max",
                defaultValue: "Max"
            )
        }
        
        // Effects Section
        enum Effects {
            static let sectionTitle = LocalizedStringResource(
                "themeEditor.effects.sectionTitle",
                defaultValue: "Effects"
            )
            static let enableShadow = LocalizedStringResource(
                "themeEditor.effects.enableShadow",
                defaultValue: "Enable Shadow"
            )
            static func shadowRadius(_ radius: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "themeEditor.effects.shadowRadius",
                    defaultValue: "Shadow Radius: \(radius)"
                )
            }
            static func shadowOpacity(_ percent: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "themeEditor.effects.shadowOpacity",
                    defaultValue: "Shadow Opacity: \(percent)%"
                )
            }
            static let enableGlow = LocalizedStringResource(
                "themeEditor.effects.enableGlow",
                defaultValue: "Enable Glow"
            )
            static func glowRadius(_ radius: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "themeEditor.effects.glowRadius",
                    defaultValue: "Glow Radius: \(radius)"
                )
            }
        }
        
        // Face Overlay Section
        enum FaceOverlay {
            static let sectionTitle = LocalizedStringResource(
                "themeEditor.faceOverlay.sectionTitle",
                defaultValue: "Face Overlay"
            )
            static let faceStyle = LocalizedStringResource(
                "themeEditor.faceOverlay.faceStyle",
                defaultValue: "Face Style"
            )
        }
    }
    
    // MARK: - Accessibility Settings View
    enum Accessibility {
        // Visual Section
        enum Visual {
            static let sectionTitle = LocalizedStringResource(
                "accessibility.visual.sectionTitle",
                defaultValue: "Visual"
            )
            static let highContrastMode = LocalizedStringResource(
                "accessibility.visual.highContrastMode",
                defaultValue: "High Contrast Mode"
            )
            static let largeElements = LocalizedStringResource(
                "accessibility.visual.largeElements",
                defaultValue: "Large Elements"
            )
            static func minimumSize(_ size: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "accessibility.visual.minimumSize",
                    defaultValue: "Minimum Size: \(size)"
                )
            }
            static let colorBlindnessMode = LocalizedStringResource(
                "accessibility.visual.colorBlindnessMode",
                defaultValue: "Color Blindness Mode"
            )
            static let showPatternsOnShapes = LocalizedStringResource(
                "accessibility.visual.showPatternsOnShapes",
                defaultValue: "Show Patterns on Shapes"
            )
            static let patternsDescription = LocalizedStringResource(
                "accessibility.visual.patternsDescription",
                defaultValue: "Patterns help distinguish shapes beyond color alone."
            )
        }
        
        // Motion Section
        enum Motion {
            static let sectionTitle = LocalizedStringResource(
                "accessibility.motion.sectionTitle",
                defaultValue: "Motion"
            )
            static let reduceMotion = LocalizedStringResource(
                "accessibility.motion.reduceMotion",
                defaultValue: "Reduce Motion"
            )
            static let animationSpeed = LocalizedStringResource(
                "accessibility.motion.animationSpeed",
                defaultValue: "Animation Speed"
            )
            static let disableRotationEffects = LocalizedStringResource(
                "accessibility.motion.disableRotationEffects",
                defaultValue: "Disable Rotation Effects"
            )
            static let systemReduceMotionEnabled = LocalizedStringResource(
                "accessibility.motion.systemReduceMotionEnabled",
                defaultValue: "System Reduce Motion is enabled"
            )
        }
        
        // Audio Section
        enum Audio {
            static let sectionTitle = LocalizedStringResource(
                "accessibility.audio.sectionTitle",
                defaultValue: "Audio"
            )
            static let visualSoundIndicators = LocalizedStringResource(
                "accessibility.audio.visualSoundIndicators",
                defaultValue: "Visual Sound Indicators"
            )
            static let flashesDescription = LocalizedStringResource(
                "accessibility.audio.flashesDescription",
                defaultValue: "Flashes the screen border when sounds play."
            )
            static let showCaptions = LocalizedStringResource(
                "accessibility.audio.showCaptions",
                defaultValue: "Show Captions"
            )
            static let captionsDescription = LocalizedStringResource(
                "accessibility.audio.captionsDescription",
                defaultValue: "Shows text describing sounds and speech."
            )
            static let volumeBoost = LocalizedStringResource(
                "accessibility.audio.volumeBoost",
                defaultValue: "Volume Boost"
            )
        }
        
        // Motor Section
        enum Motor {
            static let sectionTitle = LocalizedStringResource(
                "accessibility.motor.sectionTitle",
                defaultValue: "Motor"
            )
            static let autoPlayMode = LocalizedStringResource(
                "accessibility.motor.autoPlayMode",
                defaultValue: "Auto-Play Mode"
            )
            static func interval(_ seconds: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "accessibility.motor.interval",
                    defaultValue: "Interval: \(seconds)s"
                )
            }
            static let autoPlayDescription = LocalizedStringResource(
                "accessibility.motor.autoPlayDescription",
                defaultValue: "Shapes appear automatically at this interval."
            )
            static let switchControlMode = LocalizedStringResource(
                "accessibility.motor.switchControlMode",
                defaultValue: "Switch Control Mode"
            )
            static let switchControlDescription = LocalizedStringResource(
                "accessibility.motor.switchControlDescription",
                defaultValue: "Enables scanning through actions for single-switch input."
            )
        }
        
        // Cognitive Section
        enum Cognitive {
            static let sectionTitle = LocalizedStringResource(
                "accessibility.cognitive.sectionTitle",
                defaultValue: "Cognitive"
            )
            static let simplifiedMode = LocalizedStringResource(
                "accessibility.cognitive.simplifiedMode",
                defaultValue: "Simplified Mode"
            )
            static func maxShapes(_ count: Int) -> LocalizedStringResource {
                LocalizedStringResource(
                    "accessibility.cognitive.maxShapes",
                    defaultValue: "Max Shapes: \(count)"
                )
            }
            static let maxShapesDescription = LocalizedStringResource(
                "accessibility.cognitive.maxShapesDescription",
                defaultValue: "Limits the number of shapes on screen for reduced complexity."
            )
            static let predictableMode = LocalizedStringResource(
                "accessibility.cognitive.predictableMode",
                defaultValue: "Predictable Mode"
            )
            static let predictableModeDescription = LocalizedStringResource(
                "accessibility.cognitive.predictableModeDescription",
                defaultValue: "Shapes appear in consistent positions rather than randomly."
            )
            static let focus = LocalizedStringResource(
                "accessibility.cognitive.focus",
                defaultValue: "Focus"
            )
            static let focusDescription = LocalizedStringResource(
                "accessibility.cognitive.focusDescription",
                defaultValue: "Limits content to specific types."
            )
        }
        
        // Photosensitivity Section
        enum Photosensitivity {
            static let sectionTitle = LocalizedStringResource(
                "accessibility.photosensitivity.sectionTitle",
                defaultValue: "Photosensitivity"
            )
            static let safeMode = LocalizedStringResource(
                "accessibility.photosensitivity.safeMode",
                defaultValue: "Safe Mode (No Flashing)"
            )
            static let safeModeDescription = LocalizedStringResource(
                "accessibility.photosensitivity.safeModeDescription",
                defaultValue: "Disables all rapid visual changes, flashing effects, and ensures gentle transitions only. Recommended for users with photosensitive epilepsy."
            )
        }
        
        // System Section
        enum System {
            static let sectionTitle = LocalizedStringResource(
                "accessibility.system.sectionTitle",
                defaultValue: "System"
            )
            static let voiceOver = LocalizedStringResource(
                "accessibility.system.voiceOver",
                defaultValue: "VoiceOver"
            )
            static let systemReduceMotion = LocalizedStringResource(
                "accessibility.system.systemReduceMotion",
                defaultValue: "System Reduce Motion"
            )
            static let systemIncreaseContrast = LocalizedStringResource(
                "accessibility.system.systemIncreaseContrast",
                defaultValue: "System Increase Contrast"
            )
            static let resetAccessibilitySettings = LocalizedStringResource(
                "accessibility.system.resetAccessibilitySettings",
                defaultValue: "Reset Accessibility Settings"
            )
        }
    }
    
    // MARK: - Shape Names
    enum ShapeNames {
        static let circle = LocalizedStringResource(
            "shapes.circle",
            defaultValue: "Circle"
        )
        static let oval = LocalizedStringResource(
            "shapes.oval",
            defaultValue: "Oval"
        )
        static let rectangle = LocalizedStringResource(
            "shapes.rectangle",
            defaultValue: "Rectangle"
        )
        static let square = LocalizedStringResource(
            "shapes.square",
            defaultValue: "Square"
        )
        static let triangle = LocalizedStringResource(
            "shapes.triangle",
            defaultValue: "Triangle"
        )
        static let hexagon = LocalizedStringResource(
            "shapes.hexagon",
            defaultValue: "Hexagon"
        )
        static let trapezoid = LocalizedStringResource(
            "shapes.trapezoid",
            defaultValue: "Trapezoid"
        )
        static let star = LocalizedStringResource(
            "shapes.star",
            defaultValue: "Star"
        )
        static let heart = LocalizedStringResource(
            "shapes.heart",
            defaultValue: "Heart"
        )
    }
    
    // MARK: - Sound Mode Names
    enum SoundModeNames {
        static let laughter = LocalizedStringResource(
            "soundMode.laughter",
            defaultValue: "Laughter"
        )
        static let speech = LocalizedStringResource(
            "soundMode.speech",
            defaultValue: "Speech"
        )
        static let off = LocalizedStringResource(
            "soundMode.off",
            defaultValue: "Off"
        )
    }
    
    // MARK: - Cursor Type Names
    enum CursorTypeNames {
        static let hand = LocalizedStringResource(
            "cursorType.hand",
            defaultValue: "Hand"
        )
        static let arrow = LocalizedStringResource(
            "cursorType.arrow",
            defaultValue: "Arrow"
        )
        static let hidden = LocalizedStringResource(
            "cursorType.hidden",
            defaultValue: "Hidden"
        )
    }
    
    // MARK: - Display Mode Names
    enum DisplayModeNames {
        static let allDisplays = LocalizedStringResource(
            "displayMode.allDisplays",
            defaultValue: "All Displays"
        )
        static let primaryOnly = LocalizedStringResource(
            "displayMode.primaryOnly",
            defaultValue: "Primary Only"
        )
        static let selectDisplay = LocalizedStringResource(
            "displayMode.selectDisplay",
            defaultValue: "Select Display..."
        )
    }
    
    // MARK: - Background Style Names
    enum BackgroundStyleNames {
        static let solidColor = LocalizedStringResource(
            "backgroundStyle.solidColor",
            defaultValue: "Solid Color"
        )
        static let linearGradient = LocalizedStringResource(
            "backgroundStyle.linearGradient",
            defaultValue: "Linear Gradient"
        )
        static let radialGradient = LocalizedStringResource(
            "backgroundStyle.radialGradient",
            defaultValue: "Radial Gradient"
        )
        static let animatedGradient = LocalizedStringResource(
            "backgroundStyle.animatedGradient",
            defaultValue: "Animated Gradient"
        )
        static let starfield = LocalizedStringResource(
            "backgroundStyle.starfield",
            defaultValue: "Starfield"
        )
    }
    
    // MARK: - Shape Style Names
    enum ShapeStyleNames {
        static let filled = LocalizedStringResource(
            "shapeStyle.filled",
            defaultValue: "Filled"
        )
        static let outlined = LocalizedStringResource(
            "shapeStyle.outlined",
            defaultValue: "Outlined"
        )
        static let filledWithOutline = LocalizedStringResource(
            "shapeStyle.filledWithOutline",
            defaultValue: "Filled + Outline"
        )
        static let gradient = LocalizedStringResource(
            "shapeStyle.gradient",
            defaultValue: "Gradient"
        )
    }
    
    // MARK: - Face Style Names
    enum FaceStyleNames {
        static let none = LocalizedStringResource(
            "faceStyle.none",
            defaultValue: "None"
        )
        static let simple = LocalizedStringResource(
            "faceStyle.simple",
            defaultValue: "Simple"
        )
        static let kawaii = LocalizedStringResource(
            "faceStyle.kawaii",
            defaultValue: "Kawaii"
        )
    }
    
    // MARK: - Color Blindness Mode Names
    enum ColorBlindnessModeNames {
        static let none = LocalizedStringResource(
            "colorBlindnessMode.none",
            defaultValue: "None"
        )
        static let deuteranopia = LocalizedStringResource(
            "colorBlindnessMode.deuteranopia",
            defaultValue: "Deuteranopia (Green-blind)"
        )
        static let protanopia = LocalizedStringResource(
            "colorBlindnessMode.protanopia",
            defaultValue: "Protanopia (Red-blind)"
        )
        static let tritanopia = LocalizedStringResource(
            "colorBlindnessMode.tritanopia",
            defaultValue: "Tritanopia (Blue-blind)"
        )
        static let monochromacy = LocalizedStringResource(
            "colorBlindnessMode.monochromacy",
            defaultValue: "Monochromacy (Grayscale)"
        )
    }
    
    // MARK: - Animation Speed Names
    enum AnimationSpeedNames {
        static let slow = LocalizedStringResource(
            "animationSpeed.slow",
            defaultValue: "Slow"
        )
        static let normal = LocalizedStringResource(
            "animationSpeed.normal",
            defaultValue: "Normal"
        )
        static let fast = LocalizedStringResource(
            "animationSpeed.fast",
            defaultValue: "Fast"
        )
        static let none = LocalizedStringResource(
            "animationSpeed.none",
            defaultValue: "None"
        )
    }
    
    // MARK: - Focus Mode Names
    enum FocusModeNames {
        static let all = LocalizedStringResource(
            "focusMode.all",
            defaultValue: "All"
        )
        static let lettersOnly = LocalizedStringResource(
            "focusMode.lettersOnly",
            defaultValue: "Letters Only"
        )
        static let numbersOnly = LocalizedStringResource(
            "focusMode.numbersOnly",
            defaultValue: "Numbers Only"
        )
        static let shapesOnly = LocalizedStringResource(
            "focusMode.shapesOnly",
            defaultValue: "Shapes Only"
        )
    }
    
    // MARK: - Performance Mode Names
    enum PerformanceModeNames {
        static let auto = LocalizedStringResource(
            "performanceMode.auto",
            defaultValue: "Auto"
        )
        static let highQuality = LocalizedStringResource(
            "performanceMode.highQuality",
            defaultValue: "High Quality"
        )
        static let balanced = LocalizedStringResource(
            "performanceMode.balanced",
            defaultValue: "Balanced"
        )
        static let batterySaver = LocalizedStringResource(
            "performanceMode.batterySaver",
            defaultValue: "Battery Saver"
        )
    }
    
    // MARK: - Performance Section Strings
    enum Performance {
        static let sectionTitle = LocalizedStringResource(
            "settings.performance.sectionTitle",
            defaultValue: "Performance"
        )
        static let performanceMode = LocalizedStringResource(
            "settings.performance.performanceMode",
            defaultValue: "Performance Mode"
        )
        static let autoDescription = LocalizedStringResource(
            "settings.performance.autoDescription",
            defaultValue: "Automatically adjusts quality based on system load."
        )
        static let highQualityDescription = LocalizedStringResource(
            "settings.performance.highQualityDescription",
            defaultValue: "Full effects, animations, and visual quality."
        )
        static let balancedDescription = LocalizedStringResource(
            "settings.performance.balancedDescription",
            defaultValue: "Reduced effects for better performance."
        )
        static let batterySaverDescription = LocalizedStringResource(
            "settings.performance.batterySaverDescription",
            defaultValue: "Minimal effects for maximum performance."
        )
        static func currentTier(_ tier: String) -> LocalizedStringResource {
            LocalizedStringResource(
                "settings.performance.currentTier",
                defaultValue: "Current tier: \(tier)"
            )
        }
    }
    
    // MARK: - Onboarding Strings
    enum Onboarding {
        // Performance Test
        enum Performance {
            static let title = LocalizedStringResource(
                "onboarding.performance.title",
                defaultValue: "Performance Check"
            )
            static let subtitle = LocalizedStringResource(
                "onboarding.performance.subtitle",
                defaultValue: "Let's find the best settings for your Mac"
            )
            static let runningTitle = LocalizedStringResource(
                "onboarding.performance.runningTitle",
                defaultValue: "Testing..."
            )
            static let runningSubtitle = LocalizedStringResource(
                "onboarding.performance.runningSubtitle",
                defaultValue: "Measuring your Mac's performance"
            )
            static let completeTitle = LocalizedStringResource(
                "onboarding.performance.completeTitle",
                defaultValue: "Test Complete!"
            )
            static let completeSubtitle = LocalizedStringResource(
                "onboarding.performance.completeSubtitle",
                defaultValue: "We've found the best settings for you"
            )
            static let infoTest = LocalizedStringResource(
                "onboarding.performance.infoTest",
                defaultValue: "We'll run a quick visual test"
            )
            static let infoOptimize = LocalizedStringResource(
                "onboarding.performance.infoOptimize",
                defaultValue: "Optimize settings for smooth animation"
            )
            static let infoDuration = LocalizedStringResource(
                "onboarding.performance.infoDuration",
                defaultValue: "Takes only 5 seconds"
            )
            static let startTest = LocalizedStringResource(
                "onboarding.performance.startTest",
                defaultValue: "Start Test"
            )
            static let testing = LocalizedStringResource(
                "onboarding.performance.testing",
                defaultValue: "Testing..."
            )
            static let continueButton = LocalizedStringResource(
                "onboarding.performance.continueButton",
                defaultValue: "Continue"
            )
            static let recommended = LocalizedStringResource(
                "onboarding.performance.recommended",
                defaultValue: "Recommended Setting"
            )
            static let resultHigh = LocalizedStringResource(
                "onboarding.performance.resultHigh",
                defaultValue: "Your Mac handles everything beautifully! Full effects enabled."
            )
            static let resultBalanced = LocalizedStringResource(
                "onboarding.performance.resultBalanced",
                defaultValue: "Balanced mode will give you smooth animations with great visuals."
            )
            static let resultLow = LocalizedStringResource(
                "onboarding.performance.resultLow",
                defaultValue: "Battery saver mode ensures smooth performance on your Mac."
            )
        }
        
        // System Blocking
        enum SystemBlocking {
            static let title = LocalizedStringResource(
                "onboarding.systemBlocking.title",
                defaultValue: "Baby-Proof Mode"
            )
            static let subtitle = LocalizedStringResource(
                "onboarding.systemBlocking.subtitle",
                defaultValue: "Keep your baby from accidentally closing the app"
            )
            static let blocksTitle = LocalizedStringResource(
                "onboarding.systemBlocking.blocksTitle",
                defaultValue: "What Gets Blocked"
            )
            static let quitApp = LocalizedStringResource(
                "onboarding.systemBlocking.quitApp",
                defaultValue: "Quit the app"
            )
            static let switchApps = LocalizedStringResource(
                "onboarding.systemBlocking.switchApps",
                defaultValue: "Switch to other apps"
            )
            static let spotlight = LocalizedStringResource(
                "onboarding.systemBlocking.spotlight",
                defaultValue: "Open Spotlight search"
            )
            static let missionControl = LocalizedStringResource(
                "onboarding.systemBlocking.missionControl",
                defaultValue: "Mission Control"
            )
            static let exitTitle = LocalizedStringResource(
                "onboarding.systemBlocking.exitTitle",
                defaultValue: "Parents Can Still Exit"
            )
            static let openSettings = LocalizedStringResource(
                "onboarding.systemBlocking.openSettings",
                defaultValue: "Open settings"
            )
            static let exitApp = LocalizedStringResource(
                "onboarding.systemBlocking.exitApp",
                defaultValue: "Exit the app"
            )
            static let emergencyExit = LocalizedStringResource(
                "onboarding.systemBlocking.emergencyExit",
                defaultValue: "Emergency exit (press period 20 times)"
            )
            static let statusEnabled = LocalizedStringResource(
                "onboarding.systemBlocking.statusEnabled",
                defaultValue: "Baby-Proof Mode is ON"
            )
            static let statusDisabled = LocalizedStringResource(
                "onboarding.systemBlocking.statusDisabled",
                defaultValue: "Baby-Proof Mode is OFF - Enable in Settings"
            )
            static let openSettingsButton = LocalizedStringResource(
                "onboarding.systemBlocking.openSettingsButton",
                defaultValue: "Open Settings"
            )
            static let continueButton = LocalizedStringResource(
                "onboarding.systemBlocking.continueButton",
                defaultValue: "Let's Play!"
            )
        }
    }
}
