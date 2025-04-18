//
//  GymVisitView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 10/04/2025.
//

import Foundation
import SwiftUI

struct VisitPostView: View {
    let gymVisit: GymVisit
    let userVisit: UserVisit
    let onDelete: (() -> Void)?
    let onJoin: (() -> Void)?
    let onLeave: (() -> Void)?
    let onAuthorTapped: (User) -> Void
    
    @ObservedObject var visitsViewModel: GymVisitViewModel
    
    var body: some View {
        HStack(spacing: 20) {
            // Left side: Gym logo with overlaid user avatars
            ZStack {
                // Gym logo/image
                GymAvatarView(gym: gymVisit.gym, size: 60)
                
                // Attendee avatars in quarter circle formation
                ZStack {
                    // Position each avatar in a quarter circle
                    ForEach(0..<min(3, gymVisit.attendees.count), id: \.self) { index in
                        let userVisit = gymVisit.attendees[index]
                        let angle = Double(index) * (Double.pi / 4) // Spread 45 degrees apart
                        let radius: CGFloat = 16 // Distance from the bottom-right corner
                        
                        // Calculate position from angle
                        let xOffset = radius * cos(angle)
                        let yOffset = radius * sin(angle)
                        
                        // User avatar
                        if let imageUrl = userVisit.user.imageUrl {
                            AsyncImage(url: imageUrl) { image in
                                image
                                    .resizable()
                                    .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(width: 24, height: 24)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                            .offset(x: xOffset, y: yOffset)
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 24, height: 24)
                                .overlay(
                                    Text(userVisit.user.firstName.prefix(1))
                                        .font(.system(size: 10))
                                        .foregroundColor(.gray)
                                )
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                .offset(x: xOffset, y: yOffset)
                        }
                    }
                }
                .frame(width: 60, height: 60)
                .offset(x: 15, y: 15) // Position the entire formation toward bottom-right
            }
            .frame(width: 60, height: 60)
            
            // Middle: Text content and CTA
            VStack(alignment: .leading, spacing: 6) {
                // Gym name as headline
                Text(gymVisit.gym.name)
                    .font(.headline)
                    .lineLimit(1)
                
                // Attendee names - NOW USING VIEWMODEL METHOD
                if !gymVisit.attendees.isEmpty {
                    Text(visitsViewModel.formatAttendeeList(gymVisit.attendees))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No attendees yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Join/Leave button with reduced width
                HStack {
                    if let onJoin = onJoin {
                        Button(action: onJoin) {
                            Text("Join")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: 148)
                                .padding(.vertical, 6)
                                .background(Color.appButton)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    } else if let onLeave = onLeave {
                        Button(action: onLeave) {
                            Text("Leave")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .frame(maxWidth: 148)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                        }
                        .padding(.top, 4)
                    }
                }
            }
            
            Spacer()
            
            // Right side: Date and time information - NOW USING VIEWMODEL METHODS
            VStack(alignment: .center, spacing: 2) {
                Text(visitsViewModel.formatVisitDay(userVisit.visitDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(visitsViewModel.formatAMPM(userVisit.visitDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(width: 60) // Fixed width for consistency
            .padding(.trailing, 4)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
    }
    
}

// Updated preview provider
#Preview {
    // Create a mock view model for preview
    let viewModel = GymVisitViewModel()
    
    // Use SampleData to create sample users for the preview
    let previewUsers = SampleData.createSampleUsers(count: 3)
    
    // Create UserVisits for attendees
    let attendees = [
        UserVisit(
            visitId: "visit1",
            user: previewUsers[0],
            visitDate: Date().addingTimeInterval(3600)
        ),
        UserVisit(
            visitId: "visit2",
            user: previewUsers[1],
            visitDate: Date().addingTimeInterval(7200)
        ),
        UserVisit(
            visitId: "visit3",
            user: previewUsers[2],
            visitDate: Date().addingTimeInterval(10800)
        )
    ]
    
    // Create a sample GymVisit
    let gymVisit = GymVisit(
        gym: SampleData.previewGym,
        attendees: attendees,
        isFavourite: true
    )
    
    VStack {
        // Example with attendees and Leave button
        VisitPostView(
            gymVisit: gymVisit,
            userVisit: attendees[0], // Show the first user's visit
            onDelete: {},
            onJoin: nil,
            onLeave: { print("Leave tapped") },
            onAuthorTapped: { _ in },
            visitsViewModel: viewModel
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
