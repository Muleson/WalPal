//
//  ImagePicker.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 13/03/2025.
//

import SwiftUI
import AVKit
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
                            Color.black
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
            PHPickerView(selectedImages: $selectedImages, selectedVideos: $selectedVideos)
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
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        var parent: PHPickerView
        
        init(parent: PHPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            for result in results {
                let itemProvider = result.itemProvider
                
                if itemProvider.canLoadObject(ofClass: UIImage.self) {
                    itemProvider.loadObject(ofClass: UIImage.self) { [weak self] image, error in
                        if let image = image as? UIImage {
                            DispatchQueue.main.async {
                                self?.parent.selectedImages.append(image)
                            }
                        }
                    }
                } else if itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                    itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { [weak self] url, error in
                        if let url = url {
                            // Create a local copy of the video
                            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                            let localURL = documentsDirectory.appendingPathComponent(url.lastPathComponent)
                            
                            try? FileManager.default.copyItem(at: url, to: localURL)
                            
                            DispatchQueue.main.async {
                                self?.parent.selectedVideos.append(localURL)
                            }
                        }
                    }
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
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    @Environment(\.presentationMode) private var presentationMode

    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = sourceType
        imagePicker.delegate = context.coordinator
        return imagePicker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        var parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
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
            if let videoURL = info[.mediaURL] as? URL {
                // Create a local copy of the video
                let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                let localURL = documentsDirectory.appendingPathComponent(videoURL.lastPathComponent)
                
                try? FileManager.default.copyItem(at: videoURL, to: localURL)
                parent.selectedVideo = localURL
            }
            
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
