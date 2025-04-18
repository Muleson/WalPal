//
//  FollowButton.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 14/03/2025.
//

import SwiftUI

struct FollowButton: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Button {
            Task {
                await viewModel.toggleFollowStatus()
            }
        } label: {
            HStack {
                if viewModel.isFollowProcessing {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                        .padding(.trailing, 4)
                } else {
                    Image(systemName: viewModel.isFollowing ? "person.badge.minus" : "person.badge.plus")
                        .font(.system(size: 14))
                        .padding(.trailing, 4)
                }
                
                Text(viewModel.isFollowing ? "Unfollow" : "Follow")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(minWidth: 100)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(viewModel.isFollowing ? Color.gray.opacity(0.2) : AppTheme.appButton)
            .foregroundColor(viewModel.isFollowing ? .primary : .white)
            .clipShape(Capsule())
        }
        .disabled(viewModel.isFollowProcessing)
    }
}

// MARK: - Previews
struct FollowButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Preview for not following state
            FollowButton(viewModel: createMockViewModel(isFollowing: false, isProcessing: false))
                .previewDisplayName("Not Following")
            
            // Preview for following state
            FollowButton(viewModel: createMockViewModel(isFollowing: true, isProcessing: false))
                .previewDisplayName("Following")
            
            // Preview for loading state
            FollowButton(viewModel: createMockViewModel(isFollowing: false, isProcessing: true))
                .previewDisplayName("Loading")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
    
    // Helper function to create a mock ViewModel for previews
    static func createMockViewModel(isFollowing: Bool, isProcessing: Bool) -> ProfileViewModel {
        let viewModel = ProfileViewModel(appState: AppState())
        
        // Set the properties we need for the preview
        viewModel.isFollowing = isFollowing
        viewModel.isFollowProcessing = isProcessing
        
        return viewModel
    }
}
