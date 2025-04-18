//
//  Message.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 25/03/2025.
//

import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let conversationId: String
    let senderId: String
    let content: String
    let timestamp: Date
    let readStatus: [String: Bool]
    let mediaURL: URL?
    
    /// Create a new message
    init(id: String = UUID().uuidString,
         conversationId: String,
         senderId: String,
         content: String,
         timestamp: Date = Date(),
         readStatus: [String: Bool] = [:],
         mediaURL: URL? = nil) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.content = content
        self.timestamp = timestamp
        self.readStatus = readStatus
        self.mediaURL = mediaURL
    }
    
    /// Returns whether this message has been read by the given user
       func isRead(by userId: String) -> Bool {
           return readStatus[userId] ?? false
       }
       
       /// Returns whether this message was sent by the given user
       func isSentByCurrentUser(_ userId: String) -> Bool {
           return senderId == userId
       }
    
    
}
