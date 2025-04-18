//
//  Notification.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 04/04/2025.
//

import Foundation

struct Notification: Identifiable, Codable, Equatable {
    let id: String
    let userId: String
    let title: String
    let message: String
    let timestamp: Date
    var isRead: Bool
    let type: NotificationType
    let relatedItemId: String?
    
    enum NotificationType: String, Codable, CaseIterable {
        case like = "like"
        case comment = "comment"
        case follow = "follow"
        case mention = "mention"
        case system = "system"
    }
    
    static func == (lhs: Notification, rhs: Notification) -> Bool {
        return lhs.id == rhs.id
    }
}
