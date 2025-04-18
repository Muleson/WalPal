//
//  ActivityItem.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import Foundation

/// Base protocol that all activity items in the feed must conform to
protocol ActivityItem: Identifiable, Equatable, Codable {
    var id: String { get }
    var author: User { get }
    var createdAt: Date { get }
    var likeCount: Int { get set }
    var commentCount: Int { get set }
    var isFeatured: Bool { get set }
}

// MARK: - Basic Post
struct BasicPost: ActivityItem {
    let id: String
    let author: User
    let content: String
    let mediaURL: URL?
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var isFeatured: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, author, content, mediaURL, createdAt, likeCount, commentCount, isFeatured
    }
}

// MARK: - Beta Post
struct BetaPost: ActivityItem {
    let id: String
    let author: User
    let content: String
    let mediaURL: URL?
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    let gym: Gym
    var viewCount: Int
    var isFeatured: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, author, content, mediaURL, createdAt, likeCount, commentCount, gym, viewCount, isFeatured
    }
}

// MARK: - Event Post
struct EventPost: ActivityItem {
    let id: String
    let author: User
    let title: String
    let description: String?
    let mediaURL: URL?
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    let eventDate: Date
    let location: String
    let maxAttendees: Int
    var registered: Int
    let gym: Gym?
    var isFeatured: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, author, title, description, mediaURL, createdAt, likeCount, commentCount, eventDate, location, maxAttendees, registered, gym, isFeatured
    }
}

// MARK: - Visit
struct GroupVisit: ActivityItem {
    let id: String
    let author: User
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    let gym: Gym
    let visitDate: Date
    let duration: TimeInterval
    let description: String?
    var attendees: [String] // User IDs
    var status: VisitStatus
    var isFeatured: Bool
    
    enum VisitStatus: String, Codable, CaseIterable {
        case planned, ongoing, completed, cancelled
    }
    
    enum CodingKeys: String, CodingKey {
        case id, author, createdAt, likeCount, commentCount, gym, visitDate, duration, description, attendees, status, isFeatured
    }
}
