//
//  PassDetailView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import SwiftUI

struct PassDetailView: View {
    @ObservedObject var passViewModel: PassViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isPrimary: Bool = false
    @State private var showDuplicateAlert: Bool = false
    
    // Completion handler to notify parent views when a pass is saved
    var onPassSaved: () -> Void
    
    // Add a property to control dismissal to root
    @Binding var dismissToRoot: Bool
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                // Title
                Text("Scanned Barcode")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)
                
                // Duplicate warning if applicable
                if !passViewModel.duplicatePassName.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("This pass already exists as \"\(passViewModel.duplicatePassName)\"")
                            .font(.subheadline)
                            .foregroundColor(.orange)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
                    .padding(.horizontal)
                }
                
                // Barcode display
                if let lastScannedPass = passViewModel.lastScannedPass {
                    BarcodeImageView(pass: lastScannedPass, viewModel: passViewModel)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                }
                
                // Gym name input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Gym Name")
                        .font(.headline)
                    
                    TextField("Enter Gym Name", text: $passViewModel.titlePlaceholder)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal, 4)
                }
                .padding(.horizontal)
                
                // Primary pass toggle
                Toggle("Set as primary pass", isOn: $isPrimary)
                    .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button {
                        // Try to save the pass
                        let success = passViewModel.savePassWithTitle(primaryStatus: isPrimary)
                        
                        if success {
                            // Call completion handler to notify parent views
                            onPassSaved()
                            
                            // Set the dismissToRoot flag to true to dismiss all the way back to PassesView
                            dismissToRoot = true
                        } else {
                            // If save failed due to duplicate, show the alert
                            showDuplicateAlert = true
                        }
                    } label: {
                        Text("Save Pass")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(passViewModel.titlePlaceholder.isEmpty ? Color.gray : Color.blue)
                            )
                    }
                    .disabled(passViewModel.titlePlaceholder.isEmpty)
                    
                    Button {
                        // Cancel and go back to the passes view by setting dismissToRoot
                        dismissToRoot = true
                    } label: {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(leading: Button(action: {
                // Use dismissToRoot here as well for consistency
                dismissToRoot = true
            }) {
                HStack {
                    Image(systemName: "chevron.left")
                    Text("Back")
                }
            })
            .alert("Duplicate Pass", isPresented: $showDuplicateAlert) {
                Button("OK") {
                    // Do nothing, just dismiss the alert
                }
            } message: {
                if !passViewModel.duplicatePassName.isEmpty {
                    Text("This pass already exists as \"\(passViewModel.duplicatePassName)\"")
                } else {
                    Text("This pass has already been added to your collection.")
                }
            }
        }
        .onAppear {
            // Check for duplicates when the view appears
            if let lastScannedPass = passViewModel.lastScannedPass,
               let existingPass = passViewModel.findDuplicatePass(
                   code: lastScannedPass.barcodeData.code,
                   codeType: lastScannedPass.barcodeData.codeType) {
                passViewModel.duplicatePassName = existingPass.mainInformation.title
            }
        }
    }
}

#Preview {
    PassDetailView(
        passViewModel: PassViewModel(),
        onPassSaved: {},
        dismissToRoot: .constant(false)
    )
}
