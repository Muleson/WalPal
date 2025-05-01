//
//  SampleData.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 10/03/2025.
//

import Foundation

struct SampleData {
    
    // MARK: - Sample Users
    
    static let previewUser = User(
        id: "preview-user-1",
        email: "john.doe@example.com",
        firstName: "John",
        lastName: "Doe",
        bio: "Climbing enthusiast for 5+ years. V6 boulderer, 5.12 sport climber.",
        postCount: 42,
        loggedHours: 156,
        imageUrl: URL(string: "https://example.com/profile.jpg"),
        createdAt: Date().addingTimeInterval(-86400 * 180) // 180 days ago
    )
    
    static let previewUsers = [
        previewUser,
        User(
            id: "preview-user-2",
            email: "jane.smith@example.com",
            firstName: "Jane",
            lastName: "Smith",
            bio: "Competition climber and route setter",
            postCount: 78,
            loggedHours: 230,
            imageUrl: URL(string: "https://example.com/profile2.jpg"),
            createdAt: Date().addingTimeInterval(-86400 * 220)
        ),
        User(
            id: "preview-user-3",
            email: "mike.johnson@example.com",
            firstName: "Mike",
            lastName: "Johnson",
            bio: "New to climbing, loving it so far!",
            postCount: 12,
            loggedHours: 35,
            imageUrl: nil,
            createdAt: Date().addingTimeInterval(-86400 * 60)
        )
    ]
    
    static func createSampleUsers(count: Int = 10) -> [User] {
        // Arrays of sample data to choose from randomly
        let firstNames = ["Emma", "Noah", "Olivia", "Liam", "Ava", "William", "Sophia", "James", "Isabella", "Logan",
                          "Mia", "Benjamin", "Charlotte", "Mason", "Amelia", "Elijah", "Harper", "Oliver", "Evelyn", "Jacob"]
        
        let lastNames = ["Smith", "Johnson", "Williams", "Jones", "Brown", "Davis", "Miller", "Wilson", "Moore", "Taylor",
                         "Anderson", "Thomas", "Jackson", "White", "Harris", "Martin", "Thompson", "Garcia", "Martinez", "Robinson"]
        
        let bios = [
            "Climbing enthusiast since 2018. Love bouldering and top rope!",
            "IFSC certified coach with a passion for teaching beginners.",
            "Weekend climber looking for partners at local gyms.",
            "Training for my first outdoor lead climbing expedition.",
            "Former gymnast who discovered climbing 2 years ago.",
            "V6 boulderer working on technique over strength.",
            "Always searching for the perfect climbing shoes.",
            "Competition climber with a focus on speed climbing.",
            "Enjoy both indoor and outdoor climbing equally.",
            "Just started climbing and loving every minute of it!"
        ]
        
        var users: [User] = []
        
        for i in 0..<count {
            // Generate random but consistent data for each user
            let firstName = firstNames[i % firstNames.count]
            let lastName = lastNames[i % lastNames.count]
            let email = "\(firstName.lowercased()).\(lastName.lowercased())@example.com"
            let hasBio = Bool.random()
            let bio = hasBio ? bios[i % bios.count] : nil
            let postCount = Int.random(in: 0...50)
            let loggedHours = Int.random(in: 0...500)
            let hasImage = Bool.random()
            let imageUrl = hasImage ? URL(string: "https://randomuser.me/api/portraits/\(Bool.random() ? "men" : "women")/\(i % 99).jpg") : nil
            
            // Create a unique ID
            let id = "user-\(UUID().uuidString)"
            
            // Create the user with random dates in the past year
            let createdAt = Date().addingTimeInterval(-Double.random(in: 0...(86400 * 365)))
            
            let user = User(
                id: id,
                email: email,
                firstName: firstName,
                lastName: lastName,
                bio: bio,
                postCount: postCount,
                loggedHours: loggedHours,
                imageUrl: imageUrl,
                createdAt: createdAt
            )
            
            users.append(user)
        }
        
        return users
    }
    
