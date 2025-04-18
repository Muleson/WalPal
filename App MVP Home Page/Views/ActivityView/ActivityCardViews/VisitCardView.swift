//
//  GymVisitCard.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 08/03/2025.
//

import SwiftUI

struct VisitCardView: View {
    let gymVisit: GymWithVisits
    let onJoin: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Gym header with image and name
            HStack(spacing: 12) {
                // Gym image
                if let imageUrl = gymVisit.gym.imageUrl {
                    AsyncImage(url: imageUrl) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.3)
                    }
                    .frame(width: 70, height: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 70, height: 70)
                        .overlay(
                            Image(systemName: "building.2")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                }
                
                // Gym info
                VStack(alignment: .leading, spacing: 4) {
                    Text(gymVisit.gym.name)
                        .font(.headline)
                    
                    Text(gymVisit.gym.locaiton)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Text("\(gymVisit.visitors.count) friends visiting today")
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
                Text("Friends going:")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                // Show up to 5 friends with their times
                ForEach(Array(gymVisit.visitors.prefix(5).enumerated()), id: \.1.user.id) { index, visitor in
                    HStack {
                        // User avatar
                        if let imageUrl = visitor.user.imageUrl {
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
                                    Text(visitor.user.firstName.prefix(1))
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                )
                        }
                        
                        // User name and time
                        VStack(alignment: .leading) {
                            Text("\(visitor.user.firstName) \(visitor.user.lastName)")
                                .font(.subheadline)
                            
                            Text(formatVisitTime(visitor.visitDate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                // If there are more than 5 visitors, show a "See more" button
                if gymVisit.visitors.count > 5 {
                    Button(action: {
                        // This would show all visitors (not implemented)
                    }) {
                        Text("See \(gymVisit.visitors.count - 5) more")
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
    
    // Format the visit time
    private func formatVisitTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    VStack {
        // Using the first sample gym visit
        let sampleVisits = SampleData.createSampleGymVisits()
        VisitCardView(
            gymVisit: sampleVisits[0],
            onJoin: {}
        )
        .padding()
        
        // Creating a modified gym visit with more visitors to show "See more" button
        VisitCardView(
            gymVisit: {
                let gymVisit = sampleVisits[0]
                // Add more visitors by duplicating the existing ones
                let moreVisitors = gymVisit.visitors + gymVisit.visitors + gymVisit.visitors
                return GymWithVisits(gym: gymVisit.gym, visitors: moreVisitors)
            }(),
            onJoin: {}
        )
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
