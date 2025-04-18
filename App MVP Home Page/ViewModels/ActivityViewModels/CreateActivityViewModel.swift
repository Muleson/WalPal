//
//  CreateActivityViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import Foundation
import SwiftUI

enum ActivityType: String, CaseIterable {
    case basic = "Basic Post"
    case beta = "Beta"
    case event = "Event"
    case visit = "Gym Visit"
}

class CreateActivityViewModel: ObservableObject {
    // Common properties
    @Published var selectedType: ActivityType = .basic
    @Published var content: String = ""
    @Published var mediaURL: URL?
    @Published var showMediaPicker = false
    @Published var selectedGymId: String = ""
    @Published var gyms: [Gym] = []
    @Published var isLoadingGyms = false
    
    // Beta-specific properties
    @Published var difficulty: String = ""
    @Published var routeName: String = ""
    
    // Event-specific properties
    @Published var eventTitle: String = ""
    @Published var eventDescription: String = ""
    @Published var eventDate = Date()
    @Published var eventLocation = ""
    @Published var maxAttendees = 10
    
    // Visit-specific properties
    @Published var visitDate = Date()
    @Published var visitDuration: Double = 2.0 // hours
    @Published var visitDescription: String = ""
    
    // Status properties
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    private let activityRepository = ActivityRepositoryService()
    private var _preselectedGym: Gym?

    
    // MARK: - Validation
    
    var isFormValid: Bool {
        switch selectedType {
        case .basic:
            return !content.isEmpty
        case .beta:
            return !content.isEmpty && !selectedGymId.isEmpty
        case .event:
            return !eventTitle.isEmpty && !eventLocation.isEmpty
        case .visit:
            return !selectedGymId.isEmpty && visitDuration > 0
        }
    }
    
    // MARK: - Creation Methods
    
    @MainActor
    func createActivityItem(author: User) async {
        guard isFormValid else { return }
        
        isLoading = true
        
        do {
            switch selectedType {
            case .basic:
                try await createBasicPost(author: author)
            case .beta:
                try await createBetaPost(author: author)
            case .event:
                try await createEventPost(author: author)
            case .visit:
                try await createVisit(author: author)
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
                isLoading = false
            }
        }
    }
    
    private func createBasicPost(author: User) async throws {
        _ = try await activityRepository.createBasicPost(
            author: author,
            content: content,
            mediaURL: mediaURL
        )
    }
    
    private func createBetaPost(author: User) async throws {
        // First, fetch the gym
        let gymService = GymService()
        guard let gym = try await gymService.fetchGym(id: selectedGymId) else {
            throw NSError(
                domain: "CreateActivityViewModel",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Selected gym not found"]
            )
        }
        
        _ = try await activityRepository.createBetaPost(
            author: author,
            content: content,
            gym: gym,
            mediaURL: mediaURL
        )
    }
    
    private func createEventPost(author: User) async throws {
        // Fetch gym if selected
        var gym: Gym?
        if !selectedGymId.isEmpty {
            let gymService = GymService()
            gym = try await gymService.fetchGym(id: selectedGymId)
        }
        
        _ = try await activityRepository.createEventPost(
            author: author,
            title: eventTitle,
            description: eventDescription.isEmpty ? nil : eventDescription,
            eventDate: eventDate,
            location: eventLocation,
            maxAttendees: maxAttendees,
            gym: gym,
            mediaURL: mediaURL
        )
    }
    
    private func createVisit(author: User) async throws {
        // First, fetch the gym
        let gymService = GymService()
        guard let gym = try await gymService.fetchGym(id: selectedGymId) else {
            throw NSError(
                domain: "CreateActivityViewModel",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Selected gym not found"]
            )
        }
        
        _ = try await activityRepository.createVisit(
            author: author,
            gym: gym,
            visitDate: visitDate,
            duration: visitDuration * 3600, // Convert hours to seconds
            description: visitDescription.isEmpty ? nil : visitDescription
        )
    }
    
    // MARK: - Load Operations
    
    @MainActor
    func loadGyms() async {
    
        isLoadingGyms = true
        
        let gymService = GymService()
        do {
            try await gymService.fetchGyms()
            await MainActor.run {
                self.gyms = gymService.gyms
                self.isLoadingGyms = false
                
                // If we already had a gym selected but it's no longer available,
                // reset the selection
                if !selectedGymId.isEmpty && !gyms.contains(where: { $0.id == selectedGymId }) {
                    selectedGymId = ""
                }
            }
        } catch {
            await MainActor.run {
                self.isLoadingGyms = false
                self.errorMessage = "Failed to load gyms: \(error.localizedDescription)"
                self.showError = true
            }
        }
    }

    //MARK: - Create activity for selected gym
    var preselectedGym: Gym? {
        get {
            return _preselectedGym
        }
        set {
            _preselectedGym = newValue
            if let gym = newValue {
                selectedGymId = gym.id
            }
        }
    }
}
