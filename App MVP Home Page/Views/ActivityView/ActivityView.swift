//
//  ContentView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 05/02/2025.
//

import SwiftUI

struct ActivityView: View {
    // For swipe gesture handling
    @State private var dragOffset: CGFloat = 0
    @State private var previousFilter: FilterOption = .all
    
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = ActivityViewModel()
    
    // UI state
    @State private var showingComments = false
    @State private var selectedItemForComments: (any ActivityItem)?
    @State private var showCreateContent = false
    
    //Navigate to User Profiles
    @State private var navigateToUserProfile: User?
    @State private var showingProfile = false
    
    // Search state
    @State private var searchText = ""
    @State private var isSearchActive = false
    @State private var navigateToSearch = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    
                    Spacer().frame(height: 36)
                    
                    // Title that would normally be in navigationTitle
                    Text("Activity")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // Filter tabs
                    UnderlineFilterTabs(
                        selectedFilter: Binding(
                            get: { mapActivityFilterToFilterOption(viewModel.selectedFilter) },
                            set: {
                                let newFilter = mapFilterOptionToActivityFilter($0)
                                viewModel.selectedFilter = newFilter
                                
                                // When filter changes, trigger any needed data fetching
                                Task {
                                    await viewModel.filterChanged(to: newFilter, userId: appState.user?.id)
                                }
                            }
                        )
                    )
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    
                    // Activity content with vertical scrolling
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(Array(viewModel.filteredActivityItems.enumerated()), id: \.element.id) { _, item in
                                activityItemView(for: item)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                    // Disable horizontal scrolling while maintaining vertical scrolling
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 10, coordinateSpace: .local)
                            .onChanged { value in
                                // Only handle horizontal drags
                                let horizontalAmount = abs(value.translation.width)
                                let verticalAmount = abs(value.translation.height)
                                
                                // If primarily horizontal, consume the gesture for filter swiping
                                if horizontalAmount > verticalAmount && horizontalAmount > 10 {
                                    if value.translation.width != 0 && dragOffset == 0 {
                                        previousFilter = mapActivityFilterToFilterOption(viewModel.selectedFilter)
                                    }
                                    
                                    dragOffset = value.translation.width
                                }
                            }
                            .onEnded { value in
                                // Only process if it was primarily a horizontal gesture
                                let horizontalAmount = abs(value.translation.width)
                                let verticalAmount = abs(value.translation.height)
                                
                                if horizontalAmount > verticalAmount && horizontalAmount > 50 {
                                    // Get the current filter option
                                    let currentFilter = mapActivityFilterToFilterOption(viewModel.selectedFilter)
                                    let filterOptions = FilterOption.allCases
                                    
                                    // Swipe left - go to next filter
                                    if value.translation.width < 0 {
                                        if let currentIndex = filterOptions.firstIndex(of: currentFilter),
                                           currentIndex < filterOptions.count - 1 {
                                            let nextFilter = filterOptions[currentIndex + 1]
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                viewModel.selectedFilter = mapFilterOptionToActivityFilter(nextFilter)
                                            }
                                        }
                                    }
                                    // Swipe right - go to previous filter
                                    else if value.translation.width > 0 {
                                        if let currentIndex = filterOptions.firstIndex(of: currentFilter),
                                           currentIndex > 0 {
                                            let prevFilter = filterOptions[currentIndex - 1]
                                            withAnimation(.easeOut(duration: 0.3)) {
                                                viewModel.selectedFilter = mapFilterOptionToActivityFilter(prevFilter)
                                            }
                                        }
                                    }
                                }
                                
