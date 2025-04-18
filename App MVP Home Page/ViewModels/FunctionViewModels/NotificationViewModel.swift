//
//  NotificationViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 04/04/2025.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [Notification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var hasError: Bool = false
    
    private let notificationService = NotificationService()
    
    func loadNotifications(for userId: String) async {
        isLoading = true
        errorMessage = nil
        hasError = false
        
        do {
            let fetchedNotifications = try await notificationService.fetchNotifications(for: userId)
            
            self.notifications = fetchedNotifications
            self.unreadCount = fetchedNotifications.filter { !$0.isRead }.count
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasError = true
            self.isLoading = false
        }
    }
    
    func markAsRead(notificationId: String) async {
        do {
            try await notificationService.markAsRead(notificationId: notificationId)
            
            // Update local state
            if let index = notifications.firstIndex(where: { $0.id == notificationId }) {
                var updatedNotification = notifications[index]
                updatedNotification.isRead = true
                notifications[index] = updatedNotification
                
                // Update unread count
                unreadCount = notifications.filter { !$0.isRead }.count
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasError = true
        }
    }
    
    func markAllAsRead(userId: String) async {
        do {
            try await notificationService.markAllAsRead(for: notifications)
            
            // Update local state
            for i in 0..<notifications.count {
                if !notifications[i].isRead {
                    var updatedNotification = notifications[i]
                    updatedNotification.isRead = true
                    notifications[i] = updatedNotification
                }
            }
            unreadCount = 0
        } catch {
            self.errorMessage = error.localizedDescription
            self.hasError = true
        }
    }
}
