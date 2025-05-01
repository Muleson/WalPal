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
                } else {
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
        .onAppear {
            if media.type == .video {
                isPlaying = true
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
    
    @Published var isBuffering = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    
    func setupPlayer(with url: URL) {
        player = AVPlayer(url: url)
        
        // Add observers for playback status
        player?.addObserver(self, forKeyPath: "timeControlStatus", options: [.old, .new], context: nil)
        
        // Add periodic time observer
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.currentTime = time.seconds
            if let duration = self?.player?.currentItem?.duration.seconds, !duration.isNaN {
                self?.duration = duration
            }
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "timeControlStatus", let player = object as? AVPlayer {
            DispatchQueue.main.async {
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
        player?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }
    
    deinit {
        player?.removeObserver(self, forKeyPath: "timeControlStatus")
    }
}

struct VideoPlayerView: UIViewControllerRepresentable {
    let url: URL
    @Binding var isPlaying: Bool
    @ObservedObject var playerModel: VideoPlayerModel
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        let player = AVPlayer(url: url)
        controller.player = player
        controller.showsPlaybackControls = true
        
        playerModel.setupPlayer(with: url)
        
        if isPlaying {
            player.play()
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        if isPlaying {
            uiViewController.player?.play()
            playerModel.play()
        } else {
            uiViewController.player?.pause()
            playerModel.pause()
        }
    }
}
