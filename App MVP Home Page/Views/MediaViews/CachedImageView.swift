//
//  CachedImageView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 24/04/2025.
//

import SwiftUI

struct CachedImageView: View {
    let url: URL
    let contentMode: ContentMode
    
    @State private var image: UIImage?
    @State private var isLoading = true
    @State private var error: Error?
    
    init(url: URL, contentMode: ContentMode = .fill) {
        self.url = url
        self.contentMode = contentMode
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "photo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        isLoading = true
        
        // Use URLSession to download the image
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    self.error = error
                    return
                }
                
                guard let data = data, let downloadedImage = UIImage(data: data) else {
                    self.error = NSError(domain: "ImageLoadingError", code: 0, userInfo: nil)
                    return
                }
                
                self.image = downloadedImage
            }
        }.resume()
    }
}
