//
//  ConversationViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 25/03/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class ConversationViewModel: ObservableObject {
    // Services
    private let messageService = MessageService()
    private let userRepository = UserRepositoryService()
    
    // Published properties for UI state
    @Published var messages: [MessageDisplayModel] = []
    @Published var participants: [User] = []
    @Published var newMessageText: String = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Current user and conversation
    private var currentUserId: String
    private var conversationId: String
    
    // Active listeners
    private var messagesListener: ListenerRegistration?
    
    init(currentUserId: String, conversationId: String) {
        self.currentUserId = currentUserId
        self.conversationId = conversationId
    }
    
    // MARK: - Public Methods
    
    /// Load conversation and messages
    func loadConversation() async {
           isLoading = true
           errorMessage = nil
           
           do {
               // Load conversation for participant information
               let conversation = try await messageService.getConversation(id: conversationId)
               
               if let conversation = conversation {
                   // Delegate participant retrieval to MessageService
                   let participantMap = try await messageService.getParticipantsForConversations(
                       currentUserId: currentUserId,
                       conversations: [conversation]
                   )
                   
                   // Extract participants from the map
                   self.participants = conversation.participants.compactMap { participantId in
                       participantMap[participantId]
                   }
                   
                   // Mark conversation as read for current user
                   try await messageService.markConversationAsRead(
                       conversationId: conversationId,
                       for: currentUserId
                   )
                   
                   // Set up listener for messages
                   setupMessagesListener()
               } else {
                   errorMessage = "Conversation not found"
                   isLoading = false
               }
           } catch {
               errorMessage = "Error loading conversation: \(error.localizedDescription)"
               isLoading = false
           }
       }
    
    /// Send a new message
    func sendMessage() async {
        // Validation
        let trimmedMessage = newMessageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        do {
            // Get recipient IDs (everyone except current user)
            let recipientIds = participants
                .filter { $0.id != currentUserId }
                .map { $0.id }
            
            // Send the message
            try await messageService.sendMessage(
                content: trimmedMessage,
                conversationId: conversationId,
                from: currentUserId,
                to: recipientIds
            )
            
            // Clear the input field
            newMessageText = ""
        } catch {
            errorMessage = "Error sending message: \(error.localizedDescription)"
        }
    }
    
    func getMainParticipant() -> User? {
            // Get the first participant who isn't the current user
            return participants.first { $0.id != currentUserId }
        }
        
        /// Get names of all participants for display
        func getParticipantDisplayName() -> String {
            // Get all participants who aren't the current user
            let otherParticipants = participants.filter { $0.id != currentUserId }
            
            if otherParticipants.isEmpty {
                return "Conversation"
            } else if otherParticipants.count == 1 {
                return "\(otherParticipants[0].firstName) \(otherParticipants[0].lastName)"
            } else {
                // For group conversations, list first name + count
                let firstParticipant = otherParticipants[0].firstName
                return "\(firstParticipant) + \(otherParticipants.count - 1) others"
            }
        }
    
    /// Clean up resources when view disappears
    func cleanup() {
        messagesListener?.remove()
    }
    
    // MARK: - Private Methods
    
    /// Set up real-time listener for messages
    private func setupMessagesListener() {
        // Remove any existing listener
        messagesListener?.remove()
        
        // Set up new listener
        messagesListener = messageService.listenForMessages(
            conversationId: conversationId,
            onUpdate: { [weak self] messages in
                guard let self = self else { return }
                
                Task {
                    await self.processMessages(messages)
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                
                self.errorMessage = "Error loading messages: \(error.localizedDescription)"
                self.isLoading = false
            }
        )
    }
    
    /// Process raw messages into display models
    private func processMessages(_ rawMessages: [Message]) async {
        let displayMessages = rawMessages.map { message in
            let sender = participants.first(where: { $0.id == message.senderId })
            
            return MessageDisplayModel(
                id: message.id,
                content: message.content,
                timestamp: message.timestamp,
                isFromCurrentUser: message.senderId == currentUserId,
                sender: sender,
                isRead: message.isRead(by: currentUserId),
                mediaURL: message.mediaURL
            )
        }
        
        self.messages = displayMessages
        self.isLoading = false
    }
}

/// Model for displaying individual messages
struct MessageDisplayModel: Identifiable, Equatable {
    let id: String
    let content: String
    let timestamp: Date
    let isFromCurrentUser: Bool
    let sender: User?
    let isRead: Bool
    let mediaURL: URL?
    
    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    // Create from a Message model and lookup for sender
    static func from(message: Message, currentUserId: String, sender: User?) -> MessageDisplayModel {
        return MessageDisplayModel(
            id: message.id,
            content: message.content,
            timestamp: message.timestamp,
            isFromCurrentUser: message.isSentByCurrentUser(currentUserId),
            sender: sender,
            isRead: message.isRead(by: currentUserId),
            mediaURL: message.mediaURL
        )
    }
}

