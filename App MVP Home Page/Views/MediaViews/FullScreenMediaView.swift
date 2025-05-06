//
//  FullScreenMediaView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 01/05/2025.
//

import SwiftUI
import AVKit

struct FullScreenMediaView: View {
    @Environment(\.dismiss) private var dismiss
    let mediaUrl: String
    @State private var isLoading = true
    @State private var loadError = false
    
    // Determine if the URL is for a video
    private var isVideoUrl: Bool {
        let videoExtensions = ["mp4", "mov", "m4v", "3gp", "avi", "webm"]
        let url = URL(string: mediaUrl)
        let fileExtension = url?.pathExtension.lowercased() ?? ""
        return videoExtensions.contains(fileExtension)
    }
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            if let url = URL(string: mediaUrl) {
                if isVideoUrl {
                    // Use MediaDetailView for videos - it already has the proper video handling
                    let videoMedia = Media(
                        id: UUID().uuidString,
                        url: url,
                        type: .video,
                        thumbnailURL: nil,  // Add nil or a default thumbnail if available
                        uploadedAt: Date(),  // Use current date as fallback
                        ownerId: ""  // Add empty string or default owner ID
                    )
                    MediaDetailView(media: videoMedia)
                        .onAppear {
                            print("Video view appeared for URL: \(url)")
                            isLoading = false
                        }
                } else {
                    // Image viewer
                    GeometryReader { geometry in
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .onAppear { isLoading = true }
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: geometry.size.width)
                                    .onAppear { 
                                        print("Image loaded successfully")
                                        isLoading = false 
                                    }
                            case .failure(let error):
                                VStack {
                                    Image(systemName: "photo")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray)
                                    Text("Failed to load image")
                                        .foregroundColor(.white)
                                        .padding(.top, 8)
                                    Text("Error: \(error.localizedDescription)")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                        .padding(.top, 4)
                                }
                                .onAppear {
                                    print("Image loading failed: \(error.localizedDescription)")
                                    isLoading = false
                                    loadError = true
                                }
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        // Image specific dismiss button
                        if !isVideoUrl {
                            VStack {
                                HStack {
                                    Spacer()
                                    Button(action: {
                                        print("Image dismiss button tapped")
                                        dismiss()
                                    }) {
                                        Image(systemName: "xmark")
                                            .font(.title2)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Circle().fill(Color.black.opacity(0.5)))
                                    }
                                    .padding()
                                }
                                Spacer()
                            }
                        }
                    }
                }
            } else {
                // Invalid URL
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                    Text("Invalid media URL")
                        .foregroundColor(.white)
                        .padding(.top, 8)
                    Text(mediaUrl)
                        .foregroundColor(.gray)
                        .font(.caption)
                        .padding(.top, 4)
                        
                    Button(action: {
                        print("Return button tapped")
                        dismiss()
                    }) {
                        Text("Return to previous screen")
                            .foregroundColor(.white)
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color.blue))
                    }
                    .padding(.top, 20)
                }
                .onAppear {
                    print("Invalid URL provided: \(mediaUrl)")
                    isLoading = false
                    loadError = true
                }
            }
            
            // Show loading indicator when needed
            if isLoading {
                VStack {
                    Spacer()
                    Text("Loading media...")
                        .foregroundColor(.white)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5)))
                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            print("FullScreenMediaView appeared with URL: \(mediaUrl)")
            
            // Validate URL and print info
            if let url = URL(string: mediaUrl) {
                print("URL is valid: \(url)")
                if isVideoUrl {
                    print("Detected as video URL")
                } else {
                    print("Detected as image URL")
                }
            } else {
                print("Invalid URL format: \(mediaUrl)")
                isLoading = false
                loadError = true
            }
        }
    }
}

struct FullScreenMediaView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview with an image
            FullScreenMediaView(mediaUrl: "https://example.com/sample.jpg")
                .previewDisplayName("Image Preview")
            
            // Preview with a video
            FullScreenMediaView(mediaUrl: "https://example.com/sample.mp4")
                .previewDisplayName("Video Preview")
        }
    }
}
