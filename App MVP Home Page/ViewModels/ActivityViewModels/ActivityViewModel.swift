//
//  ActivityViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 28/02/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class ActivityViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var activityItems: [any ActivityItem] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false  // New property to track loading more items
    @Published var errorMessage: String?
    @Published var hasError = false
    @Published var likedItemIds: Set<String> = []
    @Published var hasMoreItems = true  // Flag to indicate if more items are available
    @Published var selectedFilter: ActivityFilter = .all
    
    // MARK: - Pagination Properties
    private let pageSize = 10
    private var lastDocumentSnapshot: DocumentSnapshot?
    
    // MARK: - Private Properties
    private let activityRepository: ActivityRepositoryService
    
    // MARK: - Initializer with Dependency Injection
    init(activityRepository: ActivityRepositoryService = ActivityRepositoryService()) {
        self.activityRepository = activityRepository
        self.isLoading = true
    }
    
    // MARK: - Computed Properties
    
    // Filtered activity items based on selected filter
    var filteredActivityItems: [any ActivityItem] {
        switch selectedFilter {
        case .all:
            return activityItems
        case .beta:
            return activityItems.filter { $0 is BetaPost }
        case .event:
            return activityItems.filter { $0 is EventPost }
        case .visit:
            return activityItems.filter { $0 is GroupVisit }
        }
    }
    
    // MARK: - Pagination Methods
    
    @MainActor
    func fetchAllActivityItems() async {
        // Reset pagination state when fetching from the beginning
        lastDocumentSnapshot = nil
        activityItems = []
        hasMoreItems = true
        
        isLoading = true
        errorMessage = nil
        hasError = false
        
        do {
            let (items, lastDoc, hasMore) = try await activityRepository.fetchPaginatedActivityItems(
                pageSize: pageSize,
                lastDocument: nil
            )
            
            activityItems = items
            lastDocumentSnapshot = lastDoc
            hasMoreItems = hasMore
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
            isLoading = false
        }
    }
    
    @MainActor
    func loadMoreItems() async {
        // Guard against loading if we're already loading or there are no more items
        guard !isLoading, !isLoadingMore, hasMoreItems, lastDocumentSnapshot != nil else {
            return
        }
        
        isLoadingMore = true
        
        do {
            let (newItems, lastDoc, hasMore) = try await activityRepository.fetchPaginatedActivityItems(
                pageSize: pageSize,
                lastDocument: lastDocumentSnapshot
            )
            
            // Append new items to existing items
            activityItems.append(contentsOf: newItems)
            lastDocumentSnapshot = lastDoc
            hasMoreItems = hasMore
            isLoadingMore = false
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
            isLoadingMore = false
        }
    }
    
    // MARK: - Filter Methods
    
    // Handle filter changes - potentially refetch data
    @MainActor
    func filterChanged(to newFilter: ActivityFilter, userId: String?) async {
        // If switching to a filter with no items, we might want to fetch more
        if filteredActivityItems.isEmpty && hasMoreItems {
            await loadMoreItems()
        }
    }
    
    // MARK: - User Activity Methods
    
    // Load user's liked items
    @MainActor
    func loadLikedItems(userId: String) async {
        do {
            let likedItems = try await activityRepository.getUserLikedItems(userId: userId)
            likedItemIds = Set(likedItems)
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
    @MainActor
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
    @MainActor
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
    
    // MARK: - Visit-Specific Methods
    @MainActor
    func joinVisit(visitId: String, userId: String) async {
        do {
            try await activityRepository.joinVisit(visitId: visitId, userId: userId)
            
            // Update local visit data
            if let index = activityItems.firstIndex(where: { ($0 as? GroupVisit)?.id == visitId }) {
                if var visit = activityItems[index] as? GroupVisit {
                    if !visit.attendees.contains(userId) {
                        visit.attendees.append(userId)
                        activityItems[index] = visit
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    @MainActor
    func leaveVisit(visitId: String, userId: String) async {
        do {
            try await activityRepository.leaveVisit(visitId: visitId, userId: userId)
            
            // Update local visit data
            if let index = activityItems.firstIndex(where: { ($0 as? GroupVisit)?.id == visitId }) {
                if var visit = activityItems[index] as? GroupVisit {
                    if let attendeeIndex = visit.attendees.firstIndex(of: userId) {
                        visit.attendees.remove(at: attendeeIndex)
                        activityItems[index] = visit
                    }
                }
            }
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    // Delete an activity item
    @MainActor
    func deleteActivityItem(itemId: String) async {
        do {
            try await activityRepository.deleteActivityItem(itemId: itemId)
            
            // Remove the item from our local array
            activityItems.removeAll { item in
                return item.id == itemId
            }
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    // MARK: - Helper Methods
    @MainActor
    private func updateItemLikeCount(itemId: String, increment: Bool) {
        for i in 0..<activityItems.count {
            let item = activityItems[i]
            if item.id == itemId {
                var updatedItem = item
                if increment {
                    updatedItem.likeCount += 1
                } else {
                    updatedItem.likeCount = max(0, updatedItem.likeCount - 1)
                }
                activityItems[i] = updatedItem
                break
            }
        }
    }
    
    @MainActor
    func updateItemCommentCount(itemId: String, increment: Bool) {
        for i in 0..<activityItems.count {
            let item = activityItems[i]
            if item.id == itemId {
                var updatedItem = item
                if increment {
                    updatedItem.commentCount += 1
                } else {
                    updatedItem.commentCount = max(0, updatedItem.commentCount - 1)
                }
                activityItems[i] = updatedItem
                break
            }
        }
    }
    
    // MARK: - Activity Filter Enum
    enum ActivityFilter: String {
        case all = "All"
        case beta = "Betas"
        case event = "Events"
        case visit = "Visits"
        
        var systemImage: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .beta: return "figure.climbing"
            case .event: return "calendar"
            case .visit: return "mappin.and.ellipse"
            }
        }
    }
}
