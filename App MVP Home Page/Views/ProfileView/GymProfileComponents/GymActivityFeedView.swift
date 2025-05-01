//
//  GymActivityFeedView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 28/03/2025.
//

import SwiftUI

struct GymActivityFeedView: View {
    
    @ObservedObject var viewModel: GymProfileViewModel
    @ObservedObject var appState: AppState
    
    // Navigation state (passed from parent view)
    @Binding var navigateToCreateVisit: Bool
    @Binding var navigateToCreateBeta: Bool
    
    // UI state (for comments)
    @Binding var showingComments: Bool
    @Binding var selectedItemForComments: (any ActivityItem)?
    
    // User profile navigation
    @Binding var navigateToUserProfile: User?
    @Binding var showingUserProfile: Bool
    
    let selectedFilter: GymActivityFilter
    
    // Media engagement
    @Binding var selectedMedia: Media?
    @Binding var showFullScreenMedia: Bool
        
    var body: some View {
        if viewModel.isLoadingActivities {
            ProgressView()
                .scaleEffect(1.5)
                .padding(.vertical, 40)
        } else if viewModel.filteredActivities.isEmpty {
            // Empty state with different message based on filter
            VStack(spacing: 16) {
                Image(systemName: selectedFilter.systemImage)
                    .font(.system(size: 50))
                    .foregroundColor(.gray.opacity(0.5))
                
                Text(selectedFilter.emptyStateTitle)
                    .font(.headline)
                
                Text(selectedFilter.emptyStateMessage)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                if selectedFilter == .beta {
                    Button(action: {
                        navigateToCreateBeta = true
                    }) {
                        Text("Post Beta")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .padding(.horizontal, 20)
                            .background(AppTheme.appButton)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(.vertical, 60)
        } else {
            // Activity feed
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.filteredActivities.enumerated()), id: \.element.id) { _, item in
                    activityItemView(for: item)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private func activityItemView(for item: any ActivityItem) -> some View {
        Group {
            if let basicPost = item as? BasicPost {
                BasicPostView(
                    post: basicPost,
                    isLiked: viewModel.isItemLiked(itemId: basicPost.id),
                    onLike: { toggleLike(itemId: basicPost.id) },
                    onComment: { showCommentsForItem(basicPost) },
                    onMediaTap: { media in handleMediaTap(media) },
                    onDelete: isAuthor(of: basicPost) ? { deleteItem(id: basicPost.id) } : nil,
                    onAuthorTapped: { navigateToProfile($0) }
                )
            } else if let betaPost = item as? BetaPost {
                BetaPostView(
                    post: betaPost,
                    isLiked: viewModel.isItemLiked(itemId: betaPost.id),
                    onLike: { toggleLike(itemId: betaPost.id) },
                    onComment: { showCommentsForItem(betaPost) },
                    onMediaTap: { media in handleMediaTap(media) },
                    onDelete: isAuthor(of: betaPost) ? { deleteItem(id: betaPost.id) } : nil,
                    onAuthorTapped: { navigateToProfile($0) }
                )
            } else if let eventPost = item as? EventPost {
                EventPostView(
                    post: eventPost,
                    isLiked: viewModel.isItemLiked(itemId: eventPost.id),
                    onLike: { toggleLike(itemId: eventPost.id) },
                    onComment: { showCommentsForItem(eventPost) },
                    onMediaTap: { media in handleMediaTap(media) },
                    onDelete: isAuthor(of: eventPost) ? { deleteItem(id: eventPost.id) } : nil,
                    onAuthorTapped: { navigateToProfile($0) }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 2)
        )
    }
    
    // Action methods (moved from parent view)
    private func toggleLike(itemId: String) {
        guard let user = appState.user else { return }
        
        Task {
            if viewModel.isItemLiked(itemId: itemId) {
                await viewModel.unlikeItem(itemId: itemId, userId: user.id)
            } else {
                await viewModel.likeItem(itemId: itemId, userId: user.id)
            }
        }
    }
    
    private func deleteItem(id: String) {
        Task {
            await viewModel.deleteActivityItem(itemId: id)
        }
    }
    
    private func showCommentsForItem(_ item: any ActivityItem) {
        selectedItemForComments = item
        showingComments = true
    }
    
    private func navigateToProfile(_ user: User) {
        navigateToUserProfile = user
        showingUserProfile = true
    }
    
    private func handleMediaTap(_ media: Media) {
        selectedMedia = media
        showFullScreenMedia = true
    }
    
    private func isAuthor(of item: any ActivityItem) -> Bool {
        guard let user = appState.user else { return false }
        return item.author.id == user.id
    }
}
