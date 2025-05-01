//
//  BasicPostView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import SwiftUI

struct BasicPostView: View {
    let post: BasicPost
    let isLiked: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    let onMediaTap: ((Media) -> Void)?
    let onDelete: (() -> Void)?
    let onAuthorTapped: (User) -> Void
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                // Header with author info
                HStack {
                    AuthorView(author: post.author, onTap: { onAuthorTapped(post.author)
                    })
                    
                    Spacer()
                    
                    Text(formatDate(post.createdAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if onDelete != nil {
                        Menu {
                            Button(role: .destructive, action: { onDelete?() }) {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .padding(8)
                                .foregroundStyle(.appButton)
                        }
                    }
                }
                
                // Content
                Text(post.content)
                    .fixedSize(horizontal: false, vertical: true)
                
                if let mediaItems = post.mediaItems, !mediaItems.isEmpty {
                    if mediaItems.count == 1 {
                        // Single media item - show large
                        MediaThumbnailView(media: mediaItems[0])
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .onTapGesture {
                                onMediaTap?(mediaItems[0])
                            }
                    } else {
                        // Multiple media items - show grid
                        MediaGridView(mediaItems: mediaItems) { media in
                            onMediaTap?(media)
                        }
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
                    .contentShape(Rectangle())
                }
                .padding(.top, 4)
            }
            .padding()
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
