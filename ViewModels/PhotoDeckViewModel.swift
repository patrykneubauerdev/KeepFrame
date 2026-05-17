//
//  PhotoDeckViewModel.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI

@Observable
final class PhotoDeckViewModel {
    private(set) var photos: [PhotoItem] = []
    private(set) var currentIndex: Int = 0

    var currentPhoto: PhotoItem? {
        guard currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }

    var remainingCount: Int {
        max(0, photos.count - currentIndex)
    }

    init() {
        loadSamplePhotos()
    }

    func perform(_ action: SwipeAction) {
        guard currentIndex < photos.count else { return }
        switch action {
        case .delete:
            break // TODO: usunięcie z biblioteki
        case .skip:
            break // przenieś dalej w kolejce
        case .keep:
            break // TODO: oznacz jako zachowane
        }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentIndex += 1
        }
    }

    private func loadSamplePhotos() {
        photos = (1...10).map { i in
            PhotoItem(imageName: "photo_\(i)")
        }
    }
}
