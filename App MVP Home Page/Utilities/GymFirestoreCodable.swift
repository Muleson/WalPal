//
//  GymFirestoreCodable.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 01/03/2025.
//

import Foundation
import FirebaseFirestore

extension Gym: FirestoreCodable {
    // Convert Gym to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "email": email,
            "name": name,
            "location": locaiton, // Note: Using the field name from your struct (with typo)
            "climbingType": climbingType.map { $0.rawValue },
            "amenities": amenities,
            "events": events,
            "createdAt": createdAt.firestoreTimestamp
        ]
        
        // Add optional fields if they exist
        if let description = description {
            data["description"] = description
        }
        
        if let imageUrl = imageUrl {
            data["imageUrl"] = imageUrl.absoluteString
        }
        
        return data
    }
    
    // Initialize a Gym from Firestore data
    init?(firestoreData: [String: Any]) {
            guard
                let id = firestoreData["id"] as? String,
                let email = firestoreData["email"] as? String,
                let name = firestoreData["name"] as? String
            else {
                // Return nil if required fields are missing
                return nil
            }
            
            // Handle location field (with typo handling)
            var location: String
            if let locaitonValue = firestoreData["locaiton"] as? String {
                location = locaitonValue
            } else if let locationValue = firestoreData["location"] as? String {
                location = locationValue
            } else {
                // Default value if neither key exists
                location = "Unknown"
            }
            
            // Handle climbing types array
            var climbingTypes: [ClimbingTypes] = []
            if let climbingTypeStrings = firestoreData["climbingType"] as? [String] {
                climbingTypes = climbingTypeStrings.compactMap { ClimbingTypes(rawValue: $0) }
            } else if let climbingTypeString = firestoreData["climbingType"] as? String,
                      let climbingType = ClimbingTypes(rawValue: climbingTypeString) {
                // Backward compatibility with old data format
                climbingTypes = [climbingType]
            }
            
            // Default to bouldering if no valid types
            if climbingTypes.isEmpty {
                climbingTypes = [.bouldering]
            }
            
            // Extract arrays with defaults
            let amenities = firestoreData["amenities"] as? [String] ?? []
            let events = firestoreData["events"] as? [String] ?? []
            
            // Handle timestamp
            let createdAt: Date
            if let timestamp = firestoreData["createdAt"] as? Timestamp {
                createdAt = timestamp.dateValue
            } else {
                createdAt = Date()  // Default to current date if missing
            }
            
            // Extract optional fields
            let description = firestoreData["description"] as? String
            
            // Handle imageUrl
            let imageUrlString = firestoreData["imageUrl"] as? String
            let imageUrl = stringToURL(imageUrlString)
            
            // Initialize Gym
            self.init(
                id: id,
                email: email,
                name: name,
                description: description,
                locaiton: location, // Note: Using the field name from your struct
                climbingType: climbingTypes,
                amenities: amenities,
                events: events,
                imageUrl: imageUrl,
                createdAt: createdAt
            )
        }
    }

// MARK: - GymAdministrator + FirestoreCodable
extension GymAdministrator: FirestoreCodable {
    // Convert GymAdministrator to Firestore data dictionary
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "userId": userId,
            "gymId": gymId,
            "role": role.rawValue,
            "addedAt": addedAt.firestoreTimestamp,
            "addedBy": addedBy
        ]
    }
    
    // Initialize a GymAdministrator from Firestore data
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let userId = firestoreData["userId"] as? String,
            let gymId = firestoreData["gymId"] as? String,
            let roleString = firestoreData["role"] as? String,
            let role = AdminRole(rawValue: roleString),
            let addedBy = firestoreData["addedBy"] as? String
        else {
            // Return nil if required fields are missing
            return nil
        }
        
        // Handle timestamp
        let addedAt: Date
        if let timestamp = firestoreData["addedAt"] as? Timestamp {
            addedAt = timestamp.dateValue
        } else {
            addedAt = Date()  // Default to current date if missing
        }
        
        // Initialize GymAdministrator
        self.init(
            id: id,
            userId: userId,
            gymId: gymId,
            role: role,
            addedAt: addedAt,
            addedBy: addedBy
        )
    }
}