    // MARK: - Sample Gyms
    
    static let previewGym = Gym(
        id: "preview-gym-1",
        email: "info@boulderdome.com",
        name: "Boulder Dome",
        description: "Premier bouldering facility with over 200 problems",
        locaiton: "123 Climbing St, Boulder, CO",
        climbingType: [.bouldering],
        amenities: ["Showers", "Cafe", "Pro Shop", "Training Area"],
        events: ["Competition", "Technique Workshop"],
        imageUrl: URL(string: "https://example.com/gym.jpg"),
        createdAt: Date().addingTimeInterval(-86400 * 365) // 1 year ago
    )
    
    static let previewGyms = [
        previewGym,
        Gym(
            id: "preview-gym-2",
            email: "info@verticalheights.com",
            name: "Vertical Heights",
            description: "Lead and top rope climbing for all levels",
            locaiton: "456 Rope Ave, Denver, CO",
            climbingType: [.lead, .bouldering],
            amenities: ["Locker Rooms", "Yoga Studio", "Weights"],
            events: ["Beginner Classes", "Lead Certification"],
            imageUrl: URL(string: "https://example.com/gym2.jpg"),
            createdAt: Date().addingTimeInterval(-86400 * 500)
        )
    ]
    
    // MARK: - Sample Activity Items
    
    static func createSampleMedia() -> Media {
        // Default to creating an image if no type specified
        return createSampleMediaItem(type: .image, id: UUID().uuidString)
    }
    
    // Add the new version that takes type and id parameters
    static func createSampleMediaItem(type: MediaType, id: String) -> Media {
        switch type {
        case .image:
            return Media(
                id: id,
                url: URL(string: "https://example.com/sample-image.jpg")!,
                type: .image,
                thumbnailURL: URL(string: "https://example.com/sample-thumbnail.jpg"),
                uploadedAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                ownerId: previewUser.id
            )
        case .video:
            return Media(
                id: id,
                url: URL(string: "https://example.com/sample-video.mp4")!,
                type: .video,
                thumbnailURL: URL(string: "https://example.com/sample-video-thumbnail.jpg"),
                uploadedAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                ownerId: previewUser.id
            )
        case .none:
            return Media(
                id: id,
                url: URL(string: "https://example.com/placeholder.jpg")!,
                type: .none,
                thumbnailURL: nil,
                uploadedAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
                ownerId: previewUser.id
            )
        }
    }

    static func createSampleBasicPost() -> BasicPost {
        return BasicPost(
            id: "preview-basic-1",
            author: previewUser,
            content: "Just had an amazing session at the gym today! Finally sent that V5 project I've been working on for weeks.",
            mediaItems: [createSampleMedia()],
            createdAt: Date().addingTimeInterval(-3600 * 3), // 3 hours ago
            likeCount: 15,
            commentCount: 4,
            isFeatured: false
        )
    }
    
    static func createSampleBetaPost() -> BetaPost {
        return BetaPost(
            id: "preview-beta-1",
            author: previewUsers[1],
            content: "For the red dyno problem on the west wall, the key is to flag with your right foot and generate momentum from your hips rather than just your arms.",
            mediaItems: [createSampleMedia()],
            createdAt: Date().addingTimeInterval(-3600 * 12), // 12 hours ago
            likeCount: 28,
            commentCount: 7,
            gym: previewGym,
            viewCount: 156,
            isFeatured: true
        )
    }
    
    static func createSampleEventPost() -> EventPost {
        return EventPost(
            id: "preview-event-1",
            author: previewUsers[0],
            title: "Spring Climbing Competition",
            description: "Join us for our annual spring competition with categories for all skill levels. Prizes from local sponsors!",
            mediaItems: [createSampleMedia()],
            createdAt: Date().addingTimeInterval(-86400 * 2), // 2 days ago
            likeCount: 42,
            commentCount: 9,
            eventDate: Date().addingTimeInterval(86400 * 10), // 10 days in future
            location: "Boulder Dome - Main Area",
            maxAttendees: 50,
            registered: 32,
            gym: previewGyms[0],
            isFeatured: true
        )
    }
    
