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
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Left side: Gym logo with overlaid user avatars
                ZStack {
                    // Gym logo/image
                    GymAvatarView(gym: gymVisit.gym, size: 60)
                    
                    // Attendee avatars in quarter circle formation
                    ZStack {
                        ForEach(0..<min(3, gymVisit.attendees.count), id: \.self) { index in
                            let userVisit = gymVisit.attendees[index]
                            let angle = Double(index) * (Double.pi / 4)
                            let radius: CGFloat = 16
                            
                            // Position from angle
                            let xOffset = radius * cos(angle)
                            let yOffset = radius * sin(angle)
                            
                            // User avatar
                            VisitorAvatarView(visitor: userVisit.user, size: 24)
                        }
                    }
                    .frame(width: 60, height: 60)
                    .offset(x: 15, y: 15)
                }
                .frame(width: 60, height: 60)
                
                // Middle: Text content
                VStack(alignment: .leading, spacing: 4) {
                    // Gym name as headline
                    Text(gymVisit.gym.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    // Attendee names
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
                }
                
                Spacer()
                
                // Right side: Date and Action
                VStack(alignment: .trailing, spacing: 4) {
                    // Get the representative date
                    let visitDate = gymVisit.attendees.first?.visitDate ?? Date()
                    
                    Text(viewModel.formatVisitDay(visitDate))
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // Conditional Join/Leave button
                    if let onLeave = onLeave {
                        Button(action: onLeave) {
                            Text("Leave")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(Color.gray.opacity(0.2))
                                .foregroundColor(.primary)
                                .clipShape(Capsule())
                        }
                    } else if let onJoin = onJoin {
                        Button(action: onJoin) {
                            Text("Join")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(AppTheme.appButton)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                }
                .frame(width: 80) // Fixed width for consistency
            }
            .padding()
            .contentShape(Rectangle())
            .onTapGesture {
                onTap()
            }
        }
        .background(Color.white)
        .cornerRadius(12)
    }
}
