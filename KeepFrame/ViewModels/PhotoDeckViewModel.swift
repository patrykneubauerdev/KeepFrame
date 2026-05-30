//
//  PhotoDeckViewModel.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 13/05/2026.
//

import SwiftUI
import SwiftData
import Photos

@Observable
final class PhotoDeckViewModel {
    private(set) var photos: [PhotoItem] = []
    private(set) var currentIndex: Int = 0
    private(set) var isLoading = false
    private(set) var authorizationDenied = false
    private(set) var trashBin: [PhotoItem] = []
    private(set) var hasActiveSession = false

    var activeSession: SessionRecord?
    var selectedYear: Int?
    var sortOrder: PhotoSortOrder = .newest

    private let service = PhotoLibraryService.shared
    private var modelContext: ModelContext?

    var currentPhoto: PhotoItem? {
        guard currentIndex < photos.count else { return nil }
        return photos[currentIndex]
    }

    var nextPhoto: PhotoItem? {
        guard currentIndex + 1 < photos.count else { return nil }
        return photos[currentIndex + 1]
    }

    var remainingCount: Int { max(0, photos.count - currentIndex) }
    var trashCount: Int { trashBin.count }

    func setup(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        Task { await loadSession() }
    }

    // MARK: - Session

    func startNewSession() async {
        await requestAccessAndLoad()
        guard let ctx = modelContext else { return }
        let session = SessionRecord()
        session.assetIdentifiers = photos.map(\.id)
        ctx.insert(session)
        try? ctx.save()
        activeSession = session
        hasActiveSession = true
        currentIndex = 0
        trashBin = []
    }

    func resumeSession() async {
        guard let session = activeSession else { return }
        await requestAccessAndLoad()
        
        // Rebuild photos in original session order
        let photoMap = Dictionary(uniqueKeysWithValues: photos.map { ($0.id, $0) })
        photos = session.assetIdentifiers.compactMap { photoMap[$0] }

        // Restore trash bin
        let deletedIds = Set(session.deletedIdentifiers)
        trashBin = photos.filter { deletedIds.contains($0.id) }

        currentIndex = min(session.currentIndex, photos.count)
        hasActiveSession = true

        for i in currentIndex..<min(currentIndex + 3, photos.count) {
            await loadThumbnail(for: i)
        }
    }

    func endSession() {
        guard let session = activeSession, let ctx = modelContext else { return }
        session.isActive = false
        session.endDate = .now
        try? ctx.save()
        activeSession = nil
        hasActiveSession = false
        photos = []
        currentIndex = 0
        trashBin = []
    }

    func endSessionWithoutDeleting() {
        guard let session = activeSession, let ctx = modelContext else { return }
        session.isActive = false
        session.endDate = .now
        // Only subtract photos still in trash (not yet deleted)
        session.deletedCount -= trashBin.count
        session.deletedIdentifiers = []
        try? ctx.save()
        activeSession = nil
        hasActiveSession = false
        photos = []
        currentIndex = 0
        trashBin = []
    }

    // MARK: - Actions

    func perform(_ action: SwipeAction) {
        guard currentIndex < photos.count else { return }
        let photo = photos[currentIndex]

        switch action {
        case .delete:
            trashBin.append(photo)
            activeSession?.deletedCount += 1
            activeSession?.deletedIdentifiers.append(photo.id)
        case .favorite:
            activeSession?.favoritedCount += 1
            activeSession?.favoriteIdentifiers.append(photo.id)
        case .keep:
            activeSession?.keptCount += 1
        }

        currentIndex += 1
        activeSession?.currentIndex = currentIndex
        try? modelContext?.save()

        // Preload next 2
        Task {
            await loadThumbnail(for: currentIndex)
            await loadThumbnail(for: currentIndex + 1)
        }
    }

    // MARK: - Trash Bin

    func restoreFromTrash(_ photos: [PhotoItem]) {
        let ids = Set(photos.map(\.id))
        trashBin.removeAll { ids.contains($0.id) }
        activeSession?.deletedIdentifiers.removeAll { ids.contains($0) }
        activeSession?.deletedCount -= photos.count
        try? modelContext?.save()
    }

    func emptyTrash() async throws {
        let assets = trashBin.map(\.asset)
        try await service.deleteAssets(assets)
        activeSession?.deletedIdentifiers.removeAll { id in
            trashBin.contains { $0.id == id }
        }
        try? modelContext?.save()
        trashBin = []
    }

    func clearTrash() {
        trashBin = []
    }

    // MARK: - Favorites

    func fetchFavoritePhotos() -> [PHAsset] {
        guard let ctx = modelContext else { return [] }
        let descriptor = FetchDescriptor<SessionRecord>()
        guard let sessions = try? ctx.fetch(descriptor) else { return [] }

        let allFavIds = Set(sessions.flatMap(\.favoriteIdentifiers))
        guard !allFavIds.isEmpty else { return [] }

        let result = PHAsset.fetchAssets(withLocalIdentifiers: Array(allFavIds), options: nil)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in assets.append(asset) }
        return assets
    }

    func startFavoritesSession() async {
        isLoading = true
        defer { isLoading = false }

        let status = await service.requestAuthorization()
        guard status == .authorized || status == .limited else {
            authorizationDenied = true
            return
        }

        let assets = fetchFavoritePhotos()
        photos = assets.map { PhotoItem(asset: $0) }

        guard let ctx = modelContext else { return }
        let session = SessionRecord()
        session.assetIdentifiers = photos.map(\.id)
        ctx.insert(session)
        try? ctx.save()
        activeSession = session
        hasActiveSession = true
        currentIndex = 0
        trashBin = []

        for i in 0..<min(3, photos.count) {
            await loadThumbnail(for: i)
        }
    }

    // MARK: - Thumbnails

    func loadThumbnail(for index: Int) async {
        guard index < photos.count, photos[index].thumbnail == nil else { return }
        let asset = photos[index].asset
        let image = await service.loadThumbnail(for: asset, size: CGSize(width: 600, height: 600))
        if index < photos.count {
            photos[index].thumbnail = image
        }
    }

    func loadTrashThumbnail(for item: PhotoItem) async -> UIImage? {
        await service.loadThumbnail(for: item.asset, size: CGSize(width: 200, height: 200))
    }

    // MARK: - Private

    private func requestAccessAndLoad() async {
        isLoading = true
        defer { isLoading = false }

        let status = await service.requestAuthorization()
        guard status == .authorized || status == .limited else {
            authorizationDenied = true
            return
        }

        let assets = service.fetchPhotos(year: selectedYear)
        photos = assets.map { PhotoItem(asset: $0) }

        switch sortOrder {
        case .newest: break
        case .oldest: photos.reverse()
        case .random: photos.shuffle()
        }

        // Preload first 3 thumbnails
        for i in 0..<min(3, photos.count) {
            await loadThumbnail(for: i)
        }
    }

    private func loadSession() async {
        guard let ctx = modelContext else { return }
        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        if let existing = try? ctx.fetch(descriptor).first {
            activeSession = existing
            await resumeSession()
        }
    }
}
