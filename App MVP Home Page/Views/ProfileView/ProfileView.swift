//
//  ProfileView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 11/02/2025.
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel: ProfileViewModel
    @State private var selectedTab = 0
    @State private var showingComments = false
    @State private var selectedItemForComments: (any ActivityItem)?
    @State private var navigateToConversation = false
    
    // State for sheets
    @State private var showFollowersList = false
    @State private var showFollowingList = false
    @State private var navigateToUserProfile: User?
    @State private var showingUserProfile = false
    
    // Activity Bar
    @State private var dragOffset: CGFloat = 0
    @State private var previousTab = 0
    
    // User parameter passed to the view
    var profileUser: User?
    
    // Constants for layout
    private let avatarSize: CGFloat = 100
    
    // Initialize with ViewModel that has access to AppState
    init(appState: AppState, profileUser: User? = nil) {
        self.appState = appState
        self.profileUser = profileUser
        // Initialize the ViewModel with appState
        _viewModel = StateObject(wrappedValue: ProfileViewModel(appState: appState))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    // Profile header - Using your refactored component
                    if let _ = viewModel.displayedUser {
                        ProfileHeaderView(viewModel: viewModel, avatarSize: avatarSize)
                            .padding(.bottom, 8)
                    }
                    
                    // Stats bar
                    statsBar
                    
                    // Content tabs and posts
                    VStack(spacing: 0) {
                        // Tab selector
                        tabSelector
                        
                        // Tab content
                        tabContent
                    }
                    .background(Color(.systemBackground))
                }
            }
            .refreshable {
                // Pull to refresh functionality
                if let user = viewModel.displayedUser {
                    await viewModel.loadUserData(profileUser: profileUser, currentUser: appState.user)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        // Edit Profile - only available to current user
                        if viewModel.isCurrentUserProfile {
                            Button(action: {
                                if let user = viewModel.displayedUser {
                                    viewModel.prepareEditProfile(user: user)
                                }
                            }) {
                                Label("Edit Profile", systemImage: "pencil")
                            }
                        }
                        
                        // Followers list
                        Button {
                            if viewModel.canShowFollowersList() {
                                showFollowersList = true
                            }
                        } label: {
                            Label("\(viewModel.followerCount) Followers", systemImage: "person.2")
                        }
                        .disabled(!viewModel.canShowFollowersList())
                        
                        // Following list
                        Button {
                            if viewModel.canShowFollowingList() {
                                showFollowingList = true
                            }
                        } label: {
                            Label("\(viewModel.followingCount) Following", systemImage: "person.2.square.stack")
                        }
                        .disabled(!viewModel.canShowFollowingList())
                        
                        // Sign Out - only available to current user
                        if viewModel.isCurrentUserProfile {
                            Divider()
                            
                            Button(role: .destructive, action: signOut) {
                                Label("Sign Out", systemImage: "arrow.right.square")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .padding(8)
                            .foregroundStyle(Color.primary)
                    }
                }
            }
            .onChange(of: viewModel.conversationId) { _, newValue in
                if newValue != nil {
                    navigateToConversation = true
                }
            }
            .navigationDestination(isPresented: $navigateToConversation) {
                if let conversationId = viewModel.conversationId {
                    ConversationView(appState: appState, conversationId: conversationId)
                        .onDisappear {
                            // Reset navigation state when returning
                            viewModel.conversationId = nil
                        }
                }
            }
            .sheet(isPresented: $viewModel.isEditingProfile) {
                // Using your refactored EditProfileView
                EditProfileView(
                    viewModel: viewModel,
                    user: viewModel.displayedUser!,
                    onSave: { updatedUser in
                        appState.updateAuthState(user: updatedUser)
                    }
                )
            }
            .sheet(isPresented: $showingComments) {
                if let item = selectedItemForComments {
                    CommentsView(
                        appState: appState,
                        itemId: item.id,
                        itemType: getItemType(from: item)
                    )
                }
            }
            // Sheets for followers/following lists
            .sheet(isPresented: $showFollowersList) {
                if let userId = viewModel.getCurrentProfileId() {
                    FollowersListView(userId: userId, appState: appState)
                }
            }
            .sheet(isPresented: $showFollowingList) {
                if let userId = viewModel.getCurrentProfileId() {
                    FollowingListView(userId: userId, appState: appState)
                }
            }
            .navigationDestination(isPresented: $showingUserProfile) {
                if let user = navigateToUserProfile {
                    ProfileView(appState: appState, profileUser: user)
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
        .onAppear {
            // Load initial data when view appears
            Task {
                await viewModel.loadUserData(profileUser: profileUser, currentUser: appState.user)
            }
        }
    }
    
    // MARK: - View Components
    
    private var statsBar: some View {
        HStack(spacing: 0) {
            // Display stats without buttons
            StatItem(
                value: viewModel.postCount,
                label: "Posts"
            )
            
            Divider()
                .frame(height: 30)
            
            StatItem(
                value: viewModel.betaCount,
                label: "Betas"
            )
            
            Divider()
                .frame(height: 30)
            
            StatItem(
                value: viewModel.loggedHours,
                label: "Hours"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            TabButton(
                title: "Posts",
                isSelected: selectedTab == 0,
                action: {
                    withAnimation {
                        selectedTab = 0
                    }
                }
            )
            
            TabButton(
                title: "Betas",
                isSelected: selectedTab == 1,
                action: {
                    withAnimation {
                        selectedTab = 1
                    }
                }
            )
        }
        .padding(.top, 8)
    }
    
    private var tabContent: some View {
        Group {
            if viewModel.userPosts.isEmpty {
                emptyStateView
            } else {
                // Wrap the content in a ZStack with gesture recognition
                ZStack {
                    if selectedTab == 0 {
                        // All posts
                        postsGrid
                            .transition(.asymmetric(
                                insertion: .move(edge: .leading),
                                removal: .move(edge: .leading)
                            ))
                    } else {
                        // Betas only
                        betasGrid
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing),
                                removal: .move(edge: .trailing)
                            ))
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onChanged { value in
                            // Only handle horizontal drags
                            let horizontalAmount = abs(value.translation.width)
                            let verticalAmount = abs(value.translation.height)
                            
                            // If primarily horizontal, track the drag
                            if horizontalAmount > verticalAmount && horizontalAmount > 10 {
                                if value.translation.width != 0 && dragOffset == 0 {
                                    previousTab = selectedTab
                                }
                                
                                dragOffset = value.translation.width
                            }
                        }
                        .onEnded { value in
                            // Only process if it was primarily a horizontal gesture
                            let horizontalAmount = abs(value.translation.width)
                            let verticalAmount = abs(value.translation.height)
                            
                            if horizontalAmount > verticalAmount && horizontalAmount > 50 {
                                // Swipe left - go from Posts to Betas
                                if value.translation.width < 0 && selectedTab == 0 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        selectedTab = 1
                                    }
                                }
                                // Swipe right - go from Betas to Posts
                                else if value.translation.width > 0 && selectedTab == 1 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        selectedTab = 0
                                    }
                                }
                            }
                            
                            // Reset drag offset
                            dragOffset = 0
                        }
                )
            }
        }
        .padding(.top, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: 50))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text(selectedTab == 0 ? "No posts yet" : "No betas yet")
                .font(.headline)
            
            Text(selectedTab == 0 ? "Posts will appear here" : "Beta posts will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var postsGrid: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(viewModel.userPosts.enumerated()), id: \.element.id) { _, item in
                activityItemView(for: item)
                    .padding(.horizontal)
            }
        }
        .padding(.bottom, 16)
    }
    
    private var betasGrid: some View {
        LazyVStack(spacing: 12) {
            let betaPosts = viewModel.userPosts.compactMap { $0 as? BetaPost }
            
            if betaPosts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 50))
                        .foregroundColor(Color.gray.opacity(0.5))
                    
                    Text("No betas yet")
                        .font(.headline)
                    
                    Text("Beta posts will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 60)
            } else {
                ForEach(betaPosts) { betaPost in
                    activityItemView(for: betaPost)
                        .padding(.horizontal)
                }
            }
        }
        .padding(.bottom, 16)
    }
    
    // MARK: - Helper Methods
    
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
                    onAuthorTapped: { user in navigateToProfile(user) }
                )
            } else if let betaPost = item as? BetaPost {
                BetaPostView(
                    post: betaPost,
                    isLiked: viewModel.isItemLiked(itemId: betaPost.id),
                    onLike: { toggleLike(itemId: betaPost.id) },
                    onComment: { showCommentsForItem(betaPost) },
                    onDelete: isAuthor(of: betaPost) ? { deleteItem(id: betaPost.id) } : nil,
                    onAuthorTapped: { user in navigateToProfile(user) }
                )
            } else if let eventPost = item as? EventPost {
                EventPostView(
                    post: eventPost,
                    isLiked: viewModel.isItemLiked(itemId: eventPost.id),
                    onLike: { toggleLike(itemId: eventPost.id) },
                    onComment: { showCommentsForItem(eventPost) },
                    onDelete: isAuthor(of: eventPost) ? { deleteItem(id: eventPost.id) } : nil,
                    onAuthorTapped: { user in navigateToProfile(user) }
                )
            } else if let visit = item as? GroupVisit {
                GroupVisitView(
                    visit: visit,
                    isLiked: viewModel.isItemLiked(itemId: visit.id),
                    onLike: { toggleLike(itemId: visit.id) },
                    onComment: { showCommentsForItem(visit) },
                    onDelete: isAuthor(of: visit) ? { deleteItem(id: visit.id) } : nil,
                    onJoin: isAttending(visit: visit) ? nil : { joinVisit(id: visit.id) },
                    onLeave: isAttending(visit: visit) ? { leaveVisit(id: visit.id) } : nil,
                    onAuthorTapped: { user in navigateToProfile(user) }
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(radius: 2)
        )
    }
    
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
            await viewModel.deletePost(itemId: id)
        }
    }
    
    private func joinVisit(id: String) {
        guard let user = appState.user else { return }
        
        Task {
            await viewModel.joinVisit(visitId: id, userId: user.id)
        }
    }
    
    private func leaveVisit(id: String) {
        guard let user = appState.user else { return }
        
        Task {
            await viewModel.leaveVisit(visitId: id, userId: user.id)
        }
    }
    
    private func navigateToProfile(_ user: User) {
        navigateToUserProfile = user
        showingUserProfile = true
    }
    
    private func isAuthor(of item: any ActivityItem) -> Bool {
        guard let user = appState.user else { return false }
        return item.author.id == user.id
    }
    
    private func isAttending(visit: GroupVisit) -> Bool {
        guard let user = appState.user else { return false }
        return visit.attendees.contains(user.id)
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
            case is GroupVisit: return "visit"
            default: return "unknown"
        }
    }
    
    private func signOut() {
        let authService = AuthService(appState: appState)
        authService.signOut()
    }
}

// MARK: - Preview
#Preview("Current User Profile") {
    // Container for current user profile preview
    let appState = AppState()
    // Set current user
    appState.user = SampleData.previewUser
    appState.authState = .authenticated
    
    return ProfileView(appState: appState)
}

#Preview("Other User Profile") {
    // Container for other user profile preview
    let appState = AppState()
    // Set current user (needed for appState)
    appState.user = SampleData.previewUser
    appState.authState = .authenticated
    
    // Create a different user to view
    let otherUser = User(
        id: "other-user-123",
        email: "jane@example.com",
        firstName: "Jane",
        lastName: "Smith",
        bio: "Climbing instructor and outdoor enthusiast",
        postCount: 27,
        loggedHours: 350,
        imageUrl: nil,
        createdAt: Date().addingTimeInterval(-86400 * 200)
    )
    
    return ProfileView(appState: appState, profileUser: otherUser)
}

