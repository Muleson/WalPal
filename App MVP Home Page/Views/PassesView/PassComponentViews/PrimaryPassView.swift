//
//  PrimaryPassView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import Foundation
import SwiftUI

struct PrimaryPassView: View {
    
    @ObservedObject var viewModel: PassViewModel
    
    var body: some View {
        if let primaryPass = viewModel.primaryPass {
            VStack(alignment: .center, spacing: 8) {
                Text(primaryPass.mainInformation.title)
                    .font(.headline)
                BarcodeImageView(pass: primaryPass, viewModel: viewModel)
            }
        }
    }
}
