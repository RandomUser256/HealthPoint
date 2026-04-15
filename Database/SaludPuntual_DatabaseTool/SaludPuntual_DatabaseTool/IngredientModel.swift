//
//  IngredientModel.swift
//  HealthPoint
//
//  Created by Máximo on 4/11/26.
//

import SwiftData
import Foundation

@Model
class Ingredient: Identifiable {
    @Attribute(.unique) var id: Int
    
    private var name: String
    var normalizedName: String
    
    //Stores related medicine, and updates corresponding medicine register
    @Relationship(inverse: \Medicine.ingredients)
    var medicines: [Medicine]
    
    //Used to link to a user if listed in allergy list
    //A single ingredient can be linked to multiple users
    var user: [User] = []
    
    init(id: Int, name: String) {
        self.id = id
        self.name = name
        self.normalizedName = name.lowercased()
        self.medicines = []
    }
    
    func getName() -> String {
        return name
    }
}
