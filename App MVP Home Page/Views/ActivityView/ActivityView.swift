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
    @StateObject private var gymVisitViewModel = GymVisitViewModel()
    
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
    
    // Gym visit state
    @State private var selectedGym: GymVisit? = nil
    @State private var showGymDetail = false
    
    // Media Engagement
    @State private var selectedMedia: Media?
    @State private var showFullScreenMedia = false
    
    // Computed property for dynamic title based on selected filter
    private var dynamicTitle: some View {
        let title: String
        switch currentFilterOption {
        case .all: title = "Activity"
        case .beta: title = "Betas"
        case .event: title = "Events"
        case .gymVisits: title = "Gym Visits"
        }
        
        return Text(title)
            .font(.largeTitle)
            .fontWeight(.bold)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .transition(.opacity.combined(with: .move(edge: .leading)))
            .id("title-\(currentFilterOption)")  // Force SwiftUI to recreate the view when filter changes
    }
    
    // Helper computed property to get current filter as FilterOption
    private var currentFilterOption: FilterOption {
        return mapActivityFilterToFilterOption(viewModel.selectedFilter)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Main content
                VStack(spacing: 0) {
                    
                    Spacer().frame(height: 36)
                    
                    // Dynamic title that changes based on filter
                    dynamicTitle
                        .animation(.easeOut, value: currentFilterOption)
                    
                    // Filter tabs
                    UnderlineFilterTabs(
                        selectedFilter: Binding(
                            get: { currentFilterOption },
                            set: { newFilter in
                                // Always animate filter transitions
                                withAnimation(.easeOut(duration: 0.3)) {
                                    // If switching away from gym visits
                                    if currentFilterOption == .gymVisits && newFilter != .gymVisits {
                                        // Reset the previousFilter state
                                        previousFilter = newFilter
                                    }
                                    
                                    // If switching to gym visits
                                    if newFilter == .gymVisits && currentFilterOption != .gymVisits {
                                        // Store that we've switched to gym visits
                                        previousFilter = .gymVisits
                                    }
                                    
                                    let activityFilter = mapFilterOptionToActivityFilter(newFilter)
                                    viewModel.selectedFilter = activityFilter
                                }
                                
                                // These data loading operations don't need to be in the animation block
                                if newFilter == .gymVisits && currentFilterOption != .gymVisits {
                                    // Load gym visit data when filter changes to gym visits
                                    if let userId = appState.user?.id {
                                        Task {
                                            await gymVisitViewModel.loadVisits(for: userId)
                                        }
                                    }
                                } else if newFilter != .gymVisits {
                                    // When filter changes, trigger any needed data fetching for activity items
                                    Task {
                                        await viewModel.filterChanged(to: mapFilterOptionToActivityFilter(newFilter), userId: appState.user?.id)
                                    }
                                }
                            }
                        )
                    )
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                    
                    // Conditional content based on filter
                    if currentFilterOption == .gymVisits {
                        // Show gym visits content
                        gymVisitsContent
                    } else {
                        // Show regular activity content
                        activityContent
                    }
                }
                
                // Position the TopNavBar at the top
                VStack(spacing: 0) {
                    TopNavBar(appState: appState)
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
            .navigationDestination(isPresented: $showGymDetail) {
                if let gym = selectedGym {
                    GymProfileView(appState: appState, gym: gym.gym)
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchAllActivityItems()
                    if let user = appState.user {
                        await viewModel.loadLikedItems(userId: user.id)
                        
                        // Also load gym visits data on initial appear
                        await gymVisitViewModel.loadVisits(for: user.id)
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
            .fullScreenCover(isPresented: $showFullScreenMedia) {
                if let media = selectedMedia {
                    FullScreenMediaView(mediaUrl: media.url.absoluteString)
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
    
    // Activity Content View
    private var activityContent: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(viewModel.filteredActivityItems.enumerated()), id: \.element.id) { _, item in
                    activityItemView(for: item)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .gesture(swipeGesture(), including: .all)
    }
    
    // Gym Visits Content View
    private var gymVisitsContent: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Favorite gyms section
                if !gymVisitViewModel.favoriteGyms.isEmpty {
                    Text("Your Favorite Gyms")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    VStack(spacing: 8) {
                        ForEach(gymVisitViewModel.favoriteGyms) { gymVisit in
                            GymVisitRow(
                                gymVisit: gymVisit,
                                onTap: {
                                    // When tapping a gym visit, store it and trigger navigation
                                    selectedGym = gymVisit
                                    showGymDetail = true
                                },
                                onJoin: gymVisitViewModel.isAttendee(userId: appState.user?.id ?? "", gymVisit: gymVisit) ? nil : {
                                    joinGym(gymId: gymVisit.gym.id)
                                },
                                onLeave: gymVisitViewModel.isAttendee(userId: appState.user?.id ?? "", gymVisit: gymVisit) ? {
                                    leaveGym(gymId: gymVisit.gym.id)
                                } : nil,
                                viewModel: gymVisitViewModel
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Friends' visits section
                if !gymVisitViewModel.friendVisitedGyms.isEmpty {
                    Text("Where Friends Are Climbing")
                        .font(.title2)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top)
                    
                    VStack(spacing: 8) {
                        ForEach(gymVisitViewModel.friendVisitedGyms) { gymVisit in
                            GymVisitRow(
                                gymVisit: gymVisit,
                                onTap: {
                                    // When tapping a gym visit, store it and trigger navigation
                                    selectedGym = gymVisit
                                    showGymDetail = true
                                },
                                onJoin: gymVisitViewModel.isAttendee(userId: appState.user?.id ?? "", gymVisit: gymVisit) ? nil : {
                                    joinGym(gymId: gymVisit.gym.id)
                                },
                                onLeave: gymVisitViewModel.isAttendee(userId: appState.user?.id ?? "", gymVisit: gymVisit) ? {
                                    leaveGym(gymId: gymVisit.gym.id)
                                } : nil,
                                viewModel: gymVisitViewModel
                            )
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Empty state
                if gymVisitViewModel.favoriteGyms.isEmpty && gymVisitViewModel.friendVisitedGyms.isEmpty {
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
        .refreshable {
            if let userId = appState.user?.id {
                await gymVisitViewModel.loadVisits(for: userId)
            }
        }
        .gesture(swipeGesture(), including: .all)
    }
    
    @ViewBuilder
    private func activityItemView(for item: any ActivityItem) -> some View {
        Group {
            if let basicPost = item as? BasicPost {
                BasicPostView(
                    post: basicPost,
                    isLiked: viewModel.isItemLiked(itemId: basicPost.id),
                    onLike: { toggleLike(itemId: basicPost.id) },
                    onComment: { showCommentsForItem(basicPost) },
                    onMediaTap: { media in handleMediaTap(media) },
                    onDelete: isAuthor(of: basicPost) ? { deleteItem(id: basicPost.id) } : nil,
                    onAuthorTapped: { user in navigateToUserProfile = user; showingProfile = true }
                )
                // Add video display if the post contains video

            } else if let betaPost = item as? BetaPost {
                BetaPostView(
                    post: betaPost,
                    isLiked: viewModel.isItemLiked(itemId: betaPost.id),
                    onLike: { toggleLike(itemId: betaPost.id) },
                    onComment: { showCommentsForItem(betaPost) },
                    onMediaTap: { media in handleMediaTap(media) },
                    onDelete: isAuthor(of: betaPost) ? { deleteItem(id: betaPost.id) } : nil,
                    onAuthorTapped: { user in navigateToUserProfile = user }
                )
            } else if let eventPost = item as? EventPost {
                EventPostView(
                    post: eventPost,
                    isLiked: viewModel.isItemLiked(itemId: eventPost.id),
                    onLike: { toggleLike(itemId: eventPost.id) },
                    onComment: { showCommentsForItem(eventPost) },
                    onMediaTap: { media in handleMediaTap(media) },
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
    
    private func handleMediaTap(_ media: Media) {
        selectedMedia = media
        showFullScreenMedia = true
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
        switch currentFilterOption {
        case .all:
            return .basic  // Default to basic for "All" filter
        case .beta:
            return .beta
        case .event:
            return .event
        case .gymVisits:
            // For gym visits, this would ideally open a different creation flow
            // but for now default to a basic post with gym context
            return .basic
        }
    }
    
    // Update the mapping functions to handle the new gymVisits filter
    private func mapActivityFilterToFilterOption(_ filter: ActivityViewModel.ActivityFilter) -> FilterOption {
        // Only show gym visits if it's explicitly set as the previous filter
        // AND we're not in the middle of a drag operation
        if previousFilter == .gymVisits && dragOffset == 0 && viewModel.selectedFilter == filter {
            return .gymVisits
        }
        
        // Normal mapping for activity filters
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
        case .gymVisits:
            // For gymVisits, we don't change the underlying filter in ActivityViewModel
            // since it's handled separately
            return viewModel.selectedFilter // Keep current filter
        }
    }
    
    // Gym visit helper methods
    private func joinGym(gymId: String) {
        if let userId = appState.user?.id {
            Task {
                _ = await gymVisitViewModel.joinGymVisit(userId: userId, gymId: gymId)
            }
        }
    }
    
    private func leaveGym(gymId: String) {
        if let userId = appState.user?.id {
            Task {
                _ = await gymVisitViewModel.leaveGymVisit(userId: userId, gymId: gymId)
            }
        }
    }
    
    // Swipe gesture helper method
    private func swipeGesture() -> some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onChanged { value in
                // Only handle horizontal drags
                let horizontalAmount = abs(value.translation.width)
                let verticalAmount = abs(value.translation.height)
                
                // If primarily horizontal, consume the gesture for filter swiping
                if horizontalAmount > verticalAmount && horizontalAmount > 10 {
                    // Store the current filter option when starting a drag
                    if value.translation.width != 0 && dragOffset == 0 {
                        previousFilter = currentFilterOption
                    }
                    
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                // Only process if it was primarily a horizontal gesture
                let horizontalAmount = abs(value.translation.width)
                let verticalAmount = abs(value.translation.height)
                
                if horizontalAmount > verticalAmount && horizontalAmount > 50 {
                    // Get all filter options
                    let filterOptions = FilterOption.allCases
                    
                    // Get current filter index
                    guard let currentIndex = filterOptions.firstIndex(of: currentFilterOption) else {
                        dragOffset = 0
                        return
                    }
                    
                    // Calculate target filter index based on swipe direction
                    var targetIndex: Int? = nil
                    
                    // Swipe left - go to next filter
                    if value.translation.width < 0 && currentIndex < filterOptions.count - 1 {
                        targetIndex = currentIndex + 1
                    }
                    // Swipe right - go to previous filter
                    else if value.translation.width > 0 && currentIndex > 0 {
                        targetIndex = currentIndex - 1
                    }
                    
                    // If we have a valid target index, transition to that filter
                    if let targetIndex = targetIndex {
                        let targetFilter = filterOptions[targetIndex]
                        
                        // Always use animation for consistent transitions
                        withAnimation(.easeOut(duration: 0.3)) {
                            // Update the previousFilter to accurately track our navigation path
                            previousFilter = targetFilter
                            
                            // Update the view model's filter
                            viewModel.selectedFilter = mapFilterOptionToActivityFilter(targetFilter)
                        }
                        
                        // Handle data loading outside of animation
                        if targetFilter == .gymVisits {
                            if let userId = appState.user?.id {
                                Task {
                                    await gymVisitViewModel.loadVisits(for: userId)
                                }
                            }
                        } else if currentFilterOption == .gymVisits {
                            // Load appropriate data when switching from gym visits
                            Task {
                                await viewModel.filterChanged(
                                    to: mapFilterOptionToActivityFilter(targetFilter),
                                    userId: appState.user?.id
                                )
                            }
                        }
                    }
                }
                
                // Reset drag offset
                dragOffset = 0
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
