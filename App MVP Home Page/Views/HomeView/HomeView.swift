//
//  ContentView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 05/02/2025.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = HomeViewModel()
    
    // Search state
    @State private var searchText = ""
    @State private var isSearchActive = false
    
    // Navigation state for search results
    @State private var navigateToSearch = false
    @State private var navigateToVisits = false
    
    init(appState: AppState, factory: HomeViewModelFactory = DefaultHomeViewModelFactory()) {
        self.appState = appState
        // Use _viewModel to initialize the @StateObject
        _viewModel = StateObject(wrappedValue: factory.makeHomeViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Main content in a ScrollView
                VStack(spacing: 0) {
                    // Add spacer to push content below the TopNavBar
                    Spacer().frame(height: 38)
                    
                    // Title that would normally be in navigationTitle
                    Text("Hello, \(appState.user?.firstName ?? "")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Main content
                    VStack(alignment: .center, spacing: 8) {
                        // Quick action button
                        HStack(spacing: 8) {
                            // Navigation link instead of a button with sheet
                            NavigationLink {
                                // Navigate directly to CreateActivityView with initial type .visit
                                CreateActivityView(appState: appState, initialType: .visit)
                            } label: {
                                VStack {
                                    Text("Plan Send")
                                        .font(.appHeadline)
                                }
                                .frame(maxWidth: 306)
                                .padding(.vertical, 4)
                                .foregroundColor(.white)
                                .background(AppTheme.appButton)
                                .cornerRadius(15)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Friends visits section
                        VStack(alignment: .leading, spacing: 18) {
                            HStack {
                                Spacer()
                                Text("\(viewModel.friendVisitsToday) friends with planned visits today,")
                                    .font(.appBody)
                                                        
                                Button {
                                    navigateToVisits = true
                                } label: {
                                    Text("see where")
                                        .font(.appBody)
                                        .foregroundColor(.appButton)
                                        .padding(.trailing)
                                }
                            }
                        }
                        
                        // Featured Events section
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("What's going on?")
                                    .font(.appHeadline)
                                    .foregroundColor(AppTheme.appTextPrimary)
                                    .padding(.leading, 16)
                                
                                Spacer()
                                // Add Event button
                                NavigationLink {
                                    CreateActivityView(appState: appState, initialType: .event)
                                } label: {
                                    Image(systemName: "plus")
                                        .foregroundColor(AppTheme.appButton)
                                }
                                .padding(.trailing, 16)
                            }
                            if viewModel.isLoadingEvents {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else if viewModel.events.isEmpty {
                                Text("No events found")
                                    .font(.appBody)
                                    .foregroundColor(AppTheme.appTextLight)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.events) { event in
                                            EventCompactView(
                                                event: event,
                                                isLiked: viewModel.isItemLiked(itemId: event.id),
                                                onLike: { toggleLike(itemId: event.id) },
                                                onComment: { showCommentsForItem(event) }
                                            )
                                            .frame(width: 280, height: 220)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)
                        
                        // Recent Betas section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent Betas")
                                    .font(.appHeadline)
                                    .foregroundColor(AppTheme.appTextPrimary)
                                    .padding(.leading, 16)
                                
                                Spacer()
                                // Add Beta button
                                NavigationLink {
                                    CreateActivityView(appState: appState, initialType: .beta)
                                } label: {
                                    Image(systemName: "plus")
                                        .foregroundColor(AppTheme.appButton)
                                }
                                .padding(.trailing, 16)
                            }
                            if viewModel.isLoadingBetas {
                                ProgressView()
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else if viewModel.betaPosts.isEmpty {
                                Text("No betas found")
                                    .font(.appBody)
                                    .foregroundColor(AppTheme.appTextLight)
                                    .frame(maxWidth: .infinity, alignment: .center)
                                    .padding()
                            } else {
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(viewModel.betaPosts, id: \.id) { beta in
                                            BetaCompactView(
                                                beta: beta,
                                                isLiked: viewModel.isItemLiked(itemId: beta.id),
                                                onLike: { toggleLike(itemId: beta.id) },
                                                onComment: { showCommentsForItem(beta) }
                                            )
                                            .frame(width: 280, height: 200)
                                            .cardStyle()
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.top)
                    }
                    .padding(.vertical)
                }
                
                // Position the TopNavBar at the top
                VStack(spacing: 0) {
                    TopNavBar(
                        appState: appState
                    )
                    Spacer()
                }
            }
            .navigationBarHidden(true) // Hide the default navigation bar
            .navigationDestination(isPresented: $navigateToVisits) {
                ActivityView(
                    appState: appState
                )
            }
            .navigationDestination(isPresented: $navigateToSearch) {
                SearchView(appState: appState, initialSearch: searchText)
            }
            .sheet(isPresented: $viewModel.showingComments) {
                if let item = viewModel.selectedItemForComments {
                    CommentsView(
                        appState: appState,
                        itemId: item.id,
                        itemType: getItemType(from: item)
                    )
                }
            }
            .onAppear {
                Task {
                    await viewModel.loadFeaturedContent()
                    if let user = appState.user {
                        await viewModel.loadLikedItems(userId: user.id)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func toggleLike(itemId: String) {
        guard let user = appState.user else { return }
        
        Task {
            if viewModel.isItemLiked(itemId: itemId) {
                await viewModel.unlikeItem(itemId: itemId, userId: user.id)
            } else {
                await viewModel.likeItem(itemId: itemId, userId: user.id)
            }
        }
    }
    
    private func showCommentsForItem(_ item: any ActivityItem) {
        viewModel.selectedItemForComments = item
        viewModel.showingComments = true
    }
    
    private func getItemType(from item: any ActivityItem) -> String {
        switch item {
        case is BasicPost: return "basic"
        case is BetaPost: return "beta"
        case is EventPost: return "event"
        case is GroupVisit: return "visit"
        default: return "unknown"
        }
    }
    
    private func navigateToUserProfile(_ user: User) {
            // In a real implementation, you would use NavigationLink programmatically
            // or set a state variable bound to a NavigationDestination
            print("Navigate to profile: \(user.firstName) \(user.lastName)")
        }
}

// Preview with the factory pattern
#Preview {
    // Create a preview container view
    HomePreviewContainer()
}

// Container struct for the preview
struct HomePreviewContainer: View {
    // Create and configure the mock AppState
    @StateObject private var appState = AppState()
    
    var body: some View {
        // Create the HomeView with our factory
        HomeView(
            appState: appState,
            factory: PreviewHomeViewModelFactory()
        )
        .onAppear {
            // Configure AppState - this will run on the main thread due to onAppear
            appState.user = SampleData.previewUser
            appState.authState = .authenticated
        }
    }
}
