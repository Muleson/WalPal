//
//  PassViewModel.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import Foundation
import CoreImage
import UIKit
import Vision
import Combine
import SwiftUI

class PassViewModel: ObservableObject {
    
    @Published var passes: [Pass] = []
    @Published var titlePlaceholder: String = ""
    @Published var showTitlePrompt: Bool = false
    @Published var deletionState: DeletionState<Pass> = .none
    @Published var primaryPass: Pass? = nil
    @Published var duplicatePassAlert: Bool = false
    @Published var duplicatePassName: String = ""
    
    private let passManager: PassManager
    private var cancellables = Set<AnyCancellable>()
    var lastScannedPass: Pass?
    
    init(passManager: PassManager = PassManager()) {
        self.passManager = passManager
        loadPasses()
        
        // Subscribe to changes in the passManager
        passManager.objectWillChange.sink { [weak self] in
            DispatchQueue.main.async {
                self?.objectWillChange.send()
                self?.loadPasses()
            }
        }.store(in: &cancellables)
    }

    
    func loadPasses() {
        passes = passManager.passes
        primaryPass = passes.first(where: { $0.isPrimary })
        
        //DEBUG
        print("PassViewModel: Loaded passes count: \(passes.count)")
        print("PassViewModel: Primary pass exists: \(primaryPass != nil)")
    }
    
    func handleScannedBarcode(code: String, codeType: String) {
        let barcodeData = BarcodeData(code: code,
                                      codeType: codeType)
        let mainInfo = MainInformation(title: "",
                                       date: Date())
        
        lastScannedPass = Pass(mainInformation: mainInfo,
                               barcodeData: barcodeData)
        showTitlePrompt = true
        
        // Check if this is a duplicate
        if let duplicatePass = findDuplicatePass(code: code, codeType: codeType) {
            duplicatePassName = duplicatePass.mainInformation.title
        } else {
            duplicatePassName = ""
        }
        
        // Debug output
        print("PassViewModel: Scanned barcode - code: \(code), type: \(codeType)")
    }
    
    func savePassWithTitle(primaryStatus: Bool = false) -> Bool {
        guard let pass = lastScannedPass else { return false }
        
        // Check one more time for duplicates (in case another device added a pass)
        if findDuplicatePass(code: pass.barcodeData.code, codeType: pass.barcodeData.codeType) != nil {
            duplicatePassAlert = true
            return false
        }
        
        let updatedInfo = MainInformation(title: titlePlaceholder,
                                          date: pass.mainInformation.date)
        
        let finalPass = Pass(mainInformation: updatedInfo,
                             barcodeData: pass.barcodeData,
                             isPrimary: primaryStatus)
        
        print("PassViewModel: Saving pass with title: \(titlePlaceholder), primary status: \(primaryStatus)")
        let success = passManager.addPass(finalPass)
        
        if success {
            // Reload passes to reflect changes
            loadPasses()
            
            showTitlePrompt = false
            titlePlaceholder = ""
            lastScannedPass = nil
            
            // Debug output
            print("PassViewModel: After saving - Passes count: \(passes.count)")
            print("PassViewModel: After saving - Primary pass exists: \(primaryPass != nil)")
        } else {
            duplicatePassAlert = true
        }
        
        return success
    }
    
    // Helper method to find duplicate passes
    func findDuplicatePass(code: String, codeType: String) -> Pass? {
        return passes.first { pass in
            return pass.barcodeData.code == code && pass.barcodeData.codeType == codeType
        }
    }
    
    func setPrimaryPass(for passID: UUID) {
        passManager.setPrimaryPass(id: passID)
        
        // Force a refresh of the view model state
        objectWillChange.send()
        loadPasses()
    }
    
    func confirmDelete(for pass: Pass) {
        deletionState = .confirming(pass)
    }
    
    func cancelDelete() {
        deletionState = .none
    }
    
    func handleDelete(for pass: Pass) {
        if case let .confirming(pass) = deletionState {
            passManager.delete(id: pass.id, wasItemPrimary: pass.isPrimary)
            loadPasses()
            deletionState = .none
        }
    }
    
    func updatePassTitle(for passID: UUID, with title: String) {
        passManager.updatePassTitle(for: passID, with: title)
        loadPasses()
    }
    
    // Rest of the code for barcode generation remains the same
    
