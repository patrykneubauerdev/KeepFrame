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
    @State private var buttonCooldown = false

    var body: some View {
        ZStack {
            ZStack {
                Color(.turq)
                RadialGradient(
                    colors: [.clear, Color(.turqDark)],
                    center: .center,
                    startRadius: 100,
                    endRadius: 400
                )
            }
            .ignoresSafeArea()

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

    private func triggerAction(_ action: SwipeAction) {
        guard !buttonCooldown else { return }
        buttonCooldown = true
        isFirstReveal = false
        buttonTrigger = action
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            buttonCooldown = false
        }
    }

    private var trashButton: some View {
        Button { showTrash = true } label: {
            HStack(spacing: 4) {
                Image(systemName: "trash")
                Text("Koszyk")
                    .font(.subheadline)
                if viewModel.trashCount > 0 {
                    Text("\(viewModel.trashCount)")
                        .font(.caption2.bold())
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .frame(minWidth: badgeWidth)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color(.turqLight).opacity(0.8), in: Capsule())
                        .glassEffect(.regular, in: .capsule)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.25), value: trashDigitCount)
                }
            }
            .foregroundStyle(.white)
            .animation(.easeInOut(duration: 0.25), value: viewModel.trashCount > 0)
        }
    }

    private var trashDigitCount: Int { String(viewModel.trashCount).count }
    private var badgeWidth: CGFloat {
        switch trashDigitCount {
        case 1: return 18
        case 2: return 24
        case 3: return 32
        case 4: return 40
        case 5: return 48
        default: return 56
        }
    }

    // MARK: - Subviews

    private func deckView(photo: PhotoItem) -> some View {
        VStack(spacing: 20) {
            Spacer(minLength: 40)

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
                    triggerAction(.delete)
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 20)
                .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.0), value: showButtons)

                ActionButton(icon: "star.fill", color: .yellow) {
                    triggerAction(.favorite)
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 20)
                .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.08), value: showButtons)

                ActionButton(icon: "checkmark", color: .green) {
                    triggerAction(.keep)
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 20)
                .animation(.spring(duration: 0.5, bounce: 0.3).delay(0.16), value: showButtons)
            }

            VStack(spacing: 8) {
                HStack(spacing: 20) {
                    statLabel(icon: "trash.fill", value: viewModel.activeSession?.deletedCount ?? 0, color: .red)
                    statLabel(icon: "star.fill", value: viewModel.activeSession?.favoritedCount ?? 0, color: .yellow)
                    statLabel(icon: "checkmark", value: viewModel.activeSession?.keptCount ?? 0, color: .green)
                }
                .frame(width: 240)
                .padding(.vertical, 12)
                .glassEffect(.regular, in: .capsule)

                HStack(spacing: 6) {
                    Image(systemName: "photo.stack")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.7))
                    Text(verbatim: "\(viewModel.remainingCount) pozostało")
                        .font(.subheadline.bold())
                        .monospacedDigit()
                        .foregroundStyle(.white)
                }
                .frame(width: 200)
                .padding(.vertical, 10)
                .glassEffect(.regular, in: .capsule)
            }
            .opacity(showButtons ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.25), value: showButtons)

            Button {
                showEndSessionAlert = true
            } label: {
                Text("Zakończ sesję")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .tint(.turq)
            .buttonStyle(.borderedProminent)
            .glassEffect(.regular.interactive())
            .padding(.horizontal, 35)
            .opacity(showButtons ? 1 : 0)
            .animation(.easeOut(duration: 0.3).delay(0.25), value: showButtons)

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
                .frame(width: 16)
            Text(compactNumber(value))
                .font(.subheadline.bold())
                .monospacedDigit()
                .foregroundStyle(.white)
                .frame(minWidth: 32)
        }
    }

    private func compactNumber(_ value: Int) -> String {
        if value >= 1_000_000 { return String(format: "%.1fm", Double(value) / 1_000_000) }
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
