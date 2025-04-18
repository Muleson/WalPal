//
//  CommentsViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 01/03/2025.
//

import SwiftUI
import FirebaseFirestore

class CommentsViewModel: ObservableObject {
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var newCommentText = ""
    
    private let commentsRepository = CommentsRepository()
    
    // MARK: - Public Methods
    
    /// Fetch comments for an activity item
    func fetchComments(itemId: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let loadedComments = try await commentsRepository.fetchComments(for: itemId)
            
            await MainActor.run {
                self.comments = loadedComments
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Add a new comment to an activity item
    func addComment(itemId: String, author: User) async {
        guard !newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        do {
            let newComment = Comment(
                author: author,
                content: newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            try await commentsRepository.addComment(to: itemId, comment: newComment)
            await fetchComments(itemId: itemId)
            await MainActor.run {
                newCommentText = ""
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    /// Delete a comment
    func deleteComment(itemId: String, commentId: String) async {
        await MainActor.run {
            isLoading = true
        }
        
        do {
            try await commentsRepository.deleteComment(from: itemId, commentId: commentId)
            
            await MainActor.run {
                // Remove from local array
                comments.removeAll { $0.id.uuidString == commentId }
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Format timestamp for display
    func formatTimestamp(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day, .weekOfYear, .month, .year], from: date, to: now)

        if let year = components.year, year >= 1 {
            return year == 1 ? "1 year ago" : "\(year) years ago"
        }
        
        if let month = components.month, month >= 1 {
            return month == 1 ? "1 month ago" : "\(month) months ago"
        }
        
        if let week = components.weekOfYear, week >= 1 {
            return week == 1 ? "1 week ago" : "\(week) weeks ago"
        }
        
        if let day = components.day, day >= 1 {
            return day == 1 ? "Yesterday" : "\(day) days ago"
        }
        
        if let hour = components.hour, hour >= 1 {
            return hour == 1 ? "1 hour ago" : "\(hour) hours ago"
        }
        
        if let minute = components.minute, minute >= 1 {
            return minute == 1 ? "1 minute ago" : "\(minute) minutes ago"
        }
        
        return "Just now"
    }
}
