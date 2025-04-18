//
//  NotificationsView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 04/04/2025.
//

import SwiftUI

struct NotificationsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = NotificationViewModel()
    @Environment(\.dismiss) private var dismiss
    
    // State for navigation
    @State private var navigateToRelatedItem: String? = nil
    @State private var navigateToProfile: User? = nil
    @State private var navigationType: Notification.NotificationType? = nil
    
    var body: some View {
        ZStack {
            // Main content
            if viewModel.isLoading && viewModel.notifications.isEmpty {
                ProgressView()
                    .scaleEffect(1.5)
            } else if viewModel.notifications.isEmpty {
                emptyStateView
            } else {
                notificationsList
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !viewModel.notifications.isEmpty && viewModel.unreadCount > 0 {
                    Button("Mark All Read") {
                        if let userId = appState.user?.id {
                            Task {
                                await viewModel.markAllAsRead(userId: userId)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            if let userId = appState.user?.id {
                Task {
                    await viewModel.loadNotifications(for: userId)
                }
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.hasError },
            set: { if !$0 { viewModel.errorMessage = nil; viewModel.hasError = false } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 50))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No Notifications")
                .font(.headline)
            
            Text("You'll see notifications here when someone interacts with your content")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
    
    private var notificationsList: some View {
        List {
            ForEach(viewModel.notifications) { notification in
                NotificationRow(
                    notification: notification,
                    onTap: {
                        // Mark as read when tapped
                        Task {
                            await viewModel.markAsRead(notificationId: notification.id)
                        }
                        
                        // Note: In a real implementation, you would handle navigation
                        // based on the notification type and related item ID
                        handleNotificationTap(notification)
                    }
                )
                .listRowSeparator(.hidden)
                .listRowBackground(
                    notification.isRead ? Color.clear : Color.appButton.opacity(0.05)
                )
            }
        }
        .listStyle(.plain)
        .refreshable {
            if let userId = appState.user?.id {
                await viewModel.loadNotifications(for: userId)
            }
        }
    }
    
    private func handleNotificationTap(_ notification: Notification) {
        // This would handle navigation based on notification type and relatedItemId
        // For now, just print the action for debugging
        print("Tapped notification: \(notification.type.rawValue), related item: \(notification.relatedItemId ?? "none")")
        
        // In a real implementation, you would set navigation state variables
        // and use NavigationDestination to navigate to the appropriate view
    }
}

#Preview {
    NavigationStack {
        NotificationsView(appState: {
            let state = AppState()
            state.user = User(
                id: "preview-user",
                email: "user@example.com",
                firstName: "Preview",
                lastName: "User",
                bio: nil,
                postCount: 5,
                loggedHours: 30,
                imageUrl: nil,
                createdAt: Date()
            )
            return state
        }())
    }
}
