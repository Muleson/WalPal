//
//  ScannerOverlayView.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import SwiftUI

struct ScannerOverlayView: View {
    let message: String
    let isBarcodeDetected: Bool
    let onManualInput: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.3)
                .edgesIgnoringSafeArea(.all)
            
            GeometryReader { geometry in
                // Scanning frame with cutout
                Path { path in
                    // Create full screen rectangle
                    let rect = CGRect(x: 0, y: 0, width: geometry.size.width, height: geometry.size.height)
                    path.addRect(rect)
                    
                    // Calculate center scan area
                    let scanWidth = min(geometry.size.width * 0.8, 300)
                    let scanHeight = scanWidth * 0.6 // Adjust for typical barcode aspect ratio
                    let scanRect = CGRect(
                        x: (geometry.size.width - scanWidth) / 2,
                        y: (geometry.size.height - scanHeight) / 2,
                        width: scanWidth,
                        height: scanHeight
                    )
                    
                    // Cut out scanning area
                    path.addRoundedRect(in: scanRect, cornerSize: CGSize(width: 10, height: 10))
                }
                .fill(
                    Color.black.opacity(0.5),
                    style: FillStyle(
                        eoFill: true,
                        antialiased: true
                    )
                )
                
                // Scanning area border
                let scanWidth = min(geometry.size.width * 0.8, 300)
                let scanHeight = scanWidth * 0.6
                let centerX = (geometry.size.width - scanWidth) / 2
                let centerY = (geometry.size.height - scanHeight) / 2
                
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isBarcodeDetected ? Color.green : Color.white, lineWidth: 3)
                    .frame(width: scanWidth, height: scanHeight)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                
                // Guidance message
                Text(message)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black.opacity(0.6))
                    )
                    .frame(width: geometry.size.width)
                    .position(x: geometry.size.width / 2, y: centerY + scanHeight + 40)
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: onManualInput) {
                        HStack {
                            Image(systemName: "keyboard")
                                .font(.body)
                            Text("Manual Input")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(width: 200)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.blue)
                        )
                    }
                    .padding(.bottom, 8)
                    
                    Button(action: onCancel) {
                        Text("Cancel")
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(width: 200)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.red.opacity(0.8))
                            )
                    }
                }
                .position(x: geometry.size.width / 2, y: geometry.size.height - 100)
            }
        }
    }
}

#Preview {
    VStack {
        ScannerOverlayView(
            message: "Align barcode within the frame",
            isBarcodeDetected: false,
            onManualInput: {},
            onCancel: {}
        )
        .background(Color.gray)
        .frame(height: 300)
        
        ScannerOverlayView(
            message: "Barcode detected",
            isBarcodeDetected: true,
            onManualInput: {},
            onCancel: {}
        )
        .background(Color.gray)
        .frame(height: 300)
    }
}
