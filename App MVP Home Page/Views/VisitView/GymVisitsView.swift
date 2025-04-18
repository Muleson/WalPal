//
//  GymVisitsView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 12/04/2025.
//

import SwiftUI

struct GymVisitsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = GymVisitViewModel()
    
    // Navigation state
    @State private var navigateToGymProfile: Gym?
    @State private var showingGymProfile = false
    @State private var navigateToUserProfile: User?
    @State private var showingUserProfile = false
    @State private var navigateToCreateVisit = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) { 
                // My Gyms Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("My Gyms")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button {
                            // This would navigate to a view to manage favorite gyms
                        } label: {
                            Text("Manage")
                                .font(.subheadline)
                                .foregroundColor(AppTheme.appButton)
                        }
                    }
                    .padding(.horizontal)
                    
                    if viewModel.isLoading && viewModel.favoriteGyms.isEmpty {
                        ProgressView()
                            .padding(.vertical, 30)
                    } else if viewModel.favoriteGyms.isEmpty {
                        EmptyStateView(
                            title: "No Favorite Gyms",
                            message: "Add gyms to your favorites to see them here",
                            systemImage: "building.2",
                            buttonTitle: "Find Gyms",
                            buttonAction: {
                                // Navigate to gym search/browse view
                            }
                        )
                    } else {
                        // Show favorite gyms
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.favoriteGyms, id: \.gym.id) { gymVisit in
                                ForEach(gymVisit.attendees, id: \.visitId) { userVisit in
                                    VisitPostView(
                                        gymVisit: gymVisit,
                                        userVisit: userVisit,
                                        onDelete: nil, // Add deletion handling if needed
                                        onJoin: isUserAttending(gymId: gymVisit.gym.id) ? nil : {
                                            joinGym(gymId: gymVisit.gym.id)
                                        },
                                        onLeave: isUserAttending(gymId: gymVisit.gym.id) ? {
                                            leaveGym(gymId: gymVisit.gym.id)
                                        } : nil,
                                        onAuthorTapped: { user in
                                            navigateToUserProfile(user)
                                        },
                                        visitsViewModel: viewModel
                                    )
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        navigateToGymProfile(gymVisit.gym)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Friends Activity Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Where Friends Are Climbing")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    if viewModel.isLoading && viewModel.friendVisitedGyms.isEmpty {
                        ProgressView()
                            .padding(.vertical, 30)
                    } else if viewModel.friendVisitedGyms.isEmpty {
                        EmptyStateView(
                            title: "No Friend Activity Today",
                            message: "Your friends haven't scheduled any climbing sessions yet",
                            systemImage: "person.3"
                        )
                    } else {
                        // Show friend-visited gyms
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.friendVisitedGyms, id: \.gym.id) { gymVisit in
                                ForEach(gymVisit.attendees, id: \.visitId) { userVisit in
                                    VisitPostView(
                                        gymVisit: gymVisit,
                                        userVisit: userVisit,
                                        onDelete: nil,
                                        onJoin: isUserAttending(gymId: gymVisit.gym.id) ? nil : {
                                            joinGym(gymId: gymVisit.gym.id)
                                        },
                                        onLeave: isUserAttending(gymId: gymVisit.gym.id) ? {
                                            leaveGym(gymId: gymVisit.gym.id)
                                        } : nil,
                                        onAuthorTapped: { user in
                                            navigateToUserProfile(user)
                                        },
                                        visitsViewModel: viewModel
                                    )
                                    .padding(.horizontal)
                                    .onTapGesture {
                                        navigateToGymProfile(gymVisit.gym)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Check-in Action Button
                Button {
                    navigateToCreateVisit = true
                } label: {
                    HStack {
                        Image(systemName: "mappin.and.ellipse")
                        Text("Check In")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.appButton)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Gym Visits")
        .onAppear {
            if let userId = appState.user?.id {
                Task {
                    await viewModel.loadVisits(for: userId)
                }
            }
        }
        .navigationDestination(isPresented: $showingGymProfile) {
            if let gym = navigateToGymProfile {
                GymProfileView(appState: appState, gym: gym)
            }
        }
        .navigationDestination(isPresented: $showingUserProfile) {
            if let user = navigateToUserProfile {
                ProfileView(appState: appState, profileUser: user)
            }
        }
        .navigationDestination(isPresented: $navigateToCreateVisit) {
            CreateActivityView(appState: appState, initialType: .visit)
        }
        .refreshable {
            if let userId = appState.user?.id {
                await viewModel.loadVisits(for: userId)
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
    
    // MARK: - Helper Methods
    
    private func isUserAttending(gymId: String) -> Bool {
        guard let userId = appState.user?.id else { return false }
        return viewModel.isUserVisitingGym(userId: userId, gymId: gymId)
    }
    
    private func joinGym(gymId: String) {
        guard let userId = appState.user?.id else { return }
        
        Task {
            let _ = await viewModel.joinGymVisit(userId: userId, gymId: gymId)
        }
    }
    
    private func leaveGym(gymId: String) {
        guard let userId = appState.user?.id else { return }
        
        Task {
            let _ = await viewModel.leaveGymVisit(userId: userId, gymId: gymId)
        }
    }
    
    private func navigateToGymProfile(_ gym: Gym) {
        navigateToGymProfile = gym
        showingGymProfile = true
    }
    
    private func navigateToUserProfile(_ user: User) {
        navigateToUserProfile = user
        showingUserProfile = true
    }
}

// Preview for the whole GymVisitsView
#Preview {
    NavigationStack {
        GymVisitsView(
            appState: {
                let appState = AppState()
                appState.user = SampleData.previewUser
                return appState
            }()
        )
    }
}
