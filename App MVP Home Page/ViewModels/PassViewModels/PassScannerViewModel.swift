//
//  PassScannerViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import Foundation
import SwiftUI
import VisionKit
import AVKit
import Combine

enum PassScannerStatus {
    case notDetermined
    case noCameraAccess
    case cameraNotFound
    case scannerAvailable
    case scannerNotAvailable
}

@MainActor
final class PassScannerViewModel: ObservableObject {
    
    @Published var scannerStatus: PassScannerStatus = .notDetermined
    @Published var recognizedCode: RecognizedItem?
    @Published var isBarcodeDetected: Bool = false
    
    // Use a callback instead of relying on property observation
    var onBarcodeDetected: ((RecognizedItem) -> Void)?
    
    // Use a passed-in PassViewModel instead of creating a new one
    private let passViewModel: PassViewModel
    private var cancellables = Set<AnyCancellable>()
    
    init(scannerStatus: PassScannerStatus = .notDetermined,
         recognizedCode: RecognizedItem? = nil,
         passViewModel: PassViewModel) {
        
        self.scannerStatus = scannerStatus
        self.recognizedCode = recognizedCode
        self.passViewModel = passViewModel
        
        // Set up publishers first
        setupPublishers()
        
        // Check permissions after init is complete
        Task {
            await checkCameraPermissions()
        }
    }
    
    // Create a separate method for setting up publishers to avoid initializer complexity
    private func setupPublishers() {
        // Monitor recognizedCode changes through combine
        $recognizedCode
            .dropFirst()
            .map { $0 != nil }
            .receive(on: RunLoop.main)
            .sink { [weak self] isDetected in
                guard let self = self else { return }
                
                // Update detection state
                self.isBarcodeDetected = isDetected
                
                // If a barcode is detected, notify after a short delay
                if isDetected, let code = self.recognizedCode {
                    // Add a short delay before triggering navigation to avoid UI glitches
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.onBarcodeDetected?(code)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // Create separate method for checking permissions to improve readability
    private func checkCameraPermissions() async {
        do {
            try await requestPassScannerStatus()
        } catch {
            await MainActor.run {
                scannerStatus = .noCameraAccess
                print("Camera permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // Data scanner configuration
    var recognizedDataType: DataScannerViewController.RecognizedDataType {
        .barcode()
    }
    
    private var isScannerAvailable: Bool {
        DataScannerViewController.isAvailable && DataScannerViewController.isSupported
    }
    
    // Process a scanned barcode
    func processScannedCode(_ item: RecognizedItem) {
        guard case .barcode(let barcode) = item else { return }
        
        passViewModel.handleScannedBarcode(
            code: barcode.payloadStringValue ?? "Unknown",
            codeType: barcode.observation.symbology.rawValue
        )
    }
    
    // Call this method when a potential barcode is detected but not yet confirmed
    func updateBarcodeDetectionStatus(_ detected: Bool) {
        Task { @MainActor in
            self.isBarcodeDetected = detected
        }
    }
    
    // Improved permission request with better error handling
    func requestPassScannerStatus() async throws {
        // First check if camera hardware is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            await MainActor.run {
                scannerStatus = .cameraNotFound
            }
            return
        }
        
        // Then check authorization status
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            
        case .authorized:
            await MainActor.run {
                // Check if scanner is available AFTER authorization is confirmed
                scannerStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
            }
            
        case .restricted, .denied:
            await MainActor.run {
                scannerStatus = .noCameraAccess
            }
            
        case .notDetermined:
            // Request permission
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            
            await MainActor.run {
                if granted {
                    scannerStatus = isScannerAvailable ? .scannerAvailable : .scannerNotAvailable
                } else {
                    scannerStatus = .noCameraAccess
                }
            }
            
        @unknown default:
            await MainActor.run {
                scannerStatus = .noCameraAccess
            }
        }
    }
}
