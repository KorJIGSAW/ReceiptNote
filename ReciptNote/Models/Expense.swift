//
//  Expense.swift
//  ReceiptNote
//

import Foundation
import SwiftUI

// 지출 데이터 모델
struct Expense: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var amount: Double
    var memo: String
    var receiptImageData: Data?
    var ocrText: String?
    
    // 날짜를 문자열로 포맷하는 computed property
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: date)
    }
    
    // 금액을 원화로 포맷하는 computed property
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₩"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₩0"
    }
}

// 샘플 데이터 (테스트용)
extension Expense {
    static let sampleData: [Expense] = [
        Expense(
            date: Date(),
            amount: 7500,
            memo: "과자/우유",
            receiptImageData: nil,
            ocrText: "CU편의점 2025.05.21 총액: 7,500원"
        ),
        Expense(
            date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            amount: 15000,
            memo: "식료품/채소",
            receiptImageData: nil,
            ocrText: nil
        )
    ]
}
