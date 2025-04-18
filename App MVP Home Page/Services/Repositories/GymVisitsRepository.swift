//
//  GymVisitsRepository.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 11/04/2025.
//

import Foundation
import FirebaseFirestore

class GymVisitRepository {
    private let db = Firestore.firestore()
    private let userRepository = UserRepositoryService()
    private let gymService = GymService()
    
    // MARK: - Gym Visit Management
    
    /// Add a user to a gym's visitors for a specific date
    func addUserToGymVisit(userId: String, gymId: String, visitTime: Date, visitId: String? = nil) async throws {
        // Get the date portion for consistent querying
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: visitTime)
        
        // Create the gym visit document ID using a consistent format
        let gymVisitId = "\(gymId)_\(formatDateForId(dateOnly))"
        
        // Reference to the document
        let gymVisitRef = db.collection("gymVisits").document(gymVisitId)
        
        // Check if the document exists
        let docSnapshot = try await gymVisitRef.getDocument()
        
        if docSnapshot.exists {
            // Check if this user is already in the visitors array
            if let data = docSnapshot.data(),
               let gymVisit = GymVisitRecord(firestoreData: data),
               gymVisit.visitors.contains(where: { $0.userId == userId }) {
                // User already in visitors, so just return
                return
            }
            
            // Document exists, add visitor to the array
            try await gymVisitRef.updateData([
                "visitors": FieldValue.arrayUnion([
                    [
                        "userId": userId,
                        "visitTime": visitTime.firestoreTimestamp,
                        "visitId": visitId as Any
                    ]
                ])
            ])
        } else {
            // Document doesn't exist, create it
            let gymVisit = GymVisitRecord(
                id: gymVisitId,
                gymId: gymId,
                date: dateOnly,
                visitors: [
                    GymVisitRecord.VisitorRecord(
                        userId: userId,
                        visitTime: visitTime,
                        visitId: visitId
                    )
                ]
            )
            
            try await gymVisitRef.setData(gymVisit.toFirestoreData())
        }
    }
    
    /// Remove a user from a gym's visitors list
    func removeUserFromGymVisit(userId: String, gymId: String, date: Date) async throws {
        // Get the date portion
        let calendar = Calendar.current
        let dateOnly = calendar.startOfDay(for: date)
        
        // Create the gym visit document ID
        let gymVisitId = "\(gymId)_\(formatDateForId(dateOnly))"
        
        // Get the document
        let gymVisitRef = db.collection("gymVisits").document(gymVisitId)
        let docSnapshot = try await gymVisitRef.getDocument()
        
        // If document exists, remove this visitor
        if docSnapshot.exists,
           let data = docSnapshot.data(),
           let gymVisit = GymVisitRecord(firestoreData: data) {
            
            // Filter out this user's records
            let updatedVisitors = gymVisit.visitors.filter { $0.userId != userId }
            
            if updatedVisitors.isEmpty {
                // If no visitors left, delete the document
                try await gymVisitRef.delete()
            } else {
                // Update with filtered visitor list
                try await gymVisitRef.updateData([
                    "visitors": updatedVisitors.map { visitor in
                        [
                            "userId": visitor.userId,
                            "visitTime": visitor.visitTime.firestoreTimestamp,
                            "visitId": visitor.visitId as Any
                        ]
                    }
                ])
            }
        }
    }
    
    /// Get all visitors for a specific gym today
    func getGymVisitorsToday(gymId: String) async throws -> [UserVisit] {
        // Get today's date
        let today = Calendar.current.startOfDay(for: Date())
        
        // Create the gym visit document ID
        let gymVisitId = "\(gymId)_\(formatDateForId(today))"
        
        // Get the document
        let gymVisitRef = db.collection("gymVisits").document(gymVisitId)
        let docSnapshot = try await gymVisitRef.getDocument()
        
        // If document exists, extract visitor info
        guard
            docSnapshot.exists,
            let data = docSnapshot.data(),
            let gymVisit = GymVisitRecord(firestoreData: data)
        else {
            return []
        }
        
        // Get all user data in batch
        let userIds = gymVisit.visitors.map { $0.userId }
        let usersMap = try await userRepository.getUsersMap(ids: userIds)
        
        // Create UserVisit objects
        return gymVisit.visitors.compactMap { visitor -> UserVisit? in
            guard let user = usersMap[visitor.userId] else { return nil }
            
            return UserVisit(
                visitId: visitor.visitId ?? UUID().uuidString,
                user: user,
                visitDate: visitor.visitTime
            )
        }
    }
    
    /// Get all gyms with friends visiting today
    func getGymsWithFriendsToday(userId: String) async throws -> [GymVisit] {
        // 1. Get the user's friend list (one query)
        let relationshipService = UserRelationshipService()
        let friendIds = try await relationshipService.getFollowingIds(userId: userId)
        
        if friendIds.isEmpty {
            return []
        }
        
        // 2. Get today's date
        let today = Calendar.current.startOfDay(for: Date())
        
        // 3. Find all gym visits for today (single query)
        let snapshot = try await db.collection("gymVisits")
            .whereField("date", isEqualTo: today.firestoreTimestamp)
            .getDocuments()
        
        // 4. Process the results and filter for friends
        var gymsWithFriendVisits: [String: [GymVisitRecord.VisitorRecord]] = [:]
        
        for document in snapshot.documents {
            guard let gymVisit = GymVisitRecord(firestoreData: document.data()) else {
                continue
            }
            
            // Filter visitors to just friends
            let friendVisitors = gymVisit.visitors.filter { visitor in
                friendIds.contains(visitor.userId)
            }
            
            if !friendVisitors.isEmpty {
                gymsWithFriendVisits[gymVisit.gymId] = friendVisitors
            }
        }
        
        // 5. If no gyms with friends, return empty array
        if gymsWithFriendVisits.isEmpty {
            return []
        }
        
        // 6. Batch fetch gym data
        let gymIds = Array(gymsWithFriendVisits.keys)
        let gymsMap = try await gymService.fetchGymsMap(ids: gymIds)
        
        // 7. Batch fetch user data
        let userIds = Set(gymsWithFriendVisits.values.flatMap { $0.map { $0.userId } })
        let usersMap = try await userRepository.getUsersMap(ids: Array(userIds))
        
        // 8. Build final result
        return gymIds.compactMap { gymId -> GymVisit? in
            guard
                let gym = gymsMap[gymId],
                let visitors = gymsWithFriendVisits[gymId]
            else { return nil }
            
            let userVisits = visitors.compactMap { visitor -> UserVisit? in
                guard let user = usersMap[visitor.userId] else { return nil }
                
                return UserVisit(
                    visitId: visitor.visitId ?? UUID().uuidString,
                    user: user,
                    visitDate: visitor.visitTime
                )
            }
            
            if userVisits.isEmpty {
                return nil
            }
            
            return GymVisit(
                gym: gym,
                attendees: userVisits,
                isFavourite: false // These are friend visits, not favorites
            )
        }
        .sorted { $0.attendees.count > $1.attendees.count }
    }
    
    // MARK: - Helper Methods
    
    private func formatDateForId(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        return formatter.string(from: date)
    }
}
