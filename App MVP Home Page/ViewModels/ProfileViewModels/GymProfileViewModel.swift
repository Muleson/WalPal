//
//  GymProfileViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 27/03/2025.
//

import Foundation
import SwiftUI

@MainActor
class GymProfileViewModel: ObservableObject {
    // Main data
    @Published var gym: Gym
    @Published var activities: [any ActivityItem] = []
    @Published var filteredActivities: [any ActivityItem] = []
    
    // UI state
    @Published var isLoading = false
    @Published var isLoadingActivities = false
    @Published var hasError = false
    @Published var errorMessage: String?
    @Published var likedItemIds: Set<String> = []
    
    // Admin state
    @Published var isAdministrator = false
    @Published var administratorRole: GymAdministrator.AdminRole?
    
    // Sheets and modals
    @Published var showEditGymSheet = false
    @Published var showManageAdminsSheet = false
    @Published var showDeleteConfirmation = false
    
    // Services
    private let gymService = GymService()
    private let activityRepository = ActivityRepositoryService()
    private let permissionsService = PermissionsService()
    
    
    // Initialize
    init(gym: Gym) {
        self.gym = gym
    }

    // MARK: - Public Methods
    
    /// Load all initial data for the gym profile
    func loadInitialData(currentUser: User?) async {
        isLoading = true
        
        do {
            // If we have a user, check their permissions
            if let user = currentUser {
                try await checkAdminStatus(user: user)
                await loadLikedItems(userId: user.id)
            }
            
            // Load activities for this gym
            await loadGymActivities()
            
            isLoading = false
        } catch {
            errorMessage = "Error loading gym data: \(error.localizedDescription)"
            hasError = true
            isLoading = false
        }
    }
    
    /// Filter activities by type
    func filterActivities(by filter: GymActivityFilter) {
        switch filter {
        case .all:
            filteredActivities = activities
        case .beta:
            filteredActivities = activities.filter { $0 is BetaPost }
        case .event:
            filteredActivities = activities.filter { $0 is EventPost }
        case .visit:
            filteredActivities = activities.filter { $0 is GroupVisit }
        }
    }
    
    /// Get formatted climbing type labels for display
    var climbingTypeLabels: [String] {
        return gym.climbingType.map { climbingType in
            switch climbingType {
            case .bouldering:
                return "Bouldering"
            case .lead:
                return "Lead Climbing"
            case .topRope:
                return "Top Rope"
            }
        }
    }
    
    // MARK: - Action Methods
    
