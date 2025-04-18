//
//  BetaPostView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import SwiftUI

struct BetaPostView: View {
    let post: BetaPost
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
            
            // Beta tag and gym
            HStack {
                Text("Beta")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.2))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
                
                Text("at \(post.gym.name)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            // Content
            Text(post.content)
                .fixedSize(horizontal: false, vertical: true)
            
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
            
            // Views counter
            HStack {
                Image(systemName: "eye")
                    .foregroundColor(.secondary)
                Text("\(post.viewCount) views")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
}

#Preview {
 BetaPostView(
    post: SampleData.createSampleBetaPost(),
    isLiked: true,
    onLike: {},
    onComment: {},
    onDelete: {},
    onAuthorTapped: { _ in }
    )
    .padding()
    .background(Color(.systemBackground))
}

