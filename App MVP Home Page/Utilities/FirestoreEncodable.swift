//
//  FirestoreEncodable.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 01/03/2025.
//

import Foundation
import FirebaseFirestore

// MARK: - FirestoreEncodable Protocol
protocol FirestoreEncodable {
    /// Convert the object to a dictionary suitable for Firestore
    func toFirestoreData() -> [String: Any]
}

// MARK: - FirestoreDecodable Protocol
protocol FirestoreDecodable {
    /// Initialize from Firestore data
    init?(firestoreData: [String: Any])
}

// MARK: - FirestoreCodable Protocol
typealias FirestoreCodable = FirestoreEncodable & FirestoreDecodable

// MARK: - Date Extensions
extension Date {
    /// Convert Date to Firestore Timestamp
    var firestoreTimestamp: Timestamp {
        return Timestamp(date: self)
    }
}

extension Timestamp {
    /// Convert Firestore Timestamp to Date
    var dateValue: Date {
        return self.dateValue()
    }
}

// MARK: - Helper Functions
/// Helper function to convert an optional string to URL
func stringToURL(_ string: String?) -> URL? {
    guard let string = string, !string.isEmpty else { return nil }
    return URL(string: string)
}

/// Helper function to convert an optional URL to string
func urlToString(_ url: URL?) -> String {
    return url?.absoluteString ?? ""
}

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
