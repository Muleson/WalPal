//
//  MainTabView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 07/02/2025.
//

import Foundation
import SwiftUI

struct MainTabView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        TabView {
            HomeView(appState: appState)
                .tabItem {
                    Label("Home", systemImage: "house")
                }
            ActivityView(appState: appState)
                .tabItem {
                    Label("All Activity", systemImage: "newspaper")
                }
            PassesRootView()
                .tabItem {
                    Label("Passes", systemImage: "wallet.pass")
                }
            ProfileView(appState: appState)
                .tabItem {
                    Label("Profile", systemImage: "person")
                }
        }
        .tint(Color.appButton)
    }
}
