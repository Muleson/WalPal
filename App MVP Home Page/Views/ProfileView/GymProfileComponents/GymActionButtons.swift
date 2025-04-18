//
//  GymActionButtons.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 28/03/2025.
//

import SwiftUI

struct GymActionButtonsView: View {
    @StateObject var viewModel: GymProfileViewModel
    
    // Navigation state for create actions
    @State private var navigateToCreateVisit = false
    @State private var navigateToCreateBeta = false
    
    var body: some View {
        HStack(spacing: 20) {
            // Check-in button
            Button(action: {
                navigateToCreateVisit = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "figure.climbing")
                        .font(.system(size: 20))
                    Text("Check In")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.appButton)
                .frame(maxWidth: .infinity)
            }
            
            // Post button
            Button(action: {
                navigateToCreateBeta = true
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 20))
                    Text("Post")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.appButton)
                .frame(maxWidth: .infinity)
            }
            
            // Share button
            Button(action: {
                viewModel.shareGym()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 20))
                    Text("Share")
                        .font(.caption)
                }
                .foregroundColor(AppTheme.appButton)
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(Color(.systemBackground))
    }
}
