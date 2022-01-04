//
//  EmojiArtApp.swift
//  EmojiArt
//
//  Created by Sankarshana V on 2022/01/03.
//

import SwiftUI

@main
struct EmojiArtApp: App {
    var document = EmojiArtDocument()
    let paletteStore = PaletteStore(named: "Default")
    
    var body: some Scene {
        WindowGroup {
            EmojiArtDocumentView(document: document)
        }
    }
}
