//
//  BetaCompactView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 07/03/2025.
//

import SwiftUI

struct BetaCompactView: View {
    let beta: BetaPost
    let isLiked: Bool
    let onLike: () -> Void
    let onComment: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Media display
            ZStack(alignment: .topTrailing) {
                if let mediaItems = beta.mediaItems, let firstMedia = mediaItems.first {
                    AsyncImage(url: firstMedia.url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                    }
                    .frame(height: 150)
                    .overlay(
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .opacity(0.8),
                        alignment: .center
                    )
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 150)
                        .overlay(
                            Image(systemName: "figure.climbing")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                        )
                }
                
                // Like button overlay
                Button(action: onLike) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white)
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                        .clipShape(Circle())
                }
                .padding(8)
            }
            
            // Info box at bottom
            VStack(alignment: .leading, spacing: 3) {
                // Top row: Username and view count
                HStack {
                    // Username
                    AuthorCompactView(author: beta.author)
                    
                    Spacer()
                    
                    // View count
                    Label {
                        Text("\(beta.viewCount)")
                            .font(.appCaption)
                    } icon: {
                        Image(systemName: "eye")
                            .font(.appCaption)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Bottom row: Gym name
                Text(beta.gym.name)
                    .font(.appCaption)
                    .foregroundColor(.appButton)
                    .lineLimit(1)
            }
            .padding(10)
            .background(Color.white)
        }
        .cardStyle()
    }
}

#Preview {
    VStack(spacing: 20) {
        // Beta post with media
        BetaCompactView(
            beta: SampleData.createSampleBetaPost(),
            isLiked: true,
            onLike: {},
            onComment: {}
        )
        .frame(width: 250)
        
        // Beta post without media
        BetaCompactView(
            beta: SampleData.createSampleBetaPost(),
            isLiked: false,
            onLike: {},
            onComment: {}
        )
        .frame(width: 250)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
