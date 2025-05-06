//
//  CreateGymViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 12/03/2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

@MainActor
class CreateGymViewModel: ObservableObject {
    @Published var name = ""
    @Published var email = ""
    @Published var description = ""
    @Published var location = ""
    @Published var selectedClimbingTypes: Set<ClimbingTypes> = [.bouldering]
    @Published var selectedAmenities: Set<String> = []
    @Published var selectedImage: UIImage?
    @Published var isImagePickerPresented = false
    
    // Common amenities for selection
    let commonAmenities = [
        "Showers",
        "Lockers",
        "Café",
        "Pro Shop",
        "Training Area",
        "Wifi",
        "Parking",
        "Changing Rooms",
        "Yoga Studio",
        "Fitness Area"
    ]
    
    @Published var customAmenities: [String] = []
    @Published var newCustomAmenity = ""
    
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isComplete = false
    
    private let gymService = GymService()
    private let mediaStorageService = MediaStorageService()

    
    var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && !location.isEmpty && !selectedClimbingTypes.isEmpty
    }
    
    // Toggle an amenity selection
    func toggleAmenity(_ amenity: String) {
        if selectedAmenities.contains(amenity) {
            selectedAmenities.remove(amenity)
        } else {
            selectedAmenities.insert(amenity)
        }
    }
    
    // Add a custom amenity
    func addCustomAmenity() {
        let trimmed = newCustomAmenity.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !commonAmenities.contains(trimmed) && !customAmenities.contains(trimmed) {
            customAmenities.append(trimmed)
            selectedAmenities.insert(trimmed)
            newCustomAmenity = ""
        }
    }
    
    // Get amenity icon, similar to GymProfileViewModel
    func getAmenityIcon(_ amenity: String) -> String {
        let amenityLowercased = amenity.lowercased()
        
        if amenityLowercased.contains("shower") {
            return "shower"
        } else if amenityLowercased.contains("wifi") {
            return "wifi"
        } else if amenityLowercased.contains("cafe") || amenityLowercased.contains("food") {
            return "cup.and.saucer"
        } else if amenityLowercased.contains("shop") || amenityLowercased.contains("store") {
            return "bag"
        } else if amenityLowercased.contains("park") {
            return "car"
        } else if amenityLowercased.contains("train") {
            return "train.side.front.car"
        } else if amenityLowercased.contains("locker") {
            return "lock"
        } else if amenityLowercased.contains("gym") || amenityLowercased.contains("workout") {
            return "dumbbell"
        } else if amenityLowercased.contains("sauna") {
            return "flame"
        } else if amenityLowercased.contains("changing") {
            return "tshirt"
        } else if amenityLowercased.contains("yoga") {
            return "figure.yoga"
        } else {
            return "checkmark.circle"
        }
    }
    
    func createGym(ownerId: String) async {
        isLoading = true
        
        do {
            // Generate gym ID first
            let gymId = UUID().uuidString
            
            // Combine selected amenities (both common and custom)
            let allAmenities = Array(selectedAmenities)
            
            // Upload image if available
            var imageUrl: URL? = nil
            if let image = selectedImage {
                imageUrl = try await uploadImage(image: image, gymId: gymId)
            }
            
            // Create a new gym using the same ID
            let newGym = Gym(
                id: gymId,
                email: email,
                name: name,
                description: description.isEmpty ? nil : description,
                locaiton: location,
                climbingType: Array(selectedClimbingTypes),
                amenities: allAmenities,
                events: [],
                imageUrl: imageUrl,
                createdAt: Date()
            )
            
            // Save the gym to Firestore
            try await gymService.createGym(gym: newGym)
            
            // Create admin relationship
            let adminId = UUID().uuidString
            let admin = GymAdministrator(
                id: adminId,
                userId: ownerId,
                gymId: gymId,
                role: .owner,
                addedAt: Date(),
                addedBy: ownerId
            )
            
            // Save admin relationship
            try await createGymAdministrator(admin: admin)
            
            isLoading = false
            isComplete = true
        } catch {
            print("Error creating gym: \(error)")
            isLoading = false
            errorMessage = error.localizedDescription
            showError = true
        }
    }
    
    private func uploadImage(image: UIImage, gymId: String) async throws -> URL {
        let media = try await mediaStorageService.uploadGymImage(image, gymId: gymId)
        return media.url
    }
    
    private func createGymAdministrator(admin: GymAdministrator) async throws {
        let db = Firestore.firestore()
        try await db.collection("gymAdministrators").document(admin.id).setData(admin.toFirestoreData())
    }
}
