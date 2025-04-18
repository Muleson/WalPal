//
//  VisitsViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 08/03/2025.
//

import Foundation

class VisitsViewModel: ObservableObject {
    @Published var gymVisits: [GymWithVisits] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Attendee management
    @Published var attendeesByVisitId: [String: [User]] = [:]
    @Published var isLoadingAttendeesByVisitId: [String: Bool] = [:]
    
    @Published var navigateToCreateVisit = false
    @Published var selectedGymId = ""
    
    private let activityRepository = ActivityRepositoryService()
    private let userRepository = UserRepositoryService()
    
    // MARK: - Public Methods
    
    func loadFriendsVisits(for userId: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let visits = try await activityRepository.fetchFriendsVisitsToday(userId: userId)
            
            await MainActor.run {
                self.gymVisits = visits
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Attendee Management
    
    /// Load attendee information for a specific visit
    @MainActor
    func loadAttendeesForVisit(visitId: String, attendeeIds: [String]) async {
        // Mark as loading
        isLoadingAttendeesByVisitId[visitId] = true
        
        // Only load up to 3 attendees for efficiency
        let idsToLoad = Array(attendeeIds.prefix(3))
        
        do {
            let users = try await userRepository.getUsers(ids: idsToLoad)
            
            // Store the loaded users
            attendeesByVisitId[visitId] = users
            isLoadingAttendeesByVisitId[visitId] = false
        } catch {
            print("Error loading attendees for visit \(visitId): \(error)")
            isLoadingAttendeesByVisitId[visitId] = false
        }
    }
    
    /// Get the loaded attendees for a specific visit
    func getAttendeesForVisit(visitId: String) -> [User] {
        return attendeesByVisitId[visitId] ?? []
    }
    
    /// Check if attendees are currently loading for a visit
    func isLoadingAttendeesForVisit(visitId: String) -> Bool {
        return isLoadingAttendeesByVisitId[visitId] ?? false
    }
    
    // MARK: - Formatting Methods
    
    /// Format attendee names for display
    func formatAttendeeNames(visitId: String, totalAttendees: Int) -> String {
        let attendees = getAttendeesForVisit(visitId: visitId)
        let displayedCount = min(3, attendees.count)
        
        let names = attendees.prefix(displayedCount).map { "\($0.firstName)" }.joined(separator: ", ")
        
        if totalAttendees > displayedCount {
            return "\(names) + \(totalAttendees - displayedCount) more"
        } else {
            return names
        }
    }
    
    /// Format the visit date to show "Today", "Tomorrow", or the day name
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
    
    /// Determine if the visit is in AM or PM
    func isAMorPM(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a" // AM/PM
        return formatter.string(from: date)
    }
    
    // MARK: - Visit Interactions
    
    /// Join a visit
    @MainActor
    func joinVisit(visitId: String, userId: String) async {
        do {
            try await activityRepository.joinVisit(visitId: visitId, userId: userId)
            
            // Update local state if needed
            // This might involve refreshing data or updating specific visit objects
        } catch {
            errorMessage = "Failed to join visit: \(error.localizedDescription)"
        }
    }
    
    /// Leave a visit
    @MainActor
    func leaveVisit(visitId: String, userId: String) async {
        do {
            try await activityRepository.leaveVisit(visitId: visitId, userId: userId)
            
            // Update local state if needed
        } catch {
            errorMessage = "Failed to leave visit: \(error.localizedDescription)"
        }
    }
}
