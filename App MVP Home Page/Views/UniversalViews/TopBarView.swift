//
//  TopBarView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 20/03/2025.
//

import SwiftUI

struct TopNavBar: View {
    @State private var navigateToMessages = false
    @State private var navigateToSearch = false
    @State private var navigateToNotifications = false

    @ObservedObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 16) {
                // Search button
                Button(action: {
                    navigateToSearch = true
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(AppTheme.appTextPrimary)
                        .font(.system(size: 20))
                }
        
                Spacer()
                
                // Notification Bell button
               Button(action: {
                   navigateToNotifications = true
               }) {
                   Image(systemName: "bell")
                       .foregroundColor(AppTheme.appTextPrimary)
                       .font(.system(size: 20))
               }
                
                // Message button
                Button(action: {
                    navigateToMessages = true
                }) {
                    Image(systemName: "message")
                        .foregroundColor(AppTheme.appTextPrimary)
                        .font(.system(size: 20))
                }
                
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.systemBackground))
        .navigationDestination(isPresented: $navigateToMessages) {
            ConversationListView(appState: appState)
        }
        .navigationDestination(isPresented: $navigateToNotifications) { NotificationsView(appState: appState)
        }
        .navigationDestination(isPresented: $navigateToSearch) {
            SearchView(appState: appState, initialSearch: "")
        }
    }
}

// Preview provider
struct TopNavBarWithSearch_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            TopNavBar(appState: AppState())
            Spacer()
        }
    }
}
