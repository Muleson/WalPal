//
//  Comment.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 05/02/2025.
//

import Foundation

struct Comment: Identifiable, Equatable, Codable {
    var author: User
    var content: String
    var timeStamp = Date()
    var id = UUID()
}
