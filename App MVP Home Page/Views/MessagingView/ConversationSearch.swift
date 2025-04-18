//
//  ConversationSearch.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 26/03/2025.
//

import SwiftUI

struct ChatSearchView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var users: [User] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    // Closure to be called when a user is selected
    let onUserSelected: (User) -> Void
    
    var body: some View {
        NavigationStack {
            VStack {
                searchResultsContent
            }
            .navigationTitle("New Message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search users")
            .onChange(of: searchText) { oldValue, newValue in
                handleSearchTextChange(newValue)
            }
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "Unknown error"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Extracted Views
    
    @ViewBuilder
    private var searchResultsContent: some View {
        if isLoading {
            ProgressView()
                .scaleEffect(1.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if users.isEmpty {
            emptyStateView
        } else {
            userListView
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if !searchText.isEmpty {
                Text("No users found")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                Text("Search for users")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    
                Text("Type a name in the search bar above")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var userListView: some View {
        List {
            ForEach(users) { user in
                Button {
                    onUserSelected(user)
                } label: {
                    ChatSearchRow(user: user)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .listStyle(.plain)
    }
    
    private func handleSearchTextChange(_ query: String) {
           if !query.isEmpty && query.count >= 2 {
               Task {
                   await searchUsers(query: query)
               }
           }
       }
    
    // MARK: - Methods
    
    private func searchUsers(query: String) async {
        guard let currentUser = appState.user else { return }
        
        isLoading = true
        users = []
        
        // Use MessageService to search for users
        do {
            let messageService = MessageService()
            let searchResults = try await messageService.searchUsers(
                query: query,
                excludeUserId: currentUser.id
            )
            
            // Update state
            isLoading = false
            users = searchResults.sorted { $0.firstName < $1.firstName } // Sort by first name
        } catch {
            errorMessage = "Error searching users: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// User row for the search results
struct ChatSearchRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile picture
            if let imageUrl = user.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(user.firstName.prefix(1))
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                    )
            }
            
            // User details
            VStack(alignment: .leading, spacing: 2) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}
    
