//
//  ViewModifiers.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 05/03/2025.
//

import SwiftUI

//MARK: - Theme
struct AppTheme {
    static let appPrimary = Color("AppPrimary")
    static let appBackground = Color("AppBackground")
    static let appAccent = Color("AppAccentColor")
    static let appButton = Color("AppButton")
    
    // Text Colors
    static let appTextPrimary = Color("AppTextPrimary")
    static let appTextAccent = Color("AppTextAccent")
    static let appTextLight = Color("AppTextLight")
    static let appTextButton = Color("AppTextButton")
    
}

// MARK: - Typography
extension Font {
    
   // Standard text styles
    static let appTitle = Font.system(size: 34, weight: .regular, design: .rounded)
    static let appHeadline = Font.system(size: 28, weight: .light, design: .rounded)
    static let appSubheadline = Font.system(size: 13, weight: .light, design: .rounded)
    static let appBody = Font.system(size: 15, weight: .regular, design: .rounded)
    static let appButton = Font.system(size: 18, weight: .light, design: .rounded)
    static let appCaption = Font.system(size: 11, weight: .light, design: .rounded)
}

// MARK: - View Modifiers

// Card styling
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

// Primary button style
struct PrimaryButtonStyle: ViewModifier {
    var isEnabled: Bool = true
    
    func body(content: Content) -> some View {
        content
            .font(.appButton)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(isEnabled ? Color.appButton : Color.gray.opacity(0.3))
            .foregroundColor(.appTextButton)
            .cornerRadius(15)
            .disabled(!isEnabled)
    }
}

// Secondary button style
struct SecondaryButtonStyle: ViewModifier {
    var isEnabled: Bool = true
    
    func body(content: Content) -> some View {
        content
            .font(.appButton)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color.white)
            .foregroundColor(isEnabled ? Color.appAccent : Color.gray)
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isEnabled ? Color.appAccent : Color.gray.opacity(0.3), lineWidth: 1)
            )
            .disabled(!isEnabled)
    }
}

// Ghost button style (text only)
struct GhostButtonStyle: ViewModifier {
    var isEnabled: Bool = true
    
    func body(content: Content) -> some View {
        content
            .font(.appBody)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .foregroundColor(isEnabled ? Color.appAccent : Color.gray)
            .disabled(!isEnabled)
    }
}

// Input field style
struct InputFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}
    
    // MARK: - View Extensions
extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
    
    func primaryButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(PrimaryButtonStyle(isEnabled: isEnabled))
    }
    
    func secondaryButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(SecondaryButtonStyle(isEnabled: isEnabled))
    }
    
    func ghostButtonStyle(isEnabled: Bool = true) -> some View {
        modifier(GhostButtonStyle(isEnabled: isEnabled))
    }
    
    func inputFieldStyle() -> some View {
        modifier(InputFieldStyle())
    }
}
