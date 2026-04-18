//
//  UserModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//

import SwiftData
import Foundation

/// Persists profile information and medication-related preferences for an app user.
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
    
    /// Array of unwanted/blackliste medicine by user for whatever reason
    @Relationship(inverse: \Medicine.user)
    var publicUnwantedMedicine: [Medicine] = []
    
    /// String to sotre medical conditions, in support is added later
    var medicalCondition: [String] = []
    
    private func userCount() {
        
    }
    
    /// Creates a fully configured user record with optional allergies, avoided medicines, and conditions.
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
    
    /// Creates a placeholder profile used when starting a new user flow.
    init() {
        self.id = Int.random(in: 1...1000)
        self.name = "New User"
        self.birthDate = Date()
        self.gender = "N"
        self.publicIngredientAllergies = []
        self.publicUnwantedMedicine = []
        self.medicalCondition = []
        self.apellidos = "New User"
    }
    
    /// Returns the user's first-name field for display in the UI.
    func getName() -> String {
        return name
    }
    
    /// Returns the user's last-name field.
    func getApellidos() -> String {
        return apellidos
    }
}
