//
//  ScannerViewController.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import Foundation
import SwiftUI
import VisionKit
 
struct PassScannerViewController: UIViewControllerRepresentable {
    
    @Binding var recognizedCode: RecognizedItem?
    let recognizedDataType: DataScannerViewController.RecognizedDataType
    let recognizesMultipleItems: Bool = false
    let viewModel: PassScannerViewModel
    
    func makeUIViewController(context: Context) -> DataScannerViewController {
        let viewController = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .balanced,
            recognizesMultipleItems: false,
            isGuidanceEnabled: false, // Disable default guidance since we have our own overlay
            isHighlightingEnabled: true
        )
        
        // Set region of interest for better scanning
        DispatchQueue.main.async {
            let screenBounds = UIScreen.main.bounds
            let scanWidth = min(screenBounds.width * 0.8, 300)
            let scanHeight = scanWidth * 0.6
            let centerX = screenBounds.width / 2
            let centerY = screenBounds.height / 2
            
            // Create region of interest rectangle
            let roiRect = CGRect(
                x: centerX - scanWidth / 2,
                y: centerY - scanHeight / 2,
                width: scanWidth,
                height: scanHeight
            )
            
            viewController.regionOfInterest = roiRect
        }
        
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        uiViewController.delegate = context.coordinator
        try? uiViewController.startScanning()
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedCode: $recognizedCode, viewModel: viewModel)
    }
    
    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }
    
    class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding var recognizedCode: RecognizedItem?
        let viewModel: PassScannerViewModel
        
        init(recognizedCode: Binding<RecognizedItem?>, viewModel: PassScannerViewModel) {
            self._recognizedCode = recognizedCode
            self.viewModel = viewModel
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            viewModel.updateBarcodeDetectionStatus(true)
            recognizedCode = item
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Auto-capture first recognized barcode when items are detected
            viewModel.updateBarcodeDetectionStatus(true)
            if let firstBarcode = addedItems.first {
                // Update the recognized code
                self.recognizedCode = firstBarcode
            }
        }
        
        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            print("Scanner no longer available. Error: \(error.localizedDescription)")
        }
    }
}
