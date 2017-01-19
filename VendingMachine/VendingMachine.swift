//
//  VendingMachine.swift
//  VendingMachine
//
//  Created by Screencast on 12/6/16.
//  Copyright © 2016 Treehouse Island, Inc. All rights reserved.
//

import Foundation
import UIKit

enum VendingSelection: String {
    case soda
    case dietSoda
    case chips
    case cookie
    case sandwich
    case wrap
    case candyBar
    case popTart
    case water
    case fruitJuice
    case sportsDrink
    case gum
    
    func icon() -> UIImage {
        if let image = UIImage(named: self.rawValue) {
            return image
        } else {
            return #imageLiteral(resourceName: "default")
        }
    }
}

protocol VendingItem {
    var price: Double { get }
    var quantity: Int { get set }
}

protocol VendingMachine {
    var selection: [VendingSelection] { get }
    var inventory: [VendingSelection: VendingItem] { get set }
    var amountDeposited: Double { get set }
    
    init(inventory: [VendingSelection: VendingItem])
    func vend(selection: VendingSelection, quantity:Int) throws
    func deposit(_ amount: Double)
    func item(forSelection selection: VendingSelection) -> VendingItem?
}

struct Item: VendingItem {
    let price: Double
    var quantity: Int
}

//handling errors
enum InventroyError: Error {
    case invalidResource
    case convertionFailure
    case invalidSelection
    case missSpelledKey
}

//type method

//convert a nsdictionary in to a swift dictionary
class PlistConverter {
    
    static func dictionary(fromFile name: String, ofType type: String) throws -> [String: AnyObject] {
        
        //checking if the path exists
        guard let path = Bundle.main.path(forResource: name, ofType: type) else {
            throw InventroyError.invalidResource
        }
        //downcasting casting a nsdictionary
        guard let dictionary = NSDictionary(contentsOfFile: path) as? [String: AnyObject] else {
            throw InventroyError.convertionFailure
        }
        return dictionary
    }
}

class InventoryUnarchiver {
    
    static func vendingInventory(fromDictionary dictionary: [String: AnyObject]) throws -> [VendingSelection: VendingItem] {
        
        //initalizing the dictionary reuqired my the model
        var inventory: [VendingSelection: VendingItem] = [:]
        
        //here the dictionary is the root dictionary of the plist that contains 12 dictionaries
        for (key,value) in dictionary {
            //here the value is a nested dictionary, next we are optional binding it with comas adding more constants
            if let itemDictionary = value as? [String: Any], let price = itemDictionary["price"] as? Double, let quantity = itemDictionary["quantity"] as? Int {
                let item = Item(price: price, quantity: quantity)
                
                //convert the item in a vendinsgelection using the raw value of the enum VendingSelection
                guard let selection = VendingSelection(rawValue: key) else {
                    throw InventroyError.invalidSelection
                }
            inventory.updateValue(item, forKey: selection)
            } else {
                throw InventroyError.missSpelledKey
            }
        }
        return inventory
    }
}
//////////type methods finish

enum VendingMachineError: Error {
    case invalidSelection
    case outOfStock
    case insufficientFunds(required: Double) //associated value
}

class FoodVendingMachine: VendingMachine {
    let selection: [VendingSelection] = [.soda, .dietSoda, .chips, .cookie, .wrap, .sandwich, .candyBar, .popTart, .water, .fruitJuice, .sportsDrink, .gum]
    var inventory: [VendingSelection : VendingItem]
    var amountDeposited: Double = 10.0
    
    required init(inventory: [VendingSelection : VendingItem]) {
        self.inventory = inventory
    }
    
    func vend(selection: VendingSelection, quantity: Int) throws {
        
        //selection here is a vendingselection case  and is used as a key checking for the key vendingselection of the inventory dictionary
        guard var item = self.inventory[selection] else {
            throw VendingMachineError.invalidSelection
        }
        
        //now that we have the item lets check for the quantity this can be vendingselection = gum for example
        guard item.quantity >= quantity else {
            throw VendingMachineError.outOfStock
        }
        
        //final price
        let totalPrice = item.price *  Double(quantity)
        
        //checking if the amount gived by the user is enogugh than the min required
        if self.amountDeposited >= totalPrice {
            self.amountDeposited -= totalPrice
            item.quantity -= quantity
            inventory.updateValue(item, forKey: selection)
            //this item contains a price and quantity
        } else {
            let amountRequired = totalPrice - self.amountDeposited
            throw VendingMachineError.insufficientFunds(required: amountRequired)
        }
    }
    
    func deposit(_ amount: Double) {
    }
    
    func item(forSelection selection: VendingSelection) -> VendingItem? {
        //here selection is a key like gum
        return self.inventory[selection]
    }

}










































