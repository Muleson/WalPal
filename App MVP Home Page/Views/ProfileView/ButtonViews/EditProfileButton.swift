//
//  EditProfileButton.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 16/03/2025.
//

import SwiftUI

struct EditProfileButton: View {
    @ObservedObject var viewModel: ProfileViewModel
    
    var body: some View {
        Button(action: {
            // Using the viewModel's prepareEditProfile method
            if let user = viewModel.displayedUser {
                viewModel.prepareEditProfile(user: user)
            }
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .frame(width: 16, height: 16)
                        .padding(.trailing, 4)
                } else {
                    Image(systemName: "pencil")
                        .font(.system(size: 14))
                        .padding(.trailing, 4)
                }
                
                Text("Edit Profile")
                    .font(.subheadline)
            }
            .frame(minWidth: 200)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.gray.opacity(0.2))
            .foregroundColor(.primary)
            .clipShape(Capsule())
        }
        .disabled(viewModel.isLoading)
    }
}

struct EditProfileButtonPreview: PreviewProvider {
    static var previews: some View {
        VStack {
            // Normal state
            let normalViewModel = ProfileViewModel()
            EditProfileButton(viewModel: normalViewModel)
                .padding()
        }
    }
}
