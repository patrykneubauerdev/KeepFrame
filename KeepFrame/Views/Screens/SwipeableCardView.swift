//
//  SwipeableCardView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI

struct SwipeableCardView: View {
    let photo: PhotoItem
    let onSwipe: (SwipeAction) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0

    private let swipeThreshold: CGFloat = 120

    var body: some View {
        PolaroidCard(photo: photo)
            .offset(offset)
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = value.translation
                        rotation = Double(value.translation.width / 20)
                    }
                    .onEnded { value in
                        let w = value.translation.width
                        let h = value.translation.height

                        if w < -swipeThreshold {
                            dismiss(to: .leading) { onSwipe(.delete) }
                        } else if w > swipeThreshold {
                            dismiss(to: .trailing) { onSwipe(.keep) }
                        } else if h < -swipeThreshold {
                            dismiss(to: .top) { onSwipe(.skip) }
                        } else {
                            reset()
                        }
                    }
            )
            .overlay(alignment: .top) { swipeLabel }
    }

    @ViewBuilder
    private var swipeLabel: some View {
        if offset.width < -50 {
            Text("USUŃ")
                .font(.title.bold())
                .foregroundStyle(.red)
                .padding(8)
                .offset(y: -40)
        } else if offset.width > 50 {
            Text("ZACHOWAJ")
                .font(.title.bold())
                .foregroundStyle(.green)
                .padding(8)
                .offset(y: -40)
        } else if offset.height < -50 {
            Text("POMIŃ")
                .font(.title.bold())
                .foregroundStyle(.yellow)
                .padding(8)
                .offset(y: -40)
        }
    }

    private func dismiss(to edge: Edge, completion: @escaping () -> Void) {
        let target: CGSize
        switch edge {
        case .leading: target = CGSize(width: -500, height: 0)
        case .trailing: target = CGSize(width: 500, height: 0)
        case .top: target = CGSize(width: 0, height: -600)
        default: target = .zero
        }
        withAnimation(.easeOut(duration: 0.3)) {
            offset = target
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            completion()
        }
    }

    private func reset() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            offset = .zero
            rotation = 0
        }
    }
}
