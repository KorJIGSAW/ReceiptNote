//
//  SampleReceiptImages.swift
//  ReceiptNote
//
//  Utils 폴더에 추가

import SwiftUI
import UIKit

class SampleReceiptImages {
    static func createSampleReceipt1() -> UIImage? {
        let size = CGSize(width: 300, height: 400)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            // 배경
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            // 텍스트 스타일
            let titleFont = UIFont.boldSystemFont(ofSize: 16)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            let smallFont = UIFont.systemFont(ofSize: 10)
            
            // 상호명
            let storeName = "CU 편의점"
            storeName.draw(at: CGPoint(x: 20, y: 20),
                          withAttributes: [.font: titleFont, .foregroundColor: UIColor.black])
            
            // 날짜
            let date = "2025.05.21 14:30"
            date.draw(at: CGPoint(x: 20, y: 50),
                     withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
            
            // 구분선
            context.cgContext.setStrokeColor(UIColor.gray.cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.move(to: CGPoint(x: 20, y: 80))
            context.cgContext.addLine(to: CGPoint(x: 280, y: 80))
            context.cgContext.strokePath()
            
            // 상품 목록
            let items = [
                ("바나나우유", "1,500"),
                ("새우깡", "2,000"),
                ("삼각김밥", "1,200"),
                ("콜라", "1,800"),
                ("과자", "1,000")
            ]
            
            var yPosition: CGFloat = 100
            for (item, price) in items {
                item.draw(at: CGPoint(x: 20, y: yPosition),
                         withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
                price.draw(at: CGPoint(x: 220, y: yPosition),
                          withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
                yPosition += 25
            }
            
            // 구분선
            yPosition += 10
            context.cgContext.move(to: CGPoint(x: 20, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: 280, y: yPosition))
            context.cgContext.strokePath()
            
            // 총액
            yPosition += 20
            let total = "총액: 7,500원"
            total.draw(at: CGPoint(x: 20, y: yPosition),
                      withAttributes: [.font: titleFont, .foregroundColor: UIColor.black])
            
            // 결제 정보
            yPosition += 40
            "카드 결제".draw(at: CGPoint(x: 20, y: yPosition),
                          withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
            yPosition += 20
            "승인번호: 12345678".draw(at: CGPoint(x: 20, y: yPosition),
                                 withAttributes: [.font: smallFont, .foregroundColor: UIColor.gray])
        }
    }
    
    static func createSampleReceipt2() -> UIImage? {
        let size = CGSize(width: 300, height: 350)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        return renderer.image { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            let titleFont = UIFont.boldSystemFont(ofSize: 16)
            let bodyFont = UIFont.systemFont(ofSize: 12)
            
            "이마트24".draw(at: CGPoint(x: 20, y: 20),
                          withAttributes: [.font: titleFont, .foregroundColor: UIColor.black])
            
            "2025.05.20 18:45".draw(at: CGPoint(x: 20, y: 50),
                                   withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
            
            context.cgContext.setStrokeColor(UIColor.gray.cgColor)
            context.cgContext.setLineWidth(1)
            context.cgContext.move(to: CGPoint(x: 20, y: 80))
            context.cgContext.addLine(to: CGPoint(x: 280, y: 80))
            context.cgContext.strokePath()
            
            let items = [
                ("라면", "1,200"),
                ("김치", "3,500"),
                ("우유", "2,800"),
                ("계란", "4,500"),
                ("빵", "3,000")
            ]
            
            var yPosition: CGFloat = 100
            for (item, price) in items {
                item.draw(at: CGPoint(x: 20, y: yPosition),
                         withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
                price.draw(at: CGPoint(x: 220, y: yPosition),
                          withAttributes: [.font: bodyFont, .foregroundColor: UIColor.black])
                yPosition += 25
            }
            
            yPosition += 10
            context.cgContext.move(to: CGPoint(x: 20, y: yPosition))
            context.cgContext.addLine(to: CGPoint(x: 280, y: yPosition))
            context.cgContext.strokePath()
            
            yPosition += 20
            "총액: 15,000원".draw(at: CGPoint(x: 20, y: yPosition),
                              withAttributes: [.font: titleFont, .foregroundColor: UIColor.black])
        }
    }
    
    // 이미지를 사진 라이브러리에 저장하는 함수
    static func saveToPhotoLibrary() {
        guard let receipt1 = createSampleReceipt1(),
              let receipt2 = createSampleReceipt2() else { return }
        
        UIImageWriteToSavedPhotosAlbum(receipt1, nil, nil, nil)
        UIImageWriteToSavedPhotosAlbum(receipt2, nil, nil, nil)
    }
}
