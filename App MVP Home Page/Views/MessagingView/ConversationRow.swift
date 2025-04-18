//
//  ConversationRow.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 26/03/2025.
//

import SwiftUI

struct ConversationRow: View {
    let conversation: ConversationDisplayModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture
            if let imageUrl = conversation.participant?.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(conversation.getInitial())
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gray)
                    )
            }
            
            // Conversation details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.getDisplayName())
                        .font(.headline)
                        .fontWeight(conversation.unreadCount > 0 ? .semibold : .regular)
                    
                    Spacer()
                    
                    Text(conversation.formattedTime())
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Preview of last message with unread indicator
                HStack {
                    if conversation.isLastMessageFromCurrentUser {
                        Text("You: ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Text(conversation.lastMessage)
                        .font(.subheadline)
                        .foregroundColor(conversation.unreadCount > 0 ? .primary : .secondary)
                        .fontWeight(conversation.unreadCount > 0 ? .medium : .regular)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Spacer()
                    
                    // Show unread count badge if there are unread messages
                    if conversation.unreadCount > 0 {
                        Text("\(conversation.unreadCount)")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.appButton)
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
