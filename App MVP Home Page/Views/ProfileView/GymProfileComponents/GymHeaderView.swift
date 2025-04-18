//
//  GymHeaderView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 28/03/2025.
//
 
import SwiftUI

struct GymHeaderView: View {
    let viewModel: GymProfileViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Gym cover image
            if let imageUrl = viewModel.gym.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "building.2")
                                .font(.system(size: 50))
                                .foregroundColor(.white)
                        )
                }
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .overlay(
                        Image(systemName: "building.2")
                            .font(.system(size: 50))
                            .foregroundColor(.white)
                    )
            }
            
            // Gym name and basics
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.gym.name)
                    .font(.title)
                    .fontWeight(.bold)
                
                if let description = viewModel.gym.description {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack {
                    Image(systemName: "mappin.and.ellipse")
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.gym.locaiton)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
               HStack {
                   ForEach(viewModel.climbingTypeLabels, id: \.self) { label in
                        Text(label)
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.appButton)
                            .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
    }
}
