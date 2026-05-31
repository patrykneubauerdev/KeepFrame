//
//  PhotoItem.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import Photos
import UIKit

struct PhotoItem: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    var thumbnail: UIImage?

    init(asset: PHAsset) {
        self.id = asset.localIdentifier
        self.asset = asset
    }

    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum SwipeAction {
    case delete, favorite, keep
}

enum PhotoSortOrder: String, CaseIterable {
    case newest = "Najnowsze"
    case oldest = "Najstarsze"
    case random = "Losowe"
}
