//
//  UserManagementService.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 09/03/2025.
//

import Foundation
import FirebaseFirestore

class UserRepositoryService {
    private let db = Firestore.firestore()
    private var cachedUsers: [String: User] = [:]
    
    // Fetch a user by ID (with caching)
    func getUser(id: String) async throws -> User {
        // Return cached user if available
        if let cachedUser = cachedUsers[id] {
            return cachedUser
        }
        
        // Fetch from Firestore
        let doc = try await db.collection("users").document(id).getDocument()
        guard let userData = doc.data(),
              let user = User(firestoreData: userData) else {
            throw NSError(domain: "UserManager", code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        // Cache the user
        cachedUsers[id] = user
        return user
    }
    
    // Batch fetch users by IDs
    func getUsers(ids: [String]) async throws -> [User] {
        var users: [User] = []
        
        // Create batches to avoid excessive parallel requests
        for id in ids {
            do {
                let user = try await getUser(id: id)
                users.append(user)
            } catch {
                print("Error fetching user \(id): \(error)")
                // Continue with next user
            }
        }
        
        return users
    }
    
    // Update a user
    func updateUser(user: User) async throws {
        try await db.collection("users").document(user.id).updateData(user.toFirestoreData())
        cachedUsers[user.id] = user // Update cache
    }
    
    // Clear cache
    func clearCache() {
        cachedUsers.removeAll()
    }
}

extension UserRepositoryService {
    func searchUsers(query: String) async throws -> [User] {
        // In a real implementation, you would use a proper query
        // This is just a simplified version
        let normalizedQuery = query.lowercased()
        
        let snapshot = try await Firestore.firestore().collection("users").getDocuments()
        
        return snapshot.documents.compactMap { document -> User? in
            // document.data() is not optional, so we don't need 'if let' here
            let data = document.data()
            
            // User initializer might return nil if the data is invalid
            guard let user = User(firestoreData: data) else { return nil }
            
            // Simple matching - in a real app, you might use a more sophisticated approach
            if user.firstName.lowercased().contains(normalizedQuery) ||
                user.lastName.lowercased().contains(normalizedQuery) ||
                (user.bio?.lowercased().contains(normalizedQuery) ?? false) {
                return user
            }
            return nil
        }
    }
}

extension UserRepositoryService {
    /// Fetch multiple users and return as a dictionary keyed by ID
    func getUsersMap(ids: [String]) async throws -> [String: User] {
        // For empty array, return empty map
        if ids.isEmpty {
            return [:]
        }
        
        // Use existing cache where possible
        var result: [String: User] = [:]
        var idsToFetch: [String] = []
        
        for id in ids {
            if let cachedUser = cachedUsers[id] {
                result[id] = cachedUser
            } else {
                idsToFetch.append(id)
            }
        }
        
        // If all users were cached, return early
        if idsToFetch.isEmpty {
            return result
        }
        
        // Split into batches of 10 due to Firestore limits
        for batch in idsToFetch.chunked(into: 10) {
            let snapshot = try await db.collection("users")
                .whereField("id", in: batch)
                .getDocuments()
            
            for document in snapshot.documents {
                if let user = User(firestoreData: document.data()) {
                    result[user.id] = user
                    cachedUsers[user.id] = user  // Update cache
                }
            }
        }
        
        return result
    }
}
