//
//  ProfileViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 10/03/2025.
//

import Foundation
import SwiftUI
import FirebaseFirestore

@MainActor
class ProfileViewModel: ObservableObject {
    // Original properties
    @Published var userPosts: [any ActivityItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var hasError = false
    @Published var likedItemIds: Set<String> = []
    
    // User stats
    @Published var postCount: Int = 0
    @Published var betaCount: Int = 0
    @Published var loggedHours: Int = 0
    
    // Edit profile state
    @Published var isEditingProfile = false
    @Published var editedFirstName = ""
    @Published var editedLastName = ""
    @Published var editedBio = ""
    
    // Following properties (from extension)
    @Published var isFollowing = false
    @Published var isFollowProcessing = false
    @Published var followerCount = 0
    @Published var followingCount = 0
    @Published var displayedUser: User?
    @Published var isCurrentUserProfile = true
    
    // Conversation properties
    @Published var isCreatingConversation = false
    @Published var navigateToConversation = false
    @Published var conversationId: String? = nil
    
    // Reference to services
    private let activityRepository = ActivityRepositoryService()
    private let userRepository = UserRepositoryService()
    
    // AppState for getting current user
    var appState: AppState?
    
    // UI component helpers
    var avatarURL: URL? {
        return displayedUser?.imageUrl
    }

    var displayName: String {
        guard let user = displayedUser else { return "" }
        return "\(user.firstName) \(user.lastName)"
    }
    
    // Initialize with AppState
    init(appState: AppState? = nil) {
        self.appState = appState
    }
    
    // Initialize the view model with the appropriate user
    func initializeForUser(profileUser: User?, currentUser: User?) {
        self.displayedUser = profileUser ?? currentUser
        self.isCurrentUserProfile = profileUser == nil || (currentUser != nil && profileUser?.id == currentUser?.id)
    }
    
    // Load all user data in one call
    func loadUserData(profileUser: User?, currentUser: User?) async {
        isLoading = true
        errorMessage = nil
        hasError = false
        
        // Set the displayed user
        initializeForUser(profileUser: profileUser, currentUser: currentUser)
        
        guard let user = displayedUser else {
            isLoading = false
            errorMessage = "No user available"
            hasError = true
            return
        }
        
        do {
            // Fetch user posts
            userPosts = try await activityRepository.fetchUserActivityItems(userId: user.id)
            
            // Fetch user data
            let userData = try await userRepository.getUser(id: user.id)
            
            // Update stats
            postCount = userData.postCount
            loggedHours = userData.loggedHours
            
            // Calculate beta count (number of BetaPost items)
            betaCount = userPosts.filter { $0 is BetaPost }.count
            
            // Load follower and following counts
            await loadFollowCounts(userId: user.id)
            
            // Check follow status if viewing another user's profile
            if !isCurrentUserProfile, let currentUserId = currentUser?.id {
                await checkFollowStatus(profileUserId: user.id, currentUserId: currentUserId)
            }
            
            // Load liked items
            if let userId = currentUser?.id {
                await loadLikedItems(userId: userId)
            }
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
            isLoading = false
        }
    }
    
    // Load user profile (original method for backward compatibility)
    func loadUserProfile(userId: String) async {
        isLoading = true
        errorMessage = nil
        hasError = false
        
        do {
            // Fetch user posts
            userPosts = try await activityRepository.fetchUserActivityItems(userId: userId)
            
            // Fetch user data
            let user = try await userRepository.getUser(id: userId)
            displayedUser = user
            
            // Update stats
            postCount = user.postCount
            loggedHours = user.loggedHours
            
            // Calculate beta count (number of BetaPost items)
            betaCount = userPosts.filter { $0 is BetaPost }.count
            
            // Load follower and following counts
            await loadFollowCounts(userId: userId)
            
            // Load liked items
            await loadLikedItems(userId: userId)
            
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
            isLoading = false
        }
    }
    
    // Check follow relationship status
    func checkFollowStatus(profileUserId: String, currentUserId: String) async {
        guard profileUserId != currentUserId else { return }
        
        do {
            let relationshipService = UserRelationshipService()
            
            // Check follow status
            isFollowing = try await relationshipService.isFollowing(
                followerId: currentUserId,
                followingId: profileUserId
            )
        } catch {
            errorMessage = "Failed to check follow status: \(error.localizedDescription)"
            hasError = true
        }
    }
    
    // Load follower and following counts
    func loadFollowCounts(userId: String) async {
        do {
            let relationshipService = UserRelationshipService()
            
            let followers = try await relationshipService.getFollowers(userId: userId)
            let following = try await relationshipService.getFollowing(userId: userId)
            
            followerCount = followers.count
            followingCount = following.count
        } catch {
            errorMessage = "Failed to load follow counts: \(error.localizedDescription)"
            hasError = true
        }
    }
    
    // Load user's liked items
    func loadLikedItems(userId: String) async {
        do {
            let likedItemsArray = try await activityRepository.getUserLikedItems(userId: userId)
            likedItemIds = Set(likedItemsArray)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    // Check if user has liked an item
    func isItemLiked(itemId: String) -> Bool {
        return likedItemIds.contains(itemId)
    }
    
    // Like an item
    func likeItem(itemId: String, userId: String) async {
        // Prevent liking an item that's already been liked
        guard !isItemLiked(itemId: itemId) else { return }
        
        do {
            try await activityRepository.likeActivityItem(itemId: itemId, userId: userId)
            
            // Add to local liked items set
            likedItemIds.insert(itemId)
            
            // Update the item in our local array
            updateItemLikeCount(itemId: itemId, increment: true)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    // Unlike an item
    func unlikeItem(itemId: String, userId: String) async {
        // Can only unlike an item that's been liked
        guard isItemLiked(itemId: itemId) else { return }
        
        do {
            try await activityRepository.unlikeActivityItem(itemId: itemId, userId: userId)
            
            // Remove from local liked items set
            likedItemIds.remove(itemId)
            
            // Update the item in our local array
            updateItemLikeCount(itemId: itemId, increment: false)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    // Initialize edit form with current user data
    func prepareEditProfile(user: User) {
        editedFirstName = user.firstName
        editedLastName = user.lastName
        editedBio = user.bio ?? ""
        isEditingProfile = true
    }
    
    // Save profile changes
    func saveProfileChanges(userId: String, currentUser: User, updateAppState: @escaping (User) -> Void) async {
        isLoading = true
        
        do {
            // Create updated user object
            let updatedUser = User(
                id: userId,
                email: currentUser.email,
                firstName: editedFirstName,
                lastName: editedLastName,
                bio: editedBio.isEmpty ? nil : editedBio,
                postCount: currentUser.postCount,
                loggedHours: currentUser.loggedHours,
                imageUrl: currentUser.imageUrl,
                createdAt: currentUser.createdAt
            )
            
            // Update in Firestore
            try await userRepository.updateUser(user: updatedUser)
            
            // Update app state
            updateAppState(updatedUser)
            
            // Reset edit state
            isEditingProfile = false
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
            isLoading = false
        }
    }
    
    // Delete a post
    func deletePost(itemId: String) async {
        do {
            try await activityRepository.deleteActivityItem(itemId: itemId)
            
            // Remove the item from our local array
            userPosts.removeAll { item in
                return item.id == itemId
            }
            
            // Update post count
            postCount = max(0, postCount - 1)
            
            // Update beta count if it was a beta post
            if userPosts.first(where: { $0.id == itemId }) is BetaPost {
                betaCount = max(0, betaCount - 1)
            }
            
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    // Navigate to conversation with user
    func navigateToConversationWithUser(currentUserId: String) async {
        guard let profileUser = self.displayedUser else {
                return
            }

        // Don't allow messaging yourself
        if currentUserId == profileUser.id {
            return
        }

            isCreatingConversation = true
            do {
                
                let messageService = MessageService()
                // Create or get existing conversation between the two users
                let conversation = try await messageService.createConversation(
                    between: [currentUserId, profileUser.id]
                )
                self.conversationId = conversation.id
                self.isCreatingConversation = false
                
            } catch {
                
                self.errorMessage = "Error creating conversation: \(error.localizedDescription)"
                self.hasError = true
                self.isCreatingConversation = false
            }
        }
    
    // Follow/unfollow handling with proper error management
    func toggleFollowStatus() async {
        guard let profileUser = displayedUser,
              let currentUser = appState?.user,
              !isCurrentUserProfile else {
            return
        }
        
        isFollowProcessing = true
        
        do {
            let relationshipService = UserRelationshipService()
            
            if isFollowing {
                try await relationshipService.unfollowUser(
                    followerId: currentUser.id,
                    followingId: profileUser.id
                )
                isFollowing = false
                followerCount -= 1
            } else {
                try await relationshipService.followUser(
                    followerId: currentUser.id,
                    followingId: profileUser.id
                )
                isFollowing = true
                followerCount += 1
            }
            
            isFollowProcessing = false
        } catch {
            errorMessage = "Failed to update follow status: \(error.localizedDescription)"
            hasError = true
            isFollowProcessing = false
        }
    }
    
    // Determine if we can show followers list (count > 0)
    func canShowFollowersList() -> Bool {
        return followerCount > 0
    }
    
    // Determine if we can show following list (count > 0)
    func canShowFollowingList() -> Bool {
        return followingCount > 0
    }
    
    // Helper to get the current profile user ID
    func getCurrentProfileId() -> String? {
        return displayedUser?.id
    }
    
    // Join a visit
    func joinVisit(visitId: String, userId: String) async {
        do {
           try await activityRepository.joinVisit(visitId: visitId, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    // Leave a visit
    func leaveVisit(visitId: String, userId: String) async {
        do {
            try await activityRepository.leaveVisit(visitId: visitId, userId: userId)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateItemLikeCount(itemId: String, increment: Bool) {
        for i in 0..<userPosts.count {
            let item = userPosts[i]
            if item.id == itemId {
                var updatedItem = item
                if increment {
                    updatedItem.likeCount += 1
                } else {
                    updatedItem.likeCount = max(0, updatedItem.likeCount - 1)
                }
                userPosts[i] = updatedItem
                break
            }
        }
    }
}
