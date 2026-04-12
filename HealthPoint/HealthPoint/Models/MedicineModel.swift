//
//  MedicineModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//

import SwiftData
import Foundation

// SwiftData model for a medicine entry (adjust fields to match your schema)
@Model
final class Medicine: Identifiable {
    @Attribute(.unique) var id: UUID
    private var name: String
    private var descriptionText: String
    
    @Relationship var ingredients: [Ingredient]
    @Relationship var adverseEffects: [AdverseEffect]
    
    //Used to link to a user if listed in allergy list
    //A single medicine can be linked to multiple users
    @Relationship var user: [User] = []

    init(id: UUID = UUID(), name: String, descriptionText: String = "", ingredients: [Ingredient] = [], adverseEffects: [AdverseEffect] = []) {
        self.id = id
        self.name = name
        self.descriptionText = descriptionText
        self.ingredients = ingredients
        self.adverseEffects = adverseEffects
    }
    
    func getName() -> String {
        return name
    }
    
    func getDescriptionText() -> String {
        return descriptionText
    }
}
