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
    @Attribute(.unique) var id: Int
    
    private var name: String
    var normalizedName: String
    
    private var descriptionText: String
    
    /*
    var publicName: String {
        get { name }
        set {name = newValue}
    }
     */
    
    @Relationship var ingredients: [Ingredient]
    @Relationship var adverseEffects: [AdverseEffect]
    
    //Used to link to a user if listed in allergy list
    //A single medicine can be linked to multiple users
    @Relationship var user: [User] = []

    init(id: Int, name: String, descriptionText: String = "") {
        self.id = id
        self.name = name
        self.normalizedName = name.lowercased()
        self.descriptionText = descriptionText
        self.ingredients = []
        self.adverseEffects = []
    }
    
    func getName() -> String {
        return name
    }
    
    func getDescriptionText() -> String {
        return descriptionText
    }
}
