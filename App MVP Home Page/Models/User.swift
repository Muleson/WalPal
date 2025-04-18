//
//  User.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 05/02/2025.
//

import Foundation

struct User: Identifiable, Equatable, Codable, Hashable {
    let id: String
    let email: String
    let firstName: String
    let lastName: String
    let bio: String?
    let postCount: Int
    let loggedHours: Int
    let imageUrl: URL?
    let createdAt: Date
     
     init(id: String, email: String, firstName: String, lastName: String, bio: String?, postCount: Int, loggedHours: Int, imageUrl: URL?, createdAt: Date) {
         self.id = id
         self.email = email
         self.firstName = firstName
         self.lastName = lastName
         self.bio = bio
         self.postCount = postCount
         self.loggedHours = loggedHours
         self.imageUrl = imageUrl
         self.createdAt = createdAt
     }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(String.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        firstName = try container.decode(String.self, forKey: .firstName)
        lastName = try container.decode(String.self, forKey: .lastName)
        bio = try container.decodeIfPresent(String.self, forKey: .bio)
        postCount = try container.decode(Int.self, forKey: .postCount)
        loggedHours = try container.decode(Int.self, forKey: .loggedHours)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        
        // Handle empty imageUrl
        let urlString = try container.decode(String.self, forKey: .imageUrl)
        imageUrl = urlString.isEmpty ? nil : URL(string: urlString)
    }
}

struct UserRelationship: Identifiable, Codable {
    let id: String
    let followerId: String
    let followingId: String
    let timestamp: Date
    
    init(id: String = UUID().uuidString, followerId: String, followingId: String, timestamp: Date = Date()) {
        self.id = id
        self.followerId = followerId
        self.followingId = followingId
        self.timestamp = timestamp
    }
}
