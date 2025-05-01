//
//  RemoteVideoPlayer.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 24/04/2025.
//

import SwiftUI
import AVKit

struct RemoteVideoPlayerView: View {
    let videoURL: URL
    let thumbnailURL: URL?
    
    @State private var isLoading: Bool = true
    @State private var error: Error?
    @State private var player: AVPlayer?
    @State private var showControls: Bool = true
    
    var body: some View {
        ZStack {
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .onAppear {
                        // Auto-play when view appears
                        player.play()
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else if error != nil {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    Text("Failed to load video")
                        .font(.headline)
                    Button("Retry") {
                        loadVideo()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
            } else if isLoading {
                if let thumbnailURL = thumbnailURL {
                    AsyncImage(url: thumbnailURL) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .overlay(
                                    ProgressView()
                                        .scaleEffect(1.5)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.black.opacity(0.3))
                                )
                        default:
                            ProgressView()
                                .scaleEffect(1.5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                } else {
                    ProgressView()
                        .scaleEffect(1.5)
                }
            }
        }
        .frame(height: 220)
        .cornerRadius(12)
        .onAppear {
            loadVideo()
        }
    }
    
    private func loadVideo() {
        isLoading = true
        error = nil
        
        DispatchQueue.global().async {
            do {
                let asset = AVAsset(url: videoURL)
                let playerItem = AVPlayerItem(asset: asset)
                
                DispatchQueue.main.async {
                    player = AVPlayer(playerItem: playerItem)
                    isLoading = false
                }
            } catch let loadError {
                DispatchQueue.main.async {
                    error = loadError
                    isLoading = false
                }
            }
        }
    }
}
