//
//  EmptyPassesView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 04/04/2025.
//

import SwiftUI

struct EmptyPassesView: View {
    var onAddPassTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "ticket")
                .font(.system(size: 70))
                .foregroundColor(Color.gray.opacity(0.5))
            
            // Title
            Text("No Passes Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            // Description
            Text("Add your gym membership passes to quickly access them when checking in at climbing facilities.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Instruction
            Text("Simply scan the barcode on your physical pass or manually enter your membership number to display your pass here.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Add button
            Button(action: onAddPassTapped) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Your First Pass")
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppTheme.appButton)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.top, 8)
        }
        .padding(.vertical, 40)
    }
}

#Preview {
    EmptyPassesView(onAddPassTapped: {})
        .padding()
}
