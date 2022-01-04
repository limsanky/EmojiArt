//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Sankarshana V on 2022/01/03.
//

import SwiftUI

class EmojiArtDocument: ObservableObject {
    typealias Model = EmojiArtModel
    
    @Published private(set) var emojiArt: Model {
        didSet {
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    init() {
        emojiArt = EmojiArtModel()
        emojiArt.addEmoji("😷", at: (-200, -100), size: 80)
        emojiArt.addEmoji("😀", at: (50, 100), size: 40)
    }
    
    var emojis: [Model.Emoji] { emojiArt.emojis }
    var background: Model.Background { emojiArt.background }
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus {
        case idle
        case fetching
    }
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        
        switch emojiArt.background {
        case .url(let url):
            // fetch image from the url
            backgroundImageFetchStatus = .fetching
            
            DispatchQueue.global(qos: .userInitiated).async {
                if let imageData = try? Data(contentsOf: url) {
                    DispatchQueue.main.async { [weak self] in
                        if self?.emojiArt.background == Model.Background.url(url) {
                            self?.backgroundImageFetchStatus = .idle
                            self?.backgroundImage = UIImage(data: imageData)
                        }
                    }
                }
            }
        case .imageData(let data):
            backgroundImage = UIImage(data: data)
        case .blank:
            break
        }
    }
    
    // MARK: - Intents
    
    func setBackground(_ background: Model.Background) {
        emojiArt.background = background
        print("background: \(background)")
    }
    
    func addEmoji(_ emoji: String, at location: (x: Int, y: Int), size: CGFloat) {
        emojiArt.addEmoji(emoji, at: location, size: Int(size))
    }
    
    func moveEmoji(_ emoji: Model.Emoji, by offset: CGSize) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            emojiArt.emojis[index].x += Int(offset.width)
            emojiArt.emojis[index].y += Int(offset.height)
        }
    }
    
    func scaleEmoji(_ emoji: Model.Emoji, by scale: CGFloat) {
        if let index = emojiArt.emojis.index(matching: emoji) {
            let scaledSize = (CGFloat(emojiArt.emojis[index].size) * scale).rounded(.toNearestOrAwayFromZero)
            emojiArt.emojis[index].size = Int(scaledSize)
        }
    }
}
