//
//  HomeVMFactory.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 07/03/2025.
//

import Foundation

protocol HomeViewModelFactory {
    func makeHomeViewModel() -> HomeViewModel
}

// Production factory that creates real view models
class DefaultHomeViewModelFactory: HomeViewModelFactory {
    func makeHomeViewModel() -> HomeViewModel {
        return HomeViewModel()
    }
}

// Preview factory that creates pre-populated view models for previews
class PreviewHomeViewModelFactory: HomeViewModelFactory {
    func makeHomeViewModel() -> HomeViewModel {
        let viewModel = HomeViewModel()
        
        // Populate with preview data
        viewModel.isLoadingEvents = false
        viewModel.isLoadingBetas = false
        viewModel.friendVisitsToday = 3
        
        // Sample events
        viewModel.events = [
            EventPost(
                id: "event1",
                author: SampleData.previewUser,
                title: "Bouldering Competition",
                description: "Annual bouldering competition with prizes!",
                mediaItems: [SampleData.createSampleMediaItem(type: .image, id: "event1-image")],
                createdAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                likeCount: 24,
                commentCount: 7,
                eventDate: Date().addingTimeInterval(86400 * 5), // 5 days from now
                location: "Boulder Gym Main Hall",
                maxAttendees: 50,
                registered: 32,
                gym: SampleData.previewGym,
                isFeatured: true
            ),
            EventPost(
                id: "event2",
                author: SampleData.previewUser,
                title: "Beginner Workshop",
                description: "Learn the basics of climbing",
                mediaItems: [],
                createdAt: Date().addingTimeInterval(-86400 * 1), // 1 day ago
                likeCount: 12,
                commentCount: 3,
                eventDate: Date().addingTimeInterval(86400 * 3), // 3 days from now
                location: "Training Room",
                maxAttendees: 15,
                registered: 8,
                gym: SampleData.previewGym,
                isFeatured: true
            )
        ]
        
        // Sample beta posts
        viewModel.betaPosts = [
            BetaPost(
                id: "beta1",
                author: SampleData.previewUser,
                content: "Here's how to solve the tricky overhang on the red route",
                mediaItems: [SampleData.createSampleMediaItem(type: .video, id: "beta1-video")],
                createdAt: Date().addingTimeInterval(-3600 * 5), // 5 hours ago
                likeCount: 18,
                commentCount: 6,
                gym: SampleData.previewGym,
                viewCount: 95,
                isFeatured: true
            ),
            BetaPost(
                id: "beta2",
                author: SampleData.previewUser,
                content: "Footwork technique for the yellow V4",
                mediaItems: [],
                createdAt: Date().addingTimeInterval(-3600 * 12), // 12 hours ago
                likeCount: 11,
                commentCount: 2,
                gym: SampleData.previewGym,
                viewCount: 42,
                isFeatured: true
            )
        ]
        
        return viewModel
    }
}

// Mock factory for testing that can be configured with customized behavior
class MockHomeViewModelFactory: HomeViewModelFactory {
    var mockViewModel: HomeViewModel
    
    init(mockViewModel: HomeViewModel = HomeViewModel()) {
        self.mockViewModel = mockViewModel
    }
    
    func makeHomeViewModel() -> HomeViewModel {
        return mockViewModel
    }
}
