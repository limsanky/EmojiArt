//
//  EmojiArtDocument.swift
//  EmojiArt
//
//  Created by Sankarshana V on 2022/01/03.
//

import SwiftUI
import Combine

class EmojiArtDocument: ObservableObject {
    typealias Model = EmojiArtModel
    
    @Published private(set) var emojiArt: Model {
        didSet {
            scheduleAutosave()
            if emojiArt.background != oldValue.background {
                fetchBackgroundImageDataIfNecessary()
            }
        }
    }
    
    private var autosaveTimer: Timer?
    
    private func scheduleAutosave() {
        autosaveTimer?.invalidate()
        
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: Autosave.coalescingInterval, repeats: false) { _ in
            self.autosave()
        }
    }
    
    private struct Autosave {
        static let filename = "Autosaved.emojiart"
        static var url: URL? {
            let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            return documentDirectory?.appendingPathComponent(filename)
        }
        static let coalescingInterval = 5.0
    }
    
    private func autosave() {
        if let url = Autosave.url {
            save(to: url)
        }
    }
    // For saving file to the filesystem
    private func save(to url: URL) {
        let thisfunction = "\(String(describing: self)).\(#function)"
        
        do {
            let data : Data = try emojiArt.json()
            print("The JSON file: \(String(data: data, encoding: .utf8) ?? "nil")")
            try data.write(to: url)
            
            print("The data was stored well!")
        } catch let encodingError where encodingError is EncodingError {
            print("There was an encoding error: \(encodingError.localizedDescription).")
        }
        catch {
            print("\(thisfunction) error = \(error)")
        }
        
    }
    
    init() {
        if let url = Autosave.url, let autosavedEmojiArt = try? EmojiArtModel(url: url) {
            emojiArt = autosavedEmojiArt
            fetchBackgroundImageDataIfNecessary()
        } else {
            emojiArt = EmojiArtModel()
        }
       
//        emojiArt.addEmoji("😷", at: (-200, -100), size: 80)
//        emojiArt.addEmoji("😀", at: (50, 100), size: 40)
    }
    
    var emojis: [Model.Emoji] { emojiArt.emojis }
    var background: Model.Background { emojiArt.background }
    
    @Published var backgroundImage: UIImage?
    @Published var backgroundImageFetchStatus = BackgroundImageFetchStatus.idle
    
    enum BackgroundImageFetchStatus: Equatable {
        case idle
        case fetching
        case failed(URL)
    }
    
    private var backgroundImageFetchCancellable: AnyCancellable?
    
    private func fetchBackgroundImageDataIfNecessary() {
        backgroundImage = nil
        
        switch emojiArt.background {
        case .url(let url):
            // fetch image from the url
            backgroundImageFetchStatus = .fetching
            
            // To make sure that the previous image fetch request is cancelled (if there WAS a request)
            backgroundImageFetchCancellable?.cancel()
            
            let session = URLSession.shared
            let publisher = session.dataTaskPublisher(for: url)
                .map { (data, urlResponse) in UIImage(data: data) }
                .replaceError(with: nil)
                .receive(on: DispatchQueue.main)
            
            backgroundImageFetchCancellable = publisher
                .sink { [weak self] image in
                    self?.backgroundImage = image
                    self?.backgroundImageFetchStatus = image != nil ? .idle : .failed(url)
                }
            //                .assign(to: \EmojiArtDocument.backgroundImage, on: self)
            
            
//            DispatchQueue.global(qos: .userInitiated).async {
//                let imageData = try? Data(contentsOf: url)
//
//                DispatchQueue.main.async { [weak self] in
//                    if self?.emojiArt.background == Model.Background.url(url) {
//                        self?.backgroundImageFetchStatus = .idle
//
//                        if imageData != nil {
//                            self?.backgroundImage = UIImage(data: imageData!)
//                        }
//                        if self?.backgroundImage == nil {
//                            self?.backgroundImageFetchStatus = .failed(url)
//                        }
//                    }
//                }
//            }
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
