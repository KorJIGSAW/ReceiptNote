//
//  ExpenseStore.swift
//  ReceiptNote
//
//  ViewModels 폴더에 추가

import Foundation
import CoreData
import SwiftUI

class ExpenseStore: ObservableObject {
    @Published var expenses: [Expense] = []
    
    private let container: NSPersistentContainer
    
    init() {
        print("🟡 ExpenseStore 초기화 시작...")
        
        // Core Data 모델 파일명 확인
        let modelName = "ReciptNote"  // 🔥 철자 수정: ReceiptNote → ReciptNote
        print("🟡 모델 이름: \(modelName)")
        
        container = NSPersistentContainer(name: modelName)
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("❌ Core Data 로딩 실패: \(error)")
                print("❌ 스토어 설명: \(storeDescription)")
            } else {
                print("✅ Core Data 로딩 성공!")
                print("✅ 스토어 위치: \(storeDescription.url?.absoluteString ?? "알 수 없음")")
            }
        }
        
        // Core Data 설정 확인
        checkCoreDataSetup()
        loadExpenses()
    }
    
    private func checkCoreDataSetup() {
        let context = container.viewContext
        
        // Entity 확인
        if let model = container.managedObjectModel.entitiesByName["ExpenseEntity"] {
            print("✅ ExpenseEntity 엔티티 발견")
            print("✅ 속성들: \(model.attributesByName.keys)")
        } else {
            print("❌ ExpenseEntity 엔티티를 찾을 수 없음!")
            print("❌ 사용 가능한 엔티티들: \(container.managedObjectModel.entitiesByName.keys)")
        }
    }
    
    // MARK: - 지출 추가
    func addExpense(_ expense: Expense) {
        print("🟡 지출 추가 시작: \(expense.memo)")
        
        let context = container.viewContext
        
        // ExpenseEntity 생성 시도
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "ExpenseEntity", in: context) else {
            print("❌ ExpenseEntity 엔티티 설명을 찾을 수 없음!")
            return
        }
        
        let expenseEntity = ExpenseEntity(entity: entityDescription, insertInto: context)
        
        expenseEntity.id = expense.id
        expenseEntity.date = expense.date
        expenseEntity.amount = expense.amount
        expenseEntity.memo = expense.memo
        expenseEntity.category = expense.category.rawValue
        expenseEntity.receiptImageData = expense.receiptImageData
        expenseEntity.ocrText = expense.ocrText
        
        print("🟡 ExpenseEntity 데이터 설정 완료")
        
        if saveContext() {
            print("✅ 지출 저장 성공: \(expense.memo) - \(expense.amount)원")
            loadExpenses()
        } else {
            print("❌ 지출 저장 실패: \(expense.memo)")
        }
    }
    
    // MARK: - 지출 수정
    func updateExpense(_ expense: Expense) {
        print("🟡 지출 수정 시작: \(expense.memo)")
        
        let context = container.viewContext
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", expense.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let expenseEntity = results.first {
                expenseEntity.date = expense.date
                expenseEntity.amount = expense.amount
                expenseEntity.memo = expense.memo
                expenseEntity.category = expense.category.rawValue
                expenseEntity.receiptImageData = expense.receiptImageData
                expenseEntity.ocrText = expense.ocrText
                
                if saveContext() {
                    print("✅ 지출 수정 성공: \(expense.memo)")
                    loadExpenses()
                }
            } else {
                print("❌ 수정할 지출을 찾을 수 없음: \(expense.id)")
            }
        } catch {
            print("❌ 지출 수정 실패: \(error)")
        }
    }
    
    // MARK: - 지출 삭제
    func deleteExpense(_ expense: Expense) {
        print("🟡 지출 삭제 시작: \(expense.memo)")
        
        let context = container.viewContext
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", expense.id as CVarArg)
        
        do {
            let results = try context.fetch(request)
            if let expenseEntity = results.first {
                context.delete(expenseEntity)
                if saveContext() {
                    print("✅ 지출 삭제 성공: \(expense.memo)")
                    loadExpenses()
                }
            } else {
                print("❌ 삭제할 지출을 찾을 수 없음: \(expense.id)")
            }
        } catch {
            print("❌ 지출 삭제 실패: \(error)")
        }
    }
    
    // MARK: - 데이터 로딩
    private func loadExpenses() {
        print("🟡 지출 데이터 로딩 시작...")
        
        let context = container.viewContext
        let request: NSFetchRequest<ExpenseEntity> = ExpenseEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \ExpenseEntity.date, ascending: false)]
        
        do {
            let expenseEntities = try context.fetch(request)
            print("🟡 Core Data에서 \(expenseEntities.count)개 엔티티 로드됨")
            
            expenses = expenseEntities.compactMap { entity in
                guard let id = entity.id,
                      let date = entity.date,
                      let memo = entity.memo,
                      let categoryString = entity.category,
                      let category = ExpenseCategory(rawValue: categoryString) else {
                    print("❌ 엔티티 변환 실패: \(entity)")
                    return nil
                }
                
                return Expense(
                    date: date,
                    amount: entity.amount,
                    memo: memo,
                    category: category,
                    receiptImageData: entity.receiptImageData,
                    ocrText: entity.ocrText
                )
            }
            
            print("✅ \(expenses.count)개 지출이 Expense 배열로 변환됨")
            
            // 샘플 데이터 자동 추가 제거 - 이제 완전히 빈 상태로 시작
            
        } catch {
            print("❌ 지출 로딩 실패: \(error)")
        }
    }
    
    // MARK: - Core Data 저장
    @discardableResult
    private func saveContext() -> Bool {
        let context = container.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
                print("💾 Core Data 저장 성공!")
                return true
            } catch {
                print("❌ Core Data 저장 실패: \(error)")
                return false
            }
        } else {
            print("🟡 저장할 변경사항 없음")
            return true
        }
    }
}

