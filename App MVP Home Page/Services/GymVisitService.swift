//
//  GymVisitService.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 11/04/2025.
//

import Foundation
import FirebaseFirestore

struct GymVisitRecord: FirestoreCodable {
    let id: String                  // Unique ID for the record
    let gymId: String               // Reference to the gym
    let date: Date                  // The visit date (store just the date part)
    let visitors: [VisitorRecord]   // Array of visitors
    
    // Helper struct for visitor data
    struct VisitorRecord: Codable {
        let userId: String          // User ID
        let visitTime: Date         // Specific time they plan to visit
        let visitId: String?        // Optional reference to original visit activity
    }
    
    init(id: String, gymId: String, date: Date, visitors: [VisitorRecord]) {
        self.id = id
        self.gymId = gymId
        self.date = date
        self.visitors = visitors
    }
    
    // FirestoreCodable implementation
    func toFirestoreData() -> [String: Any] {
        return [
            "id": id,
            "gymId": gymId,
            "date": date.firestoreTimestamp,
            "visitors": visitors.map { visitor in
                [
                    "userId": visitor.userId,
                    "visitTime": visitor.visitTime.firestoreTimestamp,
                    "visitId": visitor.visitId as Any
                ]
            }
        ]
    }
    
    init?(firestoreData: [String: Any]) {
        guard
            let id = firestoreData["id"] as? String,
            let gymId = firestoreData["gymId"] as? String,
            let dateTimestamp = firestoreData["date"] as? Timestamp,
            let visitorsData = firestoreData["visitors"] as? [[String: Any]]
        else { return nil }
        
        self.id = id
        self.gymId = gymId
        self.date = dateTimestamp.dateValue
        
        self.visitors = visitorsData.compactMap { visitorData in
            guard
                let userId = visitorData["userId"] as? String,
                let visitTimeTimestamp = visitorData["visitTime"] as? Timestamp
            else { return nil }
            
            return VisitorRecord(
                userId: userId,
                visitTime: visitTimeTimestamp.dateValue,
                visitId: visitorData["visitId"] as? String
            )
        }
    }
}
