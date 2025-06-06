//
//  StatisticsView.swift
//  ReceiptNote
//

import SwiftUI

struct StatisticsView: View {
    let expenses: [Expense]
    @State private var selectedPeriod: StatisticsPeriod = .weekly
    
    enum StatisticsPeriod: String, CaseIterable {
        case weekly = "주별"
        case monthly = "월별"
    }
    
    var body: some View {
        VStack {
            // 기간 선택 세그먼트
            Picker("기간", selection: $selectedPeriod) {
                ForEach(StatisticsPeriod.allCases, id: \.self) { period in
                    Text(period.rawValue).tag(period)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // 원형 차트 영역
            VStack {
                Text("지출 분포")
                    .font(.headline)
                    .padding(.top)
                
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.3), lineWidth: 20)
                        .frame(width: 200, height: 200)
                    
                    Circle()
                        .trim(from: 0, to: 0.7) // 70% 예시
                        .stroke(Color.blue, lineWidth: 20)
                        .frame(width: 200, height: 200)
                        .rotationEffect(Angle(degrees: -90))
                    
                    VStack {
                        Text("총 지출")
                            .font(.caption)
                        Text(totalAmount)
                            .font(.title2)
                            .fontWeight(.bold)
                    }
                }
                .padding()
            }
            
            // 주별/월별 막대 차트
            VStack(alignment: .leading) {
                Text("\(selectedPeriod.rawValue) 지출 내역")
                    .font(.headline)
                    .padding(.horizontal)
                
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(statisticsData, id: \.period) { data in
                            StatisticsRowView(data: data, maxAmount: maxAmount)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .navigationTitle("지출 통계")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // 계산된 속성들
    private var totalAmount: String {
        let total = expenses.reduce(0) { $0 + $1.amount }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₩"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: total)) ?? "₩0"
    }
    
    private var statisticsData: [StatisticsData] {
        let data = switch selectedPeriod {
        case .weekly:
            generateWeeklyData()
        case .monthly:
            generateMonthlyData()
        }
        
        // 빈 데이터가 있으면 기본 메시지 표시
        return data.isEmpty ? [StatisticsData(period: "데이터 없음", amount: 0)] : data
    }
    
    private var maxAmount: Double {
        statisticsData.map { $0.amount }.max() ?? 1
    }
    
    private func generateWeeklyData() -> [StatisticsData] {
        let calendar = Calendar.current
        let now = Date()
        var weeklyData: [StatisticsData] = []
        
        // 최근 4주간의 데이터 생성
        for weekOffset in 0..<4 {
            let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: now) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) ?? now
            
            // 해당 주의 지출 필터링
            let weekExpenses = expenses.filter { expense in
                expense.date >= weekStart && expense.date <= weekEnd
            }
            
            let totalAmount = weekExpenses.reduce(0) { $0 + $1.amount }
            let weekNumber = 4 - weekOffset
            
            weeklyData.append(StatisticsData(period: "\(weekNumber)주차", amount: totalAmount))
        }
        
        return weeklyData.reversed() // 1주차부터 순서대로
    }
    
    private func generateMonthlyData() -> [StatisticsData] {
        let calendar = Calendar.current
        let now = Date()
        var monthlyData: [StatisticsData] = []
        
        // 최근 6개월간의 데이터 생성
        for monthOffset in 0..<6 {
            guard let monthDate = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }
            
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: monthDate)) ?? monthDate
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart)?.addingTimeInterval(-1) ?? monthDate
            
            // 해당 월의 지출 필터링
            let monthExpenses = expenses.filter { expense in
                expense.date >= monthStart && expense.date <= monthEnd
            }
            
            let totalAmount = monthExpenses.reduce(0) { $0 + $1.amount }
            
            let formatter = DateFormatter()
            formatter.dateFormat = "M월"
            let monthName = formatter.string(from: monthDate)
            
            monthlyData.append(StatisticsData(period: monthName, amount: totalAmount))
        }
        
        return monthlyData.reversed() // 시간순으로 정렬
    }
}

// 통계 데이터 구조체
struct StatisticsData {
    let period: String
    let amount: Double
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "₩"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "₩0"
    }
}

// 통계 한 줄 표시 뷰
struct StatisticsRowView: View {
    let data: StatisticsData
    let maxAmount: Double
    
    var body: some View {
        HStack {
            Text(data.period)
                .frame(width: 60, alignment: .leading)
                .font(.subheadline)
            
            // 막대 차트
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 20)
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.blue)
                    .frame(width: CGFloat(data.amount / maxAmount) * 200, height: 20)
            }
            
            Text(data.formattedAmount)
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(minWidth: 80, alignment: .trailing)
        }
    }
}

#Preview {
    NavigationView {
        StatisticsView(expenses: Expense.sampleData)
    }
}
