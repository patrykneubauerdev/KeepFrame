//
//  PolaroidCard.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI

struct PolaroidCard: View {
    let image: UIImage?

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Color.white
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                }
            }
            .frame(width: 280, height: 340)
            .clipped()
            .padding(.top, 16)
            .padding(.horizontal, 16)

            Spacer()
                .frame(height: 40)
        }
        .background(.white)
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}

struct CardBack: View {
    var body: some View {
        VStack {
            Image("iconKFturq")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        }
        .frame(width: 312, height: 396)
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .overlay(
            RoundedRectangle(cornerSize: .zero)
                .stroke(Color("turq"), lineWidth: 12)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}
