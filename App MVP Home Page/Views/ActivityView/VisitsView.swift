//
//  VisitsView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 11/03/2025.
//

import SwiftUI

struct VisitsView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = VisitsViewModel()
    @State private var showCreateVisit = false
    @State private var selectedGymForVisit: Gym?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header section
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Friend Activity")
                            .font(.appHeadline)
                            .foregroundColor(.appTextPrimary)
                        
                        Spacer()
                        
                        Button {
                            // Use your existing CreateActivityView with visit type
                            showCreateVisit = true
                        } label: {
                            Text("+ New Visit")
                                .font(.appSubheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(AppTheme.appButton)
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    
                    Text("See where your friends are climbing today")
                        .font(.appSubheadline)
                        .foregroundColor(.appTextLight)
                        .padding(.horizontal)
                }
                .padding(.top)
                
                // Gym visits cards
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                } else if viewModel.gymVisits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "figure.climbing")
                            .font(.system(size: 60))
                            .foregroundColor(.gray.opacity(0.5))
                        
                        Text("No friends climbing right now")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("When your friends plan gym visits, they'll appear here")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button {
                            showCreateVisit = true
                        } label: {
                            Text("Plan a Visit")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(AppTheme.appButton)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.vertical, 60)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.gymVisits) { gymVisit in
                            VisitCardView(
                                gymVisit: gymVisit,
                                onJoin: {
                                    selectedGymForVisit = gymVisit.gym
                                    showCreateVisit = true
                                }
                            )
                            .padding(.horizontal)
                        }
                    }
                    .padding(.bottom)
                }
            }
        }
        .navigationTitle("Gym Visits")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                if let user = appState.user {
                    await viewModel.loadFriendsVisits(for: user.id)
                }
            }
        }
        .navigationDestination(isPresented: $showCreateVisit) {
            // Use your existing CreateActivityView with Visit type
            CreateActivityView(
                appState: appState,
                initialType: .visit
            )
            .onDisappear {
                // Refresh data when returning from create view
                if let user = appState.user {
                    Task {
                        await viewModel.loadFriendsVisits(for: user.id)
                    }
                }
            }
        }
        .refreshable {
            if let user = appState.user {
                await viewModel.loadFriendsVisits(for: user.id)
            }
        }
    }
}

#Preview {
    // Create a NavigationStack around the VisitsView for preview
    NavigationStack {
        VisitsView(appState: {
            let appState = AppState()
            appState.user = SampleData.previewUser
            return appState
        }())
    }
}
