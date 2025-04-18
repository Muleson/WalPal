//
//  UserFirestoreCodable.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 01/03/2025.
//

import Foundation
import FirebaseFirestore

extension User: FirestoreCodable {
    // Convert User to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "postCount": postCount,
            "loggedHours": loggedHours,
            "imageUrl": urlToString(imageUrl),
            "createdAt": createdAt.firestoreTimestamp
        ]
        
        // Add optional fields if they exist
        if let bio = bio {
            data["bio"] = bio
        }
        
        return data
    }
    
    // Initialize a User from Firestore data
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let email = firestoreData["email"] as? String,
            let firstName = firestoreData["firstName"] as? String,
            let lastName = firestoreData["lastName"] as? String
        else {
            // Return nil if required fields are missing
            return nil
        }
        
        // Extract other required fields with default values if missing
        let postCount = firestoreData["postCount"] as? Int ?? 0
        let loggedHours = firestoreData["loggedHours"] as? Int ?? 0
        
        // Handle createdAt timestamp
        let createdAt: Date
        if let timestamp = firestoreData["createdAt"] as? Timestamp {
            createdAt = timestamp.dateValue
        } else {
            createdAt = Date()  // Default to current date if missing
        }
        
        // Handle optional fields
        let bio = firestoreData["bio"] as? String
        
        // Handle imageUrl conversion
        let imageUrlString = firestoreData["imageUrl"] as? String
        let imageUrl = stringToURL(imageUrlString)
        
        // Initialize User
        self.init(
            id: id,
            email: email,
            firstName: firstName,
            lastName: lastName,
            bio: bio,
            postCount: postCount,
            loggedHours: loggedHours,
            imageUrl: imageUrl,
            createdAt: createdAt
        )
    }
}

extension UserRelationship: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "followerId": followerId,
            "followingId": followingId,
            "timestamp": timestamp.firestoreTimestamp
        ]
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let followerId = firestoreData["followerId"] as? String,
            let followingId = firestoreData["followingId"] as? String
        else {
            return nil
        }
        
        let timestamp: Date
        if let ts = firestoreData["timestamp"] as? Timestamp {
            timestamp = ts.dateValue
        } else {
            timestamp = Date()
        }
        
        self.init(
            id: id,
            followerId: followerId,
            followingId: followingId,
            timestamp: timestamp
        )
    }
}
