//
//  TrashBinView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 20/05/2026.
//

import SwiftUI

struct TrashBinView: View {
    @Bindable var viewModel: PhotoDeckViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteAlert = false
    @State private var showRestoreAlert = false

    private var selectedItems: Set<String> {
        get { viewModel.trashSelection ?? [] }
        nonmutating set { viewModel.trashSelection = newValue }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if viewModel.trashBin.isEmpty {
                    ContentUnavailableView(
                        "Koszyk pusty",
                        systemImage: "trash",
                        description: Text("Zdjęcia swipe'owane w lewo trafią tutaj")
                    )
                } else {
                    ScrollView {
                        LazyVGrid(
                            columns: [GridItem(.adaptive(minimum: 110), spacing: 3)],
                            spacing: 3
                        ) {
                            ForEach(viewModel.trashBin) { item in
                                TrashItemCell(
                                    item: item,
                                    isSelected: selectedItems.contains(item.id),
                                    viewModel: viewModel
                                ) {
                                    toggleSelection(item.id)
                                }
                            }
                        }
                        .padding(.horizontal, 3)
                        .padding(.bottom, 100)
                    }
                }

                // Bottom action bar
                if !viewModel.trashBin.isEmpty {
                    bottomBar
                }
            }
            .navigationTitle("Koszyk (\(viewModel.trashCount))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.trashBin.isEmpty {
                        Button(selectedItems.count == viewModel.trashCount ? "Odznacz wszystko" : "Zaznacz wszystko") {
                            if selectedItems.count == viewModel.trashCount {
                                selectedItems.removeAll()
                            } else {
                                selectedItems = Set(viewModel.trashBin.map(\.id))
                            }
                        }
                        .font(.subheadline)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .alert("Usunąć \(viewModel.trashCount) zdjęć?", isPresented: $showDeleteAlert) {
                Button("Anuluj", role: .cancel) {}
                Button("Usuń wszystkie", role: .destructive) {
                    Task {
                        try? await viewModel.emptyTrash()
                        dismiss()
                    }
                }
            } message: {
                Text("Zdjęcia trafią do kosza systemowego na 30 dni.")
            }
            .alert("Przywrócić \(selectedItems.count) zdjęć?", isPresented: $showRestoreAlert) {
                Button("Anuluj", role: .cancel) {}
                Button("Przywróć") {
                    let toRestore = viewModel.trashBin.filter { selectedItems.contains($0.id) }
                    viewModel.restoreFromTrash(toRestore)
                    selectedItems.removeAll()
                }
            } message: {
                Text("Zaznaczone zdjęcia wrócą do puli do przejrzenia.")
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack(spacing: 12) {
            // Restore button
            Button {
                showRestoreAlert = true
            } label: {
                Label(
                    selectedItems.isEmpty ? "Przywróć" : "Przywróć (\(selectedItems.count))",
                    systemImage: "arrow.uturn.backward"
                )
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .disabled(selectedItems.isEmpty)
            .tint(selectedItems.isEmpty ? .gray : Color("turq"))
            .buttonStyle(.borderedProminent)
            .glassEffect(.regular.interactive())

            // Delete all button
            Button {
                showDeleteAlert = true
            } label: {
                Label("Usuń wszystkie", systemImage: "trash.fill")
                    .font(.subheadline.weight(.semibold))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 4)
            }
            .tint(.red)
            .buttonStyle(.bordered)
            .glassEffect(.regular.interactive())
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    private func toggleSelection(_ id: String) {
        if selectedItems.contains(id) {
            selectedItems.remove(id)
        } else {
            selectedItems.insert(id)
        }
    }
}

// MARK: - Trash Item Cell

private struct TrashItemCell: View {
    let item: PhotoItem
    let isSelected: Bool
    let viewModel: PhotoDeckViewModel
    let onTap: () -> Void
    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.clear
                .aspectRatio(1, contentMode: .fit)
                .overlay {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Rectangle().fill(.gray.opacity(0.15))
                            .overlay { ProgressView().tint(Color("turq")) }
                    }
                }
                .clipped()
        }
        .aspectRatio(1, contentMode: .fit)
        .contentShape(Rectangle())
        .overlay(alignment: .topLeading) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color("turq") : .white.opacity(0.8))
                .font(.title3)
                .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                .padding(6)
        }
        .overlay(isSelected ? Color("turq").opacity(0.15) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .onTapGesture { onTap() }
        .task { thumbnail = await viewModel.loadTrashThumbnail(for: item) }
    }
}
