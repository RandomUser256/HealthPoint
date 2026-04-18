//
//  AdverseEffectModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//
import SwiftData
import Foundation

/// Stores an adverse effect entry and its relationships to the medicines that may cause it.
@Model
class AdverseEffect: Identifiable {
    @Attribute(.unique) var id: Int
    
    private var name: String
    var normalizedName: String
    
    private var meddraTermType: String
    
    /// Stores related medicine, and updates corresponding medicine register
    @Relationship(inverse: \Medicine.adverseEffects)
    var medicines: [Medicine]
    
    init(id: Int, name: String, meddraTermType: String, medicines: [Medicine] = []) {
        self.id = id
        self.name = name
        self.normalizedName = name.lowercased()
        self.meddraTermType = meddraTermType
        self.medicines = medicines
    }
    
    /// Returns the display name used throughout the UI.
    func getName() -> String {
        return name
    }
    
    /// Returns the MedDRA classification type associated with this adverse effect.
    func getMeddraTermType() -> String {
        return meddraTermType
    }
}
