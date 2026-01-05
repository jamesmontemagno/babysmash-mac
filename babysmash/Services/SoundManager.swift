//
//  SoundManager.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import AVFoundation

class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var currentPlayer: AVAudioPlayer?
    
    enum Sound: String, CaseIterable {
        case giggle = "giggle"
        case babylaugh = "babylaugh"
        case babygigl2 = "babygigl2"
        case ccgiggle = "ccgiggle"
        case laughingmice = "laughingmice"
        case scooby2 = "scooby2"
        case smallbumblebee = "smallbumblebee"
        case rising = "rising"
        case falling = "falling"
        case startup = "EditedJackPlaysBabySmash"
        
        static var randomLaughter: Sound {
            let laughterSounds: [Sound] = [.giggle, .babylaugh, .babygigl2, .ccgiggle, .laughingmice, .scooby2]
            return laughterSounds.randomElement()!
        }
    }
    
    private init() {
        preloadSounds()
    }
    
    private func preloadSounds() {
        for sound in Sound.allCases {
            if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    audioPlayers[sound.rawValue] = player
                } catch {
                    print("Failed to load sound: \(sound.rawValue) - \(error)")
                }
            }
        }
    }
    
    func play(_ sound: Sound) {
        guard audioPlayers[sound.rawValue] != nil else { return }
        
        // Create a new player instance for overlapping sounds
        if let url = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav"),
           let newPlayer = try? AVAudioPlayer(contentsOf: url) {
            newPlayer.play()
            currentPlayer = newPlayer
        }
    }
    
    func playRandomLaughter() {
        play(Sound.randomLaughter)
    }
    
    func stopAll() {
        audioPlayers.values.forEach { $0.stop() }
        currentPlayer?.stop()
    }
}
