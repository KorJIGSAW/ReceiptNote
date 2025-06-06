# ReceiptNote 📱

**영수증을 통한 지출 관리 iOS 어플리케이션**

ReceiptNote는 영수증 OCR 인식 기능을 활용하여 간편하게 지출을 기록하고 관리할 수 있는 iOS 앱입니다.

## ✨ 주요 기능

### 📸 영수증 OCR 인식
- **카메라 촬영** 또는 **갤러리 선택**으로 영수증 등록
- **Vision 프레임워크** 기반 텍스트 자동 인식
- **금액, 상호명, 날짜** 자동 추출
- **카테고리 자동 분류** (편의점 → 식비, 주유소 → 교통비 등)

### 💰 지출 관리
- **날짜, 금액, 메모** 입력으로 지출 기록
- **8개 카테고리** 분류: 식비, 교통비, 생활용품, 의료비, 여가/오락, 교육, 공과금, 기타
- **편집/삭제** 기능으로 유연한 관리
- **Core Data** 기반 영구 저장

### 🔍 검색 및 필터링
- **실시간 텍스트 검색** (메모, OCR 텍스트, 금액)
- **카테고리별 필터링**
- **금액 범위 설정** (최소/최대 금액)
- **검색어 하이라이트** 표시

### 📊 통계 및 분석
- **주별/월별** 지출 통계
- **막대형/원형** 차트 시각화
- **카테고리별** 지출 분포 분석
- **기간별** 지출 트렌드 확인

### 💸 예산 관리
- **월별 예산** 설정 및 관리
- **카테고리별 예산** 개별 설정
- **실시간 사용률** 및 **진행률** 표시
- **예산 초과 알림** (시각적 경고)

### 📱 사용자 경험
- **탭 기반 네비게이션** (홈, 검색, 통계, 예산)
- **직관적인 UI/UX** 디자인
- **카테고리별 아이콘** 및 **색상 시스템**
- **반응형 애니메이션** 효과

## 🛠 기술 스택

### **개발 환경**
- **언어**: Swift
- **프레임워크**: SwiftUI
- **플랫폼**: iOS 15.0+
- **IDE**: Xcode 15+

### **주요 기술**
- **Core Data**: 로컬 데이터 영구 저장
- **Vision Framework**: OCR 텍스트 인식
- **AVFoundation**: 카메라 기능
- **UserDefaults**: 설정 데이터 저장
- **Combine**: 반응형 프로그래밍

### **라이브러리**
- **SwiftUI Charts**: 통계 차트 시각화
- **PhotosUI**: 이미지 선택 기능

## 📂 프로젝트 구조

```
ReceiptNote/
├── Models/
│   ├── Expense.swift              # 지출 데이터 모델
│   ├── ExpenseCategory.swift      # 카테고리 열거형
│   ├── Budget.swift               # 예산 모델
│   └── ExpenseEntity+CoreDataClass.swift # Core Data 엔티티
│
├── Views/
│   ├── MainView.swift             # 메인 화면 (탭 네비게이션)
│   ├── AddExpenseView.swift       # 지출 추가 화면
│   ├── EditExpenseView.swift      # 지출 편집 화면
│   ├── SearchView.swift           # 검색 화면
│   ├── StatisticsView.swift       # 통계 화면
│   └── BudgetView.swift           # 예산 관리 화면
│
├── ViewModels/
│   ├── ExpenseStore.swift         # 지출 데이터 관리
│   └── OCRManager.swift           # OCR 텍스트 인식
│
├── Utils/
│   ├── ImagePicker.swift          # 이미지 선택 유틸리티
│   └── SampleReceiptImages.swift  # 샘플 이미지 생성
│
└── Assets/
    └── ReceiptNote.xcdatamodeld   # Core Data 모델
```

## 🚀 설치 및 실행

### **요구사항**
- **macOS** Sequoia 15.5
- **Xcode** 16.4
- **iOS** iOS 18.5

### **설치 방법**
1. **레포지토리 클론**
   ```bash
   git clone https://github.com/your-username/ReceiptNote.git
   cd ReceiptNote
   ```

2. **Xcode에서 프로젝트 열기**
   ```bash
   open ReceiptNote.xcodeproj
   ```

3. **타겟 설정**
   - **Team**: Apple Developer 계정 설정
   - **Bundle Identifier**: 고유한 식별자로 변경

4. **권한 설정 확인**
   - `Info.plist`에 카메라 및 사진 라이브러리 권한 설정됨
   ```xml
   <key>NSCameraUsageDescription</key>
   <string>영수증 촬영을 위해 카메라 접근이 필요합니다.</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>영수증 이미지 선택을 위해 사진 라이브러리 접근이 필요합니다.</string>
   ```

5. **빌드 및 실행**
   - **Command + R** 또는 **Product > Run**

## 📱 주요 기능

### **지출 추가**
1. **홈 화면**에서 **"지출 추가"** 버튼 클릭
2. **금액, 메모, 카테고리** 입력
3. **영수증 사진** 촬영 또는 선택 (선택사항)
4. **OCR 자동 인식**으로 정보 자동 입력
5. **저장** 버튼으로 완료

### **지출 관리**
- **지출 항목 탭**: 편집 화면으로 이동
- **좌측 스와이프**: 삭제 기능
- **카테고리별 정렬**: 아이콘과 색상으로 구분

### **검색 및 필터**
1. **검색 탭**에서 **키워드 입력**
2. **필터 버튼**으로 고급 옵션 설정
3. **카테고리, 금액 범위** 설정
4. **실시간 결과** 확인

### **예산 관리**
1. **예산 탭**에서 **설정 버튼** 클릭
2. **월별 총 예산** 및 **카테고리별 예산** 설정
3. **홈 화면**에서 **실시간 사용률** 확인
4. **예산 초과 시 시각적 경고** 표시


## 👨‍💻 개발자

**2071360 이종범**
- 📧 Email: bm8383@naver.com
- 💼 GitHub: [@KorJIGSAW](https://github.com/KorJIGSAW)

## 시연 영상
[@시연영상]([https://github.com/KorJIGSAW](https://www.youtube.com/watch?v=TSIBI2OKucQ))

---