    static func createSampleActivityItems() -> [any ActivityItem] {
        return [
            createSampleBasicPost(),
            createSampleBetaPost(),
            createSampleEventPost(),
        ]
    }
    
    // MARK: - Sample Comments
    
    static let previewComments = [
        Comment(
            author: previewUsers[0],
            content: "This is really helpful, thanks for sharing!",
            timeStamp: Date().addingTimeInterval(-3600), // 1 hour ago
            id: UUID()
        ),
        Comment(
            author: previewUsers[1],
            content: "I tried this approach and it worked great. Also found that starting with left hand in a gaston position helps with the initial balance.",
            timeStamp: Date().addingTimeInterval(-1800), // 30 minutes ago
            id: UUID()
        ),
        Comment(
            author: previewUsers[2],
            content: "Looking forward to trying this beta tomorrow!",
            timeStamp: Date().addingTimeInterval(-600), // 10 minutes ago
            id: UUID()
        )
    ]
}

extension SampleData {
    // Sample conversations for preview
    static func createSampleConversations() -> [ConversationDisplayModel] {
        return [
            // Conversation with recent messages
            ConversationDisplayModel(
                id: "conversation1",
                lastMessage: "Are you going to the climbing event tomorrow?",
                lastMessageTimestamp: Date().addingTimeInterval(-600), // 10 minutes ago
                unreadCount: 2,
                isLastMessageFromCurrentUser: false,
                participant: User(
                    id: "user1",
                    email: "emma@example.com",
                    firstName: "Emma",
                    lastName: "Wilson",
                    bio: "Boulder enthusiast. V5 climber.",
                    postCount: 35,
                    loggedHours: 248,
                    imageUrl: nil,
                    createdAt: Date().addingTimeInterval(-86400 * 120)
                )
            ),
            
            // Conversation with message from current user
            ConversationDisplayModel(
                id: "conversation2",
                lastMessage: "I'll bring the climbing shoes!",
                lastMessageTimestamp: Date().addingTimeInterval(-3600 * 2), // 2 hours ago
                unreadCount: 0,
                isLastMessageFromCurrentUser: true,
                participant: User(
                    id: "user2",
                    email: "david@example.com",
                    firstName: "David",
                    lastName: "Chen",
                    bio: "Lead climbing instructor",
                    postCount: 72,
                    loggedHours: 512,
                    imageUrl: nil,
                    createdAt: Date().addingTimeInterval(-86400 * 200)
                )
            ),
            
            // Older conversation
            ConversationDisplayModel(
                id: "conversation3",
                lastMessage: "Thanks for the beta on that route!",
                lastMessageTimestamp: Date().addingTimeInterval(-86400), // 1 day ago
                unreadCount: 0,
                isLastMessageFromCurrentUser: false,
                participant: User(
                    id: "user3",
                    email: "sarah@example.com",
                    firstName: "Sarah",
                    lastName: "Johnson",
                    bio: "Competition climber",
                    postCount: 128,
                    loggedHours: 875,
                    imageUrl: nil,
                    createdAt: Date().addingTimeInterval(-86400 * 90)
                )
            ),
            
            // Very old conversation
            ConversationDisplayModel(
                id: "conversation4",
                lastMessage: "Let's plan a climbing trip next month!",
                lastMessageTimestamp: Date().addingTimeInterval(-86400 * 7), // 1 week ago
                unreadCount: 0,
                isLastMessageFromCurrentUser: true,
                participant: User(
                    id: "user4",
                    email: "mike@example.com",
                    firstName: "Mike",
                    lastName: "Robinson",
                    bio: "Outdoor climber, trad enthusiast",
                    postCount: 63,
                    loggedHours: 340,
                    imageUrl: nil,
                    createdAt: Date().addingTimeInterval(-86400 * 150)
                )
            )
        ]
    }
    
