//
//  ActivityRepository.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class ActivityRepositoryService {
    let db = Firestore.firestore()
    private let gymService = GymService()
    private let userRepository: UserRepositoryService
    
    init(userRepository: UserRepositoryService = UserRepositoryService(),
           gymService: GymService = GymService()) {
          self.userRepository = userRepository
      }
    
    // MARK: - Create Methods
    
    func createBasicPost(author: User, content: String, mediaURL: URL? = nil, isFeatured: Bool = false) async throws -> BasicPost {
        let newPost = BasicPost(
            id: UUID().uuidString,
            author: author,
            content: content,
            mediaURL: mediaURL,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            isFeatured: isFeatured
        )
        
        try await db.collection("activityItems").document(newPost.id).setData(newPost.toFirestoreData())
        
        // Increment post count for user
        try await db.collection("users").document(author.id).updateData([
            "postCount": FieldValue.increment(Int64(1))
        ])
        
        return newPost
    }

    func createBetaPost(author: User, content: String, gym: Gym, mediaURL: URL? = nil, isFeatured: Bool = false) async throws -> BetaPost {
        let newPost = BetaPost(
            id: UUID().uuidString,
            author: author,
            content: content,
            mediaURL: mediaURL,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            gym: gym,
            viewCount: 0,
            isFeatured: isFeatured
        )
        
        try await db.collection("activityItems").document(newPost.id).setData(newPost.toFirestoreData())
        
        // Increment post count for user
        try await db.collection("users").document(author.id).updateData([
            "postCount": FieldValue.increment(Int64(1))
        ])
        
        return newPost
    }

    func createEventPost(
        author: User,
        title: String,
        description: String?,
        eventDate: Date,
        location: String,
        maxAttendees: Int,
        gym: Gym?,
        mediaURL: URL? = nil,
        isFeatured: Bool = false
    ) async throws -> EventPost {
        let newPost = EventPost(
            id: UUID().uuidString,
            author: author,
            title: title,
            description: description,
            mediaURL: mediaURL,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            eventDate: eventDate,
            location: location,
            maxAttendees: maxAttendees,
            registered: 0,
            gym: gym,
            isFeatured: isFeatured
        )
        
        try await db.collection("activityItems").document(newPost.id).setData(newPost.toFirestoreData())
        
        // Increment post count for user
        try await db.collection("users").document(author.id).updateData([
            "postCount": FieldValue.increment(Int64(1))
        ])
        
        return newPost
    }

    func createVisit(
        author: User,
        gym: Gym,
        visitDate: Date,
        duration: TimeInterval,
        description: String? = nil,
        isFeatured: Bool = false
    ) async throws -> GroupVisit {
        let newVisit = GroupVisit(
            id: UUID().uuidString,
            author: author,
            createdAt: Date(),
            likeCount: 0,
            commentCount: 0,
            gym: gym,
            visitDate: visitDate,
            duration: duration,
            description: description,
            attendees: [author.id],
            status: .planned,
            isFeatured: isFeatured
        )
        
        try await db.collection("activityItems").document(newVisit.id).setData(newVisit.toFirestoreData())
        
        return newVisit
    }
    
    // MARK: - Fetch Methods
    
    func fetchAllActivityItems() async throws -> [any ActivityItem] {
        let snapshot = try await db.collection("activityItems")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try await processActivitySnapshotDocuments(snapshot.documents)
    }
    
    func fetchUserActivityItems(userId: String) async throws -> [any ActivityItem] {
        let snapshot = try await db.collection("activityItems")
            .whereField("authorId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try await processActivitySnapshotDocuments(snapshot.documents)
    }
    
    func fetchGymActivityItems(gymId: String) async throws -> [any ActivityItem] {
        let snapshot = try await db.collection("activityItems")
            .whereField("gymId", isEqualTo: gymId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try await processActivitySnapshotDocuments(snapshot.documents)
    }
    
    func fetchFollowingFeed(userId: String) async throws -> [any ActivityItem] {
        // Step 1: Get IDs of users the current user is following
        let relationshipService = UserRelationshipService()
        let followingUsers = try await relationshipService.getFollowing(userId: userId)
        let followingIds = followingUsers.map { $0.id }
        
        // Add current user to include their posts too
        var userIds = followingIds
        userIds.append(userId)
        
        // Step 2: Construct a query to get posts from these users
        if userIds.isEmpty {
            // If not following anyone, just show an empty feed
            return []
        } else {
            let snapshot = try await db.collection("activityItems")
                .whereField("authorId", in: userIds)
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            // Process the documents
            return try await processActivitySnapshotDocuments(snapshot.documents)
        }
    }
    
    // Helper method to process documents and turn them into the right activity item types
    private func processActivitySnapshotDocuments(_ documents: [QueryDocumentSnapshot]) async throws -> [any ActivityItem] {
        var activityItems: [any ActivityItem] = []
        
        for document in documents {
            let data = document.data()
            
            // Check the type of activity item
            guard let typeString = data["type"] as? String else { continue }
            
            // Get author ID
            guard let authorId = data["authorId"] as? String else { continue }
            
            // Fetch the author user
            let author: User
                        do {
                            author = try await userRepository.getUser(id: authorId)
                        } catch {
                            print("Error fetching author for activity item: \(error)")
                            continue
                        }
            
            // Process based on type
            switch typeString {
            case "basic":
                if let basicPost = BasicPost(firestoreData: data, author: author) {
                    activityItems.append(basicPost)
                }
                
            case "beta", "event", "visit":
                // These types require gym data
                if let gymId = data["gymId"] as? String {
                    let gym = try await gymService.fetchGym(id: gymId)
                    
                    // Only proceed if we could fetch the gym
                    if let gym = gym {
                        if typeString == "beta" {
                            if let betaPost = BetaPost(firestoreData: data, author: author, gym: gym) {
                                activityItems.append(betaPost)
                            }
                        } else if typeString == "event" {
                            if let eventPost = EventPost(firestoreData: data, author: author, gym: gym) {
                                activityItems.append(eventPost)
                            }
                        } else if typeString == "visit" {
                            if let visit = GroupVisit(firestoreData: data, author: author, gym: gym) {
                                activityItems.append(visit)
                            }
                        }
                    }
                } else if typeString == "event" {
                    // Events can exist without a gym
                    if let eventPost = EventPost(firestoreData: data, author: author, gym: nil) {
                        activityItems.append(eventPost)
                    }
                }
                
            default:
                // Unknown type, skip
                continue
            }
        }
        
        return activityItems
    }
    
    // MARK: - Engagement Methods
    
    func likeActivityItem(itemId: String, userId: String) async throws {
        // Check if we have an authenticated user
        guard Auth.auth().currentUser != nil else {
            throw NSError(
                domain: "ActivityRepositoryService",
                code: 401,
                userInfo: [NSLocalizedDescriptionKey: "User must be authenticated to like items"]
            )
        }
        
        // Create a reference to the likes collection
        let likeRef = db.collection("activityItems").document(itemId)
            .collection("likes").document(userId)
        
        // Check if the user has already liked this item
        let likeDoc = try await likeRef.getDocument()
        
        // If the user hasn't liked this item yet
        if !likeDoc.exists {
            // Add user to likes collection
            try await likeRef.setData([
                "userId": userId,
                "timestamp": Timestamp(date: Date())
            ])
            
            // Increment the item's like count
            try await db.collection("activityItems").document(itemId).updateData([
                "likeCount": FieldValue.increment(Int64(1))
            ])
        }
    }
    
    func unlikeActivityItem(itemId: String, userId: String) async throws {
        // Create a reference to the like document
        let likeRef = db.collection("activityItems").document(itemId)
            .collection("likes").document(userId)
        
        // Check if the user has liked this item
        let likeDoc = try await likeRef.getDocument()
        
        // If the user has liked this item
        if likeDoc.exists {
            // Remove user from likes collection
            try await likeRef.delete()
            
            // Decrement the item's like count
            try await db.collection("activityItems").document(itemId).updateData([
                "likeCount": FieldValue.increment(Int64(-1))
            ])
        }
    }
    
    func getUserLikedItems(userId: String) async throws -> [String] {
        var likedItemIds: [String] = []
        
        // Get all activity items
        let snapshot = try await db.collection("activityItems").getDocuments()
        
        // Check each item for a like from this user
        for document in snapshot.documents {
            let likeDoc = try await db.collection("activityItems")
                .document(document.documentID)
                .collection("likes")
                .document(userId)
                .getDocument()
            
            if likeDoc.exists {
                likedItemIds.append(document.documentID)
            }
        }
        
        return likedItemIds
    }
    
    // MARK: - Comment Methods
    
    func updateCommentCount(itemId: String, increment: Bool) async throws {
        try await db.collection("activityItems").document(itemId).updateData([
            "commentCount": FieldValue.increment(Int64(increment ? 1 : -1))
        ])
    }
    
    // MARK: - Visit-specific Methods
    
    func joinVisit(visitId: String, userId: String) async throws {
        // Get the current visit document
        let visitDoc = try await db.collection("activityItems").document(visitId).getDocument()
        guard visitDoc.exists else {
            throw NSError(
                domain: "ActivityRepositoryService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Visit not found"]
            )
        }
        
        // Check if it's actually a visit
        guard let data = visitDoc.data(),
              let typeString = data["type"] as? String,
              typeString == "visit" else {
            throw NSError(
                domain: "ActivityRepositoryService",
                code: 400,
                userInfo: [NSLocalizedDescriptionKey: "Item is not a visit"]
            )
        }
        
        // Get current attendees
        guard var attendees = data["attendees"] as? [String] else {
            throw NSError(
                domain: "ActivityRepositoryService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Could not read attendees list"]
            )
        }
        
        // Check if user is already attending
        if !attendees.contains(userId) {
            // Add user to attendees
            attendees.append(userId)
            
            // Update the visit document
            try await db.collection("activityItems").document(visitId).updateData([
                "attendees": attendees
            ])
        }
    }
    
    func leaveVisit(visitId: String, userId: String) async throws {
        // Get the current visit document
        let visitDoc = try await db.collection("activityItems").document(visitId).getDocument()
        guard visitDoc.exists else {
            throw NSError(
                domain: "ActivityRepositoryService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Visit not found"]
            )
        }
        
        // Get current attendees
        guard let data = visitDoc.data(),
              var attendees = data["attendees"] as? [String] else {
            throw NSError(
                domain: "ActivityRepositoryService",
                code: 500,
                userInfo: [NSLocalizedDescriptionKey: "Could not read attendees list"]
            )
        }
        
        // Remove user from attendees if they're in the list
        if let index = attendees.firstIndex(of: userId) {
            attendees.remove(at: index)
            
            // Update the visit document
            try await db.collection("activityItems").document(visitId).updateData([
                "attendees": attendees
            ])
        }
    }
    
    func updateVisitStatus(visitId: String, newStatus: GroupVisit.VisitStatus) async throws {
        // Update the visit status
        try await db.collection("activityItems").document(visitId).updateData([
            "status": newStatus.rawValue
        ])
    }
    
    func fetchFriendsVisitsToday(userId: String) async throws -> [GymWithVisits] {
        // Get the user's following list
        let relationshipService = UserRelationshipService(userRepository: userRepository)
        let following = try await relationshipService.getFollowing(userId: userId)
        let followingIds = following.map { $0.id }
        
        if followingIds.isEmpty {
            return []
        }
        
        // Find visits for today from these users
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        let snapshot = try await db.collection("activityItems")
            .whereField("type", isEqualTo: "visit")
            .whereField("authorId", in: followingIds)
            .whereField("visitDate", isGreaterThanOrEqualTo: today.firestoreTimestamp)
            .whereField("visitDate", isLessThan: tomorrow.firestoreTimestamp)
            .getDocuments()
        
        // Process visits using the cached user data already fetched by relationshipService
        let visits = try await processVisitDocuments(snapshot.documents)
        
        // Group by gym
        let groupedByGym = Dictionary(grouping: visits) { visit in
            return visit.gym.id
        }
        
        // Convert to GymWithVisits array
        return groupedByGym.map { gymId, visits in
            let gym = visits.first!.gym
            let visitorInfos = visits.map { visit in
                VisitorInfo(user: visit.author, visitDate: visit.visitDate)
            }
            return GymWithVisits(gym: gym, visitors: visitorInfos)
        }
    }
    
    // Helper method to process visit documents and convert them to Visit objects
    private func processVisitDocuments(_ documents: [QueryDocumentSnapshot]) async throws -> [GroupVisit] {
            var visits: [GroupVisit] = []
            
            for document in documents {
                let data = document.data()
                
                // Verify it's a visit
                guard
                    let typeString = data["type"] as? String,
                    typeString == "visit",
                    let authorId = data["authorId"] as? String,
                    let gymId = data["gymId"] as? String
                else { continue }
                
                // Use userRepository to get author
                let author: User
                do {
                    author = try await userRepository.getUser(id: authorId)
                } catch {
                    print("Error fetching author for visit: \(error)")
                    continue
                }
                
                // Fetch the gym
                let gymDoc = try await db.collection("gyms").document(gymId).getDocument()
                guard
                    gymDoc.exists,
                    let gymData = gymDoc.data(),
                    let gym = Gym(firestoreData: gymData)
                else { continue }
                
                // Now we can try to create the Visit object
                if let visit = GroupVisit(firestoreData: data, author: author, gym: gym) {
                    visits.append(visit)
                }
            }
            return visits
        }
    
    // MARK: - Delete Methods
    
    func deleteActivityItem(itemId: String) async throws {
        // First get the item to check for author ID and type
        let itemDoc = try await db.collection("activityItems").document(itemId).getDocument()
        guard let data = itemDoc.data(),
              let authorId = data["authorId"] as? String,
              let typeString = data["type"] as? String else {
            throw NSError(
                domain: "ActivityRepositoryService",
                code: 404,
                userInfo: [NSLocalizedDescriptionKey: "Activity item not found or invalid"]
            )
        }
        
        // Delete the document
        try await db.collection("activityItems").document(itemId).delete()
        
        // If this was a post type (basic, beta, event), update the user's post count
        if typeString == "basic" || typeString == "beta" || typeString == "event" {
            try await db.collection("users").document(authorId).updateData([
                "postCount": FieldValue.increment(Int64(-1))
            ])
        }
        
        // Delete all related subcollections (likes, comments)
        // Note: This is a simple approach. For a production app, consider using Firebase Functions
        // to handle cascading deletes or implement more robust deletion logic.
        
        // Delete likes
        let likesSnapshot = try await db.collection("activityItems").document(itemId)
            .collection("likes").getDocuments()
        
        for likeDoc in likesSnapshot.documents {
            try await db.collection("activityItems").document(itemId)
                .collection("likes").document(likeDoc.documentID).delete()
        }
        
        // Delete comments
        let commentsSnapshot = try await db.collection("activityItems").document(itemId)
            .collection("comments").getDocuments()
        
        for commentDoc in commentsSnapshot.documents {
            try await db.collection("activityItems").document(itemId)
                .collection("comments").document(commentDoc.documentID).delete()
        }
    }
    
    // MARK: - Featured Item Methods

    /// Toggle the featured status of an activity item
    /// - Parameters:
    ///   - itemId: The ID of the item to toggle
    ///   - featured: The new featured status
    func toggleItemFeatured(itemId: String, featured: Bool) async throws {
        // Update the item's featured status
        try await db.collection("activityItems").document(itemId).updateData([
            "isFeatured": featured
        ])
    }

    /// Fetch only featured activity items
    /// - Returns: Array of featured activity items
    func fetchFeaturedActivityItems() async throws -> [any ActivityItem] {
        let snapshot = try await db.collection("activityItems")
            .whereField("isFeatured", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try await processActivitySnapshotDocuments(snapshot.documents)
    }

    /// Fetch featured items of a specific type
    /// - Parameter type: The type of activity items to fetch ("basic", "beta", "event", "visit")
    /// - Returns: Array of featured activity items of the specified type
    func fetchFeaturedItemsByType(type: String) async throws -> [any ActivityItem] {
        let snapshot = try await db.collection("activityItems")
            .whereField("isFeatured", isEqualTo: true)
            .whereField("type", isEqualTo: type)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return try await processActivitySnapshotDocuments(snapshot.documents)
    }
}

