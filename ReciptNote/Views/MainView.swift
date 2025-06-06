//
//  MainView.swift
//  ReceiptNote
//

import SwiftUI

struct MainView: View {
    @State private var expenses: [Expense] = Expense.sampleData
    @State private var showingAddExpense = false
    
    var body: some View {
        NavigationView {
            VStack {
                // 지출 내역 리스트
                List {
                    ForEach(expenses.sorted(by: { $0.date > $1.date })) { expense in
                        ExpenseRowView(expense: expense)
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
}

// 지출 항목 한 줄을 표시하는 뷰
struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack {
            // 영수증 이미지 또는 플레이스홀더
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 50, height: 50)
                .overlay(
                    Image(systemName: "doc.text")
                        .foregroundColor(.gray)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.formattedDate)
                    .font(.headline)
                Text(expense.memo)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
        .padding(.vertical, 4)
    }
}

#Preview {
    MainView()
}
