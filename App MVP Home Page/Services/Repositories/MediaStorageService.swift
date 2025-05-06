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

// MARK: - Storage References and Constants

class MediaStorageService {
    private let storage = Storage.storage()
    private let bucketURL: String
    
    // Storage paths for better organization
    private enum StoragePath {
        static let images = "images"
        static let videos = "videos"
        static let thumbnails = "thumbnails"
        static let gymImages = "gym_images"
        static let userProfiles = "user_profiles"
        static let betaMedia = "beta_media"
        static let eventMedia = "event_media"
    }
    
    
    init() {
        self.bucketURL = Storage.storage().reference().bucket
     }
    
    // MARK: - Public Upload Methods
    
    // Enhanced method with path parameter for better organization
    func uploadImage(_ image: UIImage, ownerId: String, path: String = StoragePath.images) async throws -> Media {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "MediaStorageService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to data"])
        }
        
        // Resize image if it's too large
        let resizedImage = resizeImageIfNeeded(image, maxDimension: 1200)
        let optimizedData = resizedImage.jpegData(compressionQuality: 0.7) ?? imageData
        
        let filename = "\(path)/\(ownerId)/\(UUID().uuidString).jpg"
        let storageRef = storage.reference().child(filename)
        
        // Add metadata
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putDataAsync(optimizedData, metadata: metadata)
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
    
    // Specialized upload methods for different content types
    func uploadProfileImage(_ image: UIImage, userId: String) async throws -> Media {
        return try await uploadImage(image, ownerId: userId, path: StoragePath.userProfiles)
    }
    
    func uploadGymImage(_ image: UIImage, gymId: String) async throws -> Media {
        return try await uploadImage(image, ownerId: gymId, path: StoragePath.gymImages)
    }
    
    func uploadBetaMedia(_ image: UIImage, userId: String) async throws -> Media {
        return try await uploadImage(image, ownerId: userId, path: StoragePath.betaMedia)
    }
    
    func uploadEventImage(_ image: UIImage, eventId: String) async throws -> Media {
        return try await uploadImage(image, ownerId: eventId, path: StoragePath.eventMedia)
    }
    
    // Video upload method with progress tracking - keep your existing implementation
    func uploadVideo(_ videoURL: URL, ownerId: String, onProgress: @escaping (Double) -> Void) async throws -> Media {
        let filename = "\(StoragePath.videos)/\(ownerId)/\(UUID().uuidString).mp4"
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
    
    // MARK: - Media Management Methods
    
    // Keep your existing deleteMedia method
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
    
    // Add a method to get file metadata
    func getMediaMetadata(for url: URL) async throws -> StorageMetadata {
        let fileRef = storage.reference(forURL: url.absoluteString)
        return try await fileRef.getMetadata()
    }
    
    // MARK: - Private Helper Methods
    
    // Keep your existing generateThumbnail method
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
        
        let thumbnailFilename = "\(StoragePath.thumbnails)/\(filename).jpg"
        let thumbnailRef = storage.reference().child(thumbnailFilename)
        
        _ = try await thumbnailRef.putDataAsync(thumbnailData)
        return try await thumbnailRef.downloadURL()
    }
    
    // Add an image resizing method
    private func resizeImageIfNeeded(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let originalWidth = image.size.width
        let originalHeight = image.size.height
        
        // If the image is already smaller than the max dimension, return it as is
        if originalWidth <= maxDimension && originalHeight <= maxDimension {
            return image
        }
        
        // Calculate the new size while preserving aspect ratio
        let aspectRatio = originalWidth / originalHeight
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        if originalWidth > originalHeight {
            newWidth = maxDimension
            newHeight = maxDimension / aspectRatio
        } else {
            newHeight = maxDimension
            newWidth = maxDimension * aspectRatio
        }
        
        // Create a new context and draw the resized image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: newWidth, height: newHeight))
        return renderer.image { _ in
            image.draw(in: CGRect(x: 0, y: 0, width: newWidth, height: newHeight))
        }
    }
    
    // Add a method to extract path from URL if needed
    private func extractPathFromURL(_ url: URL) -> String? {
        let urlString = url.absoluteString
        
        // Check if it's a Firebase Storage URL
        guard urlString.contains("firebasestorage.googleapis.com") else {
            return nil
        }
        
        // Parse the URL to extract the path
        // Format: https://firebasestorage.googleapis.com/v0/b/BUCKET/o/PATH?token=TOKEN
        guard let range = urlString.range(of: "/o/"),
              let endRange = urlString.range(of: "?") else {
            return nil
        }
        
        let startIndex = range.upperBound
        let endIndex = endRange.lowerBound
        let pathEncoded = String(urlString[startIndex..<endIndex])
        
        // URL decode the path
        return pathEncoded.removingPercentEncoding
    }
}
