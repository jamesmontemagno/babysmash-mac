//
//  LanguageCharacters.swift
//  babysmash
//
//  Created by Copilot on 1/5/26.
//

import Foundation

/// Defines character sets for different languages, including letters and numbers.
struct LanguageCharacters {
    let languageCode: String
    let displayName: String
    let uppercase: [Character]
    let lowercase: [Character]
    let numbers: [Character]
    
    /// Returns all letters (uppercase + lowercase)
    var allLetters: [Character] {
        uppercase + lowercase
    }
    
    // MARK: - Built-in Language Character Sets
    
    static let english = LanguageCharacters(
        languageCode: "en",
        displayName: "English",
        uppercase: Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ"),
        lowercase: Array("abcdefghijklmnopqrstuvwxyz"),
        numbers: Array("0123456789")
    )
    
    static let spanish = LanguageCharacters(
        languageCode: "es",
        displayName: "Español",
        uppercase: Array("ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"),
        lowercase: Array("abcdefghijklmnñopqrstuvwxyz"),
        numbers: Array("0123456789")
    )
    
    static let german = LanguageCharacters(
        languageCode: "de",
        displayName: "Deutsch",
        uppercase: Array("ABCDEFGHIJKLMNOPQRSTUVWXYZÄÖÜẞ"),
        lowercase: Array("abcdefghijklmnopqrstuvwxyzäöüß"),
        numbers: Array("0123456789")
    )
    
    static let french = LanguageCharacters(
        languageCode: "fr",
        displayName: "Français",
        uppercase: Array("ABCDEFGHIJKLMNOPQRSTUVWXYZÉÈÊËÀÂÙÛÎÏÔÇŒ"),
        lowercase: Array("abcdefghijklmnopqrstuvwxyzéèêëàâùûîïôçœ"),
        numbers: Array("0123456789")
    )
    
    static let italian = LanguageCharacters(
        languageCode: "it",
        displayName: "Italiano",
        uppercase: Array("ABCDEFGHIJKLMNOPQRSTUVWXYZÀÈÉÌÒÙ"),
        lowercase: Array("abcdefghijklmnopqrstuvwxyzàèéìòù"),
        numbers: Array("0123456789")
    )
    
    static let portuguese = LanguageCharacters(
        languageCode: "pt",
        displayName: "Português",
        uppercase: Array("ABCDEFGHIJKLMNOPQRSTUVWXYZÁÀÂÃÉÊÍÓÔÕÚÇ"),
        lowercase: Array("abcdefghijklmnopqrstuvwxyzáàâãéêíóôõúç"),
        numbers: Array("0123456789")
    )
    
    static let japanese = LanguageCharacters(
        languageCode: "ja",
        displayName: "日本語",
        uppercase: Array("あいうえおかきくけこさしすせそたちつてとなにぬねのはひふへほまみむめもやゆよらりるれろわをん"),
        lowercase: Array("アイウエオカキクケコサシスセソタチツテトナニヌネノハヒフヘホマミムメモヤユヨラリルレロワヲン"),
        numbers: Array("〇一二三四五六七八九")
    )
    
    static let chineseSimplified = LanguageCharacters(
        languageCode: "zh-Hans",
        displayName: "简体中文",
        uppercase: Array("一二三四五六七八九十百千万"),
        lowercase: Array("的是不我有大在人了中"),
        numbers: Array("〇一二三四五六七八九")
    )
    
    static let korean = LanguageCharacters(
        languageCode: "ko",
        displayName: "한국어",
        uppercase: Array("ㄱㄴㄷㄹㅁㅂㅅㅇㅈㅊㅋㅌㅍㅎ"),
        lowercase: Array("ㅏㅑㅓㅕㅗㅛㅜㅠㅡㅣ"),
        numbers: Array("0123456789")
    )
    
    static let russian = LanguageCharacters(
        languageCode: "ru",
        displayName: "Русский",
        uppercase: Array("АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ"),
        lowercase: Array("абвгдеёжзийклмнопрстуфхцчшщъыьэюя"),
        numbers: Array("0123456789")
    )
    
    // MARK: - All Language Character Sets
    
    static let all: [LanguageCharacters] = [
        english, spanish, german, french, italian, portuguese, japanese, chineseSimplified, korean, russian
    ]
    
    /// Returns the character set for a given language code, defaulting to English if not found.
    static func forLanguage(_ code: String) -> LanguageCharacters {
        all.first { $0.languageCode == code } ?? english
    }
}
