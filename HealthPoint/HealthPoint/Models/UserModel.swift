//
//  UserModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//

import SwiftData
import Foundation

@Model
class User {
    @Attribute(.unique) var id: UUID

    private var name: String
    private var birthDate: Date
    private var gender: String
    
    // Stored arrays managed by SwiftData. Use defaults to avoid KVC accessor errors.
    @Relationship(inverse: \Ingredient.user)
    var publicIngredientAllergies: [Ingredient] = []
    
    @Relationship(inverse: \Medicine.user)
    var publicUnwantedMedicine: [Medicine] = []
    
    
    var medicalCondition: [String] = []
    
    init(id: UUID = UUID(), name: String = "placeholder", birthDate: Date = Date(), gender: String = "N", ingredientAllergies: [Ingredient] = [], unwantedMedicine: [Medicine] = [], medicalCondition: [String] = []) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.publicIngredientAllergies = ingredientAllergies
        self.publicUnwantedMedicine = unwantedMedicine
        self.medicalCondition = medicalCondition
    }
}

