//
//  ViewController.swift
//  VendingMachine
//
//  Created by Pasan Premaratne on 12/1/16.
//  Copyright © 2016 Treehouse Island, Inc. All rights reserved.
//

import UIKit

fileprivate let reuseIdentifier = "vendingItem"
fileprivate let screenWidth = UIScreen.main.bounds.width

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var totalLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var quantityLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var stepper: UIStepper!
    
    
    let vendingMachine: VendingMachine
    var curretSelection: VendingSelection?
    
    //initializing the vendingMachine property inthe decoder method
    required init?(coder aDecoder: NSCoder) {
        do {
            //returns nsdictionary
            let dictionary = try PlistConverter.dictionary(fromFile: "VendingInventory", ofType: "plist")
            //downcast to dictionary
            let inventory = try InventoryUnarchiver.vendingInventory(fromDictionary: dictionary)
            self.vendingMachine = FoodVendingMachine(inventory: inventory)
        } catch let error {
            fatalError("\(error)")
        }
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
       // print(vendingMachine.inventory)
        self.setupCollectionViewCells()
        self.updateDisplayWith(balance: self.vendingMachine.amountDeposited, totalPrice: 0, itemPrice: 0, itemQuantity: 1)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Setup

    func setupCollectionViewCells() {
        
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        
        let padding: CGFloat = 10
        let itemWidth = screenWidth/3 - padding
        let itemHeight = screenWidth/3 - padding
        
        layout.itemSize = CGSize(width: itemWidth, height: itemHeight)
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        
        collectionView.collectionViewLayout = layout
    }
    
    // MARK: - Vending Machine
    
    @IBAction func purchase(_ sender: UIButton) {
        if let currentSelection = self.curretSelection {
            
            do {
                try self.vendingMachine.vend(selection: currentSelection , quantity: Int(self.stepper.value))
                self.updateDisplayWith(balance: self.vendingMachine.amountDeposited, totalPrice: 0.0, itemPrice: 0, itemQuantity: 1)
            } catch VendingMachineError.outOfStock {
                self.showAlertWith(title: "out of stock", message: "this item is unavailable")
                
            } catch VendingMachineError.invalidSelection {
                self.showAlertWith(title: "Invalid selection", message: "please make another selection")
                
                //the required comes from the helper method in the model and its like a "success response"
            } catch VendingMachineError.insufficientFunds(let required) {
                let message = "you need $\(required) to complete transaction"
                self.showAlertWith(title: "insufficient Funds", message: message)
                
            }  catch let error {
                fatalError("\(error)")
            }
            
            if let indexPath = collectionView.indexPathsForSelectedItems?.first {
                collectionView.deselectItem(at: indexPath, animated: true)
                updateCell(having: indexPath, selected: false)
            }
            
        } else {
            //FIXME:alert user
        }
    }
    
    func updateDisplayWith(balance: Double? = nil, totalPrice: Double? = nil, itemPrice: Double? = nil, itemQuantity: Int? = nil) {
        
        if let balanceValue = balance {
            self.balanceLabel.text = "$\(balanceValue)"
        }
        
        if let totalValue = totalPrice {
            self.totalLabel.text = "$\(totalValue)"
        }
        
        if let priceValue = itemPrice {
            self.priceLabel.text = "$\(priceValue)"
        }
        
        if let quantityValue = itemQuantity {
            self.quantityLabel.text = "\(quantityValue)"
        }
    }
    
    func updateTotalPrice(for item:VendingItem) {
      
        let totalPrice = item.price * self.stepper.value
        updateDisplayWith(totalPrice:totalPrice)
    }
    
    @IBAction func updateQuantity(_ sender: UIStepper) {
        
        let quantity = Int(self.stepper.value)
        self.updateDisplayWith(itemQuantity:quantity)
        
        if let currentSelection = self.curretSelection, let item = self.vendingMachine.item(forSelection: currentSelection) {
            updateTotalPrice(for: item)
        }
    }
    
    func showAlertWith(title: String, message: String, style: UIAlertControllerStyle = .alert) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        let action = UIAlertAction(title: "ok", style: .default, handler: self.dismsissAlert)
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
    
    //for the completion handler in the alert action
    func dismsissAlert(sender: UIAlertAction) -> Void {

        DispatchQueue.main.async {
            self.updateDisplayWith(balance: 0, totalPrice: 0, itemPrice: 0, itemQuantity: 1)
        }
    }
    
    
    @IBAction func depositFunds(_ sender: UIButton) {
        self.vendingMachine.deposit(5.0)
        self.updateDisplayWith(balance:self.vendingMachine.amountDeposited)
    }
    
    
    // MARK: UICollectionViewDataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return vendingMachine.selection.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? VendingItemCell else { fatalError() }
        let item = vendingMachine.selection[indexPath.row]
        cell.iconView.image = item.icon()
        return cell
    }
    
    // MARK: - UICollectionViewDelegate
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
        
        //updating the values "refreshing"
        self.stepper.value = 1
        self.updateDisplayWith(totalPrice: 0, itemQuantity: 1)
        self.curretSelection = self.vendingMachine.selection[indexPath.row]
        
        if let curretSelection = self.curretSelection, let item = self.vendingMachine.item(forSelection: curretSelection) {
            
            let totalPrice = item.price * self.stepper.value
            self.updateDisplayWith(totalPrice: totalPrice, itemPrice: item.price)
    
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        updateCell(having: indexPath, selected: false)
    }
    
    func updateCell(having indexPath: IndexPath, selected: Bool) {
        
        let selectedBackgroundColor = #colorLiteral(red: 1, green: 0.4932718873, blue: 0.4739984274, alpha: 1) //UIColor(red: 41/255.0, green: 211/255.0, blue: 241/255.0, alpha: 1.0)
        let defaultBackgroundColor = UIColor(red: 27/255.0, green: 32/255.0, blue: 36/255.0, alpha: 1.0)
        
        if let cell = collectionView.cellForItem(at: indexPath) {
            cell.contentView.backgroundColor = selected ? selectedBackgroundColor : defaultBackgroundColor
        }
    }
    
    
}

