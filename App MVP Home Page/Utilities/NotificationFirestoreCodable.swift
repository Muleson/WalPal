//
//  NotificationFirestoreCodable.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 04/04/2025.
//

import FirebaseFirestore

extension Notification: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "userId": userId,
            "title": title,
            "message": message,
            "timestamp": timestamp.firestoreTimestamp,
            "isRead": isRead,
            "type": type.rawValue
        ]
        
        if let relatedItemId = relatedItemId {
            data["relatedItemId"] = relatedItemId
        }
        
        return data
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let userId = firestoreData["userId"] as? String,
            let title = firestoreData["title"] as? String,
            let message = firestoreData["message"] as? String,
            let typeString = firestoreData["type"] as? String,
            let type = NotificationType(rawValue: typeString),
            let isRead = firestoreData["isRead"] as? Bool
        else {
            return nil
        }
        
        self.id = id
        self.userId = userId
        self.title = title
        self.message = message
        self.type = type
        self.isRead = isRead
        self.relatedItemId = firestoreData["relatedItemId"] as? String
        
        // Handle timestamp
        if let timestamp = firestoreData["timestamp"] as? Timestamp {
            self.timestamp = timestamp.dateValue
        } else {
            self.timestamp = Date()
        }
    }
}
