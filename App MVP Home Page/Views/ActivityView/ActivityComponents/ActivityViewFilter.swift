//
//  ActivityViewFilter.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 12/03/2025.
//

import SwiftUI

enum FilterOption: String, CaseIterable, Identifiable {
    case all = "All"
    case beta = "Betas"
    case event = "Events"
    case visit = "Visits"
    
    var id: String { self.rawValue }
}

// Alternative style with underline indicators
struct UnderlineFilterTabs: View {
    @Binding var selectedFilter: FilterOption
    var options: [FilterOption] = FilterOption.allCases
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(options) { option in
                    UnderlineTabButton(
                        title: option.rawValue,
                        isSelected: selectedFilter == option,
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                selectedFilter = option
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

struct UnderlineTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.appBody)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? AppTheme.appButton : AppTheme.appTextLight)
                
                // Indicator line
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? AppTheme.appButton : .clear)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                // Indicator line
                Rectangle()
                    .frame(height: 2)
                    .foregroundColor(isSelected ? .appButton : .clear)
            }
        }
        .frame(maxWidth: .infinity)
        .buttonStyle(PlainButtonStyle())
    }
}

struct TabButton_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack {
                TabButton(title: "Posts", isSelected: true, action: {})
                TabButton(title: "Betas", isSelected: false, action: {})
            }
            
            HStack {
                TabButton(title: "Following", isSelected: false, action: {})
                TabButton(title: "For You", isSelected: true, action: {})
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

#Preview {
    VStack(spacing: 30) {
        UnderlineFilterTabs(selectedFilter: .constant(.all))
    }
    .padding(.vertical)
}
