//
//  SwipeableCardView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI

struct SwipeableCardView: View {
    let photo: PhotoItem
    var isFirstCard: Bool = false
    var buttonAction: SwipeAction? = nil
    @Binding var dragProgress: CGFloat
    let onReady: () -> Void
    let onSwipe: (SwipeAction) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var cardOpacity: Double = 1
    @State private var slideOffset: CGFloat = 0
    @State private var flipAngle: Double = 0
    @State private var isReady = false
    @State private var didAppear = false
    @State private var showFront = false
    @State private var showImage = false
    @State private var animationStarted = false
    @State private var isDismissing = false

    private let swipeThreshold: CGFloat = 120

    private var dragMagnitude: CGFloat {
        sqrt(offset.width * offset.width + offset.height * offset.height)
    }

    var body: some View {
        ZStack {
            CardBack()
                .opacity(showFront ? 0 : 1)

            PolaroidCard(image: showImage ? photo.thumbnail : nil)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
                .opacity(showFront ? 1 : 0)
        }
        .rotation3DEffect(.degrees(flipAngle), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .offset(x: offset.width, y: offset.height + slideOffset)
        .rotationEffect(.degrees(rotation))
        .opacity(cardOpacity)
        .gesture(
            DragGesture()
                .onChanged { value in
                    guard isReady, !isDismissing else { return }
                    offset = value.translation
                    rotation = Double(value.translation.width / 20)
                    cardOpacity = 1 - min(dragMagnitude / 300, 1) * 0.3
                    dragProgress = min(dragMagnitude / 200, 1)
                }
                .onEnded { value in
                    guard isReady, !isDismissing else { return }
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
        .onAppear {
            guard !didAppear else { return }
            didAppear = true

            if !isFirstCard {
                flipAngle = 180
                showFront = true
                showImage = true
                isReady = true
                animationStarted = true
                return
            }

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
        .onChange(of: buttonAction) { _, action in
            guard let action, isReady, !isDismissing else { return }
            switch action {
            case .delete: dismiss(to: .leading) { onSwipe(.delete) }
            case .keep: dismiss(to: .trailing) { onSwipe(.keep) }
            case .favorite: dismiss(to: .top) { onSwipe(.favorite) }
            }
        }
    }

    private func animateEntrance() {
        guard !animationStarted else { return }
        animationStarted = true
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            slideOffset = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeInOut(duration: 0.5)) {
                flipAngle = 180
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            showFront = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            withAnimation(.easeIn(duration: 0.35)) {
                showImage = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isReady = true
            onReady()
        }
    }

    @ViewBuilder
    private var swipeLabel: some View {
        let progress = min(dragMagnitude / 100, 1)
        if offset.width < -50 {
            Text("USUŃ")
                .font(.title.bold())
                .foregroundStyle(.red)
                .opacity(progress)
                .padding(8)
                .offset(y: -40)
        } else if offset.width > 50 {
            Text("ZACHOWAJ")
                .font(.title.bold())
                .foregroundStyle(.green)
                .opacity(progress)
                .padding(8)
                .offset(y: -40)
        } else if offset.height < -50 {
            Text("ULUBIONE")
                .font(.title.bold())
                .foregroundStyle(.yellow)
                .opacity(progress)
                .padding(8)
                .offset(y: -40)
        }
    }

    private func dismiss(to edge: Edge, completion: @escaping () -> Void) {
        isDismissing = true
        let target: CGSize
        switch edge {
        case .leading: target = CGSize(width: -500, height: 0)
        case .trailing: target = CGSize(width: 500, height: 0)
        case .top: target = CGSize(width: 0, height: -600)
        default: target = .zero
        }
        dragProgress = 1
        withAnimation(.easeOut(duration: 0.35)) {
            offset = target
            cardOpacity = 0
            rotation = edge == .leading ? -15 : edge == .trailing ? 15 : 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { completion() }
    }

    private func reset() {
        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            offset = .zero
            rotation = 0
            cardOpacity = 1
        }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            dragProgress = 0
        }
    }
}
