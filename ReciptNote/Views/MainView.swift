//
//  MainView.swift
//  ReceiptNote
//

import SwiftUI

struct MainView: View {
    @State private var expenses: [Expense] = Expense.sampleData
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var showingEditExpense = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 지출 내역 리스트
                List {
                    ForEach(expenses.sorted(by: { $0.date > $1.date })) { expense in
                        ExpenseRowView(expense: expense)
                            .onTapGesture {
                                selectedExpense = expense
                                showingEditExpense = true
                            }
                    }
                    .onDelete(perform: deleteExpenses)
                }
                
                // 하단 버튼들
                VStack(spacing: 16) {
                    // 지출 추가 버튼
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("지출 추가")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    
                    // 통계 보기 버튼
                    NavigationLink(destination: StatisticsView(expenses: expenses)) {
                        HStack {
                            Image(systemName: "chart.bar")
                            Text("지출 통계")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            .navigationTitle("ReceiptNote")
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView { newExpense in
                    expenses.append(newExpense)
                }
            }
            .sheet(isPresented: $showingEditExpense) {
                if let expense = selectedExpense {
                    EditExpenseView(
                        expense: expense,
                        onSave: { updatedExpense in
                            updateExpense(updatedExpense)
                        },
                        onDelete: {
                            deleteExpense(expense)
                        }
                    )
                }
            }
        }
    }
    
    func deleteExpenses(offsets: IndexSet) {
        let sortedExpenses = expenses.sorted(by: { $0.date > $1.date })
        for index in offsets {
            if let originalIndex = expenses.firstIndex(where: { $0.id == sortedExpenses[index].id }) {
                expenses.remove(at: originalIndex)
            }
        }
    }
    
    func updateExpense(_ updatedExpense: Expense) {
        if let index = expenses.firstIndex(where: { $0.id == updatedExpense.id }) {
            expenses[index] = updatedExpense
        }
    }
    
    func deleteExpense(_ expense: Expense) {
        expenses.removeAll { $0.id == expense.id }
    }
}

// 지출 항목 한 줄을 표시하는 뷰
struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            // 카테고리 아이콘
            Image(systemName: expense.category.icon)
                .foregroundColor(expense.category.color)
                .frame(width: 30, height: 30)
                .background(expense.category.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(expense.formattedDate)
                        .font(.headline)
                    Spacer()
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(expense.category.color.opacity(0.2))
                        .foregroundColor(expense.category.color)
                        .cornerRadius(12)
                }
                
                Text(expense.memo)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let ocrText = expense.ocrText {
                    Text(ocrText)
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(expense.formattedAmount)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    MainView()
}
