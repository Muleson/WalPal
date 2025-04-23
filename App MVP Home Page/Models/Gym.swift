//
//  Gym.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 15/02/2025.
//

import Foundation
import FirebaseFirestore

struct Gym: Identifiable, Equatable, Codable {
    let id: String
    let email: String
    let name: String
    let description: String?
    let locaiton: String
    let climbingType: [ClimbingTypes]
    let amenities: [String]
    let events: [String]
    let imageUrl: URL?
    let createdAt: Date
}

struct GymAdministrator: Identifiable, Codable {
    let id: String
    let userId: String
    let gymId: String
    let role: AdminRole
    let addedAt: Date
    let addedBy: String
    
    enum AdminRole: String, Codable {
        case owner
        case admin
        case manager
    }
}

enum ClimbingTypes: String, Codable, CaseIterable {
    case bouldering
    case lead
    case topRope
}

struct GymFavorite: Identifiable, Codable, Equatable {
    let userId: String
    let gymId: String
    
    var id: String {
        return "\(userId)-\(gymId)"
    }
}
