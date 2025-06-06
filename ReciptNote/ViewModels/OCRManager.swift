//
//  OCRManager.swift
//  ReceiptNote
//
//  ViewModels 폴더에 추가

import UIKit
import Vision

class OCRManager: ObservableObject {
    
    // 이미지에서 텍스트를 인식하는 함수
    func recognizeText(from image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        guard let cgImage = image.cgImage else {
            completion(.failure(OCRError.invalidImage))
            return
        }
        
        // Vision 텍스트 인식 요청 생성
        let request = VNRecognizeTextRequest { request, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            // 인식된 텍스트 결과 처리
            guard let observations = request.results as? [VNRecognizedTextObservation] else {
                DispatchQueue.main.async {
                    completion(.failure(OCRError.noTextFound))
                }
                return
            }
            
            // 모든 인식된 텍스트를 하나의 문자열로 합치기
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            DispatchQueue.main.async {
                if recognizedText.isEmpty {
                    completion(.failure(OCRError.noTextFound))
                } else {
                    completion(.success(recognizedText))
                }
            }
        }
        
        // OCR 정확도 설정 (accurate가 더 정확하지만 느림)
        request.recognitionLevel = .accurate
        
        // 한국어와 영어 지원
        request.recognitionLanguages = ["ko-KR", "en-US"]
        
        // 숫자와 구두점도 인식하도록 설정
        request.usesLanguageCorrection = true
        
        // Vision 요청 실행
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
            }
        }
    }
    
    // 영수증에서 특정 정보 추출하기
    func extractReceiptInfo(from text: String) -> ReceiptInfo {
        var info = ReceiptInfo()
        
        // 텍스트를 줄별로 분리
        let lines = text.components(separatedBy: .newlines)
        
        // 금액 찾기 - 다양한 패턴으로 시도
        info.totalAmount = findBestAmount(in: text, lines: lines)
        
        // 날짜 찾기
        info.date = findDate(in: text)
        
        // 상호명 찾기
        info.storeName = findStoreName(in: lines)
        
        return info
    }
    
    private func findBestAmount(in text: String, lines: [String]) -> Double? {
        var foundAmounts: [(amount: Double, confidence: Int)] = []
        
        // 1. 키워드 기반 금액 찾기 (가장 신뢰도 높음)
        let keywordPatterns = [
            ("합계", "합계[\\s:₩]*([0-9,]+)", 100),
            ("총액", "총액[\\s:₩]*([0-9,]+)", 95),
            ("계", "[^가-힣]계[\\s:₩]*([0-9,]+)", 90),
            ("total", "total[\\s:₩]*([0-9,]+)", 85),
            ("총", "총[\\s]*([0-9,]+)", 80)
        ]
        
        for (_, pattern, confidence) in keywordPatterns {
            if let amount = extractAmount(from: text, pattern: pattern) {
                foundAmounts.append((amount, confidence))
            }
        }
        
        // 2. 마지막 줄의 큰 금액 찾기 (보통 총액)
        for i in (max(0, lines.count - 5)..<lines.count).reversed() {
            let line = lines[i]
            let amounts = extractAllAmounts(from: line)
            for amount in amounts {
                if amount >= 1000 { // 1000원 이상만
                    foundAmounts.append((amount, 70))
                }
            }
        }
        
        // 3. ₩ 기호가 붙은 금액 찾기
        let wonPatterns = [
            "₩\\s*([0-9,]+)",
            "\\\\([0-9,]+)",
            "won\\s*([0-9,]+)"
        ]
        
        for pattern in wonPatterns {
            if let amount = extractAmount(from: text, pattern: pattern) {
                foundAmounts.append((amount, 75))
            }
        }
        
        // 4. 줄 끝의 큰 금액들 (보통 가격)
        for line in lines {
            if line.contains("원") {
                let amounts = extractAllAmounts(from: line)
                for amount in amounts {
                    if amount >= 1000 {
                        foundAmounts.append((amount, 60))
                    }
                }
            }
        }
        
        // 5. 가장 큰 금액 (마지막 수단)
        let allAmounts = extractAllAmounts(from: text)
        if let maxAmount = allAmounts.max(), maxAmount >= 1000 {
            foundAmounts.append((maxAmount, 40))
        }
        
        // 신뢰도가 가장 높은 금액 반환
        return foundAmounts.max(by: { $0.confidence < $1.confidence })?.amount
    }
    
    private func findStoreName(in lines: [String]) -> String? {
        // 상호명과 구입 품목을 함께 추출
        var storeName: String?
        var items: [String] = []
        
        // 첫 번째 줄에서 상호명 찾기
        if let firstLine = lines.first?.trimmingCharacters(in: .whitespaces), !firstLine.isEmpty {
            storeName = firstLine
        }
        
        // 편의점, 마트 등 키워드가 있는 줄에서 상호명 찾기
        let storeKeywords = ["편의점", "마트", "mart", "store", "shop", "카페", "cafe", "음식점", "치킨", "피자"]
        for line in lines.prefix(5) {
            let cleanLine = line.trimmingCharacters(in: .whitespaces)
            for keyword in storeKeywords {
                if cleanLine.contains(keyword) && !cleanLine.isEmpty {
                    storeName = cleanLine
                    break
                }
            }
        }
        
        // 구입 품목 추출 (가격이 있는 줄들)
        for line in lines {
            let cleanLine = line.trimmingCharacters(in: .whitespaces)
            
            // 숫자가 포함된 줄에서 품목명 추출
            if cleanLine.contains(where: { $0.isNumber }) &&
               !cleanLine.isEmpty &&
               cleanLine.count >= 2 &&
               cleanLine.count <= 50 {
                
                // 가격 부분 제거하고 품목명만 추출
                let itemName = extractItemName(from: cleanLine)
                if let item = itemName,
                   !item.isEmpty &&
                   item.count >= 2 &&
                   !isOnlyNumbers(item) &&
                   !isDateOrCode(item) {
                    items.append(item)
                }
            }
        }
        
        // 상호명과 주요 품목들을 조합
        var result = storeName ?? ""
        
        if !items.isEmpty {
            let topItems = Array(items.prefix(3)) // 최대 3개 품목
            let itemsText = topItems.joined(separator: ", ")
            
            if !result.isEmpty {
                result += " - " + itemsText
            } else {
                result = itemsText
            }
        }
        
        return result.isEmpty ? nil : result
    }
    
    private func extractItemName(from line: String) -> String? {
        // 한글, 영문이 포함된 부분을 품목명으로 간주
        let components = line.components(separatedBy: .whitespaces)
        
        for component in components {
            let cleanComponent = component.trimmingCharacters(in: CharacterSet(charactersIn: "*()[]{}"))
            
            // 한글이나 영문이 포함되고, 숫자만으로 이루어지지 않은 것
            if cleanComponent.count >= 2 &&
               cleanComponent.count <= 20 &&
               (cleanComponent.contains(where: { $0.isLetter }) ||
                cleanComponent.contains(where: { "가"..."힣" ~= $0 })) &&
               !cleanComponent.allSatisfy({ $0.isNumber || $0 == "," || $0 == "." }) {
                return cleanComponent
            }
        }
        
        return nil
    }
    
    private func isOnlyNumbers(_ text: String) -> Bool {
        return text.allSatisfy { $0.isNumber || $0 == "," || $0 == "." || $0 == "-" }
    }
    
    private func isDateOrCode(_ text: String) -> Bool {
        // 날짜나 코드로 보이는 패턴 제외
        let patterns = [
            "^\\d{4}[.-]\\d{1,2}[.-]\\d{1,2}$",  // 날짜
            "^\\d{10,}$",                        // 긴 숫자 코드
            "^[A-Z0-9]{5,}$"                     // 영문+숫자 코드
        ]
        
        for pattern in patterns {
            if text.range(of: pattern, options: .regularExpression) != nil {
                return true
            }
        }
        
        return false
    }
    
    private func findDate(in text: String) -> String? {
        let datePatterns = [
            "20\\d{2}[-.]\\d{1,2}[-.]\\d{1,2}",  // 2024-01-01, 2024.01.01
            "\\d{4}[-.]\\d{1,2}[-.]\\d{1,2}",   // 일반적인 날짜
            "\\d{1,2}/\\d{1,2}/20\\d{2}",       // MM/DD/YYYY
            "\\d{1,2}/\\d{1,2}/\\d{2}",         // MM/DD/YY
            "20\\d{2}년\\s*\\d{1,2}월\\s*\\d{1,2}일"  // 한국어 날짜
        ]
        
        for pattern in datePatterns {
            if let date = extractDate(from: text, pattern: pattern) {
                return date
            }
        }
        
        return nil
    }
    
    private func extractAllAmounts(from text: String) -> [Double] {
        let patterns = [
            "[0-9,]+\\.[0-9]{2}",  // 소수점 포함 (12,345.67)
            "[0-9,]{4,}",          // 4자리 이상 숫자 (1,000 이상)
            "[0-9]{4,}"            // 콤마 없는 4자리 이상
        ]
        
        var amounts: [Double] = []
        
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let range = NSRange(location: 0, length: text.utf16.count)
                let matches = regex.matches(in: text, options: [], range: range)
                
                for match in matches {
                    if let swiftRange = Range(match.range, in: text) {
                        let numberString = String(text[swiftRange])
                        let cleanNumber = numberString.replacingOccurrences(of: ",", with: "")
                        if let amount = Double(cleanNumber), amount >= 100 {
                            amounts.append(amount)
                        }
                    }
                }
            }
        }
        
        return amounts
    }
    
    private func extractAmount(from text: String, pattern: String) -> Double? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        let matches = regex.matches(in: text, options: [], range: range)
        
        for match in matches {
            if match.numberOfRanges > 1 {
                let amountRange = match.range(at: 1)
                if let swiftRange = Range(amountRange, in: text) {
                    let amountString = String(text[swiftRange])
                    let cleanAmount = amountString.replacingOccurrences(of: ",", with: "")
                    return Double(cleanAmount)
                }
            }
        }
        
        return nil
    }
    
    private func extractDate(from text: String, pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return nil
        }
        
        let range = NSRange(location: 0, length: text.utf16.count)
        if let match = regex.firstMatch(in: text, options: [], range: range),
           let swiftRange = Range(match.range, in: text) {
            return String(text[swiftRange])
        }
        
        return nil
    }
}

// OCR 결과 구조체
struct ReceiptInfo {
    var storeName: String?
    var date: String?
    var totalAmount: Double?
    var items: [String] = []
}

// OCR 에러 타입
enum OCRError: LocalizedError {
    case invalidImage
    case noTextFound
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "이미지를 처리할 수 없습니다."
        case .noTextFound:
            return "텍스트를 찾을 수 없습니다."
        }
    }
}
