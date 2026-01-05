//
//  SpeechService.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import AVFoundation
import SwiftUI

class SpeechService {
    static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    private let localizedService = LocalizedSpeechService.shared
    
    private init() {}
    
    func speak(_ text: String, rate: Float = 0.4) {
        // Stop any current speech
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.2 // Slightly higher pitch for friendliness
        utterance.volume = 1.0
        
        // Use voice for current language setting
        let languageCode = localizedService.primaryLanguage
        if let voice = voiceForLanguage(languageCode) {
            utterance.voice = voice
        } else if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        synthesizer.speak(utterance)
    }
    
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
    
    func speakLetter(_ letter: Character) {
        // Delegate to localized service for multi-language support
        localizedService.speakLetter(letter)
    }
    
    func speakShapeWithColor(shape: ShapeType, color: Color) {
        // Delegate to localized service for multi-language support
        localizedService.speakShape(shape, color: color)
    }
    
    func speakWord(_ word: String) {
        // Delegate to localized service for multi-language support
        localizedService.speakWord(word)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        localizedService.stop()
    }
}
