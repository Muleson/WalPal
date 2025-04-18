//
//  EditGymView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 27/03/2025.
//

import SwiftUI

struct EditGymView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var gym: Gym
    @State private var name: String
    @State private var description: String
    @State private var location: String
    @State private var email: String
    @State private var selectedClimbingTypes: [ClimbingTypes] = []
    @State private var amenities: [String] = []
    @State private var newAmenity: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private let onSave: (Gym) -> Void
    
    init(gym: Gym, onSave: @escaping (Gym) -> Void) {
        self.onSave = onSave
        _gym = State(initialValue: gym)
        _name = State(initialValue: gym.name)
        _description = State(initialValue: gym.description ?? "")
        _location = State(initialValue: gym.locaiton) // Note: Using the field name from struct (with typo)
        _email = State(initialValue: gym.email)
        _selectedClimbingTypes = State(initialValue: gym.climbingType)
        _amenities = State(initialValue: gym.amenities)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Form {
                    // Basic info section
                    Section(header: Text("Gym Information")) {
                        TextField("Gym Name", text: $name)
                        
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                        
                        TextField("Location", text: $location)
                        
                        ZStack(alignment: .topLeading) {
                            if description.isEmpty {
                                Text("Description (Optional)")
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                            }
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 100)
                        }
                    }
                    
                    // Climbing types section
                    Section(header: Text("Climbing Types")) {
                        ForEach(ClimbingTypes.allCases, id: \.self) { climbingType in
                            Button(action: {
                                toggleClimbingType(climbingType)
                            }) {
                                HStack {
                                    Text(formatClimbingType(climbingType))
                                    Spacer()
                                    if selectedClimbingTypes.contains(climbingType) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                    
                    // Amenities section
                    Section(header: Text("Amenities")) {
                        ForEach(amenities, id: \.self) { amenity in
                            HStack {
                                Text(amenity)
                                Spacer()
                                Button(action: {
                                    removeAmenity(amenity)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        
                        HStack {
                            TextField("New Amenity", text: $newAmenity)
                            Button(action: addAmenity) {
                                Text("Add")
                            }
                            .disabled(newAmenity.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    
                    // Image upload section would go here in a real app
                    Section(header: Text("Profile Image")) {
                        HStack {
                            if let imageUrl = gym.imageUrl {
                                AsyncImage(url: imageUrl) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                } placeholder: {
                                    Color.gray
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                    .overlay(
                                        Image(systemName: "building.2")
                                            .font(.system(size: 30))
                                            .foregroundColor(.white)
                                    )
                            }
                            
                            Button("Upload New Image") {
                                // This would open an image picker in a real app
                            }
                            .padding(.leading)
                        }
                    }
                }
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.1))
                }
            }
            .navigationTitle("Edit Gym")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveGym()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert(isPresented: Binding<Bool>(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        // Basic validation
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !selectedClimbingTypes.isEmpty
    }
    
    private func toggleClimbingType(_ type: ClimbingTypes) {
        if selectedClimbingTypes.contains(type) {
            selectedClimbingTypes.removeAll { $0 == type }
        } else {
            selectedClimbingTypes.append(type)
        }
    }
    
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
    
    private func addAmenity() {
        let trimmedAmenity = newAmenity.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedAmenity.isEmpty else { return }
        
        if !amenities.contains(trimmedAmenity) {
            amenities.append(trimmedAmenity)
        }
        newAmenity = ""
    }
    
    private func removeAmenity(_ amenity: String) {
        amenities.removeAll { $0 == amenity }
    }
    
    private func saveGym() {
        // Create updated gym with new values
        let updatedGym = Gym(
            id: gym.id,
            email: email.trimmingCharacters(in: .whitespacesAndNewlines),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            locaiton: location.trimmingCharacters(in: .whitespacesAndNewlines), // Using original field name
            climbingType: selectedClimbingTypes,
            amenities: amenities,
            events: gym.events, // Keep existing events
            imageUrl: gym.imageUrl, // Keep existing image URL (would be updated separately in a real app)
            createdAt: gym.createdAt
        )
        
        // Call the save handler
        onSave(updatedGym)
        dismiss()
    }
}

#Preview {
    EditGymView(
        gym: SampleData.previewGym,
        onSave: { _ in }
    )
}
