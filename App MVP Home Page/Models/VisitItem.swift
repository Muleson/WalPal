//
//  VisitItem.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 17/04/2025.
//

import Foundation

struct GymVisit: Identifiable, Codable, Equatable {
    let id: String
    let gym: Gym
    let attendees: [UserVisit]
    let isFavourite: Bool
}

struct UserVisit: Identifiable, Codable, Equatable {
    let id: String
    let visitId: String
    let user: User
    let visitDate: Date
}

struct VisitCollection: Codable, Equatable {
    let favouriteGyms: [GymVisit]
    let friendVisitedGyms: [GymVisit]
}
