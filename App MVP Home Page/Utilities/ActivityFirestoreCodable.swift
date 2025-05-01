//
//  ActivityFirestoreCodable.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import Foundation
import FirebaseFirestore

// MARK: - BasicPost + FirestoreCodable
extension BasicPost: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "authorId": author.id,
            "type": "basic", // Type identifier
            "content": content,
            "createdAt": createdAt.firestoreTimestamp,
            "likeCount": likeCount,
            "commentCount": commentCount,
            "isFeatured": isFeatured
        ]
        
        // Convert media items to JSON data
        if let mediaItems = mediaItems, !mediaItems.isEmpty {
            data["mediaItems"] = mediaItems.map { media -> [String: Any] in
                var mediaData: [String: Any] = [
                    "id": media.id,
                    "url": media.url.absoluteString,
                    "type": media.type.rawValue,
                    "uploadedAt": media.uploadedAt.firestoreTimestamp,
                    "ownerId": media.ownerId
                ]
                
                if let thumbnailURL = media.thumbnailURL {
                    mediaData["thumbnailURL"] = thumbnailURL.absoluteString
                }
                
                return mediaData
            }
        }
        
        return data
    }
    
    // Initialize from Firestore data and author
    init?(firestoreData: [String: Any], author: User) {
        guard
            let id = firestoreData["id"] as? String,
            let content = firestoreData["content"] as? String
        else {
            return nil
        }
        
        // Handle timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue
        } else {
            createdAt = Date()
        }
        
        // Parse media items
        var mediaItems: [Media] = []
        if let mediaItemsData = firestoreData["mediaItems"] as? [[String: Any]] {
            for mediaData in mediaItemsData {
                if let mediaItem = parseMediaItem(from: mediaData) {
                    mediaItems.append(mediaItem)
                }
            }
        } else if let legacyMediaURLString = firestoreData["mediaURL"] as? String, 
                  let mediaURL = stringToURL(legacyMediaURLString) {
            // Handle legacy format with single mediaURL
            let media = Media(
                id: UUID().uuidString,
                url: mediaURL,
                type: .image,
                thumbnailURL: nil,
                uploadedAt: Date(),
                ownerId: author.id
            )
            mediaItems.append(media)
        }
        
        // Extract engagement metrics with defaults
        let likeCount = firestoreData["likeCount"] as? Int ?? 0
        let commentCount = firestoreData["commentCount"] as? Int ?? 0
        let isFeatured = firestoreData["isFeatured"] as? Bool ?? false
        
        self.init(
            id: id,
            author: author,
            content: content,
            mediaItems: mediaItems,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount,
            isFeatured: isFeatured
        )
    }
    
    // Required initializer for FirestoreDecodable protocol
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let authorId = firestoreData["authorId"] as? String,
            let content = firestoreData["content"] as? String
        else {
            return nil
        }
        
        // Create placeholder user since we only have the ID
        let placeholderAuthor = User(
            id: authorId,
            email: "placeholder@example.com",
            firstName: "Loading",
            lastName: "User",
            bio: nil,
            postCount: 0,
            loggedHours: 0,
            imageUrl: nil,
            createdAt: Date()
        )
        
        // Handle timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue
        } else {
            createdAt = Date()
        }
        
        // Parse media items
        var mediaItems: [Media] = []
        if let mediaItemsData = firestoreData["mediaItems"] as? [[String: Any]] {
            for mediaData in mediaItemsData {
                if let mediaItem = parseMediaItem(from: mediaData) {
                    mediaItems.append(mediaItem)
                }
            }
        } else if let legacyMediaURLString = firestoreData["mediaURL"] as? String, 
                  let mediaURL = stringToURL(legacyMediaURLString) {
            // Handle legacy format with single mediaURL
            let media = Media(
                id: UUID().uuidString,
                url: mediaURL,
                type: .image,
                thumbnailURL: nil,
                uploadedAt: Date(),
                ownerId: placeholderAuthor.id
            )
            mediaItems.append(media)
        }
        
        // Extract engagement metrics with defaults
        let likeCount = firestoreData["likeCount"] as? Int ?? 0
        let commentCount = firestoreData["commentCount"] as? Int ?? 0
        let isFeatured = firestoreData["isFeatured"] as? Bool ?? false
        
        self.init(
            id: id,
            author: placeholderAuthor,
            content: content,
            mediaItems: mediaItems,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount,
            isFeatured: isFeatured
        )
    }
}

// Helper function to parse Media objects from Firestore data
private func parseMediaItem(from mediaData: [String: Any]) -> Media? {
    guard
        let id = mediaData["id"] as? String,
        let urlString = mediaData["url"] as? String,
        let url = URL(string: urlString),
        let typeString = mediaData["type"] as? String,
        let type = MediaType(rawValue: typeString),
        let ownerId = mediaData["ownerId"] as? String
    else {
        return nil
    }
    
    // Handle thumbnail URL
    var thumbnailURL: URL? = nil
    if let thumbnailURLString = mediaData["thumbnailURL"] as? String {
        thumbnailURL = URL(string: thumbnailURLString)
    }
    
    // Handle upload date
    let uploadedAt: Date
    if let timestamp = mediaData["uploadedAt"] as? Timestamp {
        uploadedAt = timestamp.dateValue
    } else {
        uploadedAt = Date()
    }
    
    return Media(
        id: id,
        url: url,
        type: type,
        thumbnailURL: thumbnailURL,
        uploadedAt: uploadedAt,
        ownerId: ownerId
    )
}

