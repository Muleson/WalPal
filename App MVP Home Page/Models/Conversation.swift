//
//  Conversation.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 25/03/2025.
//

import Foundation

struct Conversation: Identifiable, Codable, Equatable {
    let id: String
    let participants: [String]
    let lastMessage: String
    let lastMessageTimestamp: Date
    let lastMessageSenderId: String
    let unreadCounts: [String: Int]
    
    /// Create a new conversation between users
    init(id: String = UUID().uuidString,
         participants: [String],
         lastMessage: String = "",
         lastMessageTimestamp: Date = Date(),
         lastMessageSenderId: String = "",
         unreadCounts: [String: Int] = [:]) {
        self.id = id
        self.participants = participants
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.lastMessageSenderId = lastMessageSenderId
        self.unreadCounts = unreadCounts
    }
    
    func otherParticipantId(currentUserId: String) -> String? {
           return participants.first { $0 != currentUserId }
       }
       
   /// Returns whether there are unread messages for the given user
   func hasUnreadMessages(for userId: String) -> Bool {
       return (unreadCounts[userId] ?? 0) > 0
   }
   
   /// Returns the count of unread messages for the given user
   func unreadMessageCount(for userId: String) -> Int {
       return unreadCounts[userId] ?? 0
   }
}
