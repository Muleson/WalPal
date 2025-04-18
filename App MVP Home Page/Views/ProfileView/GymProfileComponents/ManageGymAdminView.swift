//
//  ManageGymAdminView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 27/03/2025.
//

import SwiftUI

struct ManageGymAdminsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = GymAdminsViewModel()
    
    let gym: Gym
    
    init(appState: AppState, gym: Gym) {
        self.appState = appState
        self.gym = gym
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    // Admin list section
                    Section {
                        if viewModel.administrators.isEmpty {
                            Text("No administrators found")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(viewModel.administrators) { admin in
                                AdminRow(
                                    admin: admin,
                                    onRemove: viewModel.currentUserRole == .owner ? { removeAdmin(admin) } : nil
                                )
                            }
                        }
                    } header: {
                        Text("Current Administrators")
                    } footer: {
                        if viewModel.currentUserRole == .owner {
                            Text("As the owner, you can add or remove administrators.")
                        } else {
                            Text("Only the owner can add or remove administrators.")
                        }
                    }
                    
                    // Add admin section (only for owners)
                    if viewModel.currentUserRole == .owner {
                        Section(header: Text("Add Administrator")) {
                            Button("Add New Administrator") {
                                viewModel.showAddAdminSheet = true
                            }
                        }
                    }
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .navigationTitle("Manage Administrators")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $viewModel.showAddAdminSheet) {
                AddAdminView(
                    appState: appState,
                    gymId: gym.id,
                    onAdminAdded: { admin in
                        viewModel.administrators.append(admin)
                    }
                )
            }
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .onAppear {
                Task {
                    // Load admin data
                    if let user = appState.user {
                        await viewModel.loadAdmins(for: gym.id, currentUser: user)
                    }
                }
            }
        }
    }
    
    // MARK: - Action Handlers
    
    private func removeAdmin(_ admin: GymAdministratorDisplay) {
        Task {
            await viewModel.removeAdmin(admin)
        }
    }
}

// MARK: - Supporting Views

struct AdminRow: View {
    let admin: GymAdministratorDisplay
    let onRemove: (() -> Void)?
    
    var body: some View {
        HStack {
            // Admin avatar
            if let imageUrl = admin.user?.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.3)
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(admin.user?.firstName.prefix(1) ?? "?")
                            .foregroundColor(.gray)
                    )
            }
            
            // Admin info
            VStack(alignment: .leading, spacing: 4) {
                Text(admin.user?.firstName ?? "Unknown" + " " + (admin.user?.lastName ?? "User"))
                    .font(.headline)
                
                Text(roleTitle(admin.role))
                    .font(.caption)
                    .foregroundColor(roleColor(admin.role))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(roleColor(admin.role).opacity(0.1))
                    .clipShape(Capsule())
            }
            
            Spacer()
            
            // Remove button
            if let onRemove = onRemove {
                Button(action: onRemove) {
                    Image(systemName: "minus.circle.fill")
                        .foregroundColor(.red)
                        .font(.title3)
                }
                .disabled(admin.role == .owner)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func roleTitle(_ role: GymAdministrator.AdminRole) -> String {
        switch role {
        case .owner:
            return "Owner"
        case .admin:
            return "Administrator"
        case .manager:
            return "Manager"
        }
    }
    
    private func roleColor(_ role: GymAdministrator.AdminRole) -> Color {
        switch role {
        case .owner:
            return .purple
        case .admin:
            return .blue
        case .manager:
            return .green
        }
    }
}

// MARK: - Add Admin View

struct AddAdminView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = AddAdminViewModel()
    
    let gymId: String
    let onAdminAdded: (GymAdministratorDisplay) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    // Search field
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search users by name or email", text: $viewModel.searchText)
                            .onChange(of: viewModel.searchText) { oldValue, newValue in
                                // Debounce search
                                viewModel.debounceSearch()
                            }
                        
                        if !viewModel.searchText.isEmpty {
                            Button(action: {
                                viewModel.searchText = ""
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                    
                    // Role selector
                    Picker("Role", selection: $viewModel.selectedRole) {
                        Text("Admin").tag(GymAdministrator.AdminRole.admin)
                        Text("Manager").tag(GymAdministrator.AdminRole.manager)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    if viewModel.isSearching {
                        ProgressView()
                            .padding()
                    } else if viewModel.searchResults.isEmpty && !viewModel.searchText.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            
                            Text("No users found")
                                .font(.headline)
                            
                            Text("Try a different search term")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 40)
                    } else {
                        // Search results
                        List {
                            ForEach(viewModel.searchResults) { user in
                                Button(action: {
                                    Task {
                                        if let admin = await viewModel.addAdmin(
                                            userId: user.id,
                                            gymId: gymId,
                                            role: viewModel.selectedRole,
                                            addedBy: appState.user?.id ?? ""
                                        ) {
                                            onAdminAdded(admin)
                                            dismiss()
                                        }
                                    }
                                }) {
                                    HStack {
                                        // User avatar
                                        if let imageUrl = user.imageUrl {
                                            AsyncImage(url: imageUrl) { image in
                                                image
                                                    .resizable()
                                                    .scaledToFill()
                                            } placeholder: {
                                                Color.gray.opacity(0.3)
                                            }
                                            .frame(width: 40, height: 40)
                                            .clipShape(Circle())
                                        } else {
                                            Circle()
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(width: 40, height: 40)
                                                .overlay(
                                                    Text(user.firstName.prefix(1))
                                                        .foregroundColor(.gray)
                                                )
                                        }
                                        
                                        // User info
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(user.firstName) \(user.lastName)")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            Text(user.email)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .listStyle(PlainListStyle())
                    }
                    
                    Spacer()
                }
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .navigationTitle("Add Administrator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        ManageGymAdminsView(
            appState: {
                let appState = AppState()
                appState.user = SampleData.previewUser
                return appState
            }(),
            gym: SampleData.previewGym
        )
    }
}
