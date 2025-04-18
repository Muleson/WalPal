//
//  GymFavouriteButton.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 12/04/2025.
//

import SwiftUI

struct FavoriteGymButton: View {
    let gymId: String
    let userId: String
    @Binding var isFavorite: Bool
    @State private var isLoading = false
    
    // Optional action to notify parent when status changes
    var onStatusChanged: ((Bool) -> Void)?
    
    // Services
    private let gymService = GymService()
    
    var body: some View {
        Button(action: toggleFavorite) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 20))
                .foregroundColor(isFavorite ? .red : .gray)
                .overlay(
                    Group {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(isFavorite ? .white : .gray)
                        }
                    }
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .disabled(isLoading)
    }
    
    private func toggleFavorite() {
        guard !isLoading else { return }
        
        isLoading = true
        
        Task {
            do {
                if isFavorite {
                    try await gymService.removeFavoriteGym(userId: userId, gymId: gymId)
                } else {
                    try await gymService.addFavoriteGym(userId: userId, gymId: gymId)
                }
                
                await MainActor.run {
                    isFavorite.toggle()
                    onStatusChanged?(isFavorite)
                    isLoading = false
                }
            } catch {
                print("Error toggling favorite status: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
    }
}
