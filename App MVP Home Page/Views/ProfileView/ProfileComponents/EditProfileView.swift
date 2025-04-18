//
//  EditProfileView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 16/03/2025.
//

import SwiftUI

struct EditProfileView: View {
    @ObservedObject var viewModel: ProfileViewModel
    let user: User
    var onSave: (User) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Personal Information")) {
                    TextField("First Name", text: $viewModel.editedFirstName)
                    TextField("Last Name", text: $viewModel.editedLastName)
                    
                    ZStack(alignment: .topLeading) {
                        if viewModel.editedBio.isEmpty {
                            Text("Bio (Optional)")
                                .foregroundColor(.gray)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                        }
                        
                        TextEditor(text: $viewModel.editedBio)
                            .frame(minHeight: 100)
                    }
                }
                
                // Future sections can be added here, like profile image, etc.
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await viewModel.saveProfileChanges(
                                userId: user.id,
                                currentUser: user,
                                updateAppState: onSave
                            )
                            dismiss()
                        }
                    }
                    .disabled(viewModel.editedFirstName.isEmpty || viewModel.editedLastName.isEmpty)
                }
            }
            .disabled(viewModel.isLoading)
            .overlay {
                if viewModel.isLoading {
                    Color.black.opacity(0.1)
                        .ignoresSafeArea()
                    
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
    }
}

struct EditProfileView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample user and viewModel for preview
        let user = User(
            id: "preview-user",
            email: "user@example.com",
            firstName: "John",
            lastName: "Doe",
            bio: "Climbing enthusiast",
            postCount: 15,
            loggedHours: 120,
            imageUrl: nil,
            createdAt: Date()
        )
        
        let viewModel = ProfileViewModel()
        viewModel.prepareEditProfile(user: user)
        
        return EditProfileView(
            viewModel: viewModel,
            user: user,
            onSave: { _ in }
        )
    }
}
