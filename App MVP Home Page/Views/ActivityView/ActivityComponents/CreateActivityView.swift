//
//  CreateActivityView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import SwiftUI
import PhotosUI
import AVKit

struct CreateActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = CreateActivityViewModel()
    
    // New property to set initial type
    let initialActivityType: ActivityType
    
    // Initialize with an activity type
    init(appState: AppState, initialType: ActivityType) {
        self.appState = appState
        self.initialActivityType = initialType
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Activity Type")) {
                    Picker("Select Type", selection: $viewModel.selectedType) {
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            Text(type.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .onAppear {
                        // Set the initial type when the view appears
                        viewModel.selectedType = initialActivityType
                    }
                }
                
                // Dynamic sections based on activity type
                switch viewModel.selectedType {
                case .basic:
                    basicPostSection
                case .beta:
                    betaPostSection
                case .event:
                    eventPostSection
                }
                
                // Media preview section if media is selected
                if !viewModel.selectedImages.isEmpty || !viewModel.selectedVideos.isEmpty {
                    mediaPreviewSection
                }
            }
            .navigationTitle("Share \(viewModel.selectedType.rawValue)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Post") {
                        Task {
                            if let user = appState.user {
                                await viewModel.createActivityItem(author: user)
                                dismiss()
                            }
                        }
                    }
                    .disabled(!viewModel.isFormValid)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.errorMessage)
            }
            .overlay {
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                        if viewModel.uploadProgress > 0 {
                            Text("\(Int(viewModel.uploadProgress * 100))%")
                                .padding(.top, 8)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
                }
            }
            .sheet(isPresented: $viewModel.showMediaPicker) {
                MediaPickerView(
                    selectedImages: $viewModel.selectedImages,
                    selectedVideos: $viewModel.selectedVideos
                )
                .onDisappear {
                    // Generate thumbnails when media picker is dismissed
                    viewModel.generateVideoThumbnails()
                }
            }
        }
    }
    
    // MARK: - Content Sections
    
    private var basicPostSection: some View {
        Section(header: Text("Post Content")) {
            TextField("What's on your mind?", text: $viewModel.content, axis: .vertical)
                .lineLimit(5...10)
            
            mediaSelector
        }
    }
    
    private var betaPostSection: some View {
        Section {
            TextField("Describe your beta", text: $viewModel.content, axis: .vertical)
                .lineLimit(5...10)
            
            TextField("Route Name (optional)", text: $viewModel.routeName)
            
            TextField("Difficulty (optional)", text: $viewModel.difficulty)
            
            mediaSelector
            
            gymSelector
        } header: {
            Text("Beta Details")
        } footer: {
            Text("A 'beta' is a climbing route strategy. Videos are recommended.")
        }
    }
    
    private var eventPostSection: some View {
        Section(header: Text("Event Details")) {
            TextField("Event Title", text: $viewModel.eventTitle)
            
            TextField("Description", text: $viewModel.eventDescription, axis: .vertical)
                .lineLimit(3...6)
            
            DatePicker("Date & Time", selection: $viewModel.eventDate)
            
            TextField("Location", text: $viewModel.eventLocation)
            
            Stepper("Max Attendees: \(viewModel.maxAttendees)", value: $viewModel.maxAttendees, in: 1...100)
            
            mediaSelector
            
            gymSelector
        }
    }
    
    private var mediaSelector: some View {
        Button {
            viewModel.showMediaPicker = true
        } label: {
            Label("Add Photo or Video", systemImage: "photo")
        }
    }
    
    // MARK: - Media Preview
    
    private var mediaPreviewSection: some View {
        Section(header: Text("Media Preview")) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Show selected images
                    ForEach(viewModel.selectedImages.indices, id: \.self) { index in
                        VStack {
                            Image(uiImage: viewModel.selectedImages[index])
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            
                            Button(action: {
                                viewModel.selectedImages.remove(at: index)
                            }) {
                                Text("Remove")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Show video thumbnails if available
                    ForEach(viewModel.selectedVideos.indices, id: \.self) { index in
                        VStack {
                            ZStack {
                                if index < viewModel.videoThumbnails.count {
                                    Image(uiImage: viewModel.videoThumbnails[index])
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                } else {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Image(systemName: "play.circle")
                                    .font(.largeTitle)
                                    .foregroundColor(.white)
                            }
                            
                            Button(action: {
                                viewModel.selectedVideos.remove(at: index)
                                // If we have thumbnails, also remove the corresponding thumbnail
                                if index < viewModel.videoThumbnails.count {
                                    viewModel.videoThumbnails.remove(at: index)
                                }
                            }) {
                                Text("Remove")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var gymSelector: some View {
        VStack {
            Picker("Gym", selection: $viewModel.selectedGymId) {
                Text("Select a gym").tag("")
                
                ForEach(viewModel.gyms) { gym in
                    Text(gym.name).tag(gym.id)
                }
            }
            .disabled(viewModel.isLoadingGyms)
            
            if viewModel.isLoadingGyms {
                HStack {
                    Spacer()
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading gyms...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .onAppear {
            Task {
                await viewModel.loadGyms()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatDuration(_ hours: Double) -> String {
        let wholeHours = Int(hours)
        let minutes = Int((hours - Double(wholeHours)) * 60)
        
        if wholeHours > 0 {
            return "\(wholeHours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

// Preview for direct activity creation navigation
struct CreateActivityView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CreateActivityView(appState: AppState(), initialType: .basic)
                .previewDisplayName("Basic Post")
            
            CreateActivityView(appState: AppState(), initialType: .beta)
                .previewDisplayName("Beta Post")
            
            CreateActivityView(appState: AppState(), initialType: .event)
                .previewDisplayName("Event")
        }
    }
}

// Enhanced initializer for CreateActivityView with gym preselection
extension CreateActivityView {
    init(appState: AppState, initialType: ActivityType, preselectedGym: Gym? = nil) {
        self.appState = appState
        self.initialActivityType = initialType
        
        // If we have a preselected gym, we need to make sure it's set during initialization
        if let gym = preselectedGym {
            // Create a view model with the preselected gym
            let viewModel = CreateActivityViewModel()
            viewModel.preselectedGym = gym
            viewModel.selectedGymId = gym.id
            self._viewModel = StateObject(wrappedValue: viewModel)
        } else {
            // Standard initialization
            self._viewModel = StateObject(wrappedValue: CreateActivityViewModel())
        }
    }
}