    private func getCIFilter(for barcodeType: String) -> CIFilter? {
        // Map VNBarcodeSymbology raw values to appropriate CIFilter
         switch barcodeType {
         case VNBarcodeSymbology.qr.rawValue:
             return CIFilter.qrCodeGenerator()
         case VNBarcodeSymbology.code128.rawValue:
             return CIFilter.code128BarcodeGenerator()
         case VNBarcodeSymbology.pdf417.rawValue:
             return CIFilter.pdf417BarcodeGenerator()
         case VNBarcodeSymbology.aztec.rawValue:
             return CIFilter.aztecCodeGenerator()
        // Unsuported barcode types default to code128 generator
         case VNBarcodeSymbology.code39.rawValue,
              VNBarcodeSymbology.ean13.rawValue,
              VNBarcodeSymbology.ean8.rawValue,
              VNBarcodeSymbology.upce.rawValue,
              VNBarcodeSymbology.itf14.rawValue,
             VNBarcodeSymbology.dataMatrix.rawValue:
             return CIFilter.code128BarcodeGenerator()
         default:
        // Default to QR code if type is not supported
             print("Unsupported barcode type: \(barcodeType), defaulting to QR")
             return CIFilter.qrCodeGenerator()
         }
     }
     
     private func configureFilter(_ filter: CIFilter, withData data: Data) {
         switch filter.name {
         case "CIQRCodeGenerator",
              "CIAztecCodeGenerator",
              "CIPDF417BarcodeGenerator",
              "CIDataMatrixGenerator":
             filter.setValue(data, forKey: "inputMessage")
             
         case "CICode128BarcodeGenerator",
              "CICode39BarcodeGenerator":
             filter.setValue(data, forKey: "inputMessage")
             filter.setValue(0.0, forKey: "inputQuietSpace")
             
         case "CIEAN13BarcodeGenerator",
              "CIEAN8BarcodeGenerator",
              "CIUPCEGenerator",
              "CIITF14BarcodeGenerator":
             if let stringValue = String(data: data, encoding: .ascii),
                let doubleValue = Double(stringValue) {
                 filter.setValue(doubleValue, forKey: "inputMessage")
             }
             
         default:
             filter.setValue(data, forKey: "inputMessage")
         }
     }
     
     func generateBarcodeImage(from pass: Pass) -> UIImage? {
         
         //DEBUG
            print("Generating barcode for pass: \(pass.id)")
            print("Barcode code: \(pass.barcodeData.code)")
            print("Barcode type: \(pass.barcodeData.codeType)")
         
         guard let filter = getCIFilter(for: pass.barcodeData.codeType) else {
             
             //DEBUG
             print("Failed to get filter for type: \(pass.barcodeData.codeType)")
             
             return nil
         }

         // Convert string to data
         guard let barcodeData = pass.barcodeData.code.data(using: .ascii) else {
             
             //DEBUG
             print("Failed to convert barcode code to ASCII data")
             
             return nil
         }
         
         //DEBUG
         print("Successfully created barcode data of length: \(barcodeData.count)")
         
         // Configure the filter based on its type
         configureFilter(filter, withData: barcodeData)
         
         // Get the output image
         guard let outputImage = filter.outputImage else {
             //DEBUG
             print("Filter failed to generate output image")
             return nil
         }
         
         //DEBUG
         print("Successfully generated CIImage")

         
         // Scale the image
         let transform = CGAffineTransform(scaleX: 10, y: 10)
         let scaledImage = outputImage.transformed(by: transform)
         
         // Create context and generate UIImage
         let context = CIContext()
         guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
             print("Failed to create CGImage from scaled image")
             return nil
         }
         
         // For 1D barcodes, we want to adjust the aspect ratio
         let is1DBarcode = [
             VNBarcodeSymbology.code128.rawValue,
             VNBarcodeSymbology.code39.rawValue,
             VNBarcodeSymbology.ean13.rawValue,
             VNBarcodeSymbology.ean8.rawValue,
             VNBarcodeSymbology.upce.rawValue,
             VNBarcodeSymbology.itf14.rawValue
         ].contains(pass.barcodeData.codeType)
         
         if is1DBarcode {
             // For 1D barcodes, we create a resized image with appropriate aspect ratio
             let size = CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height) * 0.5)
             UIGraphicsBeginImageContextWithOptions(size, false, 0)
             UIImage(cgImage: cgImage).draw(in: CGRect(origin: .zero, size: size))
             let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
             UIGraphicsEndImageContext()
             return resizedImage
         }
        return UIImage(cgImage: cgImage)
    }
}
