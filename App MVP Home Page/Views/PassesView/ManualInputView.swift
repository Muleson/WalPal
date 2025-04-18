//
//  ManualInputView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import SwiftUI

struct ManualInputView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hammer.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            Text("Under Construction")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Manual pass input feature coming soon!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Back")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Manual Input")
        .navigationBarBackButtonHidden(true)
        .navigationBarItems(leading: Button(action: {
            dismiss()
        }) {
            HStack {
                Image(systemName: "chevron.left")
                Text("Back")
            }
        })
    }
}

#Preview {
    NavigationStack {
        ManualInputView()
    }
}
