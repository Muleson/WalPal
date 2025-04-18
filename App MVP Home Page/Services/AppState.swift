//
//  AppState.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 06/02/2025.
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

enum AuthenticationState {
    case unauthenticated
    case authenticated
    case checking
}

enum ProfileType {
    case gym
    case user
}

@MainActor
class AppState: ObservableObject {
    @Published var authState: AuthenticationState = .checking
    @Published var user: User?
    @Published var gym: Gym?
    @Published var profileType: ProfileType?
    
    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    
    init() {
        if let currentUser = auth.currentUser {
            Task {
                await fetchUserData(uid: currentUser.uid)
            }
        } else {
            self.authState = .unauthenticated
        }
    }
    
    private func fetchUserData(uid: String) async {
        do {
            let document = try await db.collection("users").document(uid).getDocument()
            let user = try? document.data(as: User.self)
            self.updateAuthState(user: user)
        } catch {
            print("Error fetching user data: \(error)")
        }
    }
    
    func updateAuthState(user: User?) {
        self.user = user
        self.authState = user != nil ? .authenticated : .unauthenticated
    }
}

struct RootView: View {
    @StateObject private var appState = AppState()
    
    var body: some View {
        Group {
            switch appState.authState {
                case .checking:
                    ProgressView("Checking Authentication...")
                case .authenticated:
                    MainTabView(appState: appState)
                case .unauthenticated:
                    AuthContainerView(appState: appState)
            }
        }
    }
}
