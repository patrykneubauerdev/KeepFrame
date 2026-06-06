//
//  SessionRecord.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 20/05/2026.
//

import Foundation
import SwiftData

@Model
final class SessionRecord {
    var startDate: Date
    var endDate: Date?
    var deletedCount: Int
    var keptCount: Int
    var favoritedCount: Int
    var isActive: Bool
    var currentIndex: Int
    var assetIdentifiers: [String]
    var favoriteIdentifiers: [String]
    var deletedIdentifiers: [String] = []
    var keptIdentifiers: [String] = []

    init(startDate: Date = .now) {
        self.startDate = startDate
        self.endDate = nil
        self.deletedCount = 0
        self.keptCount = 0
        self.favoritedCount = 0
        self.isActive = true
        self.currentIndex = 0
        self.assetIdentifiers = []
        self.favoriteIdentifiers = []
        self.deletedIdentifiers = []
        self.keptIdentifiers = []
    }

    var totalReviewed: Int { deletedCount + keptCount + favoritedCount }
}
