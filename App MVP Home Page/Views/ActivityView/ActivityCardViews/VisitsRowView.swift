//
//  VisitsRowView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 08/03/2025.
//

import SwiftUI

struct GymVisitRow: View {
    let gymVisit: GymWithVisits
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Gym image
                GymAvatarView(gym: gymVisit.gym, size: 50)
                
                // Gym info
                VStack(alignment: .leading, spacing: 2) {
                    Text(gymVisit.gym.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appTextPrimary)
                    
                    Text(gymVisit.gym.locaiton)
                        .font(.caption)
                        .foregroundColor(.appTextLight)
                    
                    // Friend avatars and count
                    if !gymVisit.visitors.isEmpty {
                        HStack(spacing: 4) {
                            // First 3 friend avatars
                            HStack(spacing: -8) {
                                ForEach(Array(gymVisit.visitors.prefix(3).enumerated()), id: \.1.user.id) { index, visitor in
                                    VisitorAvatarView(visitor: visitor.user, size: 20)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: 1)
                                        )
                                }
                            }
                            
                            // Friend count label
                            if !gymVisit.visitors.isEmpty {
                                Text("\(gymVisit.visitors.count) \(gymVisit.visitors.count == 1 ? "friend" : "friends")")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Right chevron icon
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GymVisitRow_Previews: PreviewProvider {
    static var previews: some View {
        // Sample gym
        let gym = Gym(
            id: "gym1",
            email: "info@boulderhub.com",
            name: "Boulder Hub",
            description: "Premier bouldering gym",
            locaiton: "Downtown",
            climbingType: [.bouldering],
            amenities: ["Showers", "Cafe"],
            events: [],
            imageUrl: nil,
            createdAt: Date()
        )
        
        // Sample visitors
        let visitors = [
            VisitorInfo(
                user: User(
                    id: "user1",
                    email: "alice@example.com",
                    firstName: "Alice",
                    lastName: "Johnson",
                    bio: nil,
                    postCount: 15,
                    loggedHours: 75,
                    imageUrl: nil,
                    createdAt: Date()
                ),
                visitDate: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date())!
            ),
            VisitorInfo(
                user: User(
                    id: "user2",
                    email: "bob@example.com",
                    firstName: "Bob",
                    lastName: "Smith",
                    bio: nil,
                    postCount: 8,
                    loggedHours: 42,
                    imageUrl: nil,
                    createdAt: Date()
                ),
                visitDate: Calendar.current.date(bySettingHour: 15, minute: 0, second: 0, of: Date())!
            )
        ]
        
        // Create sample data
        let gymVisit = GymWithVisits(gym: gym, visitors: visitors)
        
        return VStack(spacing: 20) {
            GymVisitRow(
                gymVisit: gymVisit,
                onTap: {}
            )
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            GymVisitRow(
                gymVisit: GymWithVisits(
                    gym: gym,
                    visitors: [visitors[0]] // Just one visitor
                ),
                onTap: {}
            )
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
            
            GymVisitRow(
                gymVisit: GymWithVisits(
                    gym: gym,
                    visitors: [] // No visitors
                ),
                onTap: {}
            )
            .padding()
            .background(Color.white)
            .cornerRadius(10)
            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
