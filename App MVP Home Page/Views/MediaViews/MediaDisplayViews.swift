//
//  MediaDisplayViews.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 25/04/2025.
//

import SwiftUI
import AVKit
import PhotosUI

struct MediaGridView: View {
    let mediaItems: [Media]
    let onMediaTap: (Media) -> Void
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(mediaItems) { media in
                MediaThumbnailView(media: media)
                    .aspectRatio(1, contentMode: .fill)
                    .frame(minHeight: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onTapGesture {
                        onMediaTap(media)
                    }
            }
        }
        .padding(.horizontal)
    }
}

struct MediaThumbnailView: View {
    let media: Media
    
    var body: some View {
        ZStack {
            // Image or Video Thumbnail
            if media.type == .video {
                // Use thumbnailURL for videos
                AsyncImage(url: media.thumbnailURL ?? media.url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                
                // Play button overlay for videos
                Image(systemName: "play.fill")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .shadow(radius: 2)
            } else {
                // Regular image display
                AsyncImage(url: media.url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
            }
        }
    }
}

struct MediaDetailView: View {
    let media: Media
    @State private var isPlaying = false
    @StateObject private var videoPlayerModel = VideoPlayerModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack {
                if media.type == .video {
                    VideoPlayerView(url: media.url, isPlaying: $isPlaying, playerModel: videoPlayerModel)
                        .onAppear {
                            // Initialize player
                            videoPlayerModel.setupPlayer(with: media.url)
                            
                            // Start playback after a small delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                isPlaying = true
                            }
                        }
                        // Two-way binding for isPlaying state
                        .onChange(of: videoPlayerModel.isPlaying) { newValue in
                            isPlaying = newValue
                        }
                } else {
                    // Image display code
                    AsyncImage(url: media.url) { image in
                        image
                            .resizable()
                            .scaledToFit()
                    } placeholder: {
                        ProgressView()
                    }
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .foregroundColor(.white)
                            .padding()
                    }
                    Spacer()
                }
                Spacer()
            }
        }
        .onDisappear {
            isPlaying = false
            videoPlayerModel.pause()
        }
    }
}

class VideoPlayerModel: NSObject, ObservableObject {
    private var player: AVPlayer?
    private var timeObserverToken: Any?
    private var itemEndObserver: Any?
    
    // Closure for handling end of playback
    var endPlaybackHandler: (() -> Void)?
    
    @Published var isBuffering = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying: Bool = false
    
    func setupPlayer(with url: URL) {
        // Clean up previous observers if needed
        cleanupObservers()
        
        if player == nil {
            let playerItem = AVPlayerItem(url: url)
            player = AVPlayer(playerItem: playerItem)
            
            // Configure player behavior
            player?.automaticallyWaitsToMinimizeStalling = true
            player?.preventsDisplaySleepDuringVideoPlayback = true
            
            setupObservers()
        } else if let currentItem = player?.currentItem, currentItem.asset != AVAsset(url: url) {
            let playerItem = AVPlayerItem(url: url)
            player?.replaceCurrentItem(with: playerItem)
            setupObservers()
        }
    }
    
    private func setupObservers() {
        guard let player = player, let playerItem = player.currentItem else { return }
        
        // Add observer for player rate changes
        player.addObserver(self, forKeyPath: "rate", options: [.new], context: nil)
        player.addObserver(self, forKeyPath: "timeControlStatus", options: [.new], context: nil)
        
        // Add time observer
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            
            // Fixed duration check - don't use if let since duration.seconds is not optional
            let duration = playerItem.duration.seconds
            if duration.isFinite && duration > 0 {
                self?.duration = duration
            }
        }
        
        // Add notification observer for playback ended
        itemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main) { [weak self] _ in
                self?.isPlaying = false
                self?.endPlaybackHandler?()
            }
    }
    
    private func cleanupObservers() {
        if let player = player {
            player.removeObserver(self, forKeyPath: "rate")
            player.removeObserver(self, forKeyPath: "timeControlStatus")
            
            if let timeObserverToken = timeObserverToken {
                player.removeTimeObserver(timeObserverToken)
                self.timeObserverToken = nil
            }
            
            if let itemEndObserver = itemEndObserver {
                NotificationCenter.default.removeObserver(itemEndObserver)
                self.itemEndObserver = nil
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard let player = object as? AVPlayer else { return }
        
        DispatchQueue.main.async {
            if keyPath == "rate" {
                self.isPlaying = player.rate != 0
            } else if keyPath == "timeControlStatus" {
                self.isBuffering = player.timeControlStatus == .waitingToPlayAtSpecifiedRate
            }
        }
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func seek(to time: Double) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        player?.seek(to: cmTime)
    }
    
    func getPlayer() -> AVPlayer? {
        return player
    }
    
    deinit {
        cleanupObservers()
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPlaying: Bool
    @ObservedObject var playerModel: VideoPlayerModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        
        // Set up the player
        playerModel.setupPlayer(with: url)
        controller.player = playerModel.getPlayer()
        controller.showsPlaybackControls = true
        controller.delegate = context.coordinator
        
        // Add the coordinator as observer
        playerModel.endPlaybackHandler = {
            DispatchQueue.main.async {
                self.isPlaying = false
            }
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // Update controller state based on isPlaying
        if isPlaying && uiViewController.player?.rate == 0 {
            playerModel.play()
        } else if !isPlaying && uiViewController.player?.rate != 0 {
            playerModel.pause()
        }
    }
    
    class Coordinator: NSObject, AVPlayerViewControllerDelegate {
        var parent: VideoPlayerView
        
        init(_ parent: VideoPlayerView) {
            self.parent = parent
        }
        
        // Using delegate methods for handling player events
        func playerViewControllerDidStartPictureInPicture(_ playerViewController: AVPlayerViewController) {
            parent.isPlaying = true
        }
        
        func playerViewControllerDidStopPictureInPicture(_ playerViewController: AVPlayerViewController) {
            // Optional: Update state if needed when PiP stops
        }
        
        func playerViewController(_ playerViewController: AVPlayerViewController, 
                                willBeginFullScreenPresentationWithAnimationCoordinator coordinator: UIViewControllerTransitionCoordinator) {
            // Optional: Handle transition to fullscreen if needed
        }
    }
}
