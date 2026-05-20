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
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(.gray.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
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
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: .black.opacity(0.15), radius: 10, x: 0, y: 4)
    }
}
