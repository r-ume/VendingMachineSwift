import UIKit
import Foundation

// protocols

protocol VendingMachineType{
    // 自動販売機の商品の種類の配列
    var selection: [VendingSelection] {get}
    
    // 自動販売機の商品の倉庫（二重配列）
    var inventory: [VendingSelection: ItemType]{ get set }
    
    // 元々入っている金
    var amountDeposited: Double { get set }
    
    // 倉庫の初期化
    init (inventory: [VendingSelection: ItemType])
    
    // 自動販売機から商品を出す
    func vend(_ selection: VendingSelection, quantity: Double) throws
    
    // お金
    func deposit(_ amount: Double)
    
    //　今選択しているもの
    func itemForCurrentSelection(_ selection: VendingSelection) -> ItemType?
}

//　商品の詳細
protocol ItemType{
    var price: Double {get}
    var quantity: Double {get set}
}

// Error Types
enum InventoryError: Error{
    case invalidResource
    case conversionError
    case invalidKey
}

enum VendingMachineError: Error{
    case invalidSelection
    case outOfStock
    case insufficientFunds(required: Double)
}

//Helper Classes
// plistにアクセスするためのメソッド
class PlistConverter{
    class func dictionaryFromFile(_ resource: String, ofType type: String) throws
        -> [String: AnyObject]{
            
        //　商品のpathを選択する
        guard let path = Bundle.main.path(forResource: resource, ofType: type) else {
            // 該当する商品がないとき
            throw InventoryError.invalidResource
        }
         
        // 商品
        guard let dictionary = NSDictionary(contentsOfFile: path),
            // as? downcastingが成功するかわからないときは?を使う
            let castDictionary = dictionary as? [String: AnyObject] else{
            throw InventoryError.conversionError
        }
            
        return castDictionary
    }
}

class InventoryUnarchiver{
    class func vendingInventoryFromDictionary(_ dictionary: [String: AnyObject]) throws -> [VendingSelection: ItemType]{
            
            var inventory: [VendingSelection: ItemType] = [:]
            
            for (key, value) in dictionary{
                if let itemDict = value as? [String: Double],
                    let price = itemDict["price"], let quantity = itemDict["quantity"]{
                    
                        let item = VendingItem(price: price, quantity: quantity)
                        
                        guard let key = VendingSelection(rawValue: key) else {
                            throw InventoryError.invalidKey
                        }
                        
                        inventory.updateValue(item, forKey: key)
                }
                
            }
        
        return inventory
    }
}


// Concrete Type

enum VendingSelection: String {
    case Soda
    case DietSoda
    case Chips
    case Cookie
    case Sandwich
    case Wrap
    case CandyBar
    case PopTart
    case Water
    case FruitJuice
    case SportsDrink
    case Gum
    
    //　該当するアイコンを返すメソッド
    func icon() -> UIImage{
        // rawValueはString型として返す
        if let image = UIImage(named: self.rawValue){
            return image
        } else{
            return UIImage(named: "Default")!
        }
    }
}

struct VendingItem: ItemType {
    let price: Double
    var quantity: Double
}


//　自動販売機クラス
class VendingMachine: VendingMachineType{
    var selection: [VendingSelection] = [.Soda, .DietSoda, .Chips, .Cookie, .Sandwich, .Wrap, .CandyBar, .PopTart, .Water, .FruitJuice, .SportsDrink, .Gum]

    var inventory: [VendingSelection: ItemType]
    var amountDeposited: Double = 10.0
    
    required init(inventory: [VendingSelection: ItemType]){
        self.inventory = inventory
    }
    
    // 自動販売機から商品を取り出す
    func vend(_ selection: VendingSelection, quantity: Double) throws {
        // guard文 - elseの後に条件が満たされなかったときに使う
        // VendingSelectionの中から商品を選択
        guard var item = inventory[selection] else{
            //ViewController.swiftでこのvendメソッドを使う時に, VendingMachineError.InvalidSelectionがcatchされる
            throw VendingMachineError.invalidSelection
        }
        
        // 商品の数が0以下だった場合、VendingMachineError.OutOfStockがthrowされ、catchされる
        guard item.quantity > 0 else {
            throw VendingMachineError.outOfStock
        }
        
        // 引数のquantityが引かれる
        item.quantity -= quantity
        
        inventory.updateValue(item, forKey: selection)
        
        let totalPrice = item.price * quantity
        
        //もともとあったお金が払うお金より少ない場合は、もともとあったお金-払うお金になる
        if amountDeposited >= totalPrice{
            amountDeposited -= totalPrice
        } else {
            //　もともとあったがお金が払うお金より多い場合は、あと何円必要なのかを変数amountRequiredに代入する。
            let amountRequired = totalPrice - amountDeposited
            //　そして、エラーを投げる
            throw VendingMachineError.insufficientFunds(required: amountRequired)
        }
    }
    
    
    func itemForCurrentSelection(_ selection: VendingSelection) -> ItemType?{
        return inventory[selection]
    }
    
    func deposit(_ amount: Double) {
        amountDeposited += amount
    }
}


















