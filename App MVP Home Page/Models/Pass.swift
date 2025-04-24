//
//  Pass.swift
//  App MVP Home Page
//
//  Created by Sam Quested on 02/04/2025.
//

import Foundation
import CoreImage.CIFilterBuiltins

struct Pass: Identifiable, Codable {
    var id: UUID
    let mainInformation: MainInformation
    let barcodeData: BarcodeData
    let isPrimary: Bool
    
    var isValid: Bool {
        mainInformation.isValid && barcodeData.isValid
    }
    
    init(mainInformation: MainInformation, barcodeData:BarcodeData, isPrimary: Bool = false) {
        self.id = UUID()
        self.mainInformation = mainInformation
        self.barcodeData = barcodeData
        self.isPrimary = isPrimary
    }
}

struct MainInformation: Codable {
    let title: String
    let date: Date
    
    init(title: String, date: Date) {
        self.title = title
        self.date = date
    }
    
    var isValid: Bool {
        !title.isEmpty
    }
}

struct BarcodeData: Codable {
    let code: String
    let codeType: String
    
    init(code: String, codeType: String) {
        self.code = code
        self.codeType = codeType
    }
    
    var isValid: Bool {
        !code.isEmpty && !codeType.isEmpty
    }
}


extension Pass: DeletableItem {
    var deletionMessage: String {
        isPrimary ? "This is your primary pass. Are you sure you want to delete it?" : "Are you sure you want to delete this pass?"
    }
    var requiresConfirmation: Bool {
        true
    }
}