extension ActivityRepositoryService {
    
    // MARK: - Paginated Fetch Methods
    
    // Fetch paginated activity items
    func fetchPaginatedActivityItems(pageSize: Int, lastDocument: DocumentSnapshot?) async throws -> (items: [any ActivityItem], lastDocument: DocumentSnapshot?, hasMore: Bool) {
        // Create query
        var query = db.collection("activityItems")
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize + 1) // Fetch one extra to check if there are more items
        
        // If we have a last document, start after it
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        // Fetch documents
        let snapshot = try await query.getDocuments()
        
        // Check if there are more items
        let hasMore = snapshot.documents.count > pageSize
        
        // Process only pageSize items (or fewer if that's all we got)
        let documentsToProcess = hasMore ? Array(snapshot.documents.prefix(pageSize)) : snapshot.documents
        
        // Process and convert documents to activity items
        let activityItems = try await processActivitySnapshotDocuments(documentsToProcess)
        
        // Return the last document for pagination
        let lastDocForPagination = documentsToProcess.last
        
        return (activityItems, lastDocForPagination, hasMore)
    }
    
    // Fetch paginated activity items for a specific user
    func fetchPaginatedUserActivityItems(userId: String, pageSize: Int, lastDocument: DocumentSnapshot?) async throws -> (items: [any ActivityItem], lastDocument: DocumentSnapshot?, hasMore: Bool) {
        // Create query
        var query = db.collection("activityItems")
            .whereField("authorId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize + 1)
        
        // If we have a last document, start after it
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        // Fetch documents
        let snapshot = try await query.getDocuments()
        
        // Check if there are more items
        let hasMore = snapshot.documents.count > pageSize
        
        // Process only pageSize items (or fewer if that's all we got)
        let documentsToProcess = hasMore ? Array(snapshot.documents.prefix(pageSize)) : snapshot.documents
        
        // Process and convert documents to activity items
        let activityItems = try await processActivitySnapshotDocuments(documentsToProcess)
        
        // Return the last document for pagination
        let lastDocForPagination = documentsToProcess.last
        
        return (activityItems, lastDocForPagination, hasMore)
    }
    
    // Fetch paginated feed of followed users
    func fetchPaginatedFollowingFeed(userId: String, pageSize: Int, lastDocument: DocumentSnapshot?) async throws -> (items: [any ActivityItem], lastDocument: DocumentSnapshot?, hasMore: Bool) {
        // Step 1: Get IDs of users the current user is following
        let relationshipService = UserRelationshipService()
        let followingUsers = try await relationshipService.getFollowing(userId: userId)
        let followingIds = followingUsers.map { $0.id }
        
        // Add current user to include their posts too
        var userIds = followingIds
        userIds.append(userId)
        
        // If not following anyone, just show an empty feed
        if userIds.isEmpty {
            return ([], nil, false)
        }
        
        // Step 2: Construct a paginated query
        var query = db.collection("activityItems")
            .whereField("authorId", in: userIds)
            .order(by: "createdAt", descending: true)
            .limit(to: pageSize + 1)
        
        // If we have a last document, start after it
        if let lastDocument = lastDocument {
            query = query.start(afterDocument: lastDocument)
        }
        
        // Fetch documents
        let snapshot = try await query.getDocuments()
        
        // Check if there are more items
        let hasMore = snapshot.documents.count > pageSize
        
        // Process only pageSize items (or fewer if that's all we got)
        let documentsToProcess = hasMore ? Array(snapshot.documents.prefix(pageSize)) : snapshot.documents
        
        // Process and convert documents to activity items
        let activityItems = try await processActivitySnapshotDocuments(documentsToProcess)
        
        // Return the last document for pagination
        let lastDocForPagination = documentsToProcess.last
        
        return (activityItems, lastDocForPagination, hasMore)
    }
}

