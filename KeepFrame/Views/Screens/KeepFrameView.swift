//
//  KeepFrameView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI
import SwiftData

struct KeepFrameView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var viewModel: PhotoDeckViewModel
    @State private var showHistory = false
    @State private var showTrash = false
    @State private var showEndSessionAlert = false
    @State private var isFirstReveal = true
    @State private var buttonTrigger: SwipeAction? = nil
    @State private var showButtons = false
    @State private var stackSpread: CGFloat = 0
    @State private var dragProgress: CGFloat = 0

    var body: some View {
        ZStack {
            Color("turq").opacity(0.7).ignoresSafeArea()

            if viewModel.authorizationDenied {
                deniedView
            } else if let photo = viewModel.currentPhoto {
                deckView(photo: photo)
            } else if viewModel.hasActiveSession && !viewModel.isLoading {
                sessionCompleteView
            } else {
                Color.clear
                    .frame(height: 420)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showHistory = true } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Historia")
                            .font(.subheadline)
                    }
                    .foregroundStyle(.white)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                trashButton
            }
        }
        .sheet(isPresented: $showHistory) {
            NavigationStack { SessionHistoryView() }
        }
        .sheet(isPresented: $showTrash) {
            TrashBinView(viewModel: viewModel)
        }
        .alert("Zakończyć sesję?", isPresented: $showEndSessionAlert) {
            Button("Anuluj", role: .cancel) {}
            if viewModel.trashCount > 0 {
                Button("Zakończ i usuń zdjęcia", role: .destructive) {
                    Task {
                        try? await viewModel.emptyTrash()
                        viewModel.endSession()
                    }
                }
                Button("Zakończ bez usuwania") {
                    viewModel.endSessionWithoutDeleting()
                }
            } else {
                Button("Zakończ") { viewModel.endSession() }
            }
        } message: {
            if viewModel.trashCount > 0 {
                Text("Masz \(viewModel.trashCount) zdjęć w koszyku. Co chcesz z nimi zrobić?")
            } else {
                Text("Sesja zostanie zapisana w historii.")
            }
        }
        .onAppear { viewModel.setup(modelContext: modelContext) }
    }

    // MARK: - Trash Button (custom badge)

    private var trashButton: some View {
        Button { showTrash = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "trash")
                Text("Koszyk")
                    .font(.subheadline)
                if viewModel.trashCount > 0 {
                    Text("\(viewModel.trashCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .frame(minWidth: 22)
                        .background(.red, in: Capsule())
                }
            }
            .foregroundStyle(.white)
            .animation(.easeInOut(duration: 0.2), value: viewModel.trashCount)
        }
    }

    // MARK: - Subviews

    private func deckView(photo: PhotoItem) -> some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                // Stack behind — stable, not destroyed on swipe
                ForEach(Array(viewModel.nextPhotos.prefix(4).enumerated().reversed()), id: \.element.id) { index, item in
                    if item.thumbnail != nil {
                        let depth = CGFloat(index + 1)
                        let visibleCount = viewModel.nextPhotos.prefix(4).filter { $0.thumbnail != nil }.count
                        let isFullStack = visibleCount >= 4
                        let effectiveDepth = max(depth - dragProgress, 0)
                        // Only the deepest card in a full stack slides out from behind
                        let isDeepest = Int(depth) == visibleCount && isFullStack
                        let slideProgress: CGFloat = isDeepest
                            ? min(dragProgress * 1.5, 1)
                            : 1.0
                        let cardDepthForPosition = isDeepest
                            ? effectiveDepth * slideProgress + CGFloat(visibleCount - 1) * (1 - slideProgress)
                            : effectiveDepth
                        let cardOpacity: CGFloat = isDeepest
                            ? slideProgress
                            : 1.0

                        PolaroidCard(image: item.thumbnail)
                            .scaleEffect(1 - cardDepthForPosition * 0.06 * stackSpread)
                            .offset(y: -cardDepthForPosition * 18 * stackSpread)
                            .shadow(color: .black.opacity((0.08 + cardDepthForPosition * 0.04) * stackSpread),
                                    radius: (4 + cardDepthForPosition * 3) * stackSpread,
                                    x: 0, y: (2 + cardDepthForPosition * 2) * stackSpread)
                            .opacity(cardOpacity * stackSpread)
                            .transition(.scale(scale: 0.94).combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.7, bounce: 0.15), value: viewModel.nextPhotos.map(\.id))

                // Top card
                SwipeableCardView(
                    photo: photo,
                    isFirstCard: isFirstReveal,
                    buttonAction: buttonTrigger,
                    dragProgress: $dragProgress,
                    onReady: {
                        withAnimation(.spring(duration: 0.7, bounce: 0.15)) {
                            stackSpread = 1
                        }
                        withAnimation(.spring(duration: 0.5, bounce: 0.3)) {
                            showButtons = true
                        }
                    },
                    onSwipe: { action in
                        buttonTrigger = nil
                        dragProgress = 0
                        viewModel.perform(action)
                        isFirstReveal = false
                    }
                )
                .id(photo.id)
            }
            .frame(height: 420)
            .onAppear {
                if !isFirstReveal {
                    stackSpread = 1
                    showButtons = true
                }
            }

            HStack(spacing: 40) {
                ActionButton(icon: "xmark", color: .red) {
                    isFirstReveal = false
                    buttonTrigger = .delete
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 20)
                .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.0), value: showButtons)

                ActionButton(icon: "star.fill", color: .yellow) {
                    isFirstReveal = false
                    buttonTrigger = .favorite
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 20)
                .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.08), value: showButtons)

                ActionButton(icon: "checkmark", color: .green) {
                    isFirstReveal = false
                    buttonTrigger = .keep
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 20)
                .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.16), value: showButtons)
            }

            VStack(spacing: 8) {
                HStack(spacing: 16) {
                    statLabel(icon: "trash", value: viewModel.activeSession?.deletedCount ?? 0, color: .red)
                    statLabel(icon: "star.fill", value: viewModel.activeSession?.favoritedCount ?? 0, color: .yellow)
                    statLabel(icon: "checkmark", value: viewModel.activeSession?.keptCount ?? 0, color: .green)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .capsule)

                HStack(spacing: 4) {
                    Image(systemName: "photo.stack")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text("\(100000) pozostało")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                }
                .frame(minWidth: 160)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.25), value: showButtons)

            Button { showEndSessionAlert = true } label: {
                Text("Zakończ sesję")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
            }
            .glassEffect(.regular, in: .capsule)
            .opacity(showButtons ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.35), value: showButtons)

            Spacer()
        }
        .padding()
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(Color("turq"))
            Text("Wszystkie zdjęcia przejrzane!")
                .font(.title2.bold())
                .foregroundStyle(.white)
            if viewModel.trashCount > 0 {
                Button { showTrash = true } label: {
                    Label("Przejrzyj koszyk (\(viewModel.trashCount))", systemImage: "trash")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .glassEffect(.regular.interactive())
            }
        }
    }

    private func statLabel(icon: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            Text(compactNumber(value))
                .font(.subheadline.bold())
                .foregroundStyle(.white)
                .frame(minWidth: 28)
        }
    }

    private func compactNumber(_ value: Int) -> String {
        if value >= 100_000 { return "\(value / 1000)k" }
        if value >= 10_000 { return String(format: "%.1fk", Double(value) / 1000) }
        return "\(value)"
    }

    private var deniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Brak dostępu do zdjęć")
                .font(.headline)
                .foregroundStyle(.white)
            Text("Włącz dostęp w Ustawieniach → Prywatność → Zdjęcia")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
