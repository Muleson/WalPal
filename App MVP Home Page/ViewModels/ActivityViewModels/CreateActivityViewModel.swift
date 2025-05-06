//
//  CreateActivityViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import Foundation
import SwiftUI
import AVKit

enum ActivityType: String, CaseIterable {
    case basic = "Basic Post"
    case beta = "Beta"
    case event = "Event"
}

class CreateActivityViewModel: ObservableObject {
    // Common properties
    @Published var selectedType: ActivityType = .basic
    @Published var content: String = ""
    @Published var mediaURL: URL?
    @Published var showMediaPicker = false
    @Published var selectedGymId: String = ""
    @Published var gyms: [Gym] = []
    @Published var isLoadingGyms = false
    
    // Beta-specific properties
    @Published var difficulty: String = ""
    @Published var routeName: String = ""
    
    // Event-specific properties
    @Published var eventTitle: String = ""
    @Published var eventDescription: String = ""
    @Published var eventDate = Date()
    @Published var eventLocation = ""
    @Published var maxAttendees = 10
    
    // Status properties
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Media-related properties
    @Published var selectedImages: [UIImage] = []
    @Published var selectedVideos: [URL] = []
    @Published var isUploadingMedia = false
    @Published var uploadProgress: Double = 0
    @Published var mediaItems: [Media] = []
    
    // Add video thumbnail support for previewing in UI
    @Published var videoThumbnails: [UIImage] = []
    
    private let mediaStorageService = MediaStorageService()
    private let activityRepository = ActivityRepositoryService()
    private var _preselectedGym: Gym?

    // MARK: - Validation
    
    var isFormValid: Bool {
        switch selectedType {
        case .basic:
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || 
                   !selectedImages.isEmpty || 
                   !selectedVideos.isEmpty
        case .beta:
            return !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                  !selectedGymId.isEmpty
        case .event:
            return !eventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                  !eventLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   eventDate > Date()
        }
    }
    
    // MARK: - Media Handling
    
    // Generate thumbnails when videos are added
    func generateVideoThumbnails() {
        // Clear existing thumbnails that might be outdated
        videoThumbnails = []
        
        for videoURL in selectedVideos {
            generateThumbnail(from: videoURL) { [weak self] thumbnail in
                if let thumbnail = thumbnail {
                    DispatchQueue.main.async {
                        self?.videoThumbnails.append(thumbnail)
                    }
                }
            }
        }
    }
    
