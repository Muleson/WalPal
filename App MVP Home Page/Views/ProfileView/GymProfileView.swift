//
//  GymProfileView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 27/03/2025.
//

import SwiftUI

struct GymProfileView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: GymProfileViewModel
    
    // Navigation state for create actions
    @State private var navigateToCreateVisit = false
    @State private var navigateToCreateBeta = false
    
    // UI state
    @State private var showingComments = false
    @State private var selectedItemForComments: (any ActivityItem)?
    @State private var navigateToUserProfile: User?
    @State private var showingUserProfile = false
    
    // Filter state
    @State private var selectedFilter: GymActivityFilter = .all
    
    // Initialize with Gym ID
    init(appState: AppState, gym: Gym) {
        self.appState = appState
        _viewModel = StateObject(wrappedValue: GymProfileViewModel(
            gym: gym
        ))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView() {
                VStack(spacing: 8) {
                    // Gym header with image and basic info
                    GymHeaderView(viewModel: viewModel)
                    
                    // Action buttons (follow gym, etc)
                    GymActionButtonsView(viewModel: viewModel)
                    
                    // Gym details (amenities, hours, etc)
                    GymDetailsView(viewModel: viewModel)
                    
                    // Activity filter tabs
                    filterTabsView
                    
                    // Gym activity feed
                    GymActivityFeedView(
                        viewModel: viewModel,
                        appState: appState,
                        navigateToCreateVisit: $navigateToCreateVisit,
                        navigateToCreateBeta: $navigateToCreateBeta,
                        showingComments: $showingComments,
                        selectedItemForComments: $selectedItemForComments,
                        navigateToUserProfile: $navigateToUserProfile,
                        showingUserProfile: $showingUserProfile,
                        selectedFilter: selectedFilter
                    )
                }
            }
        }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar (content: {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isAdministrator {
                        Menu {
                            Button(action: { viewModel.showEditGymSheet = true }) {
                                Label("Edit Gym", systemImage: "pencil")
                            }
                            
                            Button(action: { viewModel.showManageAdminsSheet = true }) {
                                Label("Manage Administrators", systemImage: "person.2.badge.gearshape")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive, action: {
                                viewModel.showDeleteConfirmation = true
                            }) {
                                Label("Delete Gym", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .padding(8)
                                .foregroundStyle(Color.primary)
                        }
                    }
                }
            })
            .sheet(isPresented: $showingComments) {
                if let item = selectedItemForComments {
                    CommentsView(
                        appState: appState,
                        itemId: item.id,
                        itemType: getItemType(from: item)
                    )
                }
            }
            .navigationDestination(isPresented: $showingUserProfile) {
                if let user = navigateToUserProfile {
                    ProfileView(appState: appState, profileUser: user)
                }
            }
            .navigationDestination(isPresented: $navigateToCreateVisit) {
                CreateActivityView(
                    appState: appState,
                    initialType: ActivityType.visit,
                    preselectedGym: viewModel.gym
                )
            }
            .navigationDestination(isPresented: $navigateToCreateBeta) {
                CreateActivityView(
                    appState: appState,
                    initialType: ActivityType.beta,
                    preselectedGym: viewModel.gym
                )
            }
            .alert("Delete Gym", isPresented: $viewModel.showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteGym()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this gym? This action cannot be undone.")
            }
            .sheet(isPresented: $viewModel.showEditGymSheet) {
                EditGymView(gym: viewModel.gym, onSave: { updatedGym in
                    Task {
                        await viewModel.updateGym(updatedGym)
                    }
                })
            }
            .sheet(isPresented: $viewModel.showManageAdminsSheet) {
                ManageGymAdminsView(appState: appState, gym: viewModel.gym)
            }
            .onAppear {
                Task {
                    // Load gym, activities, and check admin status
                    if let user = appState.user {
                        await viewModel.loadInitialData(currentUser: user)
                    } else {
                        await viewModel.loadInitialData(currentUser: nil)
                    }
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.hasError },
                set: { if !$0 { viewModel.errorMessage = nil; viewModel.hasError = false } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    
    // MARK: - View Components
    
    private var filterTabsView: some View {
        UnderlineFilterTabs(
            selectedFilter: Binding(
                get: { mapGymFilterToFilterOption(selectedFilter) },
                set: {
                    let newFilter = mapFilterOptionToGymFilter($0)
                    selectedFilter = newFilter
                    viewModel.filterActivities(by: newFilter)
                }
            )
        )
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
        
    // MARK: - Helper Methods
    
    private func getItemType(from item: any ActivityItem) -> String {
        switch item {
            case is BasicPost: return "basic"
            case is BetaPost: return "beta"
            case is EventPost: return "event"
            case is GroupVisit: return "visit"
            default: return "unknown"
        }
    }
    
    private func mapGymFilterToFilterOption(_ filter: GymActivityFilter) -> FilterOption {
        switch filter {
        case .all:
            return .all
        case .beta:
            return .beta
        case .event:
            return .event
        case .visit:
            return .visit
        }
    }
    
    private func mapFilterOptionToGymFilter(_ option: FilterOption) -> GymActivityFilter {
        switch option {
        case .all:
            return .all
        case .beta:
            return .beta
        case .event:
            return .event
        case .visit:
            return .visit
        }
    }
}

enum GymActivityFilter {
    case all, beta, event, visit
    
    var systemImage: String {
        switch self {
        case .all: return "list.bullet"
        case .beta: return "figure.climbing"
        case .event: return "calendar"
        case .visit: return "person.3"
        }
    }
    
    var emptyStateTitle: String {
        switch self {
        case .all: return "No activity yet"
        case .beta: return "No beta posts yet"
        case .event: return "No events yet"
        case .visit: return "No check-ins yet"
        }
    }
    
    var emptyStateMessage: String {
        switch self {
        case .all: return "Be the first to post in this gym"
        case .beta: return "Be the first to share beta for climbs at this gym"
        case .event: return "No upcoming events at this gym"
        case .visit: return "No one has checked in to this gym recently"
        }
    }
}

#Preview {
    NavigationStack {
        GymProfileView(
            appState: {
                let appState = AppState()
                appState.user = SampleData.previewUser
                return appState
            }(),
            gym: SampleData.previewGym
        )
    }
}
