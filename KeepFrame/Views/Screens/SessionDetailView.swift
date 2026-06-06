//
//  SessionDetailView.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 05/06/2026.
//

import SwiftUI
import Photos

struct SessionDetailView: View {
    let session: SessionRecord
    @Environment(\.dismiss) private var dismiss
    @State private var thumbnails: [String: UIImage] = [:]
    @State private var showRestoreHint = false
    @State private var showTutorial = false
    @AppStorage("hasSeenRestoreHint") private var hasSeenRestoreHint = false

    private let service = PhotoLibraryService.shared

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    if session.totalReviewed == 0 {
                        VStack(spacing: 12) {
                            Image(systemName: "hand.raised")
                                .font(.system(size: 48))
                                .foregroundStyle(.white.opacity(0.3))
                            Text("Brak aktywności")
                                .font(.headline)
                                .foregroundStyle(.white.opacity(0.6))
                            Text("W tej sesji nie przejrzano żadnych zdjęć")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    }

                    if !session.deletedIdentifiers.isEmpty {
                        deletedSection
                    }

                    if !session.favoriteIdentifiers.isEmpty {
                        photoSection(title: "Dodane do ulubionych", icon: "star.fill", identifiers: session.favoriteIdentifiers)
                    }

                    if !session.keptIdentifiers.isEmpty {
                        photoSection(title: "Zachowane", icon: "checkmark", identifiers: session.keptIdentifiers)
                    }
                }
                .padding()
                .safeAreaPadding(.bottom, 50)
            }
            .mask(
                VStack(spacing: 0) {
                    Color.black
                    LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                }
                .ignoresSafeArea()
            )
            .background(Color("turq").opacity(0.15).ignoresSafeArea())
            .navigationTitle("Sesja \(dateLabel)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
            .alert("Przywracanie zdjęć", isPresented: $showRestoreHint) {
                Button("Rozumiem") { hasSeenRestoreHint = true }
            } message: {
                Text("Przytrzymaj usunięte zdjęcie aby zobaczyć jak je przywrócić.")
            }
            .onAppear {
                if !hasSeenRestoreHint && !session.deletedIdentifiers.isEmpty {
                    showRestoreHint = true
                }
            }
            .sheet(isPresented: $showTutorial) {
                RestoreTutorialView()
                    .presentationDetents([.medium])
                    .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Deleted Section

    private var deletedSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "trash.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text("Usunięte (\(session.deletedIdentifiers.count))")
                    .font(.footnote.bold())
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                Spacer()
                hintLabel
            }
            .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 3)], spacing: 3) {
                ForEach(session.deletedIdentifiers, id: \.self) { id in
                    photoCell(id: id, isDeleted: true)
                }
            }
        }
    }

    private var hintLabel: some View {
        HStack(alignment: .center, spacing: 6) {
            Image(systemName: "hand.tap.fill")
                .font(.body)
                .foregroundStyle(Color("turq"))
                .symbolEffect(.pulse, options: .repeating)
            Text("Przytrzymaj zdjęcie które\nchcesz przywrócić")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color("turq").opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.1), lineWidth: 0.5)
        )
    }

    // MARK: - Photo Section

    private func photoSection(title: String, icon: String, identifiers: [String]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                Text("\(title) (\(identifiers.count))")
                    .font(.footnote.bold())
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
            }
            .padding(.leading, 4)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 3)], spacing: 3) {
                ForEach(identifiers, id: \.self) { id in
                    photoCell(id: id, isDeleted: false)
                }
            }
        }
    }

    private func photoCell(id: String, isDeleted: Bool) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if let img = thumbnails[id] {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .overlay(Color.clear)
                } else {
                    Rectangle().fill(Color("turq").opacity(0.08))
                        .overlay {
                            Image(systemName: isDeleted ? "trash" : "photo")
                                .foregroundStyle(.white.opacity(0.15))
                        }
                }
            }
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.white.opacity(0.15), lineWidth: 0.5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color("turq"), lineWidth: 1.5)
            )
            .glassEffect(isDeleted ? .regular.interactive() : .regular, in: .rect(cornerRadius: 8))
            .onLongPressGesture { if isDeleted { showTutorial = true } }
            .task { loadThumbnail(id: id, isDeleted: isDeleted) }
    }

    // MARK: - Helpers

    private var dateLabel: String {
        let d = session.startDate
        let cal = Calendar.current
        let day = String(format: "%02d", cal.component(.day, from: d))
        let month = String(format: "%02d", cal.component(.month, from: d))
        let year = cal.component(.year, from: d)
        return "\(day).\(month).\(year)"
    }

    private func loadThumbnail(id: String, isDeleted: Bool) {
        guard thumbnails[id] == nil else { return }
        if isDeleted {
            let safe = id.replacingOccurrences(of: "/", with: "_")
            let url = PhotoDeckViewModel.deletedThumbnailsDirectory.appendingPathComponent(safe + ".jpg")
            if let data = try? Data(contentsOf: url), let img = UIImage(data: data) {
                thumbnails[id] = img
            }
        } else {
            Task {
                let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
                guard let asset = result.firstObject else { return }
                let img = await service.loadThumbnail(for: asset, size: CGSize(width: 220, height: 220))
                thumbnails[id] = img
            }
        }
    }
}

// MARK: - Restore Tutorial View

private struct RestoreTutorialView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "arrow.uturn.backward.circle")
                    .font(.system(size: 36))
                    .foregroundStyle(Color("turq"))
                    .symbolEffect(.pulse, options: .repeating)

                VStack(spacing: 4) {
                    Text("Przywracanie usuniętych zdjęć")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("(dostępne do 30 dni od usunięcia)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.4))
                }

                VStack(alignment: .leading, spacing: 14) {
                    stepRow(number: "1", text: "Otwórz aplikację **Zdjęcia**")
                    stepRow(number: "2", text: "Przejdź do zakładki **Inne rzeczy**")
                    stepRow(number: "3", text: "Kliknij **Ostatnio usunięte**")
                    stepRow(number: "4", text: "Zaznacz zdjęcia i kliknij **Odzyskaj**")
                }
                .padding(.horizontal, 24)

                Spacer()

                Button {
                    if let url = URL(string: "photos-redirect://") {
                        UIApplication.shared.open(url)
                    }
                    dismiss()
                } label: {
                    Text("Przejdź do aplikacji **Zdjęcia**")
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color("turq"))
            }
            .padding(24)
            .background(Color("turq").opacity(0.15).ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.footnote.weight(.bold))
                            .foregroundStyle(.white)
                    }
                }
            }
        }
    }

    private func stepRow(number: String, text: LocalizedStringKey) -> some View {
        HStack(spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Color("turq").opacity(0.5), in: Circle())
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
        }
    }
}
