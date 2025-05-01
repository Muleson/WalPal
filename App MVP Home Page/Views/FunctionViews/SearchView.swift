//
//  SearchView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 20/03/2025.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = SearchViewModel()
    
    // Optional initialSearch parameter to set initial search text
    var initialSearch: String?
    
    // For managing navigation to profiles
    @State private var navigateToUserProfile: User?
    @State private var showingUserProfile = false
    
    // For comment sheets
    @State private var showingComments = false
    @State private var selectedItemForComments: (any ActivityItem)?
    
    // Media engagement
    @State private var selectedMedia: Media?
    @State private var showFullScreenMedia = false
    
    // Add this to initialize with a search term
    init(appState: AppState, initialSearch: String? = nil) {
        self.appState = appState
        self.initialSearch = initialSearch
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search bar
                searchBar
                
                // Filter tabs - similar to your activity filter
                filterTabs
                
                // Results list
                contentView
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(item: $navigateToUserProfile) { user in
                ProfileView(appState: appState, profileUser: user)
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
            .fullScreenCover(isPresented: $showFullScreenMedia) {
                if let media = selectedMedia {
                    FullScreenMediaView(mediaUrl: media.url.absoluteString) 
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { viewModel.hasError },
                set: { if !$0 { viewModel.hasError = false; viewModel.errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(viewModel.errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Search Bar
    
    private var searchBar: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Search", text: $viewModel.searchText)
                    .submitLabel(.search)
                    .onSubmit {
                        Task {
                            await viewModel.search()
                        }
                    }
                
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.cancelSearch()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Filter Tabs
    
    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(SearchViewModel.SearchFilter.allCases) { filter in
                    filterTabButton(filter)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(.systemGray6))
    }
    
    private func filterTabButton(_ filter: SearchViewModel.SearchFilter) -> some View {
        Button(action: {
            withAnimation {
                viewModel.selectedFilter = filter
                if !viewModel.searchText.isEmpty {
                    Task {
                        await viewModel.search()
                    }
                }
            }
        }) {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: filter.systemImage)
                        .font(.system(size: 14))
                    
                    Text(filter.rawValue)
                        .font(.appBody)
                        .fontWeight(viewModel.selectedFilter == filter ? .semibold : .regular)
                }
                
                // Indicator line
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(viewModel.selectedFilter == filter ? AppTheme.appButton : .clear)
            }
            .foregroundColor(viewModel.selectedFilter == filter ? AppTheme.appButton : AppTheme.appTextLight)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Content View
    
    private var contentView: some View {
        Group {
            if viewModel.isSearching {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.searchText.isEmpty {
                emptySearchView
            } else if viewModel.searchResults.isEmpty {
                noResultsView
            } else {
                searchResultsList
            }
        }
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("Search for users, betas, events, or visits")
                .font(.headline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noResultsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 60))
                .foregroundColor(Color.gray.opacity(0.5))
            
            Text("No results found")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("Try a different search term or filter")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var searchResultsList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(viewModel.searchResults) { result in
                    searchResultRow(for: result)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
    
    // MARK: - Result Row
    
    @ViewBuilder
    private func searchResultRow(for result: SearchViewModel.SearchResult) -> some View {
        switch result {
        case .user(let user):
            userResultRow(user)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white)
                        .shadow(radius: 2)
                )
                .onTapGesture {
                    navigateToUserProfile = user
                }
            
        case .beta(let beta):
            BetaPostView(
                post: beta,
                isLiked: false, // You would need to check this from a service
                onLike: {}, // Implement these handlers
                onComment: { showCommentsForItem(beta) },
                onMediaTap: { media in handleMediaTap(media) },
                onDelete: nil,
                onAuthorTapped: { navigateToUserProfile = $0 }
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(radius: 2)
            )
            
        case .event(let event):
            EventPostView(
                post: event,
                isLiked: false, // You would need to check this from a service
                onLike: {}, // Implement these handlers
                onComment: { showCommentsForItem(event) },
                onMediaTap: { media in handleMediaTap(media) },
                onDelete: nil,
                onAuthorTapped: { navigateToUserProfile = $0 }
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(radius: 2)
            )
        }
    }
    
    private func userResultRow(_ user: User) -> some View {
        HStack(spacing: 12) {
            // User avatar
            if let imageUrl = user.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Text(user.firstName.prefix(1))
                            .font(.title3)
                            .foregroundColor(.gray)
                    )
            }
            
            // User info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(user.firstName) \(user.lastName)")
                    .font(.headline)
                
                if let bio = user.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
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
}

// MARK: - Preview
struct SearchView_Previews: PreviewProvider {
    static var previews: some View {
        let appState = AppState()
        appState.user = SampleData.previewUser
        appState.authState = .authenticated
        
        return SearchView(appState: appState)
    }
}
