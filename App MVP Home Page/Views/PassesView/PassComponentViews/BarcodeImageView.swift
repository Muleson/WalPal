//
//  BarcodeImageView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import Foundation
import SwiftUI

struct BarcodeImageView: View {
    let pass: Pass
    
    @ObservedObject var viewModel: PassViewModel
    
    var body: some View {
        if let barcodeImage = viewModel.generateBarcodeImage(from: pass) {
            Image(uiImage: barcodeImage)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(height: 150)
                .padding(.vertical, 8)
        }
    }
}
