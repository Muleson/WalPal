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
    let mediaItems: [Media]?
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    var isFeatured: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, author, content, mediaItems, createdAt, likeCount, commentCount, isFeatured
    }
}

// MARK: - Beta Post
struct BetaPost: ActivityItem {
    let id: String
    let author: User
    let content: String
    let mediaItems: [Media]?
    let createdAt: Date
    var likeCount: Int
    var commentCount: Int
    let gym: Gym
    var viewCount: Int
    var isFeatured: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, author, content, mediaItems, createdAt, likeCount, commentCount, gym, viewCount, isFeatured
    }
}

// MARK: - Event Post
struct EventPost: ActivityItem {
    let id: String
    let author: User
    let title: String
    let description: String?
    let mediaItems: [Media]?
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
        case id, author, title, description, mediaItems, createdAt, likeCount, commentCount, eventDate, location, maxAttendees, registered, gym, isFeatured
    }
}
