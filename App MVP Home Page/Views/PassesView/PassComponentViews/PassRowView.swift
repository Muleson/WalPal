//
//  PassRowView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import SwiftUI
import Foundation

struct PassRowView: View {
    
    @ObservedObject var viewModel: PassViewModel
    @Binding var passToDelete: Pass?
    let pass: Pass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(pass.mainInformation.title)
                .font(.headline)
            
            Text("Scanned: \(pass.mainInformation.date.formatted())")
                .font(.subheadline)
                .frame(alignment: .trailing)
            
            if pass.isPrimary {
                Text("Active")
                    .font(.caption)
                    .foregroundStyle(Color.gray)
                    .padding(.top, 4)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            viewModel.setPrimaryPass(for: pass.id)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                viewModel.confirmDelete(for: pass)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}
