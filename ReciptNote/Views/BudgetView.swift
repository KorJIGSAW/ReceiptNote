//
//  BudgetView.swift
//  ReceiptNote
//
//  Views 폴더에 추가

import SwiftUI

struct BudgetView: View {
    @Binding var budget: Budget
    let expenses: [Expense]
    @State private var showingBudgetSetting = false
    
    var currentMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1) ?? now
        
        return expenses.filter { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
    }
    
    var totalSpent: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    var remainingBudget: Double {
        budget.monthlyBudget - totalSpent
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 이번 달 예산 현황
                    monthlyBudgetCard
                    
                    // 카테고리별 예산 현황
                    categoryBudgetSection
                    
                    // 예산 초과 알림
                    if budget.isOverBudget(for: expenses) {
                        budgetAlertCard
                    }
                }
                .padding()
            }
            .navigationTitle("예산 관리")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("설정") {
                        showingBudgetSetting = true
                    }
                }
            }
            .sheet(isPresented: $showingBudgetSetting) {
                BudgetSettingView(budget: $budget)
            }
        }
    }
    
    private var monthlyBudgetCard: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading) {
                    Text("이번 달 예산")
                        .font(.headline)
                    Text(formatCurrency(budget.monthlyBudget))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("사용한 금액")
                        .font(.headline)
                    Text(formatCurrency(totalSpent))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(totalSpent > budget.monthlyBudget ? .red : .primary)
                }
            }
            
            // 진행률 바
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("진행률")
                    Spacer()
                    Text("\(Int(budget.usagePercentage(for: expenses)))%")
                        .fontWeight(.bold)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(budget.isOverBudget(for: expenses) ? Color.red : Color.blue)
                            .frame(width: min(CGFloat(budget.usagePercentage(for: expenses) / 100) * geometry.size.width, geometry.size.width), height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(height: 8)
            }
            
            // 남은 예산
            HStack {
                Text("남은 예산:")
                    .font(.subheadline)
                Spacer()
                Text(formatCurrency(remainingBudget))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(remainingBudget < 0 ? .red : .green)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    private var categoryBudgetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("카테고리별 예산")
                .font(.headline)
            
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                let usage = budget.categoryUsage(for: category, expenses: expenses)
                
                if usage.budget > 0 {
                    CategoryBudgetRow(
                        category: category,
                        spent: usage.spent,
                        budget: usage.budget,
                        percentage: usage.percentage
                    )
                }
            }
        }
    }
    
    private var budgetAlertCard: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading) {
                Text("예산 초과!")
                    .font(.headline)
                    .foregroundColor(.red)
                Text("이번 달 예산을 \(formatCurrency(totalSpent - budget.monthlyBudget)) 초과했습니다.")
                    .font(.subheadline)
            }
            
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₩"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₩0"
    }
}

// 카테고리별 예산 행
struct CategoryBudgetRow: View {
    let category: ExpenseCategory
    let spent: Double
    let budget: Double
    let percentage: Double
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                Text(category.rawValue)
                    .font(.subheadline)
                Spacer()
                Text("\(formatCurrency(spent)) / \(formatCurrency(budget))")
                    .font(.caption)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 6)
                        .cornerRadius(3)
                    
                    Rectangle()
                        .fill(percentage > 100 ? Color.red : category.color)
                        .frame(width: min(CGFloat(percentage / 100) * geometry.size.width, geometry.size.width), height: 6)
                        .cornerRadius(3)
                }
            }
            .frame(height: 6)
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₩"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₩0"
    }
}

// 예산 설정 뷰
struct BudgetSettingView: View {
    @Binding var budget: Budget
    @Environment(\.presentationMode) var presentationMode
    
    @State private var monthlyBudgetText: String
    @State private var categoryBudgets: [ExpenseCategory: String] = [:]
    
    init(budget: Binding<Budget>) {
        self._budget = budget
        self._monthlyBudgetText = State(initialValue: String(Int(budget.wrappedValue.monthlyBudget)))
        
        var tempCategoryBudgets: [ExpenseCategory: String] = [:]
        for category in ExpenseCategory.allCases {
            tempCategoryBudgets[category] = String(Int(budget.wrappedValue.categoryBudgets[category] ?? 0))
        }
        self._categoryBudgets = State(initialValue: tempCategoryBudgets)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("월 예산")) {
                    HStack {
                        Text("총 예산")
                        TextField("금액 입력", text: $monthlyBudgetText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("카테고리별 예산")) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        HStack {
                            Image(systemName: category.icon)
                                .foregroundColor(category.color)
                            Text(category.rawValue)
                            TextField("금액", text: Binding(
                                get: { categoryBudgets[category] ?? "0" },
                                set: { categoryBudgets[category] = $0 }
                            ))
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                        }
                    }
                }
            }
            .navigationTitle("예산 설정")
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("저장") {
                    saveBudget()
                }
            )
        }
    }
    
    private func saveBudget() {
        if let monthlyAmount = Double(monthlyBudgetText) {
            budget.monthlyBudget = monthlyAmount
        }
        
        for category in ExpenseCategory.allCases {
            if let amount = Double(categoryBudgets[category] ?? "0"), amount > 0 {
                budget.categoryBudgets[category] = amount
            }
        }
        
        presentationMode.wrappedValue.dismiss()
    }
}

#Preview {
    BudgetView(budget: .constant(Budget()), expenses: Expense.sampleData)
}
