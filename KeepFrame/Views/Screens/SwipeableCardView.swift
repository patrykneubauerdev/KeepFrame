//
//  SwipeableCardView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI

struct SwipeableCardView: View {
    let photo: PhotoItem
    let nextPhoto: PhotoItem?
    var isFirstCard: Bool = false
    let onSwipe: (SwipeAction) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var slideOffset: CGFloat = 0
    @State private var flipAngle: Double = 0
    @State private var isReady = false
    @State private var didAppear = false
    @State private var showNextCard = false
    @State private var showFront = false
    @State private var showImage = false
    @State private var animationStarted = false

    private let swipeThreshold: CGFloat = 120

    private var dragProgress: CGFloat {
        let maxDrag: CGFloat = 200
        let total = abs(offset.width) + abs(offset.height)
        return min(total / maxDrag, 1.0)
    }


    var body: some View {
        ZStack {
            // Next card (behind)
            if showNextCard, let nextPhoto {
                if nextPhoto.thumbnail != nil {
                    PolaroidCard(image: nextPhoto.thumbnail)
                        .scaleEffect(0.92 + 0.08 * dragProgress)
                        .offset(y: 12 - 12 * dragProgress)
                        .opacity(0.7 + 0.3 * dragProgress)
                } else {
                    CardBack()
                        .scaleEffect(0.92 + 0.08 * dragProgress)
                        .offset(y: 12 - 12 * dragProgress)
                        .opacity(0.7 + 0.3 * dragProgress)
                }
            }

            // Current card with slide + flip
            ZStack {
                // Phase 1: Card back (visible until 90°)
                CardBack()
                    .opacity(showFront ? 0 : 1)

                // Phase 2: Empty frame appears at 90°, then image fades in
                PolaroidCard(image: showImage ? photo.thumbnail : nil)
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                    .opacity(showFront ? 1 : 0)
            }
            .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
            .offset(x: offset.width, y: offset.height + slideOffset)
            .rotationEffect(.degrees(rotation))
            .gesture(
                DragGesture()
                    .onChanged { value in
                        guard isReady else { return }
                        offset = value.translation
                        rotation = Double(value.translation.width / 20)
                    }
                    .onEnded { value in
                        guard isReady else { return }
                        let w = value.translation.width
                        let h = value.translation.height

                        if w < -swipeThreshold {
                            dismiss(to: .leading) { onSwipe(.delete) }
                        } else if w > swipeThreshold {
                            dismiss(to: .trailing) { onSwipe(.keep) }
                        } else if h < -swipeThreshold {
                            dismiss(to: .top) { onSwipe(.favorite) }
                        } else {
                            reset()
                        }
                    }
            )
            .overlay(alignment: .top) { swipeLabel }
        }
        .onAppear {
            guard !didAppear else { return }
            didAppear = true

            if !isFirstCard {
                flipAngle = 180
                showFront = true
                showImage = true
                isReady = true
                showNextCard = true
                animationStarted = true
                return
            }

            // First card: start off-screen
            slideOffset = 800
            if photo.thumbnail != nil {
                animateEntrance()
            }
        }
        .onChange(of: photo.thumbnail) { _, newValue in
            if newValue != nil && !animationStarted && isFirstCard {
                animateEntrance()
            }
        }
    }

    private func animateEntrance() {
        guard !animationStarted else { return }
        animationStarted = true
        // Step 1: slide up with bounce
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            slideOffset = 0
        }
        // Step 2: flip
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.5)) {
                flipAngle = 180
            }
        }
        // Step 3: at ~90° — hide back, show empty frame
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            showFront = true
        }
        // Step 4: after flip done — fade in the photo
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeIn(duration: 0.35)) {
                showImage = true
            }
        }
        // Step 5: enable interaction
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            showNextCard = true
            isReady = true
        }
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
            Text("ULUBIONE")
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
        withAnimation(.easeOut(duration: 0.3)) { offset = target }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { completion() }
    }

    private func reset() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            offset = .zero
            rotation = 0
        }
    }
}
