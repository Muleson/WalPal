//
//  GymVisitsViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 11/04/2025.
//

import Foundation
import SwiftUI

class GymVisitViewModel: ObservableObject {
    @Published var favoriteGyms: [GymVisit] = []
    @Published var friendVisitedGyms: [GymVisit] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Services
    private let gymVisitRepository = GymVisitRepository()
    private let gymService = GymService()
    
    // MARK: - Public Methods
    
    /// Load favorite gyms and friend-visited gyms
    func loadVisits(for userId: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            async let favoriteGymsTask = loadFavoriteGyms(userId: userId)
            async let friendGymsTask = loadFriendVisitedGyms(userId: userId)
            
            // Wait for both to complete
            let (favoriteGyms, friendGyms) = try await (favoriteGymsTask, friendGymsTask)
            
            // Filter friend gyms to exclude those already in favorites
            let favoriteGymIds = Set(favoriteGyms.map { $0.gym.id })
            let uniqueFriendGyms = friendGyms.filter { !favoriteGymIds.contains($0.gym.id) }
            
            await MainActor.run {
                self.favoriteGyms = favoriteGyms.sorted { $0.attendees.count > $1.attendees.count }
                self.friendVisitedGyms = uniqueFriendGyms.sorted { $0.attendees.count > $1.attendees.count }
                self.isLoading = false
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Check if the user is visiting a specific gym today
    func isUserVisitingGym(userId: String, gymId: String) -> Bool {
        // Check in favorite gyms
        if let gymVisit = favoriteGyms.first(where: { $0.gym.id == gymId }),
           gymVisit.attendees.contains(where: { $0.user.id == userId }) {
            return true
        }
        
        // Check in friend visited gyms
        if let gymVisit = friendVisitedGyms.first(where: { $0.gym.id == gymId }),
           gymVisit.attendees.contains(where: { $0.user.id == userId }) {
            return true
        }
        
        return false
    }
    
    /// Join a gym visit
    func joinGymVisit(userId: String, gymId: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Add user to the gym visit record
            try await gymVisitRepository.addUserToGymVisit(
                userId: userId,
                gymId: gymId,
                visitTime: Date()
            )
            
            // Refresh visit data
            await loadVisits(for: userId)
            
            await MainActor.run {
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
    
    /// Leave a gym visit
    func leaveGymVisit(userId: String, gymId: String) async -> Bool {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            // Remove user from the gym visit record
            try await gymVisitRepository.removeUserFromGymVisit(
                userId: userId,
                gymId: gymId,
                date: Date()
            )
            
            // Refresh visit data
            await loadVisits(for: userId)
            
            await MainActor.run {
                isLoading = false
            }
            
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            return false
        }
    }
    
    // MARK: - Helper Methods to format data for display
    
    /// Format the list of attendees for display
    func formatAttendeeList(_ attendees: [UserVisit]) -> String {
        let totalAttendees = attendees.count
        let displayedCount = min(3, totalAttendees)
        
        let names = attendees.prefix(displayedCount).map { $0.user.firstName }.joined(separator: ", ")
        
        if totalAttendees > displayedCount {
            return "\(names) + \(totalAttendees - displayedCount) more"
        } else {
            return names
        }
    }
    
    /// Format the visit day for display
    func formatVisitDay(_ date: Date) -> String {
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInTomorrow(date) {
            return "Tomorrow"
        } else {
            // For days within the next week, show the day name
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE" // Day name (e.g., "Monday")
            
            // For dates further in the future, show the short date
            if let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: Date()), to: calendar.startOfDay(for: date)).day, days > 6 {
                formatter.dateFormat = "MMM d" // Short date (e.g., "Jan 15")
            }
            
            return formatter.string(from: date)
        }
    }
    
    /// Format time to AM/PM
    func formatAMPM(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a" // Time with AM/PM
        return formatter.string(from: date)
    }
    
    // MARK: - Private Helper Methods
    
    private func loadFavoriteGyms(userId: String) async throws -> [GymVisit] {
        // 1. Load user's favorite gyms
        let favoriteGyms = try await gymService.getFavoriteGyms(userId: userId)
        
        // 2. Load visits for each favorite gym
        var favoriteGymVisits: [GymVisit] = []
        
        for gym in favoriteGyms {
            let userVisits = try await gymVisitRepository.getGymVisitorsToday(gymId: gym.id)
            
            // Add to results even if no visitors (since it's a favorite gym)
            favoriteGymVisits.append(
                GymVisit(
                    id: gym.id,
                    gym: gym,
                    attendees: userVisits,
                    isFavourite: true
                )
            )
        }
        
        return favoriteGymVisits
    }
    
    private func loadFriendVisitedGyms(userId: String) async throws -> [GymVisit] {
        // Load gyms where friends are visiting
        return try await gymVisitRepository.getGymsWithFriendsToday(userId: userId)
    }
    
    // Helper methods for view binding
    
    /// Check if a user is an attendee of a gym visit
    func isAttendee(userId: String, gymVisit: GymVisit) -> Bool {
        return gymVisit.attendees.contains { $0.user.id == userId }
    }
    
    /// Get a specific user's visit for a gym
    func getUserVisit(userId: String, gymId: String) -> UserVisit? {
        // Check favorite gyms first
        if let gymVisit = favoriteGyms.first(where: { $0.gym.id == gymId }) {
            return gymVisit.attendees.first { $0.user.id == userId }
        }
        
        // Then check friend visited gyms
        if let gymVisit = friendVisitedGyms.first(where: { $0.gym.id == gymId }) {
            return gymVisit.attendees.first { $0.user.id == userId }
        }
        
        return nil
    }
}
