//
//  ConversationListViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 26/03/2025.
//

import Foundation
import SwiftUI

@MainActor
class ConversationListViewModel: ObservableObject {
    // Services
    private let messageService = MessageService()
    
    // Published properties for UI state
    @Published var conversations: [ConversationDisplayModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Current user
    private var currentUserId: String
    
    // Active listeners
    private var conversationsListener: MessageListener?
    
    init(currentUserId: String) {
        self.currentUserId = currentUserId
    }
    
    // MARK: - Public Methods
    
    /// Load conversations for the current user
    func loadConversations() async {
        isLoading = true
        errorMessage = nil
        
        // Setup real-time listener for conversations
        setupConversationsListener()
    }
    
    /// Create a new conversation with a user
    func createConversation(with userId: String) async -> String? {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create conversation between current user and selected user
            let conversation = try await messageService.createConversation(
                between: [currentUserId, userId]
            )
            
            isLoading = false
            return conversation.id
        } catch {
            errorMessage = "Error creating conversation: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    /// Clean up resources when view disappears
    func cleanup() {
        conversationsListener?.remove()
    }
    
    // MARK: - Private Methods
    
    /// Set up real-time listener for conversations
    private func setupConversationsListener() {
        // Remove any existing listener
        conversationsListener?.remove()
        
        // Set up new listener
        conversationsListener = messageService.listenForConversations(
            userId: currentUserId,
            onUpdate: { [weak self] conversations in
                guard let self = self else { return }
                
                Task {
                    await self.processConversations(conversations)
                }
            },
            onError: { [weak self] error in
                guard let self = self else { return }
                
                self.errorMessage = "Error loading conversations: \(error.localizedDescription)"
                self.isLoading = false
            }
        )
    }
    
    /// Process raw conversations into display models
    private func processConversations(_ rawConversations: [Conversation]) async {
        do {
            // Delegate fetching participants to the MessageService
            let participantMap = try await messageService.getParticipantsForConversations(
                currentUserId: currentUserId,
                conversations: rawConversations
            )
            
            // Transform conversations to display models
            let displayConversations = rawConversations.map { conversation -> ConversationDisplayModel in
                // Find the other participant (assuming 1:1 conversations for now)
                let otherParticipantId = conversation.participants.first { $0 != currentUserId } ?? ""
                let participant = participantMap[otherParticipantId]
                
                return ConversationDisplayModel(
                    id: conversation.id,
                    lastMessage: conversation.lastMessage,
                    lastMessageTimestamp: conversation.lastMessageTimestamp,
                    unreadCount: conversation.unreadMessageCount(for: currentUserId),
                    isLastMessageFromCurrentUser: conversation.lastMessageSenderId == currentUserId,
                    participant: participant
                )
            }
            
            // Sort by timestamp (most recent first)
            self.conversations = displayConversations.sorted { $0.lastMessageTimestamp > $1.lastMessageTimestamp }
            self.isLoading = false
        } catch {
            self.errorMessage = "Error loading conversation participants: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
}

/// Model for displaying conversation in the list
struct ConversationDisplayModel: Identifiable, Equatable {
    let id: String
    let lastMessage: String
    let lastMessageTimestamp: Date
    let unreadCount: Int
    let isLastMessageFromCurrentUser: Bool
    let participant: User?
    
    func formattedTime() -> String {
        // For messages from today, show time
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(lastMessageTimestamp) {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: lastMessageTimestamp)
        }
        // For messages from yesterday, show "Yesterday"
        else if calendar.isDateInYesterday(lastMessageTimestamp) {
            return "Yesterday"
        }
        // For messages from this week, show day name
        else if calendar.isDate(lastMessageTimestamp, equalTo: now, toGranularity: .weekOfYear) {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name
            return formatter.string(from: lastMessageTimestamp)
        }
        // For older messages, show date
        else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: lastMessageTimestamp)
        }
    }
    
    func getDisplayName() -> String {
        if let participant = participant {
            return "\(participant.firstName) \(participant.lastName)"
        } else {
            return "Unknown User"
        }
    }
    
    func getInitial() -> String {
        if let participant = participant {
            return participant.firstName.prefix(1).uppercased()
        } else {
            return "?"
        }
    }
}
