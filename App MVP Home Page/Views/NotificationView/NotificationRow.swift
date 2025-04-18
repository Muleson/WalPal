//
//  NotificationRow.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 04/04/2025.
//

import SwiftUI

struct NotificationRow: View {
    let notification: Notification
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon based on notification type
                Circle()
                    .fill(notificationColor)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: notificationIcon)
                            .foregroundColor(.white)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .regular : .semibold)
                        .foregroundColor(.primary)
                    
                    Text(notification.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                    
                    Text(timeAgo(from: notification.timestamp))
                        .font(.caption2)
                }
                
                Spacer()
                
                if !notification.isRead {
                    Circle()
                        .fill(AppTheme.appButton)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var notificationIcon: String {
        switch notification.type {
        case .like:
            return "heart.fill"
        case .comment:
            return "bubble.right.fill"
        case .follow:
            return "person.badge.plus.fill"
        case .mention:
            return "at"
        case .system:
            return "bell.fill"
        }
    }
    
    private var notificationColor: Color {
        switch notification.type {
        case .like:
            return .red
        case .comment:
            return .blue
        case .follow:
            return .green
        case .mention:
            return .purple
        case .system:
            return .orange
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    List {
        NotificationRow(
            notification: Notification(
                id: "1",
                userId: "user1",
                title: "New Like",
                message: "John liked your post about climbing",
                timestamp: Date().addingTimeInterval(-3600),
                isRead: false,
                type: .like,
                relatedItemId: "post1"
            ),
            onTap: {}
        )
        
        NotificationRow(
            notification: Notification(
                id: "2",
                userId: "user1",
                title: "New Comment",
                message: "Emma commented on your beta: 'This was really helpful!'",
                timestamp: Date().addingTimeInterval(-86400),
                isRead: true,
                type: .comment,
                relatedItemId: "beta1"
            ),
            onTap: {}
        )
        
        NotificationRow(
            notification: Notification(
                id: "3",
                userId: "user1",
                title: "New Follower",
                message: "Alex is now following you",
                timestamp: Date().addingTimeInterval(-604800),
                isRead: false,
                type: .follow,
                relatedItemId: "user2"
            ),
            onTap: {}
        )
    }
    .listStyle(.plain)
}
