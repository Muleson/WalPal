//
//  CreateGymView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 12/03/2025.
//

import SwiftUI

struct CreateGymView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var appState: AppState
    @StateObject private var viewModel = CreateGymViewModel()
    
    var body: some View {
        Form {
            Section(header: Text("Gym Information")) {
                TextField("Gym Name", text: $viewModel.name)
                
                TextField("Email", text: $viewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                TextField("Description", text: $viewModel.description, axis: .vertical)
                    .lineLimit(3...6)
                
                TextField("Location", text: $viewModel.location)
            }
            
            Section(header: Text("Gym Logo")) {
                HStack {
                    Spacer()
                    
                    if let image = viewModel.selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 150)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray, lineWidth: 1)
                            )
                    } else {
                        Image(systemName: "building.2.crop.circle")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                }
                .padding(.vertical, 10)
                
                Button(viewModel.selectedImage == nil ? "Select Logo" : "Change Logo") {
                    viewModel.isImagePickerPresented = true
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .foregroundStyle(.appButton)
            }
            
            Section(header: Text("Climbing Types")) {
                ForEach(ClimbingTypes.allCases, id: \.self) { type in
                    Button(action: {
                        if viewModel.selectedClimbingTypes.contains(type) {
                            viewModel.selectedClimbingTypes.remove(type)
                        } else {
                            viewModel.selectedClimbingTypes.insert(type)
                        }
                    }) {
                        HStack {
                            Text(formatClimbingType(type))
                            Spacer()
                            if viewModel.selectedClimbingTypes.contains(type) {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            
            // Amenities section - simplified to avoid type inference issues
            Section(header: Text("Amenities")) {
                // Instead of the LazyVGrid, use a simpler layout for now
                ForEach(viewModel.commonAmenities, id: \.self) { amenity in
                    HStack {
                        Image(systemName: viewModel.getAmenityIcon(amenity))
                            .foregroundColor(.secondary)
                        Text(amenity)
                        Spacer()
                        if viewModel.selectedAmenities.contains(amenity) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.appButton)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleAmenity(amenity)
                    }
                }
                                
                // Custom amenities
                ForEach(viewModel.customAmenities, id: \.self) { amenity in
                    HStack {
                        Image(systemName: viewModel.getAmenityIcon(amenity))
                            .foregroundColor(.secondary)
                        Text(amenity)
                        Spacer()
                        if viewModel.selectedAmenities.contains(amenity) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.appButton)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.toggleAmenity(amenity)
                    }
                }
                
                HStack {
                    TextField("Add Custom Amenity", text: $viewModel.newCustomAmenity)
                    Button(action: {
                        viewModel.addCustomAmenity()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.appButton)
                    }
                    .disabled(viewModel.newCustomAmenity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .navigationTitle("Register a Gym")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Create") {
                    Task {
                        if let user = appState.user {
                            await viewModel.createGym(ownerId: user.id)
                        }
                    }
                }
                .disabled(!viewModel.isFormValid)
                .foregroundStyle(.appButton)
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
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: viewModel.isComplete) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
        .sheet(isPresented: $viewModel.isImagePickerPresented) {
            ImagePicker(selectedImage: $viewModel.selectedImage)
        }
    }
    
    // Helper method to format climbing type
    private func formatClimbingType(_ type: ClimbingTypes) -> String {
        switch type {
        case .bouldering:
            return "Bouldering"
        case .lead:
            return "Lead Climbing"
        case .topRope:
            return "Top Rope"
        }
    }
}

// Custom amenity toggle button component
struct AmenityToggleButton: View {
    let amenity: String
    let isSelected: Bool
    let iconName: String
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 8) {
                Image(systemName: iconName)
                    .foregroundColor(isSelected ? .white : .secondary)
                
                Text(amenity)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Spacer()
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        CreateGymView(
            appState: {
                let mockAppState = AppState()
                // Set up a mock user
                mockAppState.user = User(
                    id: "preview-user-id",
                    email: "preview@example.com",
                    firstName: "Preview",
                    lastName: "User",
                    bio: "This is a preview user for testing",
                    postCount: 5,
                    loggedHours: 120,
                    imageUrl: nil,
                    createdAt: Date()
                )
                mockAppState.authState = .authenticated
                return mockAppState
            }()
        )
    }
}