// MARK: - BetaPost + FirestoreCodable
extension BetaPost: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "authorId": author.id,
            "type": "beta", // Type identifier
            "content": content,
            "gymId": gym.id,
            "createdAt": createdAt.firestoreTimestamp,
            "likeCount": likeCount,
            "commentCount": commentCount,
            "viewCount": viewCount,
            "isFeatured": isFeatured
        ]
        
        // Convert media items to JSON data
        if let mediaItems = mediaItems, !mediaItems.isEmpty {
            data["mediaItems"] = mediaItems.map { media -> [String: Any] in
                var mediaData: [String: Any] = [
                    "id": media.id,
                    "url": media.url.absoluteString,
                    "type": media.type.rawValue,
                    "uploadedAt": media.uploadedAt.firestoreTimestamp,
                    "ownerId": media.ownerId
                ]
                
                if let thumbnailURL = media.thumbnailURL {
                    mediaData["thumbnailURL"] = thumbnailURL.absoluteString
                }
                
                return mediaData
            }
        }
        
        return data
    }
    
    // Initialize from Firestore data with author and gym already loaded
    init?(firestoreData: [String: Any], author: User, gym: Gym) {
        guard
            let id = firestoreData["id"] as? String,
            let content = firestoreData["content"] as? String
        else {
            return nil
        }
        
        // Handle timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue
        } else {
            createdAt = Date()
        }
        
        // Parse media items
        var mediaItems: [Media] = []
        if let mediaItemsData = firestoreData["mediaItems"] as? [[String: Any]] {
            for mediaData in mediaItemsData {
                if let mediaItem = parseMediaItem(from: mediaData) {
                    mediaItems.append(mediaItem)
                }
            }
        }
        
        // Extract engagement metrics with defaults
        let likeCount = firestoreData["likeCount"] as? Int ?? 0
        let commentCount = firestoreData["commentCount"] as? Int ?? 0
        let viewCount = firestoreData["viewCount"] as? Int ?? 0
        let isFeatured = firestoreData["isFeatured"] as? Bool ?? false
        
        self.init(
            id: id,
            author: author,
            content: content,
            mediaItems: mediaItems,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount,
            gym: gym,
            viewCount: viewCount,
            isFeatured: isFeatured
        )
    }
    
    // Required initializer for FirestoreDecodable protocol
    init?(firestoreData: [String: Any]) {
        // Cannot fully initialize without the gym, so we'll return nil
        // In practice, you would need to fetch the gym separately
        return nil
    }
}

// MARK: - EventPost + FirestoreCodable
extension EventPost: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "authorId": author.id,
            "type": "event", // Type identifier
            "title": title,
            "createdAt": createdAt.firestoreTimestamp,
            "likeCount": likeCount,
            "commentCount": commentCount,
            "eventDate": eventDate.firestoreTimestamp,
            "location": location,
            "maxAttendees": maxAttendees,
            "registered": registered,
            "isFeatured": isFeatured
        ]
        
        if let description = description {
            data["description"] = description
        }
        
        // Convert media items to JSON data
        if let mediaItems = mediaItems, !mediaItems.isEmpty {
            data["mediaItems"] = mediaItems.map { media -> [String: Any] in
                var mediaData: [String: Any] = [
                    "id": media.id,
                    "url": media.url.absoluteString,
                    "type": media.type.rawValue,
                    "uploadedAt": media.uploadedAt.firestoreTimestamp,
                    "ownerId": media.ownerId
                ]
                
                if let thumbnailURL = media.thumbnailURL {
                    mediaData["thumbnailURL"] = thumbnailURL.absoluteString
                }
                
                return mediaData
            }
        }
        
        if let gym = gym {
            data["gymId"] = gym.id
        }
        
        return data
    }
    
    // Initialize from Firestore data with author and optional gym already loaded
    init?(firestoreData: [String: Any], author: User, gym: Gym?) {
        guard
            let id = firestoreData["id"] as? String,
            let title = firestoreData["title"] as? String,
            let location = firestoreData["location"] as? String
        else {
            return nil
        }
        
        // Handle timestamps
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue
        } else {
            createdAt = Date()
        }
        
        let eventDate: Date
        if let timestamp = firestoreData["eventDate"] as? Timestamp {
            eventDate = timestamp.dateValue
        } else {
            eventDate = Date()
        }
        
        // Optional fields
        let description = firestoreData["description"] as? String
        
        // Parse media items
        var mediaItems: [Media] = []
        if let mediaItemsData = firestoreData["mediaItems"] as? [[String: Any]] {
            for mediaData in mediaItemsData {
                if let mediaItem = parseMediaItem(from: mediaData) {
                    mediaItems.append(mediaItem)
                }
            }
        }
        
        // Extract engagement metrics and other numerics with defaults
        let likeCount = firestoreData["likeCount"] as? Int ?? 0
        let commentCount = firestoreData["commentCount"] as? Int ?? 0
        let maxAttendees = firestoreData["maxAttendees"] as? Int ?? 10
        let registered = firestoreData["registered"] as? Int ?? 0
        let isFeatured = firestoreData["isFeatured"] as? Bool ?? false
        
        self.init(
            id: id,
            author: author,
            title: title,
            description: description,
            mediaItems: mediaItems,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount,
            eventDate: eventDate,
            location: location,
            maxAttendees: maxAttendees,
            registered: registered,
            gym: gym,
            isFeatured: isFeatured
        )
    }
    
    // Required initializer for FirestoreDecodable protocol
    init?(firestoreData: [String: Any]) {
        // Cannot fully initialize without potentially fetching the gym, so we'll return nil
        return nil
    }
}
