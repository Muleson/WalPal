//
//  NotificationService.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 04/04/2025.
//

import Foundation
import FirebaseFirestore

class NotificationService {
    private let db = Firestore.firestore()
    
    // Fetch user's notifications
    func fetchNotifications(for userId: String, limit: Int = 50) async throws -> [Notification] {
           let query = db.collection("notifications")
               .whereField("userId", isEqualTo: userId)
               .order(by: "timestamp", descending: true)
               .limit(to: limit)
           
           let snapshot = try await query.getDocuments()
           
           return snapshot.documents.compactMap { document in
               // document.data() returns a non-optional [String: Any]
               let data = document.data()
               return Notification(firestoreData: data)
           }
       }
    
    // Mark a single notification as read
    func markAsRead(notificationId: String) async throws {
        try await db.collection("notifications")
            .document(notificationId)
            .updateData(["isRead": true])
    }
    
    // Mark all notifications as read for a user
    func markAllAsRead(for notifications: [Notification]) async throws {
        // Only process unread notifications
        let unreadNotifications = notifications.filter { !$0.isRead }
        
        // If no unread notifications, return early
        if unreadNotifications.isEmpty {
            return
        }
        
        // Create a batch write operation
        let batch = db.batch()
        
        // Add each unread notification to the batch
        for notification in unreadNotifications {
            let docRef = db.collection("notifications").document(notification.id)
            batch.updateData(["isRead": true], forDocument: docRef)
        }
        
        // Commit the batch
        try await batch.commit()
    }
    
    // Create a new notification (useful for sending notifications)
    func createNotification(
        userId: String,
        title: String,
        message: String,
        type: Notification.NotificationType,
        relatedItemId: String? = nil
    ) async throws {
        let notificationId = UUID().uuidString
        
        let notificationData: [String: Any] = [
            "id": notificationId,
            "userId": userId,
            "title": title,
            "message": message,
            "timestamp": Timestamp(date: Date()),
            "isRead": false,
            "type": type.rawValue,
            "relatedItemId": relatedItemId as Any
        ]
        
        try await db.collection("notifications")
            .document(notificationId)
            .setData(notificationData)
    }
}
