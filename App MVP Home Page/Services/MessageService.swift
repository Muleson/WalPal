//
//  MessageService.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 25/03/2025.
//

import Foundation
import FirebaseFirestore

// Create a type alias to hide the implementation details
public typealias MessageListener = ListenerRegistration

class MessageService {
    private let db = Firestore.firestore()
    
    // MARK: - Conversation Management
    
    /// Fetch all conversations for a user with a real-time listener
    func listenForConversations(
        userId: String,
        onUpdate: @escaping ([Conversation]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> MessageListener {
        
        return db.collection("conversations")
            .whereField("participants", arrayContains: userId)
            .order(by: "lastMessageTimestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    onError(error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    onUpdate([])
                    return
                }
                
                // Parse conversations from Firestore documents
                let conversations = documents.compactMap { document -> Conversation? in
                    let data = document.data()
                    return Conversation(firestoreData: data)
                }
                
                onUpdate(conversations)
            }
    }
    
    /// Get participants for conversations in batches
    func getParticipantsForConversations(
        currentUserId: String,
        conversations: [Conversation]
    ) async throws -> [String: User] {
        // Collect all participant IDs that need to be loaded
        let participantIds = Set(conversations.flatMap { conversation in
            conversation.participants.filter { $0 != currentUserId }
        })
        
        // Use UserRepositoryService to fetch users
        let userRepository = UserRepositoryService()
        let users = try await userRepository.getUsers(ids: Array(participantIds))
        
        // Create a dictionary for easy lookup
        var participantMap: [String: User] = [:]
        for user in users {
            participantMap[user.id] = user
        }
        
        return participantMap
    }
    
    /// Create a new conversation
    func createConversation(between participants: [String]) async throws -> Conversation {
        // Sort participant IDs for consistent ID generation
        let sortedParticipants = participants.sorted()
        
        // Create a consistent ID based on participants
        let conversationId = sortedParticipants.joined(separator: "_")
        
        // Check if conversation already exists
        do {
            let document = try await db.collection("conversations").document(conversationId).getDocument()
            if document.exists, let data = document.data(), let existingConversation = Conversation(firestoreData: data) {
                return existingConversation
            }
        } catch {
            throw error
        }
        
        // Create new conversation
        let newConversation = Conversation(
            id: conversationId,
            participants: sortedParticipants
        )
        
        // Save to Firestore
        try await db.collection("conversations").document(conversationId).setData(newConversation.toFirestoreData())
        
        return newConversation
    }
    
    /// Get a single conversation by ID
    func getConversation(id: String) async throws -> Conversation? {
        let document = try await db.collection("conversations").document(id).getDocument()
        
        guard document.exists, let data = document.data() else {
            return nil
        }
        
        return Conversation(firestoreData: data)
    }
    
    /// Search for users by name
    /// Note: In a real app, you would implement this with proper Firestore query
    func searchUsers(
        query: String,
        excludeUserId: String
    ) async throws -> [User] {
        // This is a simplified implementation
        // In a real app, you would use Firestore's search capabilities or a dedicated search service
        
        // For now, fetch a limited number of users and filter client-side
        let snapshot = try await db.collection("users")
            .limit(to: 20)
            .getDocuments()
        
        let users = snapshot.documents.compactMap { document -> User? in
            let data = document.data()
            return User(firestoreData: data)
        }
        
        // Filter users based on the query
        return users.filter { user in
            // Exclude the current user
            if user.id == excludeUserId { return false }
            
            // Match against first name, last name, or full name
            let firstName = user.firstName.lowercased()
            let lastName = user.lastName.lowercased()
            let fullName = "\(firstName) \(lastName)"
            let queryLower = query.lowercased()
            
            return firstName.contains(queryLower) ||
                   lastName.contains(queryLower) ||
                   fullName.contains(queryLower)
        }
    }
    
    // MARK: - Message Management
    
    /// Fetch messages for a specific conversation with a real-time listener
    func listenForMessages(
        conversationId: String,
        onUpdate: @escaping ([Message]) -> Void,
        onError: @escaping (Error) -> Void
    ) -> MessageListener {
        
        return db.collection("conversations").document(conversationId)
            .collection("messages")
            .order(by: "timestamp", descending: false)
            .addSnapshotListener { snapshot, error in
                if let error = error {
                    onError(error)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    onUpdate([])
                    return
                }
                
                // Parse messages from Firestore documents
                let messages = documents.compactMap { document -> Message? in
                    let data = document.data()
                    return Message(firestoreData: data)
                }
                
                onUpdate(messages)
            }
    }
    
    /// Send a new message
    func sendMessage(
        content: String,
        conversationId: String,
        from senderId: String,
        to recipients: [String],
        mediaURL: URL? = nil
    ) async throws {
        // Create initial read status (sender has read, recipients have not)
        var readStatus = [String: Bool]()
        readStatus[senderId] = true
        for recipient in recipients {
            readStatus[recipient] = false
        }
        
        // Create new message
        let newMessage = Message(
            conversationId: conversationId,
            senderId: senderId,
            content: content,
            timestamp: Date(),
            readStatus: readStatus,
            mediaURL: mediaURL
        )
        
        // Add message to Firestore
        try await db.collection("conversations").document(conversationId)
            .collection("messages").document(newMessage.id)
            .setData(newMessage.toFirestoreData())
        
        // Update conversation's last message info
        var unreadCounts = [String: Int]()
        for recipient in recipients {
            if let currentCount = try await getCurrentUnreadCount(conversationId: conversationId, userId: recipient) {
                unreadCounts[recipient] = currentCount + 1
            } else {
                unreadCounts[recipient] = 1
            }
        }
        
        try await db.collection("conversations").document(conversationId).updateData([
            "lastMessage": content,
            "lastMessageTimestamp": Timestamp(date: Date()),
            "lastMessageSenderId": senderId,
            "unreadCounts": unreadCounts
        ])
    }
    
    /// Mark messages as read for a user
    func markConversationAsRead(conversationId: String, for userId: String) async throws {
        // Get all unread messages
        let querySnapshot = try await db.collection("conversations").document(conversationId)
            .collection("messages")
            .whereField("readStatus.\(userId)", isEqualTo: false)
            .getDocuments()
        
        // Create a batch to update all messages
        let batch = db.batch()
        
        for document in querySnapshot.documents {
            let messageRef = db.collection("conversations").document(conversationId)
                .collection("messages").document(document.documentID)
            
            batch.updateData(["readStatus.\(userId)": true], forDocument: messageRef)
        }
        
        // Update unread count in conversation
        let conversationRef = db.collection("conversations").document(conversationId)
        batch.updateData(["unreadCounts.\(userId)": 0], forDocument: conversationRef)
        
        // Commit the batch
        try await batch.commit()
    }
    
    // MARK: - Helper Methods
    
    /// Get the current unread count for a user in a conversation
    private func getCurrentUnreadCount(conversationId: String, userId: String) async throws -> Int? {
        let document = try await db.collection("conversations").document(conversationId).getDocument()
        guard document.exists,
              let data = document.data(),
              let unreadCounts = data["unreadCounts"] as? [String: Int] else {
            return nil
        }
        
        return unreadCounts[userId]
    }
}
