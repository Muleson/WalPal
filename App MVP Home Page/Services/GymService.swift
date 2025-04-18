//
//  GymService.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 26/02/2025.
//

import Foundation
import FirebaseFirestore

class GymService: ObservableObject {
    @Published var gyms: [Gym] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    func fetchGyms() async throws {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let snapshot = try await db.collection("gyms").getDocuments()
            
            // Use manual decoding instead of Firestore.Decoder
            let fetchedGyms = snapshot.documents.compactMap { document -> Gym? in
                guard let documentData = document.data() as [String: Any]? else { return nil }
                return Gym(firestoreData: documentData)
            }
            await MainActor.run {
                self.gyms = fetchedGyms
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
            throw error
        }
    }
    
    func createGym(gym: Gym) async throws {
        // Use manual encoding to convert Gym to Firestore data
        try await db.collection("gyms").document(gym.id).setData(gym.toFirestoreData())
    }
    
    func updateGym(gym: Gym) async throws {
        // Use manual encoding to convert Gym to Firestore data
        try await db.collection("gyms").document(gym.id).updateData(gym.toFirestoreData())
    }
    
    func deleteGym(id: String) async throws {
        try await db.collection("gyms").document(id).delete()
    }
    
    func fetchGym(id: String) async throws -> Gym? {
        let document = try await db.collection("gyms").document(id).getDocument()
        guard
            let data = document.data(),
            let gym = Gym(firestoreData: data)
        else {
            return nil
        }
        return gym
    }
}

extension GymService {
    /// Fetch multiple gyms and return as a dictionary keyed by ID
    func fetchGymsMap(ids: [String]) async throws -> [String: Gym] {
        // For empty array, return empty map
        if ids.isEmpty {
            return [:]
        }
        
        // Split into batches of 10 due to Firestore limits
        var result: [String: Gym] = [:]
        
        for batch in ids.chunked(into: 10) {
            let snapshot = try await db.collection("gyms")
                .whereField("id", in: batch)
                .getDocuments()
            
            for document in snapshot.documents {
                if let gym = Gym(firestoreData: document.data()) {
                    result[gym.id] = gym
                }
            }
        }
        
        return result
    }
    
    /// Add a gym to user's favorites
    func addFavoriteGym(userId: String, gymId: String) async throws {
        // Create a consistent document ID
        let favoriteId = "\(userId)_\(gymId)"
        
        // Add to user's favorites collection
        try await db.collection("userFavorites").document(favoriteId).setData([
            "userId": userId,
            "gymId": gymId,
            "createdAt": Timestamp(date: Date())
        ])
    }
    
    /// Remove a gym from user's favorites
    func removeFavoriteGym(userId: String, gymId: String) async throws {
        // Create the document ID
        let favoriteId = "\(userId)_\(gymId)"
        
        // Remove from favorites
        try await db.collection("userFavorites").document(favoriteId).delete()
    }
    
    /// Get all favorite gyms for a user
    func getFavoriteGyms(userId: String) async throws -> [Gym] {
        // Query favorites
        let snapshot = try await db.collection("userFavorites")
            .whereField("userId", isEqualTo: userId)
            .getDocuments()
        
        // Extract gym IDs
        let gymIds = snapshot.documents.compactMap { doc in
            doc.data()["gymId"] as? String
        }
        
        if gymIds.isEmpty {
            return []
        }
        
        // Fetch gyms in batches (Firestore limits in queries to 10 items)
        var favoriteGyms: [Gym] = []
        
        for batch in gymIds.chunked(into: 10) {
            let gymDocs = try await db.collection("gyms")
                .whereField("id", in: batch)
                .getDocuments()
            
            let batchGyms = gymDocs.documents.compactMap { doc in
                Gym(firestoreData: doc.data())
            }
            
            favoriteGyms.append(contentsOf: batchGyms)
        }
        
        return favoriteGyms
    }
    
    /// Check if a gym is in user's favorites
    func isGymFavorite(userId: String, gymId: String) async throws -> Bool {
        let favoriteId = "\(userId)_\(gymId)"
        let doc = try await db.collection("userFavorites").document(favoriteId).getDocument()
        return doc.exists
    }
}

