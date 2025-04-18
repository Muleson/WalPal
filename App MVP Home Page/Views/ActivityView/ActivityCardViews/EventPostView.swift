//
//  EventPostView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import SwiftUI

struct EventPostView: View {
    let post: EventPost
    let isLiked: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onDelete: (() -> Void)?
    let onAuthorTapped: (User) -> Void
        
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with author info
            HStack {
                AuthorView(author: post.author, onTap: { onAuthorTapped(post.author)
                })
                
                Spacer()
                
                Text(formatDate(post.createdAt))
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
            
            // Event tag
            HStack {
                Text("Event")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .clipShape(Capsule())
                
                if let gym = post.gym {
                    Text("at \(gym.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Event title
            Text(post.title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            
            // Event details
            if let description = post.description {
                Text(description)
                    .font(.appBody)
                    .foregroundColor(.appTextPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Event time and location
            HStack(alignment: .top) {
                VStack(alignment: .leading) {
                    Label {
                        Text(formatEventDate(post.eventDate))
                    } icon: {
                        Image(systemName: "calendar")
                    }
                    .font(.appSubheadline)
                    .foregroundStyle(Color.appTextLight)
                    
                    Label {
                        Text(post.location)
                    } icon: {
                        Image(systemName: "mappin.and.ellipse")
                    }
                    .font(.appSubheadline)
                    .foregroundStyle(Color.appTextLight)

                }
                
                Spacer()
                
            }
            
            // Media (if available)
            if let mediaURL = post.mediaURL {
                AsyncImage(url: mediaURL) { image in
                    image
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            
            // Action buttons
            HStack {
                Button(action: onLike) {
                    HStack {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .foregroundColor(isLiked ? .red : .gray)
                        Text("\(post.likeCount)")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: onComment) {
                    HStack {
                        Image(systemName: "bubble.right")
                        Text("\(post.commentCount)")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
                
                Spacer()
                
                Button(action: {}) {
                    Text("Register")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(post.registered < post.maxAttendees ? Color.appButton : Color.gray)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .disabled(post.registered >= post.maxAttendees)
            }
            .padding(.top, 4)
        }
        .padding()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    private func formatEventDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: date)
    }
}

#Preview {
    
    EventPostView(
        post: SampleData.createSampleEventPost(),
        isLiked: true,
        onLike: {},
        onComment: {},
        onDelete: {},
        onAuthorTapped: { _ in }
    )
    .padding()
    .background(Color(.systemBackground))
}
