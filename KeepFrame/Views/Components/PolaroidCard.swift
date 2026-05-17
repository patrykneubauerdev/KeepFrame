//
//  PolaroidCard.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI

struct PolaroidCard: View {
    let photo: PhotoItem

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "photo.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 280, height: 340)
                .clipped()
                .padding(.top, 16)
                .padding(.horizontal, 16)

            Text(photo.date, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.vertical, 20)
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}
