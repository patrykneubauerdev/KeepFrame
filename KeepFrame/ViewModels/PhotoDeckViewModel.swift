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
    private(set) var isSessionChecked = false
    private(set) var authorizationDenied = false
    private(set) var trashBin: [PhotoItem] = []
    var trashSelection: Set<String>?
    private(set) var hasActiveSession = false
    private(set) var isFavoritesSession = false

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

    var nextPhotos: [PhotoItem] {
        let start = currentIndex + 1
        let end = min(start + 4, photos.count)
        guard start < end else { return [] }
        return Array(photos[start..<end])
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
        // Deactivate any lingering active sessions
        let descriptor = FetchDescriptor<SessionRecord>(predicate: #Predicate { $0.isActive })
        if let stale = try? ctx.fetch(descriptor) {
            for s in stale {
                s.isActive = false
                s.endDate = s.endDate ?? .now
            }
        }
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
        isFavoritesSession = session.isFavoritesSession

        for i in currentIndex..<min(currentIndex + 6, photos.count) {
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
        isFavoritesSession = false
        photos = []
        currentIndex = 0
        trashBin = []
    }

    func endSessionWithoutDeleting() {
        guard let session = activeSession, let ctx = modelContext else { return }
        session.isActive = false
        session.endDate = .now
        session.deletedCount -= trashBin.count
        // Remove only the ones that weren't actually deleted from library
        let trashIds = Set(trashBin.map(\.id))
        session.deletedIdentifiers.removeAll { trashIds.contains($0) }
        try? ctx.save()
        activeSession = nil
        hasActiveSession = false
        isFavoritesSession = false
        photos = []
        currentIndex = 0
        trashBin = []
    }

    // MARK: - Actions

    func perform(_ action: SwipeAction) {
        guard currentIndex < photos.count else { return }
        trashSelection = nil
        let photo = photos[currentIndex]

        switch action {
        case .delete:
            trashBin.append(photo)
            activeSession?.deletedCount += 1
            activeSession?.deletedIdentifiers.append(photo.id)
            Task { await saveSessionThumbnail(for: photo) }
        case .favorite:
            activeSession?.favoritedCount += 1
            activeSession?.favoriteIdentifiers.append(photo.id)
            Task {
                try? await service.favoriteAsset(photo.asset)
                await saveSessionThumbnail(for: photo)
            }
        case .keep:
            activeSession?.keptCount += 1
            activeSession?.keptIdentifiers.append(photo.id)
            Task { await saveSessionThumbnail(for: photo) }
        }

        currentIndex += 1
        activeSession?.currentIndex = currentIndex
        try? modelContext?.save()

        // Preload next thumbnails for stack
        Task {
            for i in currentIndex..<min(currentIndex + 6, photos.count) {
                await loadThumbnail(for: i)
            }
        }
    }

    // MARK: - Trash Bin

    func restoreFromTrash(_ photos: [PhotoItem]) {
        let ids = Set(photos.map(\.id))
        trashBin.removeAll { ids.contains($0.id) }
        activeSession?.deletedIdentifiers.removeAll { ids.contains($0) }
        activeSession?.deletedCount -= photos.count

        // Insert back into deck at current position so user can review again
        let restoredPhotos = photos.filter { !self.photos[currentIndex...].contains($0) }
        for (i, photo) in restoredPhotos.enumerated() {
            self.photos.insert(photo, at: currentIndex + i)
        }
        activeSession?.currentIndex = currentIndex

        try? modelContext?.save()

        // Preload thumbnails for restored photos
        Task {
            for i in currentIndex..<min(currentIndex + 6, self.photos.count) {
                await loadThumbnail(for: i)
            }
        }
    }

    func emptyTrash() async throws {
        let assets = trashBin.map(\.asset)
        try await service.deleteAssets(assets)
        try? modelContext?.save()
        trashBin = []
    }

    func clearTrash() {
        trashBin = []
    }

    // MARK: - Favorites

    func fetchFavoritePhotos() -> [PHAsset] {
        service.fetchSystemFavorites()
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
        // Deactivate any lingering active sessions
        let descriptor = FetchDescriptor<SessionRecord>(predicate: #Predicate { $0.isActive })
        if let stale = try? ctx.fetch(descriptor) {
            for s in stale {
                s.isActive = false
                s.endDate = s.endDate ?? .now
            }
        }
        let session = SessionRecord(isFavoritesSession: true)
        session.assetIdentifiers = photos.map(\.id)
        ctx.insert(session)
        try? ctx.save()
        activeSession = session
        hasActiveSession = true
        isFavoritesSession = true
        currentIndex = 0
        trashBin = []

        for i in 0..<min(6, photos.count) {
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

    private func saveSessionThumbnail(for photo: PhotoItem) async {
        let image: UIImage?
        if let existing = photo.thumbnail {
            image = existing
        } else {
            image = await service.loadThumbnail(for: photo.asset, size: CGSize(width: 200, height: 200))
        }
        guard let image, let data = image.jpegData(compressionQuality: 0.5) else { return }
        let dir = Self.sessionThumbnailsDirectory
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let safe = photo.id.replacingOccurrences(of: "/", with: "_")
        let url = dir.appendingPathComponent(safe + ".jpg")
        try? data.write(to: url)
    }

    static var sessionThumbnailsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SessionThumbnails", isDirectory: true)
    }

    /// Legacy path kept for backward compatibility
    static var deletedThumbnailsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("DeletedThumbnails", isDirectory: true)
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
        for i in 0..<min(6, photos.count) {
            await loadThumbnail(for: i)
        }
    }

    private func loadSession() async {
        guard let ctx = modelContext else {
            isSessionChecked = true
            return
        }
        let descriptor = FetchDescriptor<SessionRecord>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.startDate, order: .reverse)]
        )
        guard let activeSessions = try? ctx.fetch(descriptor), let newest = activeSessions.first else {
            isSessionChecked = true
            return
        }
        // Deactivate duplicates, keep only the newest
        for s in activeSessions.dropFirst() {
            s.isActive = false
            s.endDate = s.endDate ?? .now
        }
        try? ctx.save()
        activeSession = newest
        await resumeSession()
        isSessionChecked = true
    }
}
