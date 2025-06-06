//
//  Expense.swift
//  ReceiptNote
//

import Foundation
import SwiftUI

// 지출 카테고리 열거형
enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "식비"
    case transportation = "교통비"
    case shopping = "생활용품"
    case medical = "의료비"
    case entertainment = "여가/오락"
    case education = "교육"
    case utility = "공과금"
    case other = "기타"
    
    // 카테고리 아이콘
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car.fill"
        case .shopping: return "bag.fill"
        case .medical: return "cross.case.fill"
        case .entertainment: return "gamecontroller.fill"
        case .education: return "book.fill"
        case .utility: return "bolt.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    // 카테고리 색상
    var color: Color {
        switch self {
        case .food: return .orange
        case .transportation: return .blue
        case .shopping: return .green
        case .medical: return .red
        case .entertainment: return .purple
        case .education: return .indigo
        case .utility: return .yellow
        case .other: return .gray
        }
    }
}

// 지출 데이터 모델
struct Expense: Identifiable, Codable {
    let id = UUID()
    var date: Date
    var amount: Double
    var memo: String
    var category: ExpenseCategory = .other
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
    static let sampleData: [Expense] = []  // 🔥 빈 배열로 변경
}
