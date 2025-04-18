//
//  EmptyStateView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 14/04/2025.
//

import SwiftUI

struct EmptyStateView: View {
    // Customizable properties
    let title: String
    let message: String
    let systemImage: String
    var buttonTitle: String? = nil
    var buttonAction: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            // Icon
            Image(systemName: systemImage)
                .font(.system(size: 50))
                .foregroundColor(Color.gray.opacity(0.5))
            
            // Title
            Text(title)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // Optional action button
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    Text(buttonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 20)
                        .background(AppTheme.appButton)
                        .cornerRadius(10)
                }
                .padding(.top, 8)
            }
        }
        .padding(.vertical, 30)
    }
}

// MARK: - Preview
#Preview {
    VStack {
        // Preview with button
        EmptyStateView(
            title: "No Favorite Gyms",
            message: "Add gyms to your favorites to see them here",
            systemImage: "building.2",
            buttonTitle: "Find Gyms",
            buttonAction: { print("Find Gyms tapped") }
        )
        .padding()
        .background(Color(.systemGroupedBackground))
        
        // Preview without button
        EmptyStateView(
            title: "No Friend Activity",
            message: "None of your friends are climbing today",
            systemImage: "person.3"
        )
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
