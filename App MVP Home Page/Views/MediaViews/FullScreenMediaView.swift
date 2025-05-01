//
//  FullScreenMediaView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 01/05/2025.
//

import SwiftUI

struct FullScreenMediaView: View {
    @Environment(\.dismiss) private var dismiss
    let mediaUrl: String
    
    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                VStack {
                    AsyncImage(url: URL(string: mediaUrl)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: geometry.size.width)
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
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
        .navigationBarHidden(true)
        .gesture(
            TapGesture()
                .onEnded { _ in
                    dismiss()
                }
        )
    }
}

struct FullScreenMediaView_Previews: PreviewProvider {
    static var previews: some View {
        FullScreenMediaView(mediaUrl: "https://example.com/sample.jpg")
    }
}
