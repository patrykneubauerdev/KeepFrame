//
//  ActionButton.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI

struct ActionButton: View {
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 56, height: 56)
                .background(color.opacity(0.15))
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(color.opacity(0.4), lineWidth: 1.5)
                )
                .glassEffect(.regular.interactive(), in: .circle)
        }
    }
}
