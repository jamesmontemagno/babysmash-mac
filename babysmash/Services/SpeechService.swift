//
//  SpeechService.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import AVFoundation

class SpeechService {
    static let shared = SpeechService()
    
    private let synthesizer = AVSpeechSynthesizer()
    
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
        
        // Use a child-friendly voice if available
        if let voice = AVSpeechSynthesisVoice(language: "en-US") {
            utterance.voice = voice
        }
        
        synthesizer.speak(utterance)
    }
    
    func speakLetter(_ letter: Character) {
        speak(String(letter))
    }
    
    func speakShapeWithColor(shape: ShapeType, color: Color) {
        let text = "\(color.name) \(shape.displayName)"
        speak(text)
    }
    
    func speakWord(_ word: String) {
        speak(word, rate: 0.35)
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
