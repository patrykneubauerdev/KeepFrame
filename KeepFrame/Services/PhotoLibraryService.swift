//
//  PhotoLibraryService.swift
//  KeepFrame
//
//  Created by Patryk Neubauer on 20/05/2026.
//

import Photos
import UIKit

final class PhotoLibraryService {
    static let shared = PhotoLibraryService()

    func requestAuthorization() async -> PHAuthorizationStatus {
        await PHPhotoLibrary.requestAuthorization(for: .readWrite)
    }

    func fetchPhotos(year: Int? = nil) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

        if let year {
            let calendar = Calendar.current
            let start = calendar.date(from: DateComponents(year: year, month: 1, day: 1))!
            let end = calendar.date(from: DateComponents(year: year + 1, month: 1, day: 1))!
            options.predicate = NSPredicate(
                format: "mediaType == %d AND creationDate >= %@ AND creationDate < %@",
                PHAssetMediaType.image.rawValue, start as NSDate, end as NSDate
            )
        } else {
            options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        }

        let result = PHAsset.fetchAssets(with: options)
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    func availableYears() -> [Int] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)
        let result = PHAsset.fetchAssets(with: options)

        var years = Set<Int>()
        let calendar = Calendar.current
        result.enumerateObjects { asset, _, _ in
            if let date = asset.creationDate {
                years.insert(calendar.component(.year, from: date))
            }
        }
        return years.sorted().reversed()
    }

    func loadThumbnail(for asset: PHAsset, size: CGSize) async -> UIImage? {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .highQualityFormat
            options.isNetworkAccessAllowed = true
            options.isSynchronous = false
            PHImageManager.default().requestImage(
                for: asset,
                targetSize: size,
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }

    func deleteAssets(_ assets: [PHAsset]) async throws {
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assets as NSFastEnumeration)
        }
    }
}
