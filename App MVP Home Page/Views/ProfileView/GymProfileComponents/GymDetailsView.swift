//
//  GymDetailsView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 28/03/2025.
//

import SwiftUI

struct GymDetailsView: View {
    @ObservedObject var viewModel: GymProfileViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Amenities section
            if !viewModel.gym.amenities.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amenities")
                        .font(.headline)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(viewModel.gym.amenities, id: \.self) { amenity in
                            HStack(spacing: 8) {
                                Image(systemName: viewModel.getAmenityIcon(amenity))
                                    .foregroundColor(AppTheme.appButton)
                                Text(amenity)
                                    .font(.caption)
                                Spacer()
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
    }
}
