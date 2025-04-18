//
//  VisitPostView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 09/03/2025.
//

import SwiftUI

//MARK: - This will be converted to a group visit view card

struct GroupVisitView: View {
    let visit: GroupVisit
    let isLiked: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onDelete: (() -> Void)?
    let onJoin: (() -> Void)?
    let onLeave: (() -> Void)?
    let onAuthorTapped: (User) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header with overlapping author and gym avatars
            HStack {
                // Overlapping profile pictures (Instagram collab style)
                ZStack(alignment: .bottomTrailing) {
                   
                    AuthorAvatar(author: visit.author, onTap: { onAuthorTapped(visit.author)
                    })
                    
                    // Gym avatar - overlapping the user avatar
                    GymAvatarView(gym: visit.gym, size: 28)
                        .offset(x: 8, y: 8)
                }
                .padding(.trailing, 8)
                
                // User and gym names
                VStack(alignment: .leading, spacing: 2) {
                    AuthorName(author: visit.author, onTap: { onAuthorTapped(visit.author) }
                    )
                    
                    Text("at \(visit.gym.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(formatDate(visit.createdAt))
                    .font(.appCaption)
                    .foregroundColor(.appTextLight)
                
                if onDelete != nil {
                    Menu {
                        Button(role: .destructive, action: { onDelete?() }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .padding(8)
                            .foregroundStyle(Color.appButton)
                    }
                }
            }
            
            // Visit tag and gym info
            HStack {
                Text(visit.status.rawValue.capitalized)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor(for: visit.status).opacity(0.2))
                    .foregroundColor(statusColor(for: visit.status))
                    .clipShape(Capsule())
                
                Spacer()
                
                // Attendee count
                VStack(alignment: .center) {
                    Text("\(visit.attendees.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appButton)
                    
                    Text("Attending")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description if available
            if let description = visit.description, !description.isEmpty {
                Text(description)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Attendees preview (show first 3)
            if !visit.attendees.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Attendees:")
                        .font(.appSubheadline)
                        .foregroundColor(.appTextLight)
                    
                    // TODO: In a real implementation, fetch the actual User objects
                    // This is just a placeholder for demonstration
                    HStack(spacing: -8) {
                        ForEach(0..<min(3, visit.attendees.count), id: \.self) { _ in
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 30, height: 30)
                                .overlay(
                                    Text("U")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                        }
                    }
                    
                    if visit.attendees.count > 3 {
                        Text("+ \(visit.attendees.count - 3) more")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
            }
            HStack {
                
                Spacer()
                
                // Join/Leave button
                if let onJoin = onJoin {
                    Button(action: onJoin) {
                        Text("Join")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 76)
                            .padding(.vertical, 6)
                            .background(Color.appButton)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                } else if let onLeave = onLeave {
                    Button(action: onLeave) {
                        Text("Leave")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .padding(.horizontal, 76)
                            .padding(.vertical, 6)
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
            }
            
            // Action buttons
            HStack {
                // Like button
                Button(action: onLike) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(visit.likeCount)")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                // Comment button
                Button(action: onComment) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(visit.commentCount)")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
            }
            .padding(.top, 4)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatVisitDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) minutes"
        }
    }
    
    private func statusColor(for status: GroupVisit.VisitStatus) -> Color {
        switch status {
        case .planned:
            return .blue
        case .ongoing:
            return .green
        case .completed:
            return .purple
        case .cancelled:
            return .red
        }
    }
}

#Preview {
    // Create sample data for preview
    let previewUser = User(
        id: "user123",
        email: "john@example.com",
        firstName: "John",
        lastName: "Doe",
        bio: "Climbing enthusiast",
        postCount: 42,
        loggedHours: 250,
        imageUrl: nil,
        createdAt: Date().addingTimeInterval(-86400 * 100)
    )
    
    let previewGym = Gym(
        id: "gym123",
        email: "info@climbinggym.com",
        name: "Boulder Haven",
        description: "Best climbing gym in town",
        locaiton: "123 Climb Street",
        climbingType: [.bouldering],
        amenities: ["Showers", "Café", "Training area"],
        events: [],
        imageUrl: nil,
        createdAt: Date().addingTimeInterval(-86400 * 365)
    )
    
    let previewVisit = GroupVisit(
        id: "visit123",
        author: previewUser,
        createdAt: Date().addingTimeInterval(-3600),
        likeCount: 5,
        commentCount: 2,
        gym: previewGym,
        visitDate: Date().addingTimeInterval(3600),
        duration: 7200, // 2 hours
        description: "Looking for climbing partners for a bouldering session!",
        attendees: ["user123", "user456", "user789"],
        status: .planned,
        isFeatured: false
    )
    
    VStack {
        GroupVisitView(
            visit: previewVisit,
            isLiked: false,
            onLike: {},
            onComment: {},
            onDelete: {},
            onJoin: nil,
            onLeave: { print("Leave tapped") },
            onAuthorTapped: { _ in }
        )
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding()
        
        // Show another example with different status
        GroupVisitView(
            visit: GroupVisit(
                id: "visit456",
                author: previewUser,
                createdAt: Date().addingTimeInterval(-86400),
                likeCount: 12,
                commentCount: 4,
                gym: previewGym,
                visitDate: Date().addingTimeInterval(-1800), // 30 minutes ago
                duration: 5400, // 1.5 hours
                description: nil,
                attendees: ["user123"],
                status: .ongoing,
                isFeatured: true
            ),
            isLiked: true,
            onLike: {},
            onComment: {},
            onDelete: nil,
            onJoin: { print("Join tapped") },
            onLeave: nil,
            onAuthorTapped: { _ in }
        )
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
        .padding()
    }
    .background(Color(.systemGroupedBackground))
}
