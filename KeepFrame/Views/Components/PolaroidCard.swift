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
                Color(.turqUltraDark)
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .transition(.opacity)
                }
                // Inner shadow on photo edges (3D inset effect)
                VStack {
                    LinearGradient(colors: [.black.opacity(0.12), .clear], startPoint: .top, endPoint: .bottom).frame(height: 6)
                    Spacer()
                }
                VStack {
                    Spacer()
                    LinearGradient(colors: [.black.opacity(0.12), .clear], startPoint: .bottom, endPoint: .top).frame(height: 6)
                }
                HStack {
                    LinearGradient(colors: [.black.opacity(0.08), .clear], startPoint: .leading, endPoint: .trailing).frame(width: 6)
                    Spacer()
                }
                HStack {
                    Spacer()
                    LinearGradient(colors: [.black.opacity(0.08), .clear], startPoint: .trailing, endPoint: .leading).frame(width: 6)
                }
            }
            .frame(width: 300, height: 300)
            .clipped()
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 0)
            .padding(.top, 20)
            .padding(.horizontal, 20)

            Spacer()
                .frame(height: 60)
        }
        .background(
            LinearGradient(
                colors: [Color(white: 0.98), Color(white: 0.91)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(borderVignette)
        .clipShape(Rectangle())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
    }

    private var borderVignette: some View {
        ZStack {
            VStack {
                Rectangle().fill(LinearGradient(colors: [.black.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)).frame(height: 12)
                Spacer()
            }
            VStack {
                Spacer()
                Rectangle().fill(LinearGradient(colors: [.black.opacity(0.12), .clear], startPoint: .bottom, endPoint: .top)).frame(height: 30)
            }
            HStack {
                Rectangle().fill(LinearGradient(colors: [.black.opacity(0.08), .clear], startPoint: .leading, endPoint: .trailing)).frame(width: 12)
                Spacer()
            }
            HStack {
                Spacer()
                Rectangle().fill(LinearGradient(colors: [.black.opacity(0.08), .clear], startPoint: .trailing, endPoint: .leading)).frame(width: 12)
            }
        }
    }
}
