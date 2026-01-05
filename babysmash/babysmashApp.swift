//
//  babysmashApp.swift
//  babysmash
//
//  Created by James Montemagno on 1/4/26.
//

import SwiftUI

@main
struct babysmashApp: App {
    var body: some Scene {
        WindowGroup {
            MainGameView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(replacing: .newItem) { }
            CommandGroup(after: .appSettings) {
                Button("Settings…") {
                    NotificationCenter.default.post(name: .showSettings, object: nil)
                }
                .keyboardShortcut("s", modifiers: .option)
            }
        }
    }
}
