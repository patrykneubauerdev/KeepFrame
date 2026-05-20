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

    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView("Ładowanie zdjęć...")
            } else if viewModel.authorizationDenied {
                deniedView
            } else if let photo = viewModel.currentPhoto {
                deckView(photo: photo)
            } else {
                sessionCompleteView
            }
        }
        .navigationTitle("KeepFrame")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button { showHistory = true } label: {
                    Image(systemName: "clock.arrow.circlepath")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                trashButton
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Zakończ sesję") { showEndSessionAlert = true }
                    .foregroundStyle(.red)
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
                    viewModel.clearTrash()
                    viewModel.endSession()
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
                if viewModel.trashCount > 0 {
                    Text("\(viewModel.trashCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red, in: Capsule())
                }
            }
        }
    }

    // MARK: - Subviews

    private func deckView(photo: PhotoItem) -> some View {
        VStack(spacing: 32) {
            Spacer()

            SwipeableCardView(photo: photo, nextPhoto: viewModel.nextPhoto) { action in
                viewModel.perform(action)
            }
            .id(photo.id)
            .frame(height: 420)

            HStack(spacing: 40) {
                ActionButton(icon: "xmark", color: .red) {
                    viewModel.perform(.delete)
                }
                ActionButton(icon: "star.fill", color: .yellow) {
                    viewModel.perform(.favorite)
                }
                ActionButton(icon: "checkmark", color: .green) {
                    viewModel.perform(.keep)
                }
            }

            Text("\(viewModel.remainingCount) zdjęć pozostało")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    private var sessionCompleteView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)
            Text("Wszystkie zdjęcia przejrzane!")
                .font(.title2.bold())
            if viewModel.trashCount > 0 {
                Button { showTrash = true } label: {
                    Label("Przejrzyj koszyk (\(viewModel.trashCount))", systemImage: "trash")
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
        }
    }

    private var deniedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.red)
            Text("Brak dostępu do zdjęć")
                .font(.headline)
            Text("Włącz dostęp w Ustawieniach → Prywatność → Zdjęcia")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}
