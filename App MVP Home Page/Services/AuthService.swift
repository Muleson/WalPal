//
//  AuthService.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 05/02/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

@MainActor
class AuthService: ObservableObject {
    @Published var errorMessage: String?
    @Published var isLoading = false
        
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var appState: AppState
    
    init(appState: AppState) {
        self.appState = appState
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            let documentSnapshot = try await db.collection("users").document(authResult.user.uid).getDocument()
            
            // Use manual decoding instead of Firestore.decode
            guard
                let data = documentSnapshot.data(),
                let user = User(firestoreData: data)
            else {
                errorMessage = "Failed to parse user data"
                isLoading = false
                return
            }
            
            await MainActor.run {
                appState.updateAuthState(user: user)
            }
        } catch {
            print("Detailed error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func createUser(email: String, password: String, firstName: String, lastName: String) async {
        isLoading = true
        errorMessage = nil
            
        do {
            let authResult = try await auth.createUser(withEmail: email, password: password)
            
            let user = User(
                id: authResult.user.uid,
                email: email,
                firstName: firstName,
                lastName: lastName,
                bio: nil,
                postCount: 0,
                loggedHours: 0,
                imageUrl: nil,
                createdAt: Date()
            )
            
            // Use manual encoding instead of direct dictionary creation
            try await db.collection("users").document(user.id).setData(user.toFirestoreData())
            
            await MainActor.run {
                appState.updateAuthState(user: user)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
            
        isLoading = false
    }
    
    func signOut() {
        do {
            try auth.signOut()
            appState.updateAuthState(user: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
