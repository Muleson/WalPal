//
//  MessageListView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 25/03/2025.
//

import SwiftUI

struct ConversationListView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: ConversationListViewModel
    @State private var searchText = ""
    @State private var showingUserSearch = false
    
    init(appState: AppState) {
        self.appState = appState
        // Initialize ViewModel with current user ID
        _viewModel = StateObject(wrappedValue: ConversationListViewModel(currentUserId: appState.user?.id ?? ""))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    // Conversation list
                    if viewModel.isLoading && viewModel.conversations.isEmpty {
                        ProgressView()
                            .scaleEffect(1.5)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if viewModel.conversations.isEmpty {
                        emptyStateView
                    } else {
                        List {
                            ForEach(filteredConversations) { conversation in
                                NavigationLink(destination: ConversationView(appState: appState, conversationId: conversation.id)) {
                                    ConversationRow(conversation: conversation)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                        .refreshable {
                            if (appState.user?.id) != nil {
                                await viewModel.loadConversations()
                            }
                        }
                    }
                }
                
                // Floating action button for new message
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showingUserSearch = true
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(AppTheme.appButton))
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Messages")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search conversations")
            .onAppear {
                Task {
                    if (appState.user?.id) != nil {
                        await viewModel.loadConversations()
                    }
                }
            }
            .onDisappear {
                viewModel.cleanup()
            }
            .sheet(isPresented: $showingUserSearch) {
                ChatSearchView(appState: appState) { user in
                    // When a user is selected, create a conversation with them
                    Task {
                        if (await viewModel.createConversation(with: user.id)) != nil {
                            // Navigate to the conversation
                            showingUserSearch = false
                            // Note: In a full implementation, you'd navigate to the conversation
                            // This would require additional navigation state or a coordinator
                        }
                    }
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
    }
    
    // MARK: - Computed Properties
    
    /// Filter conversations based on search text
    private var filteredConversations: [ConversationDisplayModel] {
        if searchText.isEmpty {
            return viewModel.conversations
        } else {
            return viewModel.conversations.filter { conversation in
                let name = conversation.getDisplayName().lowercased()
                let message = conversation.lastMessage.lowercased()
                let searchLower = searchText.lowercased()
                
                return name.contains(searchLower) || message.contains(searchLower)
            }
        }
    }
    
    // MARK: - View Components
    
    /// Empty state view when no conversations exist
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 70))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No conversations yet")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Start a new conversation by tapping the button below")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button {
                showingUserSearch = true
            } label: {
                Text("Start a conversation")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 20)
                    .background(AppTheme.appButton)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

#Preview {
    // Simple preview for ConversationListView with sample data
    NavigationStack {
        ConversationListPreviewView()
    }
}

struct ConversationListPreviewView: View {
    var body: some View {
        List {
            ForEach(SampleData.createSampleConversations()) { conversation in
                ConversationRow(conversation: conversation)
            }
        }
        .navigationTitle("Messages")
    }
}
