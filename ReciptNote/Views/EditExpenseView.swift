//
//  EditExpenseView.swift
//  ReceiptNote
//
//  Views 폴더에 추가

import SwiftUI

struct EditExpenseView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var ocrManager = OCRManager()
    
    @State private var amount: String
    @State private var memo: String
    @State private var selectedDate: Date
    @State private var selectedCategory: ExpenseCategory
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var ocrText: String
    @State private var isProcessingOCR = false
    @State private var ocrError: String?
    
    let expense: Expense
    let onSave: (Expense) -> Void
    let onDelete: () -> Void
    
    init(expense: Expense, onSave: @escaping (Expense) -> Void, onDelete: @escaping () -> Void) {
        self.expense = expense
        self.onSave = onSave
        self.onDelete = onDelete
        
        // 초기값 설정
        _amount = State(initialValue: EditExpenseView.formatCurrency(Int(expense.amount)))
        _memo = State(initialValue: expense.memo)
        _selectedDate = State(initialValue: expense.date)
        _selectedCategory = State(initialValue: expense.category)
        _ocrText = State(initialValue: expense.ocrText ?? "")
        
        // 이미지 복원
        if let imageData = expense.receiptImageData {
            _selectedImage = State(initialValue: UIImage(data: imageData))
        }
    }
    
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
                                let filtered = newValue.filter { $0.isNumber }
                                if let number = Int(filtered), number > 0 {
                                    amount = Self.formatCurrency(number)
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
                                        if category == selectedCategory {
                                            Image(systemName: "checkmark")
                                        }
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
                    VStack(alignment: .leading) {
                        Text("메모")
                        TextEditor(text: $memo)
                            .frame(minHeight: 60)
                    }
                }
                
                Section(header: Text("영수증 사진")) {
                    if let image = selectedImage {
                        VStack {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 200)
                                .cornerRadius(10)
                            
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
                        
                        if selectedImage != nil {
                            Button("삭제") {
                                selectedImage = nil
                                ocrText = ""
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    if let error = ocrError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                if !ocrText.isEmpty {
                    Section(header: Text("인식된 텍스트")) {
                        Text(ocrText)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // 삭제 버튼
                Section {
                    Button("지출 내역 삭제") {
                        onDelete()
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationTitle("지출 편집")
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
        
        ocrError = nil
        isProcessingOCR = true
        
        ocrManager.recognizeText(from: image) { result in
            isProcessingOCR = false
            
            switch result {
            case .success(let recognizedText):
                ocrText = recognizedText
                
                let receiptInfo = ocrManager.extractReceiptInfo(from: recognizedText)
                
                if let extractedAmount = receiptInfo.totalAmount {
                    amount = Self.formatCurrency(Int(extractedAmount))
                }
                
                if let storeName = receiptInfo.storeName, memo.isEmpty {
                    memo = storeName
                }
                
                selectedCategory = autoDetectCategory(from: recognizedText)
                
            case .failure(let error):
                ocrError = error.localizedDescription
                ocrText = "텍스트 인식에 실패했습니다: \(error.localizedDescription)"
            }
        }
    }
    
    private func saveExpense() {
        let cleanAmount = amount.replacingOccurrences(of: ",", with: "")
                                .replacingOccurrences(of: "원", with: "")
                                .trimmingCharacters(in: .whitespaces)
        
        guard let amountValue = Double(cleanAmount) else { return }
        
        var updatedExpense = expense
        updatedExpense.date = selectedDate
        updatedExpense.amount = amountValue
        updatedExpense.memo = memo
        updatedExpense.category = selectedCategory
        updatedExpense.receiptImageData = selectedImage?.jpegData(compressionQuality: 0.8)
        updatedExpense.ocrText = ocrText.isEmpty ? nil : ocrText
        
        onSave(updatedExpense)
        presentationMode.wrappedValue.dismiss()
    }
    
    private static func formatCurrency(_ amount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedNumber = formatter.string(from: NSNumber(value: amount)) ?? "\(amount)"
        return formattedNumber + "원"
    }
    
    private func autoDetectCategory(from text: String) -> ExpenseCategory {
        let lowercaseText = text.lowercased()
        
        let foodKeywords = ["편의점", "마트", "카페", "커피", "음식점", "치킨", "피자"]
        if foodKeywords.contains(where: { lowercaseText.contains($0) }) {
            return .food
        }
        
        let transportKeywords = ["지하철", "버스", "택시", "주유"]
        if transportKeywords.contains(where: { lowercaseText.contains($0) }) {
            return .transportation
        }
        
        let medicalKeywords = ["병원", "약국", "의원"]
        if medicalKeywords.contains(where: { lowercaseText.contains($0) }) {
            return .medical
        }
        
        let shoppingKeywords = ["마트", "쇼핑", "세탁"]
        if shoppingKeywords.contains(where: { lowercaseText.contains($0) }) {
            return .shopping
        }
        
        return .other
    }
}

#Preview {
    EditExpenseView(
        expense: Expense.sampleData[0],
        onSave: { _ in },
        onDelete: { }
    )
}
