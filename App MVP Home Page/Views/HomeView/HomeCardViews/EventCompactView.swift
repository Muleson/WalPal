//
//  EventCompactView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 07/03/2025.
//

import SwiftUI

struct EventCompactView: View {
    let event: EventPost
    let isLiked: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Media display
            ZStack(alignment: .topTrailing) {
                if let mediaURL = event.mediaURL {
                    AsyncImage(url: mediaURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 150)
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .overlay(
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                }
                
                // Like button overlay
                Button(action: {}) {
                    Text("Register")
                        .font(.appSubheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.appButton)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(8)
            }
            
            // Info box at bottom
            HStack {
                // Gym name or event title if gym is nil
                Text(event.gym?.name ?? event.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Spacer()
                
                // Time relative to current date
                Text(timeUntilEvent(event.eventDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(10)
            .background(Color.white)
        }
        .cardStyle()
    }
    
    // Helper function to calculate relative time until event
    private func timeUntilEvent(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if date < now {
            return "Ended"
        }
        
        let components = calendar.dateComponents([.day, .hour], from: now, to: date)
        
        if let days = components.day, days > 0 {
            return days == 1 ? "Tomorrow" : "\(days) days"
        } else if let hours = components.hour, hours > 0 {
            return "\(hours) hours"
        } else {
            return "Soon"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        // Upcoming event preview
        EventCompactView(
            event: SampleData.createSampleEventPost(),
            isLiked: true,
            onLike: {},
            onComment: {}
        )
        .frame(width: 250)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
