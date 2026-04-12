//
//  AdverseEffectModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//
import SwiftData
import Foundation

@Model
class AdverseEffect: Identifiable {
    @Attribute(.unique) var id: Int
    
    private var name: String
    
    private var meddraTermType: String
    
    @Relationship(inverse: \Medicine.adverseEffects)
    var medicines: [Medicine]
    
    init(id: Int, name: String, meddraTermType: String, medicines: [Medicine] = []) {
        self.id = id
        self.name = name
        self.meddraTermType = meddraTermType
        self.medicines = medicines
    }
    
    func getName() -> String {
        return name
    }
    
    func getMeddraTermType() -> String {
        return meddraTermType
    }
}
