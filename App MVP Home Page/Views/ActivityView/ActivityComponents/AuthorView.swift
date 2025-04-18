//
//  AuthorView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 03/03/2025.
//

import SwiftUI

struct AuthorAvatar: View {
    let author: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            // Profile image
            if let imageUrl = author.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(author.firstName.prefix(1))
                            .foregroundColor(.gray)
                    )
            }
        }
    }
}

struct AuthorName: View {
    let author: User
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading) {
                Text("\(author.firstName) \(author.lastName)")
                    .font(.headline)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AuthorView: View {
    let author: User
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            // Profile image
            AuthorAvatar(author: author, onTap: onTap)
            
            // Name
            AuthorName(author: author, onTap: onTap)
        }
    }
}

struct AuthorCompactView: View {
    let author: User
    
    var body: some View {
        HStack {
            // Profile image
            if let imageUrl = author.imageUrl {
                AsyncImage(url: imageUrl) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray
                }
                .frame(width: 20, height: 20)
                .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 20, height: 20)
                    .overlay(
                        Text(author.firstName.prefix(1))
                            .foregroundColor(.gray)
                    )
            }
            
            // Name
            VStack(alignment: .leading) {
                Text("\(author.firstName) \(author.lastName)")
                    .font(.appSubheadline)
            }
        }
    }
}

struct GymAvatarView: View {
    let gym: Gym
    let size: CGFloat
    
    var body: some View {
        if let imageUrl = gym.imageUrl {
            AsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .scaledToFill()
            } placeholder: {
                Color.gray.opacity(0.3)
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.orange.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "building.2")
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.orange)
                )
        }
    }
}

struct VisitorAvatarView: View {
    let visitor: User
    let size: CGFloat
    
    var body: some View {
        if let imageUrl = visitor.imageUrl {
            AsyncImage(url: imageUrl) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.gray
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)
                .overlay(
                    Text(visitor.firstName.prefix(1))
                        .font(.system(size: size * 0.5))
                        .foregroundColor(.gray)
                )
        }
    }
}
