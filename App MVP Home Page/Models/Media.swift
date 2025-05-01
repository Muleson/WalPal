//
//  Media.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 24/04/2025.
//

import Foundation

struct Media: Identifiable, Codable, Equatable {
    let id: String
    let url: URL
    let type: MediaType
    let thumbnailURL: URL?
    let uploadedAt: Date
    let ownerId: String
}

enum MediaType: String, Codable {
    case image
    case video
    case none
}
