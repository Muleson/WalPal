//
//  GymVisitCard.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 08/03/2025.
//

import SwiftUI

struct GymVisitCard: View {
    let gymVisit: GymVisit
    let onJoin: () -> Void
    let onLeave: (() -> Void)?
    
    @ObservedObject var viewModel: GymVisitViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Gym header with image and name
            HStack(spacing: 12) {
                // Gym image
                GymAvatarView(gym: gymVisit.gym, size: 70)
                
                // Gym info
                VStack(alignment: .leading, spacing: 4) {
                    Text(gymVisit.gym.name)
                        .font(.headline)
                    
                    Text(gymVisit.gym.locaiton)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(gymVisit.attendees.count) \(gymVisit.attendees.count == 1 ? "person" : "people") visiting today")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Divider
            Divider()
            
            // Friends list
            VStack(alignment: .leading, spacing: 8) {
                Text("Visitors today:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Show up to 5 friends with their times
                ForEach(Array(gymVisit.attendees.prefix(5)), id: \.id) { userVisit in
                    HStack {
                        // User avatar
                        if let imageUrl = userVisit.user.imageUrl {
                            AsyncImage(url: imageUrl) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Color.gray
                            }
                            .frame(width: 30, height: 30)
                            .clipShape(Circle())
                        } else {
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text(userVisit.user.firstName.prefix(1))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // User name and time
                        VStack(alignment: .leading) {
                            Text("\(userVisit.user.firstName) \(userVisit.user.lastName)")
                                .font(.subheadline)
                            
                            Text(viewModel.formatAMPM(userVisit.visitDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // If there are more than 5 visitors, show a "See more" button
                if gymVisit.attendees.count > 5 {
                    Button(action: {
                        // This would show all visitors (not implemented)
                    }) {
                        Text("See \(gymVisit.attendees.count - 5) more")
                            .font(.caption)
                            .foregroundColor(AppTheme.appButton)
                    }
                    .padding(.top, 4)
                }
            }
            
            // Join button
            Button(action: onJoin) {
                HStack {
                    Spacer()
                    Text("Join")
                        .fontWeight(.medium)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(AppTheme.appButton)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
