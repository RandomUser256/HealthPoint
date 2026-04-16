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
    @Attribute(.unique) var id: Int

    var name: String
    var apellidos: String
    var birthDate: Date
    var gender: String
    
    // Stored arrays managed by SwiftData. Use defaults to avoid KVC accessor errors.
    @Relationship(inverse: \Ingredient.user)
    var publicIngredientAllergies: [Ingredient] = []
    
    //Array of unwanted/blackliste medicine by user for whatever reason
    @Relationship(inverse: \Medicine.user)
    var publicUnwantedMedicine: [Medicine] = []
    
    //String to sotre medical conditions, in support is added later
    var medicalCondition: [String] = []
    
    init(id: Int, name: String, birthDate: Date = Date(), gender: String = "N", apellidos: String, ingredientAllergies: [Ingredient] = [], unwantedMedicine: [Medicine] = [], medicalCondition: [String] = []) {
        self.id = id
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.apellidos = apellidos
        self.publicIngredientAllergies = ingredientAllergies
        self.publicUnwantedMedicine = unwantedMedicine
        self.medicalCondition = medicalCondition
    }
    
    init() {
        self.id = -1
        self.name = "placeholder"
        self.birthDate = Date()
        self.gender = "N"
        self.publicIngredientAllergies = []
        self.publicUnwantedMedicine = []
        self.medicalCondition = []
        self.apellidos = "placeholder"
    }
}

