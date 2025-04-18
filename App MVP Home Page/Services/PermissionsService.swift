//
//  PermissionsService.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 19/02/2025.
//

import Foundation
import FirebaseFirestore

class PermissionsService {
    // Shared Firestore instance
    private let db = Firestore.firestore()
    
    // MARK: - Gym Permission Methods
    
    func canManageGym(user: User, gym: Gym) async throws -> Bool {
        let querySnapshot = try await db.collection("gymAdministrators")
            .whereField("userId", isEqualTo: user.id)
            .whereField("gymId", isEqualTo: gym.id)
            .getDocuments()
        
        return !querySnapshot.documents.isEmpty
    }
    
    func getAdminRole(user: User, gym: Gym) async throws -> GymAdministrator.AdminRole? {
        let querySnapshot = try await db.collection("gymAdministrators")
            .whereField("userId", isEqualTo: user.id)
            .whereField("gymId", isEqualTo: gym.id)
            .getDocuments()
        
        guard let document = querySnapshot.documents.first,
              let admin = try? document.data(as: GymAdministrator.self) else {
            return nil
        }
        
        return admin.role
    }
    
    // MARK: - Content Moderation Methods
    
    func canEditContent(user: User, content: any ActivityItem) async -> Bool {
        // Users can edit their own content
        if content.author.id == user.id {
            return true
        }
        
        if let betaPost = content as? BetaPost {
            do {
                return try await canManageGym(user: user, gym: betaPost.gym)
            } catch {
                return false
            }
        } else if let eventPost = content as? EventPost, let gym = eventPost.gym {
            do {
                return try await canManageGym(user: user, gym: gym)
            } catch {
                return false
            }
        } else if let visit = content as? GroupVisit {
            do {
                return try await canManageGym(user: user, gym: visit.gym)
            } catch {
                return false
            }
        }
        
        return false
    }
    
    func canDeleteContent(user: User, content: any ActivityItem) async -> Bool {
        // Users can delete their own content
        if content.author.id == user.id {
            return true
        }
        
        // Admin permissions for gym-specific content
        if let betaPost = content as? BetaPost {
            // Only actual admins or owners can delete content
            let role = try? await getAdminRole(user: user, gym: betaPost.gym)
            return role == .admin || role == .owner
        } else if let eventPost = content as? EventPost, let gym = eventPost.gym {
            let role = try? await getAdminRole(user: user, gym: gym)
            return role == .admin || role == .owner
        } else if let visit = content as? GroupVisit {
            let role = try? await getAdminRole(user: user, gym: visit.gym)
            return role == .admin || role == .owner
        }
        
        return false
    }
}


// Extension to add full administrator management functionality to PermissionsService

extension PermissionsService {
        
    // MARK: - Administrator Management
    
    /// Get all administrators for a gym
    func getGymAdministrators(gymId: String) async throws -> [GymAdministrator] {
        let querySnapshot = try await db.collection("gymAdministrators")
            .whereField("gymId", isEqualTo: gymId)
            .getDocuments()
        
        return querySnapshot.documents.compactMap { doc -> GymAdministrator? in
            let data = doc.data()
            return GymAdministrator(firestoreData: data)
        }
    }
    
    /// Check if a user is already an administrator for a gym
    func isUserAdminForGym(userId: String, gymId: String) async throws -> Bool {
        let querySnapshot = try await db.collection("gymAdministrators")
            .whereField("userId", isEqualTo: userId)
            .whereField("gymId", isEqualTo: gymId)
            .getDocuments()
        
        return !querySnapshot.documents.isEmpty
    }
    
    /// Add a user as an administrator to a gym
    func addGymAdministrator(
        userId: String,
        gymId: String,
        role: GymAdministrator.AdminRole,
        addedBy: String
    ) async throws -> GymAdministrator {
        // Create a new admin entry
        let admin = GymAdministrator(
            id: UUID().uuidString,
            userId: userId,
            gymId: gymId,
            role: role,
            addedAt: Date(),
            addedBy: addedBy
        )
        
        // Save to Firestore
        try await db.collection("gymAdministrators")
            .document(admin.id)
            .setData(admin.toFirestoreData())
        
        return admin
    }
    
    /// Remove an administrator
    func removeGymAdministrator(adminId: String) async throws {
        try await db.collection("gymAdministrators").document(adminId).delete()
    }
}

