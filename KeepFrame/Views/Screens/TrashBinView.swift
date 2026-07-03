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
                    VStack(spacing: 28) {
                        Spacer()

                        Image(systemName: "xmark.bin")
                            .font(.system(size: 44, weight: .thin))
                            .foregroundStyle(Color("turqLight"))
                            .padding(24)
                            .background(Color("turq").opacity(0.12), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .strokeBorder(Color("turqLight").opacity(0.25), lineWidth: 1)
                            )
                            .glassEffect(.regular, in: .rect(cornerRadius: 20))

                        VStack(spacing: 8) {
                            Text("trash_empty")
                                .font(.title3.bold())
                                .foregroundStyle(.white)

                            Text("swiped_left_go_here")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }

                        Spacer()
                        Spacer()
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
            .navigationTitle("\(String(localized: "trash_bin")) (\(viewModel.trashCount.compactFormatted))")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if !viewModel.trashBin.isEmpty {
                        Button(selectedItems.count == viewModel.trashCount ? String(localized: "deselect_all") : String(localized: "select_all")) {
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
            .alert(String(localized: "delete_photos_question \(viewModel.trashCount)"), isPresented: $showDeleteAlert) {
                Button("cancel", role: .cancel) {}
                Button("delete_all", role: .destructive) {
                    Task {
                        try? await viewModel.emptyTrash()
                        dismiss()
                    }
                }
            } message: {
                Text("photos_go_to_system_trash")
            }
            .alert(String(localized: "restore_photos_question \(selectedItems.count)"), isPresented: $showRestoreAlert) {
                Button("cancel", role: .cancel) {}
                Button("restore") {
                    let toRestore = viewModel.trashBin.filter { selectedItems.contains($0.id) }
                    viewModel.restoreFromTrash(toRestore)
                    selectedItems.removeAll()
                }
            } message: {
                Text("selected_photos_return_to_review")
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
                    selectedItems.isEmpty ? String(localized: "restore") : String(localized: "restore") + " (\(selectedItems.count))",
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
                Label("delete_all", systemImage: "trash.fill")
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
