//
//  LocalizedSpeechService.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import AVFoundation
import SwiftUI

/// A speech service that supports multiple languages for letter, number, shape, and word pronunciation.
class LocalizedSpeechService {
    static let shared = LocalizedSpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
    @AppStorage("speechLanguage") var primaryLanguage: String = "en"
    @AppStorage("secondaryLanguage") var secondaryLanguage: String = ""
    @AppStorage("alternateSpeechLanguages") var alternateLanguages: Bool = false
    
    private var useSecondary = false
    
    private init() {}
    
    // MARK: - Available Languages
    
    static let availableLanguages: [(code: String, name: String)] = [
        ("en", "English"),
        ("es", "Español"),
        ("de", "Deutsch"),
        ("fr", "Français"),
        ("it", "Italiano"),
        ("pt", "Português"),
        ("ja", "日本語"),
        ("zh-Hans", "简体中文"),
        ("ko", "한국어"),
        ("ru", "Русский"),
    ]
    
    // MARK: - Voice Selection
    
    private func voiceForLanguage(_ languageCode: String) -> AVSpeechSynthesisVoice? {
        let voices = AVSpeechSynthesisVoice.speechVoices()
        
        // Prefer enhanced/premium voices
        if let enhanced = voices.first(where: {
            $0.language.hasPrefix(languageCode) && $0.quality == .enhanced
        }) {
            return enhanced
        }
        
        // Fall back to any voice for the language
        return voices.first { $0.language.hasPrefix(languageCode) }
    }
    
    private var currentLanguage: String {
        if alternateLanguages && !secondaryLanguage.isEmpty {
            useSecondary.toggle()
            return useSecondary ? secondaryLanguage : primaryLanguage
        }
        return primaryLanguage
    }
    
    // MARK: - Speaking Methods
    
    func speakLetter(_ letter: Character) {
        let language = currentLanguage
        let text = letterPronunciation(letter, in: language)
        speak(text, in: language)
    }
    
    func speakNumber(_ number: Character) {
        let language = currentLanguage
        let text = numberPronunciation(number, in: language)
        speak(text, in: language)
    }
    
    func speakShape(_ shape: ShapeType, color: Color) {
        let language = currentLanguage
        let text = shapePronunciation(shape: shape, color: color, in: language)
        speak(text, in: language)
    }
    
    func speakWord(_ word: String) {
        speak(word, in: currentLanguage)
    }
    
