//
//  VisitsRowView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 08/03/2025.
//

import SwiftUI

struct GymVisitRow: View {
    let gymVisit: GymVisit
    let onTap: () -> Void
    let onJoin: (() -> Void)?
    let onLeave: (() -> Void)?
    
    @ObservedObject var viewModel: GymVisitViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Gym logo with overlaid user avatars
            ZStack {
                // Gym logo/image
                GymAvatarView(gym: gymVisit.gym, size: 60)
                
                // Attendee avatars - different layouts based on number of attendees
                ZStack {
                    if gymVisit.attendees.count == 1 {
                        // Single user avatar - position in bottom right corner
                        let userVisit = gymVisit.attendees[0]
                        VisitorAvatarView(visitor: userVisit.user, size: 24)
                            .offset(x: 15, y: 15) // Position in bottom right corner
                    } else if gymVisit.attendees.count == 2 {
                        // Two users - position both in bottom right area
                        let firstUser = gymVisit.attendees[0]
                        let secondUser = gymVisit.attendees[1]
                        
                        // First user positioned slightly right
                        VisitorAvatarView(visitor: firstUser.user, size: 24)
                            .offset(x: 15, y: 5)
                        
                        // Second user positioned slightly below
                        VisitorAvatarView(visitor: secondUser.user, size: 24)
                            .offset(x: 5, y: 15)
                    } else {
                        // Three or more users in quarter circle formation
                        ForEach(0..<min(3, gymVisit.attendees.count), id: \.self) { index in
                            let userVisit = gymVisit.attendees[index]
                            let angle = Double(index) * (Double.pi / 4)
                            let radius: CGFloat = 22
                            
                            // Position from angle
                            let xOffset = radius * cos(angle)
                            let yOffset = radius * sin(angle)
                            
                            // User avatar
                            VisitorAvatarView(visitor: userVisit.user, size: 24)
                                .offset(x: xOffset, y: yOffset)
                        }
                    }
                }
                .frame(width: 60, height: 60)
                .offset(x: 8, y: 8)
            }
            .frame(width: 60, height: 60)
            
            // Middle section with gym info and action button
            VStack(alignment: .leading, spacing: 6) {
                // Gym name
                Text(gymVisit.gym.name)
                    .font(.headline)
                    .lineLimit(1)
                
                // Attendees
                if !gymVisit.attendees.isEmpty {
                    Text(viewModel.formatAttendeeList(gymVisit.attendees))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No attendees yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Join/Leave button with consistent sizing
                HStack {
                    if let onLeave = onLeave {
                        Button(action: onLeave) {
                            Text("Leave")
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(width: 80)
                                .padding(.vertical, 6)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                        }
                    } else if let onJoin = onJoin {
                        Button(action: onJoin) {
                            Text("Join")
                                .font(.caption)
                                .fontWeight(.medium)
                                .frame(width: 80)
                                .padding(.vertical, 6)
                                .background(AppTheme.appButton)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Spacer()
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            // Right side: Visit day with chevron in HStack
            HStack(spacing: 4) {
                // Get the representative date
                let visitDate = gymVisit.attendees.first?.visitDate ?? Date()
                
                Text(viewModel.formatVisitDay(visitDate))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(minWidth: 60, alignment: .trailing) // Ensure enough space for text + chevron
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }
}

#Preview {
    // Create a sample model
    let viewModel = GymVisitViewModel()
    
    // Create sample gym visits with different configurations
    let gymWithFriends = GymVisit(
        id: "gym-with-friends",
        gym: SampleData.previewGyms[0],
        attendees: [
            UserVisit(
                id: "visit-1",
                visitId: "visit-id-1",
                user: SampleData.previewUsers[0],
                visitDate: Date()
            ),
            UserVisit(
                id: "visit-2",
                visitId: "visit-id-2",
                user: SampleData.previewUsers[1],
                visitDate: Date().addingTimeInterval(1800)
            ),
            UserVisit(
                id: "visit-3",
                visitId: "visit-id-3",
                user: SampleData.previewUsers[2],
                visitDate: Date().addingTimeInterval(3600)
            )
        ],
        isFavourite: false
    )
    
    let gymWithOneAttendee = GymVisit(
        id: "gym-with-one",
        gym: SampleData.previewGyms[1],
        attendees: [
            UserVisit(
                id: "visit-4",
                visitId: "visit-id-4",
                user: SampleData.previewUsers[0],
                visitDate: Date()
            )
        ],
        isFavourite: true
    )
    
    let gymWithTwoAttendees = GymVisit(
        id: "gym-with-two",
        gym: SampleData.previewGyms[0],
        attendees: [
            UserVisit(
                id: "visit-5",
                visitId: "visit-id-5",
                user: SampleData.previewUsers[0],
                visitDate: Date()
            ),
            UserVisit(
                id: "visit-6",
                visitId: "visit-id-6",
                user: SampleData.previewUsers[1],
                visitDate: Date().addingTimeInterval(1800)
            )
        ],
        isFavourite: true
    )
    
    let emptyGym = GymVisit(
        id: "empty-gym",
        gym: SampleData.previewGym,
        attendees: [],
        isFavourite: false
    )
    
    VStack(spacing: 20) {
        // Row with multiple attendees - Not joined (Join button)
        GymVisitRow(
            gymVisit: gymWithFriends,
            onTap: {},
            onJoin: {},
            onLeave: nil,
            viewModel: viewModel
        )
        
        // Row with multiple attendees - Already joined (Leave button)
        GymVisitRow(
            gymVisit: gymWithFriends,
            onTap: {},
            onJoin: nil,
            onLeave: {},
            viewModel: viewModel
        )
        
        // Row with two attendees
        GymVisitRow(
            gymVisit: gymWithTwoAttendees,
            onTap: {},
            onJoin: {},
            onLeave: nil,
            viewModel: viewModel
        )
        
        // Row with single attendee
        GymVisitRow(
            gymVisit: gymWithOneAttendee,
            onTap: {},
            onJoin: {},
            onLeave: nil,
            viewModel: viewModel
        )
        
        // Row with no attendees
        GymVisitRow(
            gymVisit: emptyGym,
            onTap: {},
            onJoin: {},
            onLeave: nil,
            viewModel: viewModel
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
