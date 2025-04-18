//
//  CommentRepository.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 09/03/2025.
//

import Foundation
import FirebaseFirestore

class CommentsRepository {
    private let db = Firestore.firestore()
    
    /// Fetch comments for an activity item
    func fetchComments(for itemId: String) async throws -> [Comment] {
        let snapshot = try await db.collection("activityItems").document(itemId)
            .collection("comments")
            .order(by: "timeStamp", descending: false)
            .getDocuments()
        
        var comments: [Comment] = []
        
        for document in snapshot.documents {
            let data = document.data()
            guard
                let authorId = data["authorId"] as? String,
                let content = data["content"] as? String,
                let timestamp = data["timeStamp"] as? Timestamp,
                let idString = data["id"] as? String,
                let id = UUID(uuidString: idString)
            else { continue }
            
            // Fetch the author user
            let userDoc = try await db.collection("users").document(authorId).getDocument()
            
            if !userDoc.exists {
                continue
            }
            
            guard let userData = userDoc.data(),
                  let author = User(firestoreData: userData) else { continue }
            
            // Create comment
            let comment = Comment(
                author: author,
                content: content,
                timeStamp: timestamp.dateValue,
                id: id
            )
            
            comments.append(comment)
        }
        
        return comments
    }
    
    /// Add a comment to an activity item
    func addComment(to itemId: String, comment: Comment) async throws {
        // Create comment data
        let commentData: [String: Any] = [
            "authorId": comment.author.id,
            "content": comment.content,
            "timeStamp": comment.timeStamp.firestoreTimestamp,
            "id": comment.id.uuidString
        ]
        
        // Add comment to comments subcollection
        try await db.collection("activityItems").document(itemId)
            .collection("comments").document(comment.id.uuidString)
            .setData(commentData)
        
        // Increment comment count on the item
        try await db.collection("activityItems").document(itemId).updateData([
            "commentCount": FieldValue.increment(Int64(1))
        ])
    }
    
    /// Delete a comment from an activity item
    func deleteComment(from itemId: String, commentId: String) async throws {
        // First get the comment to verify it exists
        let commentDoc = try await db.collection("activityItems").document(itemId)
            .collection("comments").document(commentId).getDocument()
        
        guard commentDoc.exists else {
            throw NSError(
                domain: "CommentsRepository",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Comment not found"]
            )
        }
        
        // Delete the comment
        try await db.collection("activityItems").document(itemId)
            .collection("comments").document(commentId).delete()
        
        // Decrement the comment count on the item
        try await db.collection("activityItems").document(itemId).updateData([
            "commentCount": FieldValue.increment(Int64(-1))
        ])
    }
}