    private func generateThumbnail(from videoURL: URL, completion: @escaping (UIImage?) -> Void) {
        DispatchQueue.global().async {
            let asset = AVURLAsset(url: videoURL)
            let imageGenerator = AVAssetImageGenerator(asset: asset)
            imageGenerator.appliesPreferredTrackTransform = true
            
            do {
                // Get thumbnail at 1 second
                let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 1, preferredTimescale: 60), actualTime: nil)
                let thumbnail = UIImage(cgImage: cgImage)
                completion(thumbnail)
            } catch {
                print("Error generating thumbnail: \(error.localizedDescription)")
                completion(nil)
            }
        }
    }
    
    // MARK: - Creation Methods
    
    @MainActor
    func createActivityItem(author: User) async {
        guard isFormValid else { return }
        
        isLoading = true
        isUploadingMedia = !selectedImages.isEmpty || !selectedVideos.isEmpty
        
        do {
            // First upload all media
            if !selectedImages.isEmpty || !selectedVideos.isEmpty {
                await uploadAllMedia(authorId: author.id)
            }

            // Then create the activity item with the uploaded media
            switch selectedType {
            case .basic:
                try await createBasicPost(author: author)
            case .beta:
                try await createBetaPost(author: author)
            case .event:
                try await createEventPost(author: author)
            }
            
            await MainActor.run {
                isLoading = false
                isUploadingMedia = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
                isUploadingMedia = false
            }
        }
    }
    
    private func uploadAllMedia(authorId: String) async {
        // First upload all images
        for image in selectedImages {
            uploadProgress = Double(mediaItems.count) / Double(selectedImages.count + selectedVideos.count)
            
            do {
                // Use the appropriate upload method based on activity type
                let media: Media
                switch selectedType {
                case .basic:
                    media = try await mediaStorageService.uploadImage(image, ownerId: authorId)
                case .beta:
                    media = try await mediaStorageService.uploadBetaMedia(image, userId: authorId)
                case .event:
                    media = try await mediaStorageService.uploadEventImage(image, eventId: authorId)
                }
                
                await MainActor.run {
                    mediaItems.append(media)
                }
            } catch {
                print("Failed to upload image: \(error.localizedDescription)")
                // Continue with other uploads even if one fails
            }
        }
        
        // Then upload all videos
        for videoURL in selectedVideos {
            do {
                let media = try await mediaStorageService.uploadVideo(videoURL, ownerId: authorId) { progress in
                    let baseProgress = Double(self.mediaItems.count) / Double(self.selectedImages.count + self.selectedVideos.count)
                    let additionalProgress = progress / Double(self.selectedImages.count + self.selectedVideos.count)
                    
                    Task { @MainActor in
                        self.uploadProgress = baseProgress + additionalProgress
                    }
                }
                
                await MainActor.run {
                    mediaItems.append(media)
                }
            } catch {
                print("Failed to upload video: \(error.localizedDescription)")
                // Continue with other uploads even if one fails
            }
        }
    }
    
    private func createBasicPost(author: User) async throws {
        _ = try await activityRepository.createBasicPost(
            author: author,
            content: content,
            mediaItems: mediaItems.isEmpty ? nil : mediaItems
        )
    }
    
    private func createBetaPost(author: User) async throws {
        // First, fetch the gym
        let gymService = GymService()
        guard let gym = try await gymService.fetchGym(id: selectedGymId) else {
            throw NSError(
                domain: "CreateActivityViewModel",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Selected gym not found"]
            )
        }
        
        _ = try await activityRepository.createBetaPost(
            author: author,
            content: content,
            gym: gym,
            mediaItems: mediaItems
            )
    }
    
    private func createEventPost(author: User) async throws {
        // Fetch gym if selected
        var gym: Gym?
        if !selectedGymId.isEmpty {
            let gymService = GymService()
            gym = try await gymService.fetchGym(id: selectedGymId)
        }
        
        _ = try await activityRepository.createEventPost(
            author: author,
            title: eventTitle,
            description: eventDescription.isEmpty ? nil : eventDescription,
            eventDate: eventDate,
            location: eventLocation,
            maxAttendees: maxAttendees,
            gym: gym,
            mediaItems: mediaItems.isEmpty ? nil : mediaItems
        )
    }
    
    // MARK: - Load Operations
    
    @MainActor
    func loadGyms() async {
        isLoadingGyms = true
        
        let gymService = GymService()
        do {
            try await gymService.fetchGyms()
            await MainActor.run {
                self.gyms = gymService.gyms
                self.isLoadingGyms = false
                
                // If we already had a gym selected but it's no longer available,
                // reset the selection
                if !selectedGymId.isEmpty && !gyms.contains(where: { $0.id == selectedGymId }) {
                    selectedGymId = ""
                }
            }
        } catch {
            await MainActor.run {
                self.isLoadingGyms = false
                self.errorMessage = "Failed to load gyms: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }

    //MARK: - Create activity for selected gym
    var preselectedGym: Gym? {
        get {
            return _preselectedGym
        }
        set {
            _preselectedGym = newValue
            if let gym = newValue {
                selectedGymId = gym.id
            }
        }
    }
    
    // Add helper method for video thumbnail access by index
    func videoThumbnail(at index: Int) -> UIImage? {
        guard index < videoThumbnails.count else { return nil }
        return videoThumbnails[index]
    }
    
    // Reset all state when the view disappears or is dismissed
    func reset() {
        // Clear media
        selectedImages = []
        selectedVideos = []
        videoThumbnails = []
        mediaItems = []
        uploadProgress = 0
        
        // Reset common fields
        content = ""
        mediaURL = nil
        
        // Reset specific fields
        difficulty = ""
        routeName = ""
        eventTitle = ""
        eventDescription = ""
        eventDate = Date()
        eventLocation = ""
        maxAttendees = 10
    }
}
