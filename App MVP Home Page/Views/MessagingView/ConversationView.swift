//
//  ConversationView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 25/03/2025.
//

import SwiftUI

struct ConversationView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: ConversationViewModel
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isInputFocused: Bool
    
    // Scroll to bottom functionality
    @State private var scrollToBottom = true
    @State private var lastMessageId = ""
    
    init(appState: AppState, conversationId: String) {
        self.appState = appState
        // Initialize the view model with current user and conversation IDs
        _viewModel = StateObject(wrappedValue:
            ConversationViewModel(
                currentUserId: appState.user?.id ?? "",
                conversationId: conversationId
            )
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages area
            messagesArea
                
            // Input area
            messageInputArea
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.appButton)
                }
            }
            
            ToolbarItem(placement: .principal) {
                // Show participant name aligned to the left
                HStack {
                    if let participant = viewModel.getMainParticipant() {
                        // Profile image
                        if let imageUrl = participant.imageUrl {
                            AsyncImage(url: imageUrl) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Text(participant.firstName.prefix(1))
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // Name with online indicator
                        VStack(alignment: .leading, spacing: 1) {
                            Text("\(participant.firstName) \(participant.lastName)")
                                .font(.headline)
                                .lineLimit(1)
                        }
                    } else {
                        Text("Conversation")
                            .font(.headline)
                    }
                    
                    Spacer()
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    // Info button - could show participant details, etc.
                } label: {
                    Image(systemName: "info.circle")
                }
            }
        }
        .onAppear {
            // Load the conversation when the view appears
            Task {
                await viewModel.loadConversation()
            }
        }
        .onDisappear {
            // Clean up listeners when the view disappears
            viewModel.cleanup()
        }
        .onChange(of: viewModel.messages) { oldValue, newValue in
            // Scroll to bottom when new messages arrive
            if !newValue.isEmpty && lastMessageId != newValue.last?.id {
                scrollToBottom = true
                lastMessageId = newValue.last?.id ?? ""
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    // MARK: - View Components
    
    private var messagesArea: some View {
        ScrollViewReader { scrollView in
            ScrollView {
                LazyVStack(spacing: 8) {
                    if viewModel.isLoading && viewModel.messages.isEmpty {
                        ProgressView()
                            .padding()
                    } else {
                        ForEach(viewModel.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                    }
                    
                    // Invisible element to scroll to
                    Color.clear
                        .frame(height: 1)
                        .id("bottomAnchor")
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            .onChange(of: scrollToBottom) { oldValue, newValue in
                if newValue {
                    withAnimation {
                        scrollView.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                    scrollToBottom = false
                }
            }
            .onChange(of: viewModel.messages.count) { oldValue, newValue in
                withAnimation {
                    scrollView.scrollTo("bottomAnchor", anchor: .bottom)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
    
    private var messageInputArea: some View {
        VStack(spacing: 0) {
            Divider()
            
            HStack(alignment: .center, spacing: 8) {
                // Text input field
                ZStack(alignment: .leading) {
                    if viewModel.newMessageText.isEmpty {
                        Text("Message")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.leading, 5)
                            .padding(.vertical, 8)
                    }
                    
                    TextField("", text: $viewModel.newMessageText, axis: .vertical)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                        .focused($isInputFocused)
                        .submitLabel(.send)
                        .onSubmit(sendMessage)
                }
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                // Send button
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(
                            viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                .gray : .appButton
                        )
                }
                .disabled(viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
    }
    
    // MARK: - Helper Methods
    
    private func sendMessage() {
        Task {
            await viewModel.sendMessage()
            isInputFocused = true // Keep keyboard open after sending
        }
    }
}

struct MessageBubble: View {
    let message: MessageDisplayModel
    
    var body: some View {
        HStack {
            // Align sender's messages to the right, receiver's to the left
            if message.isFromCurrentUser {
                Spacer()
            } else if let sender = message.sender {
                // Show avatar for messages from others
                if let imageUrl = sender.imageUrl {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 30, height: 30)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 30, height: 30)
                        .overlay(
                            Text(sender.firstName.prefix(1))
                                .font(.footnote)
                                .foregroundColor(.gray)
                        )
                }
            }
            
            VStack(alignment: message.isFromCurrentUser ? .trailing : .leading, spacing: 2) {
                // Message content
                Text(message.content)
                    .padding(10)
                    .background(message.isFromCurrentUser ? Color.appButton : Color(.systemGray5))
                    .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                    .cornerRadius(16)
                
                // Timestamp
                Text(message.formattedTime())
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 4)
                
                // Show media if available
                if let mediaURL = message.mediaURL {
                    AsyncImage(url: mediaURL) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(8)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 150)
                            .cornerRadius(8)
                            .overlay(
                                ProgressView()
                            )
                    }
                    .frame(maxWidth: 200, maxHeight: 200)
                    .padding(.top, 4)
                }
            }
            
            if !message.isFromCurrentUser {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    // Simple preview for ConversationView with sample data
    NavigationStack {
        ConversationViewPreviewView()
    }
}

struct ConversationViewPreviewView: View {
    @State private var newMessageText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat messages
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(SampleData.createSampleMessages()) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                .padding(.bottom, 8)
            }
            
            // Message input area
            HStack(alignment: .center, spacing: 8) {
                // Text input field
                ZStack(alignment: .leading) {
                    if newMessageText.isEmpty {
                        Text("Message")
                            .foregroundColor(Color(.placeholderText))
                            .padding(.leading, 5)
                            .padding(.vertical, 8)
                    }
                    
                    TextField("", text: $newMessageText, axis: .vertical)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 8)
                }
                .background(Color(.systemGray6))
                .cornerRadius(20)
                
                // Send button
                Button(action: {}) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(
                            newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                .gray : .appButton
                        )
                }
                .disabled(newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
        }
        .navigationTitle("Emma Wilson")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {} label: {
                    Image(systemName: "info.circle")
                }
            }
        }
    }
}
