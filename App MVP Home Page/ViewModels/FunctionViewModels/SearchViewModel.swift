//
//  SearchViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 20/03/2025.
//

import Foundation
import FirebaseFirestore
import SwiftUI

class SearchViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var searchResults: [SearchResult] = []
    @Published var selectedFilter: SearchFilter = .all
    @Published var errorMessage: String?
    @Published var hasError = false
    
    // Services
    private let activityRepository = ActivityRepositoryService()
    private let userRepository = UserRepositoryService()
    
    // MARK: - Search Result Types
    enum SearchFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case users = "Users"
        case betas = "Betas"
        case events = "Events"
        case visits = "Visits"
        
        var id: String { self.rawValue }
        
        var systemImage: String {
            switch self {
            case .all: return "square.grid.2x2"
            case .users: return "person"
            case .betas: return "figure.climbing"
            case .events: return "calendar"
            case .visits: return "mappin.and.ellipse"
            }
        }
    }
    
    // Unified search result type
    enum SearchResult: Identifiable {
        case user(User)
        case beta(BetaPost)
        case event(EventPost)
        
        var id: String {
            switch self {
            case .user(let user): return "user-\(user.id)"
            case .beta(let beta): return "beta-\(beta.id)"
            case .event(let event): return "event-\(event.id)"
            }
        }
    }
    
    // MARK: - Methods
    
    func search() async {
        // Don't search if query is too short
        guard searchText.count >= 2 else {
            await MainActor.run {
                self.searchResults = []
                self.isSearching = false
            }
            return
        }
        
        await MainActor.run {
            self.isSearching = true
            self.hasError = false
            self.errorMessage = nil
        }
        
        do {
            var results: [SearchResult] = []
            
            // Search users if we're on all or users tab
            if selectedFilter == .all || selectedFilter == .users {
                let userResults = try await searchUsers(query: searchText)
                results.append(contentsOf: userResults.map { .user($0) })
            }
            
            // Search activities based on the selected filter
            if selectedFilter != .users {
                let activityResults = try await searchActivities(query: searchText)
                results.append(contentsOf: activityResults)
            }
            
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.hasError = true
                self.isSearching = false
            }
        }
    }
    
    func cancelSearch() {
        searchText = ""
        searchResults = []
    }
    
    // MARK: - Private Methods
    private func searchUsers(query: String) async throws -> [User] {
        // Delegate to the repository service
        return try await userRepository.searchUsers(query: query)
    }
    
    private func searchActivities(query: String) async throws -> [SearchResult] {
        var results: [SearchResult] = []
        let normalizedQuery = query.lowercased()
        
        let allActivities = try await activityRepository.fetchAllActivityItems()
        
        for activity in allActivities {
            // Filter based on selected category
            switch activity {
            case let beta as BetaPost:
                if (selectedFilter == .all || selectedFilter == .betas) &&
                   (beta.content.lowercased().contains(normalizedQuery) ||
                    beta.gym.name.lowercased().contains(normalizedQuery)) {
                    results.append(.beta(beta))
                }
                
            case let event as EventPost:
                if (selectedFilter == .all || selectedFilter == .events) &&
                   (event.title.lowercased().contains(normalizedQuery) ||
                    event.description?.lowercased().contains(normalizedQuery) ?? false ||
                    event.location.lowercased().contains(normalizedQuery) ||
                    event.gym?.name.lowercased().contains(normalizedQuery) ?? false) {
                    results.append(.event(event))
                }
                
            case let basic as BasicPost:
                if selectedFilter == .all &&
                   basic.content.lowercased().contains(normalizedQuery) {
                    // Basic posts are only included if on "All" filter
                    // You could add another category for these if desired
                }
                
            default:
                break
            }
        }
        
        return results
    }
}
