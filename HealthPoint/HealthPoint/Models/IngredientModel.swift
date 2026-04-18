//
//  IngredientModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//

import SwiftData
import Foundation

/// Stores an ingredient entry and its relationships to medicines and user allergy lists.
@Model
class Ingredient: Identifiable {
    @Attribute(.unique) var id: Int
    
    private var name: String
    var normalizedName: String
    
    /// Stores related medicine, and updates corresponding medicine register
    @Relationship(inverse: \Medicine.ingredients)
    var medicines: [Medicine]
    
    /// Used to link to a user if listed in allergy list
    /// A single ingredient can be linked to multiple users
    var user: [User]
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.normalizedName = name.lowercased()
        self.medicines = []
        self.medicines = []
        self.user = []
    }
    
    /// Returns the display name shown in medicine details and user preferences.
    func getName() -> String {
        return name
    }
}
