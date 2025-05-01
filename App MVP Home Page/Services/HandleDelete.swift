//
//  HandleDelete.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import Foundation

protocol DeletableItem: Identifiable{
    var deletionMessage: String { get }
    var requiresConfirmation: Bool { get }
}

enum DeletionState<T: DeletableItem> {
    case none
    case confirming(T)
}

protocol DeletionManager: ObservableObject {
    associatedtype Item: DeletableItem
    func delete(id: UUID, wasItemPrimary: Bool)
}
