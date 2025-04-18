//
//  HomeViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 07/03/2025.
//

import Foundation

class HomeViewModel: ObservableObject {
    @Published var showingComments = false
    @Published var selectedItemForComments: (any ActivityItem)?
    
    @Published var events: [EventPost] = []
    @Published var betaPosts: [BetaPost] = []
    @Published var friendVisitsToday = 0
    
    @Published var isLoadingEvents = false
    @Published var isLoadingBetas = false
    @Published var errorMessage: String?
    
    @Published var likedItems: Set<String> = []
    @Published var hasError = false
    
    private let activityRepository = ActivityRepositoryService()
    
    // Load featured content for the home page
    func loadFeaturedContent() async {
        await MainActor.run {
            isLoadingEvents = true
            isLoadingBetas = true
        }
        
        do {
            // Try to load featured events first
            var featuredEvents = try await activityRepository.fetchFeaturedItemsByType(type: "event")
                .compactMap { $0 as? EventPost }
                .filter { $0.eventDate > Date() } // Only include future events
                .sorted { $0.eventDate < $1.eventDate } // Sort by date (soonest first)
            
            // If no featured events, fall back to all upcoming events
            if featuredEvents.isEmpty {
                let allActivityItems = try await activityRepository.fetchAllActivityItems()
                featuredEvents = allActivityItems
                    .compactMap { $0 as? EventPost }
                    .filter { $0.eventDate > Date() } // Only include future events
                    .sorted { $0.eventDate < $1.eventDate } // Sort by date (soonest first)
                    .prefix(10) // Limit to 10 events
                    .map { $0 }
            }
            
            // Try to load featured betas first
            var featuredBetas = try await activityRepository.fetchFeaturedItemsByType(type: "beta")
                .compactMap { $0 as? BetaPost }
                .sorted { $0.createdAt > $1.createdAt } // Sort by most recent
            
            // If no featured betas, fall back to recent betas
            if featuredBetas.isEmpty {
                let allActivityItems = try await activityRepository.fetchAllActivityItems()
                featuredBetas = allActivityItems
                    .compactMap { $0 as? BetaPost }
                    .sorted { $0.createdAt > $1.createdAt } // Sort by most recent
                    .prefix(10) // Limit to 10 betas
                    .map { $0 }
            }
            
            await MainActor.run {
                self.events = Array(featuredEvents)
                self.betaPosts = Array(featuredBetas)
                self.isLoadingEvents = false
                self.isLoadingBetas = false
                
                // Just a placeholder value - in a real app, this would come from a query
                self.friendVisitsToday = Int.random(in: 0...5)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.hasError = true
                self.isLoadingEvents = false
                self.isLoadingBetas = false
            }
        }
    }
    
    // Load liked items for the current user
    func loadLikedItems(userId: String) async {
        do {
            let likedItemsArray = try await activityRepository.getUserLikedItems(userId: userId)
            await MainActor.run {
                self.likedItems = Set(likedItemsArray)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.hasError = true
            }
        }
    }
    
    // Check if an item is liked by the current user
    func isItemLiked(itemId: String) -> Bool {
        return likedItems.contains(itemId)
    }
    
    // Like an item
    func likeItem(itemId: String, userId: String) async {
        do {
            try await activityRepository.likeActivityItem(itemId: itemId, userId: userId)
            await MainActor.run {
                likedItems.insert(itemId)
                
                // Update like count in the UI
                updateLikeCount(itemId: itemId, increment: true)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.hasError = true
            }
        }
    }
    
    // Unlike an item
    func unlikeItem(itemId: String, userId: String) async {
        do {
            try await activityRepository.unlikeActivityItem(itemId: itemId, userId: userId)
            await MainActor.run {
                likedItems.remove(itemId)
                
                // Update like count in the UI
                updateLikeCount(itemId: itemId, increment: false)
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.hasError = true
            }
        }
    }
    
    // Helper to update like counts in the UI
    private func updateLikeCount(itemId: String, increment: Bool) {
        // Check in events
        if let index = events.firstIndex(where: { $0.id == itemId }) {
            var updatedEvent = events[index]
            if increment {
                updatedEvent.likeCount += 1
            } else {
                updatedEvent.likeCount = max(0, updatedEvent.likeCount - 1)
            }
            events[index] = updatedEvent
        }
        
        // Check in betas
        if let index = betaPosts.firstIndex(where: { $0.id == itemId }) {
            var updatedBeta = betaPosts[index]
            if increment {
                updatedBeta.likeCount += 1
            } else {
                updatedBeta.likeCount = max(0, updatedBeta.likeCount - 1)
            }
            betaPosts[index] = updatedBeta
        }
    }
    
    // Show comments for an item
    func showCommentsForItem(_ item: any ActivityItem) {
        selectedItemForComments = item
        showingComments = true
    }
    
    // Helper to determine the type of activity item
    func getItemType(from item: any ActivityItem) -> String {
        switch item {
            case is BasicPost: return "basic"
            case is BetaPost: return "beta"
            case is EventPost: return "event"
            case is GroupVisit: return "visit"
            default: return "unknown"
        }
    }
}
