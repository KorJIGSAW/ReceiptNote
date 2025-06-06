//
//  MainView.swift
//  ReceiptNote
//

import SwiftUI

struct MainView: View {
    @StateObject private var expenseStore = ExpenseStore()
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var showingEditExpense = false
    @State private var selectedTab = 0
    @State private var budget = Budget()
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // 홈 탭 - 지출 내역
            homeView
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("홈")
                }
                .tag(0)
            
            // 검색 탭
            SearchView(expenses: $expenseStore.expenses)
                .tabItem {
                    Image(systemName: "magnifyingglass")
                    Text("검색")
                }
                .tag(1)
            
            // 통계 탭
            StatisticsView(expenses: expenseStore.expenses)
                .tabItem {
                    Image(systemName: "chart.bar")
                    Text("통계")
                }
                .tag(2)
            
            // 예산 탭
            BudgetView(budget: $budget, expenses: expenseStore.expenses)
                .tabItem {
                    Image(systemName: "dollarsign.circle")
                    Text("예산")
                }
                .tag(3)
        }
        .onAppear {
            loadBudget()
        }
        .onChange(of: budget) { _ in
            saveBudget()
        }
    }
    
    private var homeView: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 예산 미리보기 카드
                BudgetPreviewCard(budget: budget, expenses: expenseStore.expenses)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // 지출 내역 리스트
                List {
                    ForEach(expenseStore.expenses.sorted(by: { $0.date > $1.date })) { expense in
                        ExpenseRowView(expense: expense)
                            .onTapGesture {
                                selectedExpense = expense
                                showingEditExpense = true
                            }
                    }
                    .onDelete(perform: deleteExpenses)
                }
                .listStyle(PlainListStyle())
                
                // 지출 추가 버튼
                Button(action: {
                    showingAddExpense = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("지출 추가")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            }
            .navigationTitle("ReceiptNote")
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView { newExpense in
                    expenseStore.addExpense(newExpense)
                }
            }
            .sheet(isPresented: $showingEditExpense) {
                if let expense = selectedExpense {
                    EditExpenseView(
                        expense: expense,
                        onSave: { updatedExpense in
                            expenseStore.updateExpense(updatedExpense)
                        },
                        onDelete: {
                            expenseStore.deleteExpense(expense)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Functions
    
    func deleteExpenses(offsets: IndexSet) {
        let sortedExpenses = expenseStore.expenses.sorted(by: { $0.date > $1.date })
        for index in offsets {
            let expenseToDelete = sortedExpenses[index]
            expenseStore.deleteExpense(expenseToDelete)
        }
    }
    
    private func loadBudget() {
        guard let data = UserDefaults.standard.data(forKey: "UserBudget") else { return }
        
        do {
            budget = try JSONDecoder().decode(Budget.self, from: data)
        } catch {
            print("예산 로딩 실패: \(error)")
        }
    }
    
    private func saveBudget() {
        do {
            let data = try JSONEncoder().encode(budget)
            UserDefaults.standard.set(data, forKey: "UserBudget")
        } catch {
            print("예산 저장 실패: \(error)")
        }
    }
}

// MARK: - 예산 미리보기 카드

struct BudgetPreviewCard: View {
    let budget: Budget
    let expenses: [Expense]
    
    var body: some View {
        let usagePercentage = budget.usagePercentage(for: expenses)
        let isOverBudget = budget.isOverBudget(for: expenses)
        let totalSpent = getCurrentMonthTotal()
        let remainingBudget = budget.monthlyBudget - totalSpent
        
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("이번 달 예산")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("\(Int(usagePercentage))% 사용됨")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(isOverBudget ? .red : .primary)
                }
                
                Spacer()
                
                // 원형 진행률
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 60, height: 60)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat(min(usagePercentage / 100, 1.0)))
                        .stroke(
                            isOverBudget ? Color.red : Color.blue,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .frame(width: 60, height: 60)
                        .rotationEffect(Angle(degrees: -90))
                        .animation(.easeInOut(duration: 0.5), value: usagePercentage)
                    
                    if isOverBudget {
                        Image(systemName: "exclamationmark")
                            .font(.caption)
                            .foregroundColor(.red)
                            .fontWeight(.bold)
                    }
                }
            }
            
            // 금액 정보
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("사용")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(totalSpent))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 2) {
                    Text("예산")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(budget.monthlyBudget))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("남은")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(formatCurrency(remainingBudget))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(remainingBudget < 0 ? .red : .green)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
        )
    }
    
    private func getCurrentMonthTotal() -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)?.addingTimeInterval(-1) ?? now
        
        return expenses.filter { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }.reduce(0) { $0 + $1.amount }
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₩"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₩0"
    }
}

// MARK: - 지출 항목 행 뷰

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            // 카테고리 아이콘
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(expense.category.color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: expense.category.icon)
                    .font(.title2)
                    .foregroundColor(expense.category.color)
            }
            
            // 지출 정보
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.memo)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text(expense.formattedAmount)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                HStack {
                    Text(expense.formattedDate)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(expense.category.color.opacity(0.2))
                        .foregroundColor(expense.category.color)
                        .cornerRadius(8)
                }
                
                if let ocrText = expense.ocrText {
                    Text(ocrText)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, 8)
        .background(Color.clear)
    }
}

// MARK: - Preview

#Preview {
    MainView()
}
