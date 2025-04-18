//
//  ProfileHeader.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 18/P03/2025.
//

import SwiftUI

struct ProfileHeaderView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let avatarSize: CGFloat
    
    var body: some View {
        VStack(spacing: 8) {
            // Profile image and name row
            HStack(alignment: .center, spacing: 0) {
                // Fixed margin from left edge
                Spacer().frame(width: 32)
                
                // Profile image with fixed position
                profileImage
                
                // Spacing between image and text
                Spacer().frame(width: 16)
                
                // User info
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.displayName)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    
                    Text("Boulder · V3")
                        .font(.appSubheadline)
                        .foregroundStyle(.appTextLight)
                
                    // Bio - uncomment when needed
                    /*  if let bio = viewModel.displayedUser?.bio, !bio.isEmpty {
                          Text(bio)
                              .font(.subheadline)
                              .foregroundColor(.secondary)
                              .multilineTextAlignment(.leading)
                              .fixedSize(horizontal: false, vertical: true)
                      } */
                }
                
                Spacer() // Push everything to the left
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 24) {
                // Add follow button if this is not the current user's profile
                if !viewModel.isCurrentUserProfile {
                    FollowButton(viewModel: viewModel)
                        .frame(width: 120)
                    MessageButton(viewModel: viewModel)
                        .frame(width: 120)
                } else {
                    EditProfileButton(viewModel: viewModel)
                        .frame(width: 240)
                }
            }
        }
        .background(Color(.systemBackground))
    }
    
    private var profileImage: some View {
        Group {
            if let user = viewModel.displayedUser, let imageUrl = user.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: avatarSize * 0.8, height: avatarSize * 0.8)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.appButton, lineWidth: 2))
                .shadow(radius: 2)
            } else if let user = viewModel.displayedUser {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: avatarSize * 0.8, height: avatarSize * 0.8)
                    .overlay(
                        Text(user.firstName.prefix(1))
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    )
                    .overlay(Circle().stroke(Color.white, lineWidth: 3))
                    .shadow(radius: 2)
            } else {
                // Fallback if no user is available
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: avatarSize * 0.8, height: avatarSize * 0.8)
            }
        }
    }
}

// Updated previews
#Preview("User Profile Header") {
    let viewModel = ProfileViewModel()
    // Set up the view model for the preview
    viewModel.displayedUser = SampleData.previewUser
    viewModel.isCurrentUserProfile = true
    
    return ProfileHeaderView(
        viewModel: viewModel,
        avatarSize: 100
    )
}

#Preview("Other User Profile Header - Not Following") {
    let viewModel = ProfileViewModel()
    // Set up the view model for the preview
    viewModel.displayedUser = User(
        id: "other-user-123",
        email: "jane@example.com",
        firstName: "Jane",
        lastName: "Smith",
        bio: "Climbing instructor and outdoor enthusiast",
        postCount: 27,
        loggedHours: 350,
        imageUrl: nil,
        createdAt: Date().addingTimeInterval(-86400 * 200)
    )
    viewModel.isCurrentUserProfile = false
    viewModel.isFollowing = false
    
    return ProfileHeaderView(
        viewModel: viewModel,
        avatarSize: 100
    )
}
