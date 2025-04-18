//
//  UserRelationshipService.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 05/03/2025.
//

import Foundation
import FirebaseFirestore

class UserRelationshipService: ObservableObject {
    private let db = Firestore.firestore()
    private let userRepository: UserRepositoryService
    private var followingCache: [String: Set<String>] = [:]
    
    init(userRepository: UserRepositoryService = UserRepositoryService()) {
        self.userRepository = userRepository
    }
    
    // MARK: - Follow/Unfollow Methods
    
    func followUser(followerId: String, followingId: String) async throws {
        // Check if already following
        let querySnapshot = try await db.collection("userRelationships")
            .whereField("followerId", isEqualTo: followerId)
            .whereField("followingId", isEqualTo: followingId)
            .getDocuments()
        
        if querySnapshot.documents.isEmpty {
            // Create new relationship
            let relationship = UserRelationship(
                followerId: followerId,
                followingId: followingId
            )
            
            try await db.collection("userRelationships")
                .document(relationship.id)
                .setData(relationship.toFirestoreData())
            
            // Update cache
            updateFollowingCache(followerId: followerId, followingId: followingId, isFollowing: true)
        }
    }
    
    func unfollowUser(followerId: String, followingId: String) async throws {
        let querySnapshot = try await db.collection("userRelationships")
            .whereField("followerId", isEqualTo: followerId)
            .whereField("followingId", isEqualTo: followingId)
            .getDocuments()
        
        for document in querySnapshot.documents {
            try await db.collection("userRelationships")
                .document(document.documentID)
                .delete()
            
            // Update cache
            updateFollowingCache(followerId: followerId, followingId: followingId, isFollowing: false)
        }
    }
    
    func isFollowing(followerId: String, followingId: String) async throws -> Bool {
        // Check cache first
        if let following = followingCache[followerId] {
            return following.contains(followingId)
        }
        
        // Query database
        let querySnapshot = try await db.collection("userRelationships")
            .whereField("followerId", isEqualTo: followerId)
            .getDocuments()
        
        // Build cache
        var followingSet: Set<String> = []
        for document in querySnapshot.documents {
            if let followingId = document.data()["followingId"] as? String {
                followingSet.insert(followingId)
            }
        }
        followingCache[followerId] = followingSet
        
        return followingSet.contains(followingId)
    }
    
    // Updated getFollowers method to use UserManager
    func getFollowers(userId: String) async throws -> [User] {
        // Get all users following this user
        let querySnapshot = try await db.collection("userRelationships")
            .whereField("followingId", isEqualTo: userId)
            .getDocuments()
        
        // Extract follower IDs
        let followerIds = querySnapshot.documents.compactMap {
            $0.data()["followerId"] as? String
        }
        
        // Use UserManager to fetch users
        return try await userRepository.getUsers(ids: followerIds)
    }
    
    // Updated getFollowing method to use UserManager
    func getFollowing(userId: String) async throws -> [User] {
        // Get IDs of users this user follows
        let querySnapshot = try await db.collection("userRelationships")
            .whereField("followerId", isEqualTo: userId)
            .getDocuments()
        
        let followingIds = querySnapshot.documents.compactMap {
            $0.data()["followingId"] as? String
        }
        
        // Update cache while we're at it
        followingCache[userId] = Set(followingIds)
        
        // Use UserManager to fetch users
        return try await userRepository.getUsers(ids: followingIds)
    }
    
    func updateFollowingCache(followerId: String, followingId: String, isFollowing: Bool) {
          // Update the cache when relationship changes
          if var followingSet = followingCache[followerId] {
              if isFollowing {
                  followingSet.insert(followingId)
              } else {
                  followingSet.remove(followingId)
              }
              followingCache[followerId] = followingSet
          }
      }
    
    // Clear relationship cache
    func clearCache() {
        followingCache.removeAll()
    }
}

extension UserRelationshipService {
    /// Get just the IDs of users the current user follows
    func getFollowingIds(userId: String) async throws -> [String] {
        // Check cache first
        if let followingSet = followingCache[userId] {
            return Array(followingSet)
        }
        
        // Query database for relationship IDs only
        let querySnapshot = try await db.collection("userRelationships")
            .whereField("followerId", isEqualTo: userId)
            .getDocuments()
        
        let followingIds = querySnapshot.documents.compactMap {
            $0.data()["followingId"] as? String
        }
        
        // Update cache
        followingCache[userId] = Set(followingIds)
        
        return followingIds
    }
}
