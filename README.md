# 💬 ChatBudget

> 대화하듯 기록하고, 한눈에 파악하는 개인 금융 앱

채팅창에 자연어 한 줄을 입력하면 자동으로 가계부가 기록되는 Flutter 앱입니다.  
서버 없이 로컬 SQLite에만 의존해 완전한 오프라인 동작을 지원합니다.

---

## 주요 기능

| 기능 | 설명 |
|------|------|
| 채팅형 입력 | `"스타벅스 6000원"` 한 줄로 즉시 기록 |
| 자연어 파싱 | 금액·날짜·카테고리 자동 추출 |
| 내역 조회 | 날짜별 지출·수입 리스트 |
| 월별 통계 | 카테고리별 파이 차트 + 수입/지출/잔액 요약 |
| 저축 목표 | 목표 금액·진행률 관리 |

### 입력 예시

```
스타벅스 아메리카노 4500   →  카페 · 4,500원
어제 택시 12000            →  교통 · 12,000원 (어제 날짜)
3일전 편의점 3500          →  편의점 · 3,500원 (3일 전)
월급 250만원               →  수입 · 2,500,000원
```

---

## 🚀 바로 실행 (설치 불필요)

| 구분 | 링크 |
|------|------|
| **앱 실행** | [https://dnf98083-cmyk.github.io/chatbudget-flutter/app/](https://dnf98083-cmyk.github.io/chatbudget-flutter/app/) |
| **WBS 일정표** | [https://dnf98083-cmyk.github.io/chatbudget-flutter/](https://dnf98083-cmyk.github.io/chatbudget-flutter/) |

> Chrome 브라우저 권장. 첫 로딩에 10~20초 소요될 수 있습니다.

---

## 📊 WBS 진행 현황

> 시각적 트리 다이어그램: **[GitHub Pages에서 보기 →](https://dnf98083-cmyk.github.io/chatbudget-flutter/)**

| # | 대분류 | 세부 항목 | 상태 |
|---|--------|-----------|------|
| 1 | 프로젝트 관리 | 기획 문서 (비전·요구사항·WBS·일정) | ✅ |
| | | ADR 3건 (프레임워크·상태관리·DB) | ✅ |
| | | AUTHORING.md / AGENTS.md | ✅ |
| 2 | 개발 환경 & 아키텍처 | Flutter 프로젝트 구조·라우팅 | ✅ |
| | | SQLite 스키마 (users·transactions·savings_goals) | ✅ |
| | | GitHub Pages 웹 배포 (flutter build web) | ✅ |
| 3 | 채팅형 입력 | 채팅 UI (버블·입력창·스크롤) | ✅ |
| | | 자연어 파서 (금액·날짜·카테고리+저축) | ✅ |
| | | Gemini AI 파싱 (gemini-2.0-flash-lite) | ✅ |
| | | 저축/적금 → 저축 목표 연동 | ✅ |
| 4 | 로그인 / 회원가입 | 계정 생성·SHA-256 해시·세션 유지 | ✅ |
| | | 계정별 데이터 분리 (user_id) | ✅ |
| 5 | 내역 조회 & 삭제 | 날짜별 그룹 리스트·스와이프 삭제 | ✅ |
| | | 내역 수정 다이얼로그 | ✅ |
| 6 | 통계 & 시각화 | 월별 요약 카드·도넛 차트 | ✅ |
| | | 잔액 음수 표시 수정 | ✅ |
| | | 하루 추천 예산 카드 | ✅ |
| | | 일별 막대 차트 | ✅ |
| | | 카테고리별 예산 관리 | ✅ |
| 7 | 저축 목표 | 목표 생성·진행률 프로그레스 바 | ✅ |
| | | 목표 추가 오류 피드백 | ✅ |
| | | 달성 예상일 계산 | ✅ |
| | | 목표 날짜 D-day 표시 | ✅ |
| 8 | 배포 & 문서 | GitHub Pages WBS 간트차트 | ✅ |
| | | Android APK 빌드 & 릴리즈 | ⬜ |

**진행률**: 완료 26 / 전체 27 항목 (**96%**)

---

## 빠른 시작

```bash
git clone https://github.com/dnf98083-cmyk/chatbudget-flutter.git
cd chatbudget-flutter
flutter pub get
flutter run
```

자세한 설치 가이드 (Windows / macOS / Linux): [docs/setup.md](docs/setup.md)

---

## 기술 스택

| 항목 | 선택 | 선택 이유 |
|------|------|-----------|
| 프레임워크 | Flutter | 단일 코드로 Android/iOS 동시 지원 ([ADR-0001](.planning/decisions/ADR-0001-mobile-framework.md)) |
| 상태 관리 | StatefulWidget / setState | 단일 화면 상태로 충분한 현재 규모 ([ADR-0002](.planning/decisions/ADR-0002-state-management.md)) |
| 로컬 DB | sqflite (SQLite) | 날짜 범위·집계 쿼리 필요, 업계 표준 ([ADR-0003](.planning/decisions/ADR-0003-local-database.md)) |
| 차트 | fl_chart | Flutter 생태계 표준 차트 라이브러리 |

---

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점, 하단 네비게이션
├── core/
│   ├── database/db_helper.dart  # SQLite CRUD (싱글톤)
│   ├── models/                  # 데이터 모델
│   │   ├── transaction_model.dart
│   │   └── savings_goal_model.dart
│   └── parser/
│       └── transaction_parser.dart  # 자연어 → 거래 모델 변환
└── features/
    ├── chat/chat_screen.dart    # 채팅 입력 화면
    ├── history/history_screen.dart  # 내역 조회
    ├── stats/stats_screen.dart  # 월별 통계·차트
    └── savings/savings_screen.dart  # 저축 목표
```

**새 화면 추가**: `lib/features/<기능명>/<기능명>_screen.dart` 생성 후 `main.dart`의 `_screens` 리스트와 `NavigationBar`에 추가.

---

## 아키텍처

자세한 Mermaid 다이어그램 포함: [docs/architecture.md](docs/architecture.md)

```
Presentation  →  ChatScreen / HistoryScreen / StatsScreen / SavingsScreen
Domain        →  TransactionParser  (자연어 파싱 로직)
Data          →  DbHelper  (SQLite CRUD)
Infrastructure→  chatbudget.db  (로컬 파일)
```

- **API 호출 위치**: 이 앱은 외부 API 없음 (오프라인 전용). DB 호출은 Data Layer(`DbHelper`)에서만 발생.

---

## 테스트

```bash
flutter test                    # 전체 실행
flutter test --reporter=expanded  # 상세 출력
```

현재 `test/widget_test.dart` 에 `TransactionParser` 단위 테스트 3개 포함.  
테스트 작성 가이드: [docs/testing.md](docs/testing.md)

---

## 문서 목록

| 문서 | 내용 |
|------|------|
| [.planning/00-vision.md](.planning/00-vision.md) | 비전·목표·사용자 시나리오 |
| [.planning/01-requirements.md](.planning/01-requirements.md) | MoSCoW 요구사항 |
| [.planning/02-wbs.md](.planning/02-wbs.md) | WBS |
| [.planning/04-schedule.md](.planning/04-schedule.md) | 6주 일정·위험 관리 |
| [docs/architecture.md](docs/architecture.md) | 아키텍처 (Mermaid 다이어그램) |
| [docs/setup.md](docs/setup.md) | 개발 환경 설정 (Windows/Mac/Linux) |
| [docs/testing.md](docs/testing.md) | 테스트 가이드 |
| [AGENTS.md](AGENTS.md) | AI Agent 활용 기록 |
| [AUTHORING.md](AUTHORING.md) | 본인 AI Agent 방법론 |

---

## 발표 Q&A 준비

> 교수님이 물어볼 수 있는 개발자 기본 소양 9가지와 답변입니다.

### Q1. 사용한 플랫폼과 선택 이유는?

**Flutter**를 선택했습니다.  
대안으로 React Native, Android Native, iOS Native를 검토했으나:
- React Native: JS 생태계는 친숙하지만 브릿지 복잡도와 성능 이슈
- Native: 각 플랫폼별 코드를 따로 작성해야 해 6주 안에 양 플랫폼 불가
- Flutter: **단일 Dart 코드로 Android/iOS 동시 지원**, Hot Reload로 빠른 이터레이션, `fl_chart·sqflite` 등 필요한 패키지 생태계 충분

→ [ADR-0001](.planning/decisions/ADR-0001-mobile-framework.md) 참조

---

### Q2. 앱 구조 — 4개 레이어 설명

```
Presentation  lib/features/      UI 렌더링, 사용자 입력 처리
Domain        lib/core/parser/   비즈니스 로직 (자연어 파싱)
Data          lib/core/models/   데이터 모델 + SQLite CRUD
Infrastructure                   chatbudget.db (로컬 SQLite 파일)
```

Presentation은 UI만 담당하고, 비즈니스 로직(파싱)은 Domain으로 분리했습니다.  
덕분에 파서 로직을 UI 없이 독립 테스트할 수 있습니다.

---

### Q3. 새 화면 추가 시 어느 폴더에 파일을 만드나요?

```
lib/features/<기능명>/<기능명>_screen.dart
```

예: 예산 설정 화면을 추가한다면 `lib/features/budget/budget_screen.dart`.  
이후 `lib/main.dart`의 `_screens` 리스트와 `NavigationBar destinations`에 한 줄씩 추가하면 됩니다.

---

### Q4. API 호출이 어느 레이어에서 일어나나요?

현재 앱은 외부 API를 사용하지 않는 **오프라인 전용**입니다.  
DB 호출(SQLite)은 **Data Layer** (`lib/core/database/db_helper.dart`)에서만 발생합니다.  
Presentation Layer에서 `await DbHelper.instance.getTransactions()` 형태로 직접 호출합니다.  

향후 REST API 연동이 필요하다면 `lib/core/services/api_service.dart`를 신설해  
Presentation → Service → DB 3단계로 분리하는 구조로 확장하면 됩니다.

---

### Q5. 개발 환경 설정 방법은?

```bash
# 1. Flutter SDK 설치 (Windows: winget install Google.Flutter)
# 2. 저장소 클론
git clone https://github.com/dnf98083-cmyk/chatbudget-flutter.git
cd chatbudget-flutter
# 3. 의존성 설치
flutter pub get
# 4. 환경 점검
flutter doctor
# 5. 실행
flutter run
```

전체 가이드 (Windows/macOS/Linux): [docs/setup.md](docs/setup.md)

---

### Q6. 빌드 & 배포 단계는?

```bash
# 개발 빌드 (디버그)
flutter run

# 릴리즈 빌드
flutter build apk --release          # Android APK
flutter build appbundle              # Google Play Store
flutter build ios --release          # iOS (macOS 필요)

# 배포
# Android: APK를 GitHub Releases에 업로드 또는 Play Store 제출
# iOS: Xcode를 통해 App Store Connect 업로드
```

---

### Q7. 테스트 작성 · 실행 방법은?

```bash
flutter test                    # 전체 테스트 실행
flutter test --reporter=expanded  # 상세 출력
```

테스트 파일은 `test/` 폴더에 위치합니다.  
현재 `TransactionParser` 단위 테스트 3개 (`금액 파싱`, `날짜 파싱`, `만원 단위`)가 있습니다.

새 테스트 작성:
```dart
test('설명', () {
  final result = TransactionParser.parse('입력 문자열');
  expect(result.amount, 예상값);
});
```

→ [docs/testing.md](docs/testing.md) 참조

---

### Q8. 빌드 실패 시 어디부터 확인하나요?

```bash
flutter doctor        # 1. SDK/플랫폼 환경 점검
flutter clean         # 2. 빌드 캐시 초기화
flutter pub get       # 3. 의존성 재설치
flutter analyze       # 4. Dart 정적 분석
flutter run --verbose # 5. 상세 에러 로그
```

**확인 순서**:
1. 에러 메시지 첫 줄 정확히 읽기 (파일:줄번호 포함)
2. `flutter doctor` — SDK 설치/플랫폼 이슈
3. `flutter clean && flutter pub get` — 빌드 캐시 문제
4. `pubspec.yaml` 패키지 버전 충돌 확인

---

### Q9. git clone 후 한 줄 명령으로 실행되나요?

```bash
git clone https://github.com/dnf98083-cmyk/chatbudget-flutter.git && cd chatbudget-flutter && flutter pub get && flutter run
```

**전제 조건**: Flutter SDK 설치 + Android 에뮬레이터(또는 실기기) 연결.  
Flutter SDK가 없다면 [docs/setup.md](docs/setup.md)의 1단계부터 진행하세요.