    private func speak(_ text: String, in languageCode: String) {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voiceForLanguage(languageCode)
        utterance.rate = 0.4
        utterance.pitchMultiplier = 1.2
        utterance.volume = 1.0
        
        synthesizer.speak(utterance)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
    
    // MARK: - Pronunciation Helpers
    
    private func letterPronunciation(_ letter: Character, in language: String) -> String {
        // Some letters need special pronunciation in certain languages
        let pronunciations: [String: [Character: String]] = [
            "en": [:],  // English letters pronounced as-is
            "es": ["Ñ": "eñe", "ñ": "eñe"],
            "de": ["Ä": "Ä Umlaut", "ä": "ä Umlaut", "Ö": "Ö Umlaut", "ö": "ö Umlaut", "Ü": "Ü Umlaut", "ü": "ü Umlaut", "ß": "Eszett"],
            "fr": ["É": "É accent aigu", "È": "È accent grave", "Ê": "Ê accent circonflexe", "Ç": "C cédille"],
            "ja": [:]  // Hiragana/Katakana pronounced as-is
        ]
        
        if let special = pronunciations[language]?[letter] {
            return special
        }
        
        // For basic Latin letters, use lowercase to avoid "Capital A" pronunciation
        let letterString = String(letter)
        if letter.isLetter && letter.isASCII {
            return letterString.lowercased()
        }
        
        return letterString
    }
    
    private func numberPronunciation(_ number: Character, in language: String) -> String {
        // Numbers in different languages
        let numbers: [String: [Character: String]] = [
            "ja": [
                "0": "ゼロ", "1": "いち", "2": "に", "3": "さん", "4": "よん",
                "5": "ご", "6": "ろく", "7": "なな", "8": "はち", "9": "きゅう"
            ],
            "zh-Hans": [
                "0": "零", "1": "一", "2": "二", "3": "三", "4": "四",
                "5": "五", "6": "六", "7": "七", "8": "八", "9": "九"
            ],
            "ko": [
                "0": "영", "1": "일", "2": "이", "3": "삼", "4": "사",
                "5": "오", "6": "육", "7": "칠", "8": "팔", "9": "구"
            ]
        ]
        
        if let special = numbers[language]?[number] {
            return special
        }
        return String(number)
    }
    
    private func shapePronunciation(shape: ShapeType, color: Color, in language: String) -> String {
        let colorName = localizedColorName(color, in: language)
        let shapeName = localizedShapeName(shape, in: language)
        
        // Word order varies by language
        switch language {
        case "ja":
            return "\(colorName)の\(shapeName)"  // "Red's Circle" pattern
        case "de", "fr", "es", "it", "pt":
            return "\(shapeName) \(colorName)"  // Noun + Adjective in Romance/German
        default:
            return "\(colorName) \(shapeName)"  // Adjective + Noun in English
        }
    }
    
    // MARK: - Localized Names
    
    func localizedColorName(_ color: Color, in language: String) -> String {
        let colorNames: [String: [String: String]] = [
            "en": ["red": "Red", "blue": "Blue", "yellow": "Yellow", "green": "Green", "purple": "Purple", "pink": "Pink", "orange": "Orange", "cyan": "Cyan", "mint": "Mint"],
            "es": ["red": "Rojo", "blue": "Azul", "yellow": "Amarillo", "green": "Verde", "purple": "Morado", "pink": "Rosa", "orange": "Naranja", "cyan": "Cian", "mint": "Menta"],
            "de": ["red": "Rot", "blue": "Blau", "yellow": "Gelb", "green": "Grün", "purple": "Lila", "pink": "Rosa", "orange": "Orange", "cyan": "Cyan", "mint": "Minzgrün"],
            "fr": ["red": "Rouge", "blue": "Bleu", "yellow": "Jaune", "green": "Vert", "purple": "Violet", "pink": "Rose", "orange": "Orange", "cyan": "Cyan", "mint": "Menthe"],
            "it": ["red": "Rosso", "blue": "Blu", "yellow": "Giallo", "green": "Verde", "purple": "Viola", "pink": "Rosa", "orange": "Arancione", "cyan": "Ciano", "mint": "Menta"],
            "pt": ["red": "Vermelho", "blue": "Azul", "yellow": "Amarelo", "green": "Verde", "purple": "Roxo", "pink": "Rosa", "orange": "Laranja", "cyan": "Ciano", "mint": "Menta"],
            "ja": ["red": "あか", "blue": "あお", "yellow": "きいろ", "green": "みどり", "purple": "むらさき", "pink": "ピンク", "orange": "オレンジ", "cyan": "シアン", "mint": "ミント"],
            "zh-Hans": ["red": "红色", "blue": "蓝色", "yellow": "黄色", "green": "绿色", "purple": "紫色", "pink": "粉色", "orange": "橙色", "cyan": "青色", "mint": "薄荷色"],
            "ko": ["red": "빨간색", "blue": "파란색", "yellow": "노란색", "green": "초록색", "purple": "보라색", "pink": "분홍색", "orange": "주황색", "cyan": "청록색", "mint": "민트색"],
            "ru": ["red": "Красный", "blue": "Синий", "yellow": "Жёлтый", "green": "Зелёный", "purple": "Фиолетовый", "pink": "Розовый", "orange": "Оранжевый", "cyan": "Голубой", "mint": "Мятный"],
        ]
        
        let colorKey = color.name.lowercased()
        return colorNames[language]?[colorKey] ?? colorNames["en"]?[colorKey] ?? color.name
    }
    
    func localizedShapeName(_ shape: ShapeType, in language: String) -> String {
        let shapeNames: [String: [ShapeType: String]] = [
            "en": [.circle: "Circle", .square: "Square", .triangle: "Triangle", .star: "Star", .heart: "Heart", .rectangle: "Rectangle", .oval: "Oval", .hexagon: "Hexagon", .trapezoid: "Trapezoid"],
            "es": [.circle: "Círculo", .square: "Cuadrado", .triangle: "Triángulo", .star: "Estrella", .heart: "Corazón", .rectangle: "Rectángulo", .oval: "Óvalo", .hexagon: "Hexágono", .trapezoid: "Trapecio"],
            "de": [.circle: "Kreis", .square: "Quadrat", .triangle: "Dreieck", .star: "Stern", .heart: "Herz", .rectangle: "Rechteck", .oval: "Oval", .hexagon: "Sechseck", .trapezoid: "Trapez"],
            "fr": [.circle: "Cercle", .square: "Carré", .triangle: "Triangle", .star: "Étoile", .heart: "Cœur", .rectangle: "Rectangle", .oval: "Ovale", .hexagon: "Hexagone", .trapezoid: "Trapèze"],
            "it": [.circle: "Cerchio", .square: "Quadrato", .triangle: "Triangolo", .star: "Stella", .heart: "Cuore", .rectangle: "Rettangolo", .oval: "Ovale", .hexagon: "Esagono", .trapezoid: "Trapezio"],
            "pt": [.circle: "Círculo", .square: "Quadrado", .triangle: "Triângulo", .star: "Estrela", .heart: "Coração", .rectangle: "Retângulo", .oval: "Oval", .hexagon: "Hexágono", .trapezoid: "Trapézio"],
            "ja": [.circle: "まる", .square: "しかく", .triangle: "さんかく", .star: "ほし", .heart: "ハート", .rectangle: "ながしかく", .oval: "だえん", .hexagon: "ろっかっけい", .trapezoid: "だいけい"],
            "zh-Hans": [.circle: "圆形", .square: "正方形", .triangle: "三角形", .star: "星形", .heart: "心形", .rectangle: "矩形", .oval: "椭圆形", .hexagon: "六边形", .trapezoid: "梯形"],
            "ko": [.circle: "원", .square: "정사각형", .triangle: "삼각형", .star: "별", .heart: "하트", .rectangle: "직사각형", .oval: "타원", .hexagon: "육각형", .trapezoid: "사다리꼴"],
            "ru": [.circle: "Круг", .square: "Квадрат", .triangle: "Треугольник", .star: "Звезда", .heart: "Сердце", .rectangle: "Прямоугольник", .oval: "Овал", .hexagon: "Шестиугольник", .trapezoid: "Трапеция"],
        ]
        
        return shapeNames[language]?[shape] ?? shapeNames["en"]?[shape] ?? shape.displayName
    }
}
