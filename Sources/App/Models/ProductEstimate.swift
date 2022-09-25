//
//  ProductEstimate.swift
//  
//
//  Created by Kevin Bertrand on 25/08/2022.
//

import Fluent
import Vapor

final class ProductEstimate: Model, Content {
    // Name of the table
    static let schema: String = "product_estimate"
    
    // Unique identifier
    @ID(key: .id)
    var id: UUID?
    
    // Fields
    @Field(key: "quantity")
    var quantity: Double
    
    @Field(key: "reduction")
    var reduction: Double
    
    @Parent(key: "product_id")
    var product: Product
    
    @Parent(key: "estimate_id")
    var estimate: Estimate
    
    // Initialization functions
    init() {}
    
    init(id: UUID? = nil, quantity: Double, reduction: Double = 0.0, productID: UUID, estimateID: UUID) throws {
        self.id = id
        self.quantity = quantity
        self.reduction = reduction
        self.$product.id = productID
        self.$estimate.id = estimateID
    }
}
