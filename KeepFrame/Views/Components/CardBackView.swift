//
//  CardBackView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 02/07/2026.
//

import SwiftUI

struct CardBackView: View {
    @State private var shimmerOffset: CGFloat = -400

    var body: some View {
        ZStack {
            // White/gray border frame
            LinearGradient(
                colors: [Color(white: 0.98), Color(white: 0.91)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Turq center with vignette
            ZStack {
                Color("turq")
                RadialGradient(
                    colors: [.clear, Color("turqDark").opacity(0.7)],
                    center: .center,
                    startRadius: 30,
                    endRadius: 160
                )
            }
            .frame(width: 300, height: 340)

            // Logo
            Image("iconKF")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)

            // Diagonal shimmer
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [.clear, .white.opacity(0.35), .white.opacity(0.5), .white.opacity(0.35), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 80, height: 600)
                .rotationEffect(.degrees(25))
                .offset(x: shimmerOffset)
        }
        .frame(width: 340, height: 380)
        .overlay(borderVignette)
        .clipShape(Rectangle())
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    shimmerOffset = 400
                }
            }
        }
    }

    private var borderVignette: some View {
        ZStack {
            VStack {
                Rectangle().fill(LinearGradient(colors: [.black.opacity(0.1), .clear], startPoint: .top, endPoint: .bottom)).frame(height: 12)
                Spacer()
            }
            VStack {
                Spacer()
                Rectangle().fill(LinearGradient(colors: [.black.opacity(0.1), .clear], startPoint: .bottom, endPoint: .top)).frame(height: 12)
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
