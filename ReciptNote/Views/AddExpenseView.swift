//
//  AddExpenseView.swift
//  ReceiptNote
//

import SwiftUI

struct AddExpenseView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var ocrManager = OCRManager()
    
    @State private var amount: String = ""
    @State private var memo: String = ""
    @State private var selectedDate = Date()
    @State private var selectedCategory: ExpenseCategory = .other
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var ocrText: String = ""
    @State private var isProcessingOCR = false
    @State private var ocrError: String?
    
    let onSave: (Expense) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("지출 정보")) {
                    // 날짜 선택
                    DatePicker("날짜", selection: $selectedDate, displayedComponents: .date)
                    
                    // 금액 입력
                    HStack {
                        Text("금액")
                        TextField("금액 입력", text: $amount)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .onChange(of: amount) { newValue in
                                // 숫자만 입력되도록 필터링
                                let filtered = newValue.filter { $0.isNumber }
                                if let number = Int(filtered), number > 0 {
                                    amount = formatCurrency(number)
                                } else if filtered.isEmpty {
                                    amount = ""
                                }
                            }
                    }
                    
                    // 카테고리 선택
                    HStack {
                        Text("카테고리")
                        Spacer()
                        Menu {
                            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                                Button(action: {
                                    selectedCategory = category
                                }) {
                                    HStack {
                                        Image(systemName: category.icon)
                                        Text(category.rawValue)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedCategory.icon)
                                    .foregroundColor(selectedCategory.color)
                                Text(selectedCategory.rawValue)
                                    .foregroundColor(.primary)
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // 메모 입력
                    HStack {
                        Text("메모")
                        TextField("메모 입력", text: $memo)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section(header: Text("영수증 사진")) {
                    // 영수증 이미지 표시
                    if let image = selectedImage {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(10)
                            
                            // OCR 처리 상태 표시
                            if isProcessingOCR {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("텍스트 인식 중...")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 8)
                            }
                        }
                    }
                    
                    // OCR 기능 버튼들
                    HStack {
                        Button("촬영") {
                            showingCamera = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Button("선택") {
                            showingImagePicker = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // OCR 에러 표시
                    if let error = ocrError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // OCR 결과 표시
                if !ocrText.isEmpty {
                    Section(header: Text("인식된 텍스트")) {
                        Text(ocrText)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("지출 추가")
            .navigationBarItems(
                leading: Button("취소") {
                    presentationMode.wrappedValue.dismiss()
                },
                trailing: Button("저장") {
                    saveExpense()
                }
                .disabled(amount.isEmpty)
            )
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, onImageSelected: processImage)
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(selectedImage: $selectedImage, onImageSelected: processImage)
        }
    }
    
    private func processImage() {
        guard let image = selectedImage else { return }
        
        // OCR 에러 초기화
        ocrError = nil
        isProcessingOCR = true
        
        // 실제 OCR 처리
        ocrManager.recognizeText(from: image) { result in
            isProcessingOCR = false
            
            switch result {
            case .success(let recognizedText):
                ocrText = recognizedText
                
                // 영수증 정보 추출
                let receiptInfo = ocrManager.extractReceiptInfo(from: recognizedText)
                
                // 추출된 정보로 필드 자동 채우기
                if let extractedAmount = receiptInfo.totalAmount {
                    amount = formatCurrency(Int(extractedAmount))
                }
                
                if let storeName = receiptInfo.storeName, memo.isEmpty {
                    memo = storeName
                }
                
                // 자동 카테고리 분류
                selectedCategory = autoDetectCategory(from: recognizedText)
                
            case .failure(let error):
                ocrError = error.localizedDescription
                ocrText = "텍스트 인식에 실패했습니다: \(error.localizedDescription)"
            }
        }
    }
    
    private func saveExpense() {
        // 금액에서 콤마와 "원" 제거 후 숫자만 추출
        let cleanAmount = amount.replacingOccurrences(of: ",", with: "")
                                .replacingOccurrences(of: "원", with: "")
                                .trimmingCharacters(in: .whitespaces)
        
        guard let amountValue = Double(cleanAmount) else { return }
        
        let newExpense = Expense(
            date: selectedDate,
            amount: amountValue,
            memo: memo,
            category: selectedCategory,
            receiptImageData: selectedImage?.jpegData(compressionQuality: 0.8),
            ocrText: ocrText.isEmpty ? nil : ocrText
        )
        
        onSave(newExpense)
        presentationMode.wrappedValue.dismiss()
    }
    
    private func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return formattedNumber + "원"
    }
    
    private func autoDetectCategory(from text: String) -> ExpenseCategory {
        let lowercaseText = text.lowercased()
        
        // 식비 키워드
        let foodKeywords = ["편의점", "마트", "카페", "커피", "음식점", "치킨", "피자", "hamburger", "coffee", "restaurant"]
        if foodKeywords.contains(where: { lowercaseText.contains($0) }) {
            return .food
        }
        
        // 교통비 키워드
        let transportKeywords = ["지하철", "버스", "택시", "주유", "gas", "subway", "bus"]
        if transportKeywords.contains(where: { lowercaseText.contains($0) }) {
            return .transportation
        }
        
        // 의료비 키워드
        let medicalKeywords = ["병원", "약국", "의원", "clinic", "hospital", "pharmacy"]
        if medicalKeywords.contains(where: { lowercaseText.contains($0) }) {
            return .medical
        }
        
        // 생활용품 키워드
        let shoppingKeywords = ["마트", "쇼핑", "세탁", "mart", "shopping"]
        if shoppingKeywords.contains(where: { lowercaseText.contains($0) }) {
            return .shopping
        }
        
        return .other
    }
}

#Preview {
    AddExpenseView { _ in }
}
