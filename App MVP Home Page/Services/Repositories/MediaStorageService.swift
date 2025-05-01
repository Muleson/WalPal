//
//  MediaRepository.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 25/04/2025.
//

import Foundation
import FirebaseStorage
import UIKit
import AVKit

class MediaStorageService {
    private let storage = Storage.storage()
    
    func uploadImage(_ image: UIImage, ownerId: String) async throws -> Media {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "MediaStorageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        let filename = "images/\(ownerId)/\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child(filename)
        
        _ = try await storageRef.putDataAsync(imageData)
        let downloadURL = try await storageRef.downloadURL()
        
        return Media(
            id: UUID().uuidString,
            url: downloadURL,
            type: .image,
            thumbnailURL: nil,
            uploadedAt: Date(),
            ownerId: ownerId
        )
    }
    
    func uploadVideo(_ videoURL: URL, ownerId: String, onProgress: @escaping (Double) -> Void) async throws -> Media {
        let filename = "videos/\(ownerId)/\(UUID().uuidString).mp4"
        let storageRef = storage.reference().child(filename)
        
        // Create upload task
        let uploadTask = storageRef.putFile(from: videoURL)
        
        // Track progress
        uploadTask.observe(.progress) { snapshot in
            let progress = Double(snapshot.progress!.completedUnitCount) / Double(snapshot.progress!.totalUnitCount)
            onProgress(progress)
        }
        
        // Wait for task to complete
        return try await withCheckedThrowingContinuation { continuation in
            uploadTask.observe(.success) { _ in
                Task {
                    do {
                        let downloadURL = try await storageRef.downloadURL()
                        
                        // Generate thumbnail from video
                        let thumbnailURL = try await self.generateThumbnail(from: videoURL, for: filename)
                        
                        let media = Media(
                            id: UUID().uuidString,
                            url: downloadURL,
                            type: .video,
                            thumbnailURL: thumbnailURL,
                            uploadedAt: Date(),
                            ownerId: ownerId
                        )
                        
                        continuation.resume(returning: media)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            uploadTask.observe(.failure) { snapshot in
                if let error = snapshot.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(throwing: NSError(domain: "MediaStorageService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unknown upload error"]))
                }
            }
        }
    }
    
    private func generateThumbnail(from videoURL: URL, for filename: String) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Get the thumbnail at 1 second
        let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 60), actualTime: nil)
        let thumbnail = UIImage(cgImage: cgImage)
        
        // Upload thumbnail to Firebase
        guard let thumbnailData = thumbnail.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "MediaStorageService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Failed to create thumbnail"])
        }
        
        let thumbnailFilename = "thumbnails/\(filename).jpg"
        let thumbnailRef = storage.reference().child(thumbnailFilename)
        
        _ = try await thumbnailRef.putDataAsync(thumbnailData)
        return try await thumbnailRef.downloadURL()
    }
    
    func deleteMedia(_ media: Media) async throws {
        // Delete the main file
        let fileRef = storage.reference(forURL: media.url.absoluteString)
        try await fileRef.delete()
        
        // Delete thumbnail if it exists
        if let thumbnailURL = media.thumbnailURL {
            let thumbnailRef = storage.reference(forURL: thumbnailURL.absoluteString)
            try await thumbnailRef.delete()
        }
    }
}
