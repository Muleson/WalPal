//
//  LikeButton.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 11/04/2025.
//

import SwiftUI

struct LikeButton: View {
    let itemId: String
    let isLiked: Bool
    let likeCount: Int
    let isProcessing: Bool
    let onLike: () -> Void
    
    var body: some View {
        Button(action: onLike) {
            HStack {
                if isProcessing {
                    // Show a small loading indicator instead of the heart
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                } else {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .gray)
                }
                Text("\(likeCount)")
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
        .disabled(isProcessing) // Disable the button while processing
    }
}
