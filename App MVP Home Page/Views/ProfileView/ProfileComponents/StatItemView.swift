//
//  StatItemView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 14/03/2025.
//

import SwiftUI

struct StatItem: View {
    let value: Int
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.appButton)
                .foregroundStyle(Color.appTextAccent)
                .fontWeight(.regular)
            
            Text(label)
                .font(.subheadline)
                .foregroundColor(.appTextLight)
        }
        .frame(maxWidth: .infinity)
    }
}

struct StatItem_Previews: PreviewProvider {
    static var previews: some View {
        HStack {
            StatItem(value: 42, label: "Posts")
            StatItem(value: 128, label: "Followers")
            StatItem(value: 97, label: "Following")
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
