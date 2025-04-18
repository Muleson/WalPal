//
//  RelationshipViews.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 05/03/2025.
//

import SwiftUI

struct FollowersListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FollowListViewModel()
    let userId: String
    let appState: AppState
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.users.isEmpty {
                    VStack {
                        Text("No followers yet")
                            .font(.headline)
                        Text("When people follow you, they'll appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding(.top, 50)
                } else {
                    List {
                        ForEach(viewModel.users) { user in
                            UserRow(
                                user: user,
                                isCurrentUser: user.id == appState.user?.id,
                                isFollowing: viewModel.followingMap[user.id] ?? false,
                                onFollowTapped: {
                                    Task {
                                        if let currentUser = appState.user {
                                            if viewModel.followingMap[user.id] ?? false {
                                                await viewModel.unfollowUser(
                                                    followerId: currentUser.id,
                                                    followingId: user.id
                                                )
                                            } else {
                                                await viewModel.followUser(
                                                    followerId: currentUser.id,
                                                    followingId: user.id
                                                )
                                            }
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Followers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadFollowers(userId: userId)
                    
                    if let currentUser = appState.user {
                        await viewModel.checkFollowingStatus(currentUserId: currentUser.id)
                    }
                }
            }
        }
    }
}

// FollowingListView.swift

struct FollowingListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = FollowListViewModel()
    let userId: String
    let appState: AppState
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if viewModel.users.isEmpty {
                    VStack {
                        Text("Not following anyone yet")
                            .font(.headline)
                        Text("When you follow people, they'll appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding()
                    }
                    .padding(.top, 50)
                } else {
                    List {
                        ForEach(viewModel.users) { user in
                            UserRow(
                                user: user,
                                isCurrentUser: user.id == appState.user?.id,
                                isFollowing: true, // Already following these users
                                onFollowTapped: {
                                    Task {
                                        if let currentUser = appState.user {
                                            await viewModel.unfollowUser(
                                                followerId: currentUser.id,
                                                followingId: user.id
                                            )
                                        }
                                    }
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Following")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadFollowing(userId: userId)
                }
            }
        }
    }
}

// UserRow.swift

struct UserRow: View {
    let user: User
    let isCurrentUser: Bool
    let isFollowing: Bool
    let onFollowTapped: () -> Void
    
    var body: some View {
        HStack {
            // User avatar
            if let imageUrl = user.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(user.firstName.prefix(1))
                            .font(.title3)
                            .foregroundColor(.gray)
                    )
            }
            
            // User info
            VStack(alignment: .leading) {
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
            
            // Follow/Unfollow button
            if !isCurrentUser {
                Button(action: onFollowTapped) {
                    Text(isFollowing ? "Unfollow" : "Follow")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(isFollowing ? Color.gray.opacity(0.2) : Color.blue)
                        .foregroundColor(isFollowing ? .primary : .white)
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// FollowListViewModel.swift

class FollowListViewModel: ObservableObject {
    @Published var users: [User] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var followingMap: [String: Bool] = [:]
    
    private let relationshipService = UserRelationshipService()
    
    func loadFollowers(userId: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let followers = try await relationshipService.getFollowers(userId: userId)
            
            await MainActor.run {
                self.users = followers
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func loadFollowing(userId: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let following = try await relationshipService.getFollowing(userId: userId)
            
            await MainActor.run {
                self.users = following
                self.isLoading = false
                
                // Mark all as being followed
                for user in following {
                    self.followingMap[user.id] = true
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func checkFollowingStatus(currentUserId: String) async {
        for user in users {
            do {
                let isFollowing = try await relationshipService.isFollowing(
                    followerId: currentUserId,
                    followingId: user.id
                )
                
                await MainActor.run {
                    self.followingMap[user.id] = isFollowing
                }
            } catch {
                print("Error checking follow status: \(error)")
            }
        }
    }
    
    func followUser(followerId: String, followingId: String) async {
        do {
            try await relationshipService.followUser(
                followerId: followerId,
                followingId: followingId
            )
            
            await MainActor.run {
                self.followingMap[followingId] = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func unfollowUser(followerId: String, followingId: String) async {
        do {
            try await relationshipService.unfollowUser(
                followerId: followerId,
                followingId: followingId
            )
            
            await MainActor.run {
                self.followingMap[followingId] = false
                
                // Remove from list if in following view
                if self.users.contains(where: { $0.id == followingId }) {
                    self.users.removeAll { $0.id == followingId }
                }
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }
}
