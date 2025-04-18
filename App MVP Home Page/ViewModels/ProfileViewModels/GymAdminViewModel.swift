//
//  GymAdminViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 27/03/2025.
//

import Foundation
import SwiftUI


// MARK: - GymAdminsViewModel

@MainActor
class GymAdminsViewModel: ObservableObject {
    @Published var administrators: [GymAdministratorDisplay] = []
    @Published var currentUserRole: GymAdministrator.AdminRole?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showAddAdminSheet = false
    
    private let permissionsService = PermissionsService()
    private let userRepository = UserRepositoryService()
    
    // MARK: - Public Methods
    
    func loadAdmins(for gymId: String, currentUser: User) async {
        isLoading = true
        
        do {
            // Get all admins for this gym using PermissionsService
            let admins = try await permissionsService.getGymAdministrators(gymId: gymId)
            
            // Check if current user is an administrator
            let currentUserAdmin = admins.first { $0.userId == currentUser.id }
            currentUserRole = currentUserAdmin?.role
            
            // Get user data for each admin
            var adminDisplays: [GymAdministratorDisplay] = []
            
            for admin in admins {
                let user = try? await userRepository.getUser(id: admin.userId)
                let adminDisplay = GymAdministratorDisplay.from(admin: admin, user: user)
                adminDisplays.append(adminDisplay)
            }
            
            administrators = adminDisplays.sorted { a, b in
                // Sort by role first (owner first, then admin, then manager)
                if a.role != b.role {
                    if a.role == .owner { return true }
                    if b.role == .owner { return false }
                    if a.role == .admin { return true }
                    if b.role == .admin { return false }
                }
                
                // Then sort by added date
                return a.addedAt > b.addedAt
            }
            
            isLoading = false
        } catch {
            errorMessage = "Error loading administrators: \(error.localizedDescription)"
            isLoading = false
        }
    }
    
    func removeAdmin(_ admin: GymAdministratorDisplay) async {
        // Can't remove an owner
        guard admin.role != .owner else {
            errorMessage = "Cannot remove the owner"
            return
        }
        
        isLoading = true
        
        do {
            // Use the PermissionsService to remove the admin
            try await permissionsService.removeGymAdministrator(adminId: admin.id)
            
            // Remove from local array
            administrators.removeAll { $0.id == admin.id }
            
            isLoading = false
        } catch {
            errorMessage = "Error removing administrator: \(error.localizedDescription)"
            isLoading = false
        }
    }
}

// MARK: - AddAdminViewModel

@MainActor
class AddAdminViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var searchResults: [User] = []
    @Published var selectedRole: GymAdministrator.AdminRole = .manager
    @Published var isSearching = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let permissionsService = PermissionsService()
    private let userRepository = UserRepositoryService()
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Public Methods
    
    func debounceSearch() {
        // Cancel any existing search
        searchTask?.cancel()
        
        // Create a new search task with a delay
        searchTask = Task {
            // Only search if we have at least 3 characters
            guard searchText.count >= 3 else {
                searchResults = []
                return
            }
            
            // Wait a bit before searching to avoid too many queries
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            guard !Task.isCancelled else { return }
            
            await search()
        }
    }
    
    func addAdmin(userId: String, gymId: String, role: GymAdministrator.AdminRole, addedBy: String) async -> GymAdministratorDisplay? {
        isLoading = true
        
        do {
            // Check if user is already an admin through PermissionsService
            let isAlreadyAdmin = try await permissionsService.isUserAdminForGym(userId: userId, gymId: gymId)
            
            if isAlreadyAdmin {
                errorMessage = "This user is already an administrator"
                isLoading = false
                return nil
            }
            
            // Create a new admin entry
            let admin = try await permissionsService.addGymAdministrator(
                userId: userId,
                gymId: gymId,
                role: role,
                addedBy: addedBy
            )
            
            // Get the user data
            let user = try await userRepository.getUser(id: userId)
            
            // Create display model
            let adminDisplay = GymAdministratorDisplay.from(admin: admin, user: user)
            
            isLoading = false
            return adminDisplay
        } catch {
            errorMessage = "Error adding administrator: \(error.localizedDescription)"
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Private Methods
    
    private func search() async {
        isSearching = true
        
        do {
            // Use UserRepository to search for users
            let results = try await userRepository.searchUsers(query: searchText)
            searchResults = results
            isSearching = false
        } catch {
            errorMessage = "Error searching users: \(error.localizedDescription)"
            isSearching = false
        }
    }
}


// MARK: - Display Models

struct GymAdministratorDisplay: Identifiable, Equatable {
    let id: String
    let userId: String
    let gymId: String
    let role: GymAdministrator.AdminRole
    let addedAt: Date
    let addedBy: String
    let user: User?
    
    // Create from a GymAdministrator model
    static func from(admin: GymAdministrator, user: User?) -> GymAdministratorDisplay {
        return GymAdministratorDisplay(
            id: admin.id,
            userId: admin.userId,
            gymId: admin.gymId,
            role: admin.role,
            addedAt: admin.addedAt,
            addedBy: admin.addedBy,
            user: user
        )
    }
}
