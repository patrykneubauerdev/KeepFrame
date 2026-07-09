//
//  Int+CompactFormat.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 02/07/2026.
//

import Foundation

extension Int {
    /// Formats large numbers in a compact way: 1200 → "1.2k", 2500000 → "2.5M"
    var compactFormatted: String {
        switch self {
        case ..<1_000:
            return "\(self)"
        case ..<10_000:
            return String(format: "%.1fk", Double(self) / 1_000)
        case ..<1_000_000:
            return "\(self / 1_000)k"
        default:
            return String(format: "%.1fM", Double(self) / 1_000_000)
        }
    }
}
