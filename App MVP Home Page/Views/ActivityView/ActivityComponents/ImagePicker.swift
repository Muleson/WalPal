//
//  ImagePicker.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 13/03/2025.
//

import SwiftUI
import AVKit
import AVFoundation
import PhotosUI

struct MediaPickerView: View {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideos: [URL]
    @State private var isImagePickerPresented = false
    @State private var isVideoCameraPresented = false
    @State private var isPhotoLibraryPresented = false
    @State private var tempSelectedImage: UIImage? = nil

    
    var body: some View {
        VStack(spacing: 12) {
            // Selected Media Preview
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(selectedImages.indices, id: \.self) { index in
                        Image(uiImage: selectedImages[index])
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                Button(action: {
                                    selectedImages.remove(at: index)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.7)))
                                }
                                .padding(4),
                                alignment: .topTrailing
                            )
                    }
                    
                    ForEach(selectedVideos.indices, id: \.self) { index in
                        ZStack {
                            if let thumbnail = selectedVideos[index].videoThumbnail() {
                                Image(uiImage: thumbnail)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Color.black
                            }
                            
                            Image(systemName: "play.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                            
                            VStack {
                                Spacer()
                                Text("Video")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .padding(.bottom, 8)
                            }
                        }
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            Button(action: {
                                selectedVideos.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                                    .background(Circle().fill(Color.black.opacity(0.7)))
                            }
                            .padding(4),
                            alignment: .topTrailing
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Media Source Buttons
            HStack(spacing: 20) {
                Button(action: {
                    isPhotoLibraryPresented = true
                }) {
                    VStack {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                        Text("Photo Library")
                            .font(.caption)
                    }
                    .foregroundColor(.appButton)
                }
                
                Button(action: {
                    isImagePickerPresented = true
                }) {
                    VStack {
                        Image(systemName: "camera")
                            .font(.system(size: 24))
                        Text("Take Photo")
                            .font(.caption)
                    }
                    .foregroundColor(.appButton)
                }
                
                Button(action: {
                    isVideoCameraPresented = true
                }) {
                    VStack {
                        Image(systemName: "video")
                            .font(.system(size: 24))
                        Text("Record Video")
                            .font(.caption)
                    }
                    .foregroundColor(.appButton)
                }
            }
            .padding(.vertical, 8)
        }
        .sheet(isPresented: $isImagePickerPresented, onDismiss: {
            if let image = tempSelectedImage {
                selectedImages.append(image)
                tempSelectedImage = nil
            }
        }) {
            ImagePicker(
                selectedImage: $tempSelectedImage,
                sourceType: .camera
            )
        }
        .sheet(isPresented: $isPhotoLibraryPresented) {
            PHPickerView(
                selectedImages: $selectedImages, 
                selectedVideos: $selectedVideos,
                onComplete: {
                    print("Selection complete. Final counts - Images: \(selectedImages.count), Videos: \(selectedVideos.count)")
                }
            )
        }
        .sheet(isPresented: $isVideoCameraPresented) {
            VideoPicker(selectedVideo: Binding(
                get: { selectedVideos.first ?? URL(string: "about:blank")! },
                set: { newURL in selectedVideos.append(newURL) }
            ))
        }
    }
}

struct PHPickerView: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Binding var selectedVideos: [URL]
    var onComplete: (() -> Void)? = nil
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PHPickerView
        var pendingOperations = 0
        
        init(parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            // Don't dismiss immediately if we have video operations
            let hasVideoOperations = results.contains { 
                $0.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier)
            }
            
            if !hasVideoOperations {
                picker.dismiss(animated: true)
            }
            
            // Track number of pending operations
            pendingOperations = results.count
            
            for result in results {
                let itemProvider = result.itemProvider
                
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self?.parent.selectedImages.append(image)
                                self?.operationCompleted(picker: picker)
                            }
                        } else {
                            self?.operationCompleted(picker: picker)
                        }
                    }
                } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    print("Starting to load video from library")
                    itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                        guard let url = url else { 
                            print("Failed to load video URL")
                            self?.operationCompleted(picker: picker)
                            return 
                        }
                        
                        print("Got temporary URL: \(url.path)")
                        
                        do {
                            let localURL = FileManager.default.secureVideoURL()
                            print("Will save to: \(localURL.path)")
                            
                            // Copy without attempting bookmark creation
                            try FileManager.default.copyItem(at: url, to: localURL)
                            print("Video successfully copied")
                            
                            DispatchQueue.main.async {
                                var updatedVideos = self?.parent.selectedVideos ?? []
                                updatedVideos.append(localURL)
                                self?.parent.selectedVideos = updatedVideos
                                print("Added video to array, count now: \(updatedVideos.count)")
                                self?.operationCompleted(picker: picker)
                            }
                        } catch {
                            print("Error copying video: \(error.localizedDescription)")
                            self?.operationCompleted(picker: picker)
                        }
                    }
                } else {
                    // Item not processable, count it as completed
                    self.operationCompleted(picker: picker)
                }
            }
            
            // If no results, dismiss immediately
            if results.isEmpty {
                picker.dismiss(animated: true)
                parent.onComplete?()
            }
        }
        
        private func operationCompleted(picker: PHPickerViewController) {
            pendingOperations -= 1
            print("Operation completed, \(pendingOperations) remaining")
            
            // When all operations are complete, dismiss the picker
            if pendingOperations <= 0 {
                DispatchQueue.main.async {
                    picker.dismiss(animated: true)
                    self.parent.onComplete?()
                }
            }
        }
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .any(of: [.images, .videos])
        config.selectionLimit = 10
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    var sourceType: UIImagePickerController.SourceType
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        picker.sourceType = sourceType
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.selectedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.selectedImage = originalImage
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

struct VideoPicker: UIViewControllerRepresentable {
    @Binding var selectedVideo: URL
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.mediaTypes = ["public.movie"]
        picker.videoQuality = .typeHigh
        picker.sourceType = .camera
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: VideoPicker
        
        init(_ parent: VideoPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let mediaURL = info[.mediaURL] as? URL {
                parent.selectedVideo = mediaURL
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

extension URL {
    func videoThumbnail() -> UIImage? {
        let asset = AVURLAsset(url: self)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        do {
            let cgImage = try imageGenerator.copyCGImage(at: CMTime(seconds: 0.0, preferredTimescale: 60), actualTime: nil)
            return UIImage(cgImage: cgImage)
        } catch {
            print("Error generating video thumbnail: \(error)")
            return nil
        }
    }
}

extension FileManager {
    func secureVideoURL() -> URL {
        // Create a directory for videos if needed
        let videoDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Videos", isDirectory: true)
        
        // Create the directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: videoDirectory.path) {
            try? FileManager.default.createDirectory(at: videoDirectory, withIntermediateDirectories: true)
        }
        
        // Generate a unique filename with UUID
        let uniqueFilename = UUID().uuidString + ".mov"
        let fileURL = videoDirectory.appendingPathComponent(uniqueFilename)
        
        return fileURL
    }
}

