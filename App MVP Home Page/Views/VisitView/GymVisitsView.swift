//
//  GymVisitsView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 12/04/2025.
//

import SwiftUI

struct GymVisitsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var visitViewModel = GymVisitViewModel()
    
    @State private var selectedGym: GymVisit? = nil
    @State private var showGymDetail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Featured visits section (using rows instead of full cards for favorite gyms)
                if !visitViewModel.favoriteGyms.isEmpty {
                    Text("Your Favorite Gyms")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(visitViewModel.favoriteGyms) { gymVisit in
                            GymVisitRow(
                                gymVisit: gymVisit,
                                onTap: {
                                    selectedGym = gymVisit
                                    showGymDetail = true
                                },
                                onJoin: visitViewModel.isAttendee(userId: appState.user?.id ?? "", gymVisit: gymVisit) ? nil : {
                                    joinGym(gymId: gymVisit.gym.id)
                                },
                                onLeave: visitViewModel.isAttendee(userId: appState.user?.id ?? "", gymVisit: gymVisit) ? {
                                    leaveGym(gymId: gymVisit.gym.id)
                                } : nil,
                                viewModel: visitViewModel
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Friends' visits section (compact rows)
                if !visitViewModel.friendVisitedGyms.isEmpty {
                    Text("Where Friends Are Climbing")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    VStack(spacing: 8) {
                        ForEach(visitViewModel.friendVisitedGyms) { gymVisit in
                            GymVisitRow(
                                gymVisit: gymVisit,
                                onTap: {
                                    selectedGym = gymVisit
                                    showGymDetail = true
                                },
                                onJoin: visitViewModel.isAttendee(userId: appState.user?.id ?? "", gymVisit: gymVisit) ? nil : {
                                    joinGym(gymId: gymVisit.gym.id)
                                },
                                onLeave: visitViewModel.isAttendee(userId: appState.user?.id ?? "", gymVisit: gymVisit) ? {
                                    leaveGym(gymId: gymVisit.gym.id)
                                } : nil,
                                viewModel: visitViewModel
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Empty state
                if visitViewModel.favoriteGyms.isEmpty && visitViewModel.friendVisitedGyms.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.climbing")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No visits planned today")
                            .font(.headline)
                        
                        Text("Follow friends or add favorite gyms to see visits")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.vertical, 60)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Gym Visits")
        .navigationDestination(isPresented: $showGymDetail) {
            if let gym = selectedGym {
                // Navigate to gym detail view
                GymProfileView(appState: appState, gym: gym.gym)
            }
        }
        .onAppear {
            if let userId = appState.user?.id {
                Task {
                    await visitViewModel.loadVisits(for: userId)
                }
            }
        }
        .refreshable {
            if let userId = appState.user?.id {
                await visitViewModel.loadVisits(for: userId)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func joinGym(gymId: String) {
        if let userId = appState.user?.id {
            Task {
                _ = await visitViewModel.joinGymVisit(userId: userId, gymId: gymId)
            }
        }
    }
    
    private func leaveGym(gymId: String) {
        if let userId = appState.user?.id {
            Task {
                _ = await visitViewModel.leaveGymVisit(userId: userId, gymId: gymId)
            }
        }
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
