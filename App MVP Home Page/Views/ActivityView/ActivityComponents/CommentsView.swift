//
//  CommentsView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 01/03/2025.
//

import SwiftUI

struct CommentsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = CommentsViewModel()
    
    let itemId: String
    let itemType: String
    var onCommendAdded: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .bottom) {
                Text("Comments")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                        .font(.title3)
                }
            }
            .padding()
            
            Divider()
            
            // Comments list
            if viewModel.isLoading && viewModel.comments.isEmpty {
                Spacer()
                ProgressView()
                    .scaleEffect(1.5)
                Spacer()
            } else if viewModel.comments.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No comments yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Text("Be the first to comment")
                        .foregroundColor(.secondary)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        ForEach(viewModel.comments) { comment in
                            CommentRow(comment: comment, formatTimestamp: viewModel.formatTimestamp)
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            
            // Comment input area
            HStack(alignment: .bottom) {
                if let user = appState.user {
                    // User avatar
                    if let imageUrl = user.imageUrl {
                        AsyncImage(url: imageUrl) { image in
                            image
                                .resizable()
                                .scaledToFill()
                        } placeholder: {
                            Color.gray
                        }
                        .frame(width: 36, height: 36)
                        .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 36, height: 36)
                            .overlay(
                                Text(user.firstName.prefix(1))
                                    .foregroundColor(.gray)
                            )
                    }
                }
                
                // Text field
                TextField("Write a comment...", text: $viewModel.newCommentText, axis: .vertical)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(20)
                    .lineLimit(5)
                
                // Send button
                Button {
                    if let user = appState.user {
                        Task {
                            await viewModel.addComment(itemId: itemId, author: user)
                            onCommendAdded?()
                        }
                    }
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30))
                        .foregroundColor(
                            viewModel.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?
                                .gray : .appButton
                        )
                }
                .disabled(viewModel.newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
            .background(Color(.systemBackground))
            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: -5)
        }
        .onAppear {
            Task {
                await viewModel.fetchComments(itemId: itemId)
            }
        }
        .alert(isPresented: Binding<Bool>(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Alert(
                title: Text("Error"),
                message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                dismissButton: .default(Text("OK"))
            )
        }
    }
}

struct CommentRow: View {
    let comment: Comment
    let formatTimestamp: (Date) -> String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User avatar
            if let imageUrl = comment.author.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(comment.author.firstName.prefix(1))
                            .foregroundColor(.gray)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Author name and timestamp
                HStack {
                    Text(comment.author.firstName + " " + comment.author.lastName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(formatTimestamp(comment.timeStamp))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Comment content
                Text(comment.content)
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
