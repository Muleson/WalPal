//
//  MessagingFirestoreCodable.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 25/03/2025.
//

import Foundation
import Firebase

// MARK: - Conversation FirestoreCodable Extension
extension Conversation: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "participants": participants,
            "lastMessage": lastMessage,
            "lastMessageTimestamp": lastMessageTimestamp.firestoreTimestamp,
            "lastMessageSenderId": lastMessageSenderId,
            "unreadCounts": unreadCounts
        ]
        
        return data
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let participants = firestoreData["participants"] as? [String]
        else {
            return nil
        }
        
        let lastMessage = firestoreData["lastMessage"] as? String ?? ""
        let lastMessageSenderId = firestoreData["lastMessageSenderId"] as? String ?? ""
        
        // Handle timestamp
        let lastMessageTimestamp: Date
        if let timestamp = firestoreData["lastMessageTimestamp"] as? Timestamp {
            lastMessageTimestamp = timestamp.dateValue
        } else {
            lastMessageTimestamp = Date()
        }
        
        // Handle unread counts map
        let unreadCounts = firestoreData["unreadCounts"] as? [String: Int] ?? [:]
        
        self.init(
            id: id,
            participants: participants,
            lastMessage: lastMessage,
            lastMessageTimestamp: lastMessageTimestamp,
            lastMessageSenderId: lastMessageSenderId,
            unreadCounts: unreadCounts
        )
    }
}

// MARK: - Message FirestoreCodable Extension
extension Message: FirestoreCodable {
    func toFirestoreData() -> [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "conversationId": conversationId,
            "senderId": senderId,
            "content": content,
            "timestamp": timestamp.firestoreTimestamp,
            "readStatus": readStatus
        ]
        
        if let mediaURL = mediaURL {
            data["mediaURL"] = mediaURL.absoluteString
        }
        
        return data
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let conversationId = firestoreData["conversationId"] as? String,
            let senderId = firestoreData["senderId"] as? String,
            let content = firestoreData["content"] as? String
        else {
            return nil
        }
        
        // Handle timestamp
        let timestamp: Date
        if let firestoreTimestamp = firestoreData["timestamp"] as? Timestamp {
            timestamp = firestoreTimestamp.dateValue
        } else {
            timestamp = Date()
        }
        
        // Handle read status map
        let readStatus = firestoreData["readStatus"] as? [String: Bool] ?? [:]
        
        // Handle optional mediaURL
        let mediaURLString = firestoreData["mediaURL"] as? String
        let mediaURL = mediaURLString != nil ? URL(string: mediaURLString!) : nil
        
        self.init(
            id: id,
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            timestamp: timestamp,
            readStatus: readStatus,
            mediaURL: mediaURL
        )
    }
}
