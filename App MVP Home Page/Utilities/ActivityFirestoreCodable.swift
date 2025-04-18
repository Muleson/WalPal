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
        
        if let mediaURL = mediaURL {
            data["mediaURL"] = mediaURL.absoluteString
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
        
        // Handle mediaURL
        let mediaURLString = firestoreData["mediaURL"] as? String
        let mediaURL = stringToURL(mediaURLString)
        
        // Extract engagement metrics with defaults
        let likeCount = firestoreData["likeCount"] as? Int ?? 0
        let commentCount = firestoreData["commentCount"] as? Int ?? 0
        let isFeatured = firestoreData["isFeatured"] as? Bool ?? false
        
        self.init(
            id: id,
            author: author,
            content: content,
            mediaURL: mediaURL,
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
        
        // Handle mediaURL
        let mediaURLString = firestoreData["mediaURL"] as? String
        let mediaURL = stringToURL(mediaURLString)
        
        // Extract engagement metrics with defaults
        let likeCount = firestoreData["likeCount"] as? Int ?? 0
        let commentCount = firestoreData["commentCount"] as? Int ?? 0
        let isFeatured = firestoreData["isFeatured"] as? Bool ?? false
        
        self.init(
            id: id,
            author: placeholderAuthor,
            content: content,
            mediaURL: mediaURL,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount,
            isFeatured: isFeatured
        )
    }
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
        
        if let mediaURL = mediaURL {
            data["mediaURL"] = mediaURL.absoluteString
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
        
        // Handle mediaURL
        let mediaURLString = firestoreData["mediaURL"] as? String
        let mediaURL = stringToURL(mediaURLString)
        
        // Extract engagement metrics with defaults
        let likeCount = firestoreData["likeCount"] as? Int ?? 0
        let commentCount = firestoreData["commentCount"] as? Int ?? 0
        let viewCount = firestoreData["viewCount"] as? Int ?? 0
        let isFeatured = firestoreData["isFeatured"] as? Bool ?? false
        
        self.init(
            id: id,
            author: author,
            content: content,
            mediaURL: mediaURL,
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
        
        if let mediaURL = mediaURL {
            data["mediaURL"] = mediaURL.absoluteString
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
        
        // Handle mediaURL
        let mediaURLString = firestoreData["mediaURL"] as? String
        let mediaURL = stringToURL(mediaURLString)
        
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
            mediaURL: mediaURL,
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

// MARK: - Visit + FirestoreCodable
extension GroupVisit: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "authorId": author.id,
            "type": "visit", // Type identifier
            "createdAt": createdAt.firestoreTimestamp,
            "likeCount": likeCount,
            "commentCount": commentCount,
            "gymId": gym.id,
            "visitDate": visitDate.firestoreTimestamp,
            "duration": duration,
            "attendees": attendees,
            "status": status.rawValue,
            "isFeatured": isFeatured
        ]
        
        if let description = description {
            data["description"] = description
        }
        
        return data
    }
    
    // Initialize from Firestore data with author and gym already loaded
    init?(firestoreData: [String: Any], author: User, gym: Gym) {
        guard
            let id = firestoreData["id"] as? String,
            let statusString = firestoreData["status"] as? String,
            let status = VisitStatus(rawValue: statusString),
            let attendees = firestoreData["attendees"] as? [String]
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
        
        let visitDate: Date
        if let timestamp = firestoreData["visitDate"] as? Timestamp {
            visitDate = timestamp.dateValue
        } else {
            visitDate = Date()
        }
        
        // Optional fields
        let description = firestoreData["description"] as? String
        
        // Extract engagement metrics and other numerics with defaults
        let likeCount = firestoreData["likeCount"] as? Int ?? 0
        let commentCount = firestoreData["commentCount"] as? Int ?? 0
        let duration = firestoreData["duration"] as? TimeInterval ?? 3600 // Default 1 hour
        let isFeatured = firestoreData["isFeatured"] as? Bool ?? false
        
        self.init(
            id: id,
            author: author,
            createdAt: createdAt,
            likeCount: likeCount,
            commentCount: commentCount,
            gym: gym,
            visitDate: visitDate,
            duration: duration,
            description: description,
            attendees: attendees,
            status: status,
            isFeatured: isFeatured
        )
    }
    
    // Required initializer for FirestoreDecodable protocol
    init?(firestoreData: [String: Any]) {
        // Cannot fully initialize without the gym, so we'll return nil
        return nil
    }
}