extension ActivityRepositoryService {
    // Simple search method that can be expanded upon
    func searchActivities(query: String) async throws -> [any ActivityItem] {
        let normalizedQuery = query.lowercased()
        
        // Fetch all activity items
        let allItems = try await fetchAllActivityItems()
        
        // Filter based on the query
        return allItems.filter { item in
            if let basicPost = item as? BasicPost {
                return basicPost.content.lowercased().contains(normalizedQuery)
            } else if let betaPost = item as? BetaPost {
                return betaPost.content.lowercased().contains(normalizedQuery) ||
                betaPost.gym.name.lowercased().contains(normalizedQuery)
            } else if let eventPost = item as? EventPost {
                return eventPost.title.lowercased().contains(normalizedQuery) ||
                (eventPost.description?.lowercased().contains(normalizedQuery) ?? false) ||
                eventPost.location.lowercased().contains(normalizedQuery) ||
                (eventPost.gym?.name.lowercased().contains(normalizedQuery) ?? false)
            } else if let visit = item as? GroupVisit {
                return (visit.description?.lowercased().contains(normalizedQuery) ?? false) ||
                visit.gym.name.lowercased().contains(normalizedQuery)
            }
            return false
        }
    }
    
    // Search for activities by tag or category
    func searchByTag(tag: String) async throws -> [any ActivityItem] {
        // In a real implementation, you might have tags stored with activities
        // This is just a placeholder example
        
        let normalizedTag = tag.lowercased()
        let allItems = try await fetchAllActivityItems()
        
        return allItems.filter { item in
            if normalizedTag == "beta", item is BetaPost {
                return true
            } else if normalizedTag == "event", item is EventPost {
                return true
            } else if normalizedTag == "visit", item is GroupVisit {
                return true
            }
            return false
        }
    }
}
