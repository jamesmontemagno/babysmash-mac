//
//  WordFinder.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import Foundation

class WordFinder {
    static let shared = WordFinder()
    
    private var dictionary: Set<String> = []
    private var typedLetters: [Character] = []
    private let maxLetterHistory = 20
    
    private init() {
        loadDictionary()
    }
    
    private func loadDictionary() {
        guard let url = Bundle.main.url(forResource: "Words", withExtension: "txt"),
              let contents = try? String(contentsOf: url, encoding: .utf8) else {
            print("Failed to load dictionary")
            return
        }
        
        dictionary = Set(
            contents
                .components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
                .filter { !$0.isEmpty && $0.count >= 2 }
        )
        
        print("Loaded \(dictionary.count) words")
    }
    
    func addLetter(_ letter: Character) -> String? {
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
