//
//  MessageButton.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 19/03/2025.
//

import SwiftUI

struct MessageButton: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Button {
            if let targetUser = viewModel.displayedUser {
                Task {
                   await viewModel.navigateToConversationWithUser(currentUserId: targetUser.id)
                }
            }
        } label: {
            HStack {
                if viewModel.isCreatingConversation {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                        .padding(.trailing, 4)
                } else {
                    Image(systemName: "message")
                        .font(.system(size: 14))
                        .padding(.trailing, 4)
                }
                
                Text("Message")
                    .font(.subheadline)
            }
            .frame(minWidth: 100)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .clipShape(Capsule())
        }
        .disabled(viewModel.isCreatingConversation)
    }
}

// MARK: - Previews
struct MessageButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Normal state
            MessageButton(viewModel: createMockViewModel(isProcessing: false))
                .previewDisplayName("Normal")
            
            // Loading state
            MessageButton(viewModel: createMockViewModel(isProcessing: true))
                .previewDisplayName("Loading")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
    
    // Helper function to create a mock ViewModel
    static func createMockViewModel(isProcessing: Bool) -> ProfileViewModel {
        let viewModel = ProfileViewModel(appState: AppState())
        viewModel.isCreatingConversation = isProcessing
        return viewModel
    }
}

