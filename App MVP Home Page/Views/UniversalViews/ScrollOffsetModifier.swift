//
//  ScrollOffsetModifier.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 12/03/2025.
//

import SwiftUI

// A preference key to track scroll offset
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// A view modifier that reads scroll offset
struct ScrollOffsetModifier: ViewModifier {
    let coordinateSpace: String
    @Binding var offset: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: geometry.frame(in: .named(coordinateSpace)).minY
                        )
                }
            )
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                offset = value
            }
    }
}

// Extension to make it easier to use
extension View {
    func trackScrollOffset(coordinateSpace: String, offset: Binding<CGFloat>) -> some View {
        self.modifier(ScrollOffsetModifier(coordinateSpace: coordinateSpace, offset: offset))
    }
}
