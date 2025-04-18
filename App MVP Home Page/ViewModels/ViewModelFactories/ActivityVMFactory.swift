//
//  ActivityVMFactory.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 09/03/2025.
//

import Foundation

protocol ActivityViewModelFactory {
    func makeActivityViewModel() async -> ActivityViewModel
}

// Default implementation for production use
class DefaultActivityViewModelFactory: ActivityViewModelFactory {
    func makeActivityViewModel() -> ActivityViewModel {
        // Create the real repository
        let _ = ActivityRepositoryService()
        
        // Create and return the view model
        // Note: Since ActivityViewModel is @MainActor,
        // we need to ensure proper initialization
        return ActivityViewModel()
        // If you were to modify ActivityViewModel to accept dependencies:
        // return ActivityViewModel(activityRepository: activityRepository)
    }
}

// Preview implementation for SwiftUI previews
class PreviewActivityViewModelFactory: ActivityViewModelFactory {
    func makeActivityViewModel() -> ActivityViewModel {
        let viewModel = ActivityViewModel()
        
        // Pre-populate with sample data for previews
        // This would happen on the MainActor
        Task { @MainActor in
            viewModel.activityItems = SampleData.createSampleActivityItems()
            viewModel.isLoading = false
        }
        
        return viewModel
    }
}

// Mock implementation for testing
class MockActivityViewModelFactory: ActivityViewModelFactory {
    let mockItems: [any ActivityItem]
    let shouldSimulateError: Bool
    
    init(mockItems: [any ActivityItem] = [], shouldSimulateError: Bool = false) {
        self.mockItems = mockItems
        self.shouldSimulateError = shouldSimulateError
    }
    
    func makeActivityViewModel() -> ActivityViewModel {
        let viewModel = ActivityViewModel()
        
        Task { @MainActor in
            if shouldSimulateError {
                viewModel.errorMessage = "Simulated network error"
                viewModel.hasError = true
            } else {
                viewModel.activityItems = mockItems
            }
            viewModel.isLoading = false
        }
        
        return viewModel
    }
}
