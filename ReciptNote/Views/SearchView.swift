//
//  SearchView.swift
//  ReceiptNote
//
//  Views 폴더에 추가

import SwiftUI

struct SearchView: View {
    @Binding var expenses: [Expense]
    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var minAmount: String = ""
    @State private var maxAmount: String = ""
    @State private var showingFilters = false
    
    var filteredExpenses: [Expense] {
        var filtered = expenses
        
        // 텍스트 검색
        if !searchText.isEmpty {
            filtered = filtered.filter { expense in
                expense.memo.localizedCaseInsensitiveContains(searchText) ||
                expense.ocrText?.localizedCaseInsensitiveContains(searchText) == true ||
                expense.formattedAmount.contains(searchText)
            }
        }
        
        // 카테고리 필터
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }
        
        // 금액 범위 필터
        if let min = Double(minAmount), min > 0 {
            filtered = filtered.filter { $0.amount >= min }
        }
        
        if let max = Double(maxAmount), max > 0 {
            filtered = filtered.filter { $0.amount <= max }
        }
        
        return filtered.sorted(by: { $0.date > $1.date })
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // 검색바
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("메모, 금액, 상점명 검색...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Button("필터") {
                        showingFilters.toggle()
                    }
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                // 필터 옵션 (토글)
                if showingFilters {
                    FilterOptionsView(
                        selectedCategory: $selectedCategory,
                        minAmount: $minAmount,
                        maxAmount: $maxAmount
                    )
                    .padding(.horizontal)
                }
                
                // 검색 결과
                List {
                    ForEach(filteredExpenses) { expense in
                        SearchResultRowView(expense: expense, searchText: searchText)
                    }
                }
                
                // 검색 결과 요약
                HStack {
                    Text("총 \(filteredExpenses.count)개 항목")
                    Spacer()
                    Text("합계: \(totalAmount)")
                        .fontWeight(.bold)
                }
                .padding()
                .background(Color.gray.opacity(0.1))
            }
            .navigationTitle("검색")
        }
    }
    
    private var totalAmount: String {
        let total = filteredExpenses.reduce(0) { $0 + $1.amount }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₩"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "₩0"
    }
}

// 필터 옵션 뷰
struct FilterOptionsView: View {
    @Binding var selectedCategory: ExpenseCategory?
    @Binding var minAmount: String
    @Binding var maxAmount: String
    
    var body: some View {
        VStack(spacing: 12) {
            // 카테고리 필터
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button("전체") {
                        selectedCategory = nil
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(selectedCategory == nil ? Color.blue : Color.gray.opacity(0.2))
                    .foregroundColor(selectedCategory == nil ? .white : .primary)
                    .cornerRadius(20)
                    
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = selectedCategory == category ? nil : category
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selectedCategory == category ? category.color : Color.gray.opacity(0.2))
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
            }
            
            // 금액 범위 필터
            HStack {
                TextField("최소 금액", text: $minAmount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("~")
                
                TextField("최대 금액", text: $maxAmount)
                    .keyboardType(.numberPad)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
    }
}

// 검색 결과 행 뷰 (하이라이트 포함)
struct SearchResultRowView: View {
    let expense: Expense
    let searchText: String
    
    var body: some View {
        HStack {
            Image(systemName: expense.category.icon)
                .foregroundColor(expense.category.color)
                .frame(width: 30, height: 30)
                .background(expense.category.color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.formattedDate)
                    .font(.headline)
                
                // 하이라이트된 메모
                highlightedText(expense.memo, searchText: searchText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(expense.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(expense.category.color.opacity(0.2))
                    .foregroundColor(expense.category.color)
                    .cornerRadius(12)
            }
            
            Spacer()
            
            Text(expense.formattedAmount)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
    
    private func highlightedText(_ text: String, searchText: String) -> Text {
        if searchText.isEmpty {
            return Text(text)
        }
        
        let parts = text.components(separatedBy: searchText)
        var result = Text("")
        
        for (index, part) in parts.enumerated() {
            result = result + Text(part)
            if index < parts.count - 1 {
                result = result + Text(searchText).foregroundColor(.blue).bold()
            }
        }
        
        return result
    }
}

#Preview {
    SearchView(expenses: .constant(Expense.sampleData))
}
