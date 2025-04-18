//
//  SettingsView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 13/03/2025.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section(header: Text("Gym Management")) {
                NavigationLink {
                    CreateGymView(appState: appState)
                } label: {
                    Label("Register a Gym", systemImage: "building.2")
                }
            }
            
            Section(header: Text("Account")) {
                Button(role: .destructive, action: signOut) {
                    Label("Sign Out", systemImage: "arrow.right.square")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func signOut() {
        let authService = AuthService(appState: appState)
        authService.signOut()
    }
}
