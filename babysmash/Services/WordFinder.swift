//
//  WordFinder.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import Foundation
import SwiftUI

class WordFinder {
    static let shared = WordFinder()
    
    private var dictionary: Set<String> = []
    private var typedLetters: [Character] = []
    private let maxLetterHistory = 20
    
    @AppStorage("speechLanguage") private var speechLanguage: String = "en"
    private var loadedLanguage: String = ""
    
    private init() {
        loadDictionary()
    }
    
    private func loadDictionary() {
        // Try to load language-specific word list first
        let resourceName = speechLanguage == "en" ? "Words" : "Words_\(speechLanguage)"
        
        if let url = Bundle.main.url(forResource: resourceName, withExtension: "txt"),
           let contents = try? String(contentsOf: url, encoding: .utf8) {
            dictionary = Set(
                contents
                    .components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                    .filter { !$0.isEmpty && $0.count >= 2 }
            )
            loadedLanguage = speechLanguage
            print("Loaded \(dictionary.count) words for language: \(speechLanguage)")
        } else {
            // Fall back to English word list
            if let url = Bundle.main.url(forResource: "Words", withExtension: "txt"),
               let contents = try? String(contentsOf: url, encoding: .utf8) {
                dictionary = Set(
                    contents
                        .components(separatedBy: .newlines)
                        .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                        .filter { !$0.isEmpty && $0.count >= 2 }
                )
                loadedLanguage = "en"
                print("Loaded \(dictionary.count) English words (fallback)")
            } else {
                print("Failed to load dictionary")
            }
        }
    }
    
    /// Reloads the dictionary if the language has changed.
    private func ensureDictionaryLoaded() {
        if loadedLanguage != speechLanguage {
            loadDictionary()
        }
    }
    
    func addLetter(_ letter: Character) -> String? {
        ensureDictionaryLoaded()
        
        if let lowercased = letter.lowercased().first {
            typedLetters.append(lowercased)
        }
        
        // Keep history limited
        if typedLetters.count > maxLetterHistory {
            typedLetters.removeFirst()
        }
        
        // Check for words (minimum 2 letters)
        return findWord()
    }
    
    private func findWord() -> String? {
        // Check suffixes of typed letters for valid words
        for startIndex in 0..<typedLetters.count {
            let suffix = String(typedLetters[startIndex...])
            if suffix.count >= 2 && dictionary.contains(suffix) {
                // Clear the matched portion
                typedLetters.removeAll()
                return suffix.capitalized
            }
        }
        return nil
    }
    
    func reset() {
        typedLetters.removeAll()
    }
}