    func likeItem(itemId: String, userId: String) async {
        do {
            try await activityRepository.likeActivityItem(itemId: itemId, userId: userId)
            
            // Add to local liked items set
            likedItemIds.insert(itemId)
            
            // Update the item in our local arrays
            updateItemLikeCount(itemId: itemId, increment: true)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    func unlikeItem(itemId: String, userId: String) async {
        do {
            try await activityRepository.unlikeActivityItem(itemId: itemId, userId: userId)
            
            // Remove from local liked items set
            likedItemIds.remove(itemId)
            
            // Update the item in our local arrays
            updateItemLikeCount(itemId: itemId, increment: false)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    func deleteActivityItem(itemId: String) async {
        do {
            try await activityRepository.deleteActivityItem(itemId: itemId)
            
            // Remove from our local arrays
            activities.removeAll { $0.id == itemId }
            filteredActivities.removeAll { $0.id == itemId }
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    func joinVisit(visitId: String, userId: String) async {
        do {
            try await activityRepository.joinVisit(visitId: visitId, userId: userId)
            
            // Update local data
            updateVisitAttendee(visitId: visitId, userId: userId, isJoining: true)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    func leaveVisit(visitId: String, userId: String) async {
        do {
            try await activityRepository.leaveVisit(visitId: visitId, userId: userId)
            
            // Update local data
            updateVisitAttendee(visitId: visitId, userId: userId, isJoining: false)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    func shareGym() {
        // In a real app, this would use the system share sheet
        // For now, just print that we're sharing
        print("Sharing gym: \(gym.name)")
    }
    
    func updateGym(_ updatedGym: Gym) async {
        isLoading = true
        
        do {
            try await gymService.updateGym(gym: updatedGym)
            
            // Update our local copy
            self.gym = updatedGym
            
            isLoading = false
        } catch {
            errorMessage = "Error updating gym: \(error.localizedDescription)"
            hasError = true
            isLoading = false
        }
    }
    
    func deleteGym() async {
        isLoading = true
        
        do {
            try await gymService.deleteGym(id: gym.id)
            isLoading = false
            
            // In a real app, we'd navigate back to a previous screen here
            print("Gym deleted successfully")
        } catch {
            errorMessage = "Error deleting gym: \(error.localizedDescription)"
            hasError = true
            isLoading = false
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if a specific item is liked by the current user
    func isItemLiked(itemId: String) -> Bool {
        return likedItemIds.contains(itemId)
    }
    
    /// Get appropriate icon for an amenity
    func getAmenityIcon(_ amenity: String) -> String {
        let amenityLowercased = amenity.lowercased()
        
        if amenityLowercased.contains("shower") {
            return "shower"
        } else if amenityLowercased.contains("wifi") {
            return "wifi"
        } else if amenityLowercased.contains("cafe") || amenityLowercased.contains("food") {
            return "cup.and.saucer"
        } else if amenityLowercased.contains("shop") || amenityLowercased.contains("store") {
            return "bag"
        } else if amenityLowercased.contains("parking") {
            return "car"
        } else if amenityLowercased.contains("train") {
            return "train.side.front.car"
        } else if amenityLowercased.contains("locker") {
            return "lock"
        } else if amenityLowercased.contains("gym") || amenityLowercased.contains("workout") {
            return "dumbbell"
        } else if amenityLowercased.contains("sauna") {
            return "flame"
        } else {
            return "checkmark.circle"
        }
    }
    
    // MARK: - Private Methods
    
    private func loadGym(id: String) async {
        do {
            if let loadedGym = try await gymService.fetchGym(id: id) {
                self.gym = loadedGym
            } else {
                errorMessage = "Gym not found"
                hasError = true
            }
        } catch {
            errorMessage = "Error loading gym: \(error.localizedDescription)"
            hasError = true
        }
    }
    
    private func loadGymActivities() async {
        isLoadingActivities = true
        
        do {
            let gymActivities = try await activityRepository.fetchGymActivityItems(gymId: gym.id)
            activities = gymActivities
            filteredActivities = gymActivities // Initially show all
            isLoadingActivities = false
        } catch {
            errorMessage = "Error loading activities: \(error.localizedDescription)"
            hasError = true
            isLoadingActivities = false
        }
    }
    
    private func loadLikedItems(userId: String) async {
        do {
            let likedItems = try await activityRepository.getUserLikedItems(userId: userId)
            likedItemIds = Set(likedItems)
        } catch {
            errorMessage = error.localizedDescription
            hasError = true
        }
    }
    
    private func checkAdminStatus(user: User) async throws {
        // Use PermissionsService to check if user can manage this gym
        let permissionsService = PermissionsService()
        let canManage = try await permissionsService.canManageGym(user: user, gym: gym)
        
        if canManage {
            // Get specific role if they are an admin
            if let role = try await permissionsService.getAdminRole(user: user, gym: gym) {
                isAdministrator = true
                administratorRole = role
            }
        }
    }
    
    private func updateItemLikeCount(itemId: String, increment: Bool) {
        // Update in activities array
        for i in 0..<activities.count {
            let item = activities[i]
            if item.id == itemId {
                var updatedItem = item
                if increment {
                    updatedItem.likeCount += 1
                } else {
                    updatedItem.likeCount = max(0, updatedItem.likeCount - 1)
                }
                activities[i] = updatedItem
                break
            }
        }
        
        // Update in filtered activities array
        for i in 0..<filteredActivities.count {
            let item = filteredActivities[i]
            if item.id == itemId {
                var updatedItem = item
                if increment {
                    updatedItem.likeCount += 1
                } else {
                    updatedItem.likeCount = max(0, updatedItem.likeCount - 1)
                }
                filteredActivities[i] = updatedItem
                break
            }
        }
    }
    
    private func updateVisitAttendee(visitId: String, userId: String, isJoining: Bool) {
        // Update in activities array
        for i in 0..<activities.count {
            if let visit = activities[i] as? GroupVisit, visit.id == visitId {
                var updatedVisit = visit
                
                if isJoining {
                    // Only add if not already attending
                    if !updatedVisit.attendees.contains(userId) {
                        updatedVisit.attendees.append(userId)
                    }
                } else {
                    // Remove if attending
                    updatedVisit.attendees.removeAll { $0 == userId }
                }
                
                activities[i] = updatedVisit
                break
            }
        }
        
        // Update in filtered activities array
        for i in 0..<filteredActivities.count {
            if let visit = filteredActivities[i] as? GroupVisit, visit.id == visitId {
                var updatedVisit = visit
                
                if isJoining {
                    // Only add if not already attending
                    if !updatedVisit.attendees.contains(userId) {
                        updatedVisit.attendees.append(userId)
                    }
                } else {
                    // Remove if attending
                    updatedVisit.attendees.removeAll { $0 == userId }
                }
                
                filteredActivities[i] = updatedVisit
                break
            }
        }
    }
}
