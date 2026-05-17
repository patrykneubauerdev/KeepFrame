//
//  PhotoItem.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import Foundation

struct PhotoItem: Identifiable {
    let id: UUID
    let imageName: String
    let date: Date

    init(id: UUID = UUID(), imageName: String, date: Date = .now) {
        self.id = id
        self.imageName = imageName
        self.date = date
    }
}

enum SwipeAction {
    case delete
    case skip
    case keep
}
