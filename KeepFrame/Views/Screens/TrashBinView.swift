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
                    VStack(spacing: 12) {
                        Image(systemName: "trash")
                            .font(.system(size: 48))
                            .foregroundStyle(.white.opacity(0.3))
                        Text("Koszyk pusty")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.6))
                        Text("Zdjęcia swipe'owane w lewo trafią tutaj")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 10) {
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
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .safeAreaPadding(.bottom, 120)
                    }
                    .mask(
                        VStack(spacing: 0) {
                            Color.black
                            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                                .frame(height: 120)
                        }
                        .ignoresSafeArea()
                    )
                }

                // Bottom action bar
                if !viewModel.trashBin.isEmpty {
                    bottomBar
                }
            }
            .background(Color("turq").opacity(0.15).ignoresSafeArea())
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
                        Rectangle().fill(Color("turq").opacity(0.08))
                            .overlay {
                                Image(systemName: "trash")
                                    .foregroundStyle(.white.opacity(0.15))
                            }
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color("turq"), lineWidth: 1.5)
        )
        .glassEffect(.regular, in: .rect(cornerRadius: 8))
        .onTapGesture { onTap() }
        .task { thumbnail = await viewModel.loadTrashThumbnail(for: item) }
    }
}