    // Sample messages for conversation preview
    static func createSampleMessages() -> [MessageDisplayModel] {
        let emma = User(
            id: "user1",
            email: "emma@example.com",
            firstName: "Emma",
            lastName: "Wilson",
            bio: "Boulder enthusiast. V5 climber.",
            postCount: 35,
            loggedHours: 248,
            imageUrl: nil,
            createdAt: Date().addingTimeInterval(-86400 * 120)
        )
        
        let currentUser = previewUser
        
        return [
            // Earlier messages
            MessageDisplayModel(
                id: "msg1",
                content: "Hey, are you going to the climbing gym today?",
                timestamp: Date().addingTimeInterval(-3600), // 1 hour ago
                isFromCurrentUser: false,
                sender: emma,
                isRead: true,
                mediaURL: nil
            ),
            
            MessageDisplayModel(
                id: "msg2",
                content: "Yeah, I'm planning to go around 5pm. Want to join?",
                timestamp: Date().addingTimeInterval(-3500), // 58 minutes ago
                isFromCurrentUser: true,
                sender: currentUser,
                isRead: true,
                mediaURL: nil
            ),
            
            MessageDisplayModel(
                id: "msg3",
                content: "That works for me! I want to try that new red route.",
                timestamp: Date().addingTimeInterval(-3400), // 57 minutes ago
                isFromCurrentUser: false,
                sender: emma,
                isRead: true,
                mediaURL: nil
            ),
            
            MessageDisplayModel(
                id: "msg4",
                content: "I tried it yesterday, it's challenging but fun. The crux is in the middle section.",
                timestamp: Date().addingTimeInterval(-3300), // 55 minutes ago
                isFromCurrentUser: true,
                sender: currentUser,
                isRead: true,
                mediaURL: nil
            ),
            
            // Recent messages
            MessageDisplayModel(
                id: "msg5",
                content: "Are you still on for 5pm?",
                timestamp: Date().addingTimeInterval(-1200), // 20 minutes ago
                isFromCurrentUser: false,
                sender: emma,
                isRead: true,
                mediaURL: nil
            ),
            
            MessageDisplayModel(
                id: "msg6",
                content: "Yes! I'm about to head out. Do you need me to bring anything?",
                timestamp: Date().addingTimeInterval(-1100), // 18 minutes ago
                isFromCurrentUser: true,
                sender: currentUser,
                isRead: true,
                mediaURL: nil
            ),
            
            MessageDisplayModel(
                id: "msg7",
                content: "Can you bring some extra chalk? I'm out.",
                timestamp: Date().addingTimeInterval(-1000), // 17 minutes ago
                isFromCurrentUser: false,
                sender: emma,
                isRead: true,
                mediaURL: nil
            ),
            
            MessageDisplayModel(
                id: "msg8",
                content: "Sure, no problem!",
                timestamp: Date().addingTimeInterval(-900), // 15 minutes ago
                isFromCurrentUser: true,
                sender: currentUser,
                isRead: true,
                mediaURL: nil
            ),
            
            MessageDisplayModel(
                id: "msg9",
                content: "Are you going to the climbing event tomorrow?",
                timestamp: Date().addingTimeInterval(-600), // 10 minutes ago
                isFromCurrentUser: false,
                sender: emma,
                isRead: false,
                mediaURL: nil
            ),
        ]
    }
    
    static var placeholderGym: Gym {
        Gym(
            id: "placeholder",
            email: "placeholder@example.com",
            name: "Loading...",
            description: "Loading gym details...",
            locaiton: "Loading...",
            climbingType: [],
            amenities: [],
            events: [],
            imageUrl: nil,
            createdAt: Date()
        )
    }
}
