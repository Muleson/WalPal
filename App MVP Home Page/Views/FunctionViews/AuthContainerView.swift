//
//  AuthContainerView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 06/02/2025.
//

import SwiftUI

struct AuthContainerView: View {
    @ObservedObject var appState: AppState
    @State private var showSignUp = false
    
    var body: some View {
        SignInView(appState: appState)
            .sheet(isPresented: $showSignUp) {
                SignUpView(appState: appState)
            }
    }
}

struct SignUpView: View {
    @StateObject private var viewModel: AuthService
    @ObservedObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    
    init(appState: AppState) {
         _viewModel = StateObject(wrappedValue: AuthService(appState: appState))
         self.appState = appState
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.title)
                    .bold()
                
                VStack(spacing: 15) {
                    TextField("First Name", text: $firstName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Last Name", text: $lastName)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button {
                    Task {
                        await viewModel.createUser(
                            email: email,
                            password: password,
                            firstName: firstName,
                            lastName: lastName
                        )
                        if appState.user != nil {
                            dismiss()
                        }
                    }
                } label: {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading || !isFormValid)
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    // Form validation
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty &&
        !firstName.isEmpty && !lastName.isEmpty &&
        password.count >= 6 // Basic password validation
    }
}

struct SignInView: View {
    @StateObject private var viewModel: AuthService
    @ObservedObject var appState: AppState
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUpPresented = false
    
    init(appState: AppState) {
        _viewModel = StateObject(wrappedValue: AuthService(appState: appState))
        self.appState = appState
        }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Welcome Back")
                    .font(.title)
                    .bold()
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.horizontal)
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                }
                
                Button {
                    Task {
                        await viewModel.signIn(email: email, password: password)
                    }
                } label: {
                    Text("Sign In")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                .disabled(viewModel.isLoading)
                
                Button("Create Account") {
                    isSignUpPresented = true
                }
            }
            .padding()
        }
        .sheet(isPresented: $isSignUpPresented) {
            SignUpView(appState: appState)
        }
    }
}
