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
    @State private var selectedItems: Set<String> = []
    @State private var showDeleteAlert = false
    @State private var showRestoreAlert = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.trashBin.isEmpty {
                    ContentUnavailableView(
                        "Koszyk pusty",
                        systemImage: "trash",
                        description: Text("Zdjęcia swipe'owane w lewo trafią tutaj")
                    )
                } else {
                    VStack(spacing: 0) {
                        if !selectedItems.isEmpty {
                            selectionBar
                        }
                        trashGrid
                        deleteAllButton
                    }
                }
            }
            .navigationTitle("Koszyk (\(viewModel.trashCount))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.trashBin.isEmpty {
                        Button(selectedItems.count == viewModel.trashCount ? "Odznacz" : "Zaznacz wszystkie") {
                            if selectedItems.count == viewModel.trashCount {
                                selectedItems.removeAll()
                            } else {
                                selectedItems = Set(viewModel.trashBin.map(\.id))
                            }
                        }
                        .font(.caption)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Gotowe") { dismiss() }
                }
            }
            .alert("Przywrócić zdjęcia?", isPresented: $showRestoreAlert) {
                Button("Anuluj", role: .cancel) {}
                Button("Przywróć") {
                    let toRestore = viewModel.trashBin.filter { selectedItems.contains($0.id) }
                    viewModel.restoreFromTrash(toRestore)
                    selectedItems.removeAll()
                }
            } message: {
                Text("Zaznaczone zdjęcia wrócą do puli do przejrzenia.")
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
        }
    }

    // MARK: - Selection Bar

    private var selectionBar: some View {
        HStack {
            Text("\(selectedItems.count) zaznaczonych")
                .font(.subheadline.bold())
            Spacer()
            Button {
                showRestoreAlert = true
            } label: {
                Label("Przywróć", systemImage: "arrow.uturn.backward")
                    .font(.subheadline.bold())
            }
            .tint(.green)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }

    // MARK: - Grid

    private var trashGrid: some View {
        ScrollView {
            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 100), spacing: 2)],
                spacing: 2
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
        }
    }

    // MARK: - Delete Button

    private var deleteAllButton: some View {
        Button {
            showDeleteAlert = true
        } label: {
            Label("Usuń wszystkie (\(viewModel.trashCount))", systemImage: "trash.fill")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.red)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding()
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
            Group {
                if let thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle().fill(.gray.opacity(0.2))
                        .overlay { ProgressView() }
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100, maxHeight: 100)
            .clipped()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.white, .blue)
                    .font(.title3)
                    .padding(6)
            } else {
                Image(systemName: "circle")
                    .foregroundStyle(.white.opacity(0.7))
                    .font(.title3)
                    .padding(6)
            }
        }
        .overlay(isSelected ? Color.blue.opacity(0.2) : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .onTapGesture { onTap() }
        .task { thumbnail = await viewModel.loadTrashThumbnail(for: item) }
    }
}
