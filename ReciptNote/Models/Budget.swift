//
//  Budget.swift
//  ReceiptNote
//
//  Models 폴더에 추가

import Foundation
import SwiftUI

// 예산 모델
struct Budget: Codable, Equatable {  // 🔥 Equatable 추가
    var monthlyBudget: Double
    var categoryBudgets: [ExpenseCategory: Double]
    
    init() {
        self.monthlyBudget = 500000 // 기본 50만원
        self.categoryBudgets = [:]
    }
    
    // 현재 월의 예산 사용률 계산
    func usagePercentage(for expenses: [Expense]) -> Double {
        let currentMonthExpenses = getCurrentMonthExpenses(from: expenses)
        let totalSpent = currentMonthExpenses.reduce(0) { $0 + $1.amount }
        return monthlyBudget > 0 ? (totalSpent / monthlyBudget) * 100 : 0
    }
    
    // 카테고리별 예산 사용률
    func categoryUsage(for category: ExpenseCategory, expenses: [Expense]) -> (spent: Double, budget: Double, percentage: Double) {
        let currentMonthExpenses = getCurrentMonthExpenses(from: expenses)
        let categoryExpenses = currentMonthExpenses.filter { $0.category == category }
        let spent = categoryExpenses.reduce(0) { $0 + $1.amount }
        let budget = categoryBudgets[category] ?? 0
        let percentage = budget > 0 ? (spent / budget) * 100 : 0
        
        return (spent: spent, budget: budget, percentage: percentage)
    }
    
    // 예산 초과 여부
    func isOverBudget(for expenses: [Expense]) -> Bool {
        return usagePercentage(for: expenses) > 100
    }
    
    // 현재 월 지출만 필터링
    private func getCurrentMonthExpenses(from expenses: [Expense]) -> [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1) ?? now
        
        return expenses.filter { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
    }
}