                                // Reset drag offset
                                dragOffset = 0
                            }
                    )
                }
                // Position the TopNavBar at the top
                                VStack(spacing: 0) {
                                    TopNavBar(
                                        appState: appState
                                    )
                                    Spacer()
                                }
                
                // Loading or error states
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                } else if viewModel.hasError {
                    VStack {
                        Text("Something went wrong")
                            .font(.headline)
                        
                        Text(viewModel.errorMessage ?? "Unknown error")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button("Try Again") {
                            Task {
                                await viewModel.fetchAllActivityItems()
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.top)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(radius: 2)
                    )
                } else if viewModel.filteredActivityItems.isEmpty && !viewModel.activityItems.isEmpty {
                    // We have items, but none match the filter
                    VStack(spacing: 12) {
                        Image(systemName: viewModel.selectedFilter.systemImage)
                            .font(.system(size: 50))
                            .foregroundColor(.gray)
                        
                        Text("No \(viewModel.selectedFilter.rawValue) found")
                            .font(.headline)
                        
                        Text("Try changing the filter or swipe to view other categories")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Visual swipe indicator
                        HStack(spacing: 5) {
                            Image(systemName: "chevron.left")
                            Text("Swipe")
                            Image(systemName: "chevron.right")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.top, 12)
                    }
                } else if viewModel.activityItems.isEmpty {
                    // No items at all
                    Text("No activity yet")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                // FAB for creating new content
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            showCreateContent = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title3)
                                .foregroundColor(.white)
                                .padding()
                                .background(Circle().fill(AppTheme.appButton))
                                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $navigateToSearch) {
                            SearchView(appState: appState, initialSearch: searchText)
                        }
            .navigationDestination(isPresented: $showingProfile) {
                            if let user = navigateToUserProfile {
                                ProfileView(appState: appState, profileUser: user)
                            }
                        }
            .onAppear {
                Task {
                    await viewModel.fetchAllActivityItems()
                    if let user = appState.user {
                        await viewModel.loadLikedItems(userId: user.id)
                    }
                }
            }
            .sheet(isPresented: $showingComments) {
                if let item = selectedItemForComments {
                    CommentsView(
                        appState: appState,
                        itemId: item.id,
                        itemType: getItemType(from: item),
                        onCommendAdded: {
                            viewModel.updateItemCommentCount(itemId: item.id, increment: true)
                        }
                    )
                }
            }
            .navigationDestination(isPresented: $showCreateContent) {
                // Use your existing CreateActivityView with appropriate type
                if let activityType = mapFilterToActivityType() {
                    CreateActivityView(
                        appState: appState,
                        initialType: activityType
                    )
                    .onDisappear {
                        // Refresh activity items when returning from create view
                        Task {
                            await viewModel.fetchAllActivityItems()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func activityItemView(for item: any ActivityItem) -> some View {
        Group {
            if let basicPost = item as? BasicPost {
                BasicPostView(
                    post: basicPost,
                    isLiked: viewModel.isItemLiked(itemId: basicPost.id),
                    onLike: { toggleLike(itemId: basicPost.id) },
                    onComment: { showCommentsForItem(basicPost) },
                    onDelete: isAuthor(of: basicPost) ? { deleteItem(id: basicPost.id) } : nil,
                    onAuthorTapped: { user in navigateToUserProfile = user; showingProfile = true }
                )
            } else if let betaPost = item as? BetaPost {
                BetaPostView(
                    post: betaPost,
                    isLiked: viewModel.isItemLiked(itemId: betaPost.id),
                    onLike: { toggleLike(itemId: betaPost.id) },
                    onComment: { showCommentsForItem(betaPost) },
                    onDelete: isAuthor(of: betaPost) ? { deleteItem(id: betaPost.id) } : nil,
                    onAuthorTapped: { user in navigateToUserProfile = user }
                )
            } else if let eventPost = item as? EventPost {
                EventPostView(
                    post: eventPost,
                    isLiked: viewModel.isItemLiked(itemId: eventPost.id),
                    onLike: { toggleLike(itemId: eventPost.id) },
                    onComment: { showCommentsForItem(eventPost) },
                    onDelete: isAuthor(of: eventPost) ? { deleteItem(id: eventPost.id) } : nil,
                    onAuthorTapped: { user in navigateToUserProfile = user; showingProfile = true }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 2)
        )
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
    
    private func deleteItem(id: String) {
        Task {
            await viewModel.deleteActivityItem(itemId: id)
        }
    }
    
    private func isAuthor(of item: any ActivityItem) -> Bool {
        guard let user = appState.user else { return false }
        return item.author.id == user.id
    }
    
    private func showCommentsForItem(_ item: any ActivityItem) {
        selectedItemForComments = item
        showingComments = true
    }
    
    private func getItemType(from item: any ActivityItem) -> String {
        switch item {
            case is BasicPost: return "basic"
            case is BetaPost: return "beta"
            case is EventPost: return "event"
            default: return "unknown"
        }
    }
    
    // Helper to map ActivityViewModel.ActivityFilter to CreateActivityView.ActivityType
    private func mapFilterToActivityType() -> ActivityType? {
        switch viewModel.selectedFilter {
        case .all:
            return .basic  // Default to basic for "All" filter
        case .beta:
            return .beta
        case .event:
            return .event
        }
    }
    
    // Helper to map between ActivityViewModel.ActivityFilter and FilterOption
    private func mapActivityFilterToFilterOption(_ filter: ActivityViewModel.ActivityFilter) -> FilterOption {
        switch filter {
        case .all:
            return .all
        case .beta:
            return .beta
        case .event:
            return .event
        }
    }
    
    private func mapFilterOptionToActivityFilter(_ option: FilterOption) -> ActivityViewModel.ActivityFilter {
        switch option {
        case .all:
            return .all
        case .beta:
            return .beta
        case .event:
            return .event
        }
    }
}

// MARK: - Preview
struct ActivityView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.user = SampleData.previewUser
        appState.authState = .authenticated
        
        return ActivityView(appState: appState)
    }
}
