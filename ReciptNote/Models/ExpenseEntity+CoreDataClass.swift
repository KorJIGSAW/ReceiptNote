//
//  ExpenseEntity+CoreDataClass.swift
//  ReceiptNote
//
//  Models 폴더에 추가

import Foundation
import CoreData

@objc(ExpenseEntity)
public class ExpenseEntity: NSManagedObject {
    
}

extension ExpenseEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ExpenseEntity> {
        return NSFetchRequest<ExpenseEntity>(entityName: "ExpenseEntity")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var date: Date?
    @NSManaged public var amount: Double
    @NSManaged public var memo: String?
    @NSManaged public var category: String?
    @NSManaged public var receiptImageData: Data?
    @NSManaged public var ocrText: String?
}

extension ExpenseEntity : Identifiable {

}
