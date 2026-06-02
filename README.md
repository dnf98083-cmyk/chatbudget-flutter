# 💬 ChatBudget

> **한 줄 가치 제안**: 채팅창에 "스타벅스 6000원" 한 줄만 입력하면 AI가 자동으로 가계부를 기록해주는 Flutter 앱

---

## 🚀 바로 실행 (설치 불필요)

| 구분 | 링크 |
|------|------|
| **앱 실행** | [https://dnf98083-cmyk.github.io/chatbudget-flutter/app/](https://dnf98083-cmyk.github.io/chatbudget-flutter/app/) |
| **발표 슬라이드** | [https://dnf98083-cmyk.github.io/chatbudget-flutter/presentation.html](https://dnf98083-cmyk.github.io/chatbudget-flutter/presentation.html) |
| **WBS 일정표** | [https://dnf98083-cmyk.github.io/chatbudget-flutter/](https://dnf98083-cmyk.github.io/chatbudget-flutter/) |

> Chrome 브라우저 권장. 첫 로딩 10~20초 소요.

---

## 1. 프로젝트 비전 & 사용자 시나리오

**문제**: 가계부 앱은 많지만 입력이 귀찮아서 결국 안 쓰게 된다.  
**해결**: 말하듯 한 줄 입력 → AI가 금액·날짜·카테고리를 자동 파싱해 즉시 기록.

### 핵심 사용자 시나리오 3가지

| # | 시나리오 | 입력 예시 | 결과 |
|---|----------|-----------|------|
| 1 | 즉흥 지출 기록 | `"스타벅스 6000원"` | 카페 · 6,000원 |
| 2 | 과거 날짜 수정 | `"어제 택시 12000"` | 교통 · 어제 날짜로 기록 |
| 3 | 수입 기록 | `"월급 250만원"` | 수입 · 2,500,000원 |

> 상세 비전 문서: [.planning/00-vision.md](.planning/00-vision.md)

---

## 2. 요구사항 (MoSCoW)

| 구분 | 기능 | 상태 |
|------|------|------|
| **Must** | 채팅형 자연어 입력 | ✅ |
| **Must** | 금액·날짜·카테고리 자동 파싱 | ✅ |
| **Must** | 거래 내역 조회 & 삭제 | ✅ |
| **Must** | 로그인 / 계정별 데이터 분리 | ✅ |
| **Must** | 월별 통계 & 차트 | ✅ |
| **Should** | Gemini AI 파싱 (rule-based 폴백) | ✅ |
| **Should** | 저축 목표 관리 | ✅ |
| **Should** | 내역 수정 다이얼로그 | ✅ |
| **Could** | 일별 막대 차트 | ✅ |
| **Could** | 카테고리별 예산 관리 | ✅ |
| **Could** | AI 신규 카테고리 자동 생성 | ✅ |
| **Won't** | 서버/클라우드 동기화 | — |

> 전체 요구사항: [.planning/01-requirements.md](.planning/01-requirements.md)

---

## 3. 아키텍처 (4레이어)

```
Presentation  →  lib/features/   채팅·내역·통계·저축 화면 (UI만 담당)
Domain        →  lib/core/parser/ TransactionParser (자연어 파싱 비즈니스 로직)
Data          →  lib/core/database/ DbHelper (SQLite CRUD, 싱글톤)
Infrastructure→  chatbudget.db   로컬 SQLite 파일 (기기 내 저장)
```

### 프로젝트 구조

```
lib/
├── main.dart                        # 앱 진입점, 하단 네비게이션
├── core/
│   ├── database/db_helper.dart      # SQLite CRUD (싱글톤)
│   ├── models/                      # 데이터 모델
│   ├── parser/transaction_parser.dart  # 자연어 → 거래 변환
│   └── services/
│       ├── ai_service.dart          # Gemini API 연동
│       ├── auth_service.dart        # 로그인·세션
│       └── category_service.dart    # 동적 카테고리 관리
└── features/
    ├── chat/chat_screen.dart        # 채팅 입력
    ├── history/history_screen.dart  # 내역 조회·수정
    ├── stats/stats_screen.dart      # 통계·차트·예산
    └── savings/savings_screen.dart  # 저축 목표
```

> 상세 아키텍처 다이어그램: [docs/architecture.md](docs/architecture.md)

---

## 4. 의사결정 (ADR 3건)

| ADR | 결정 | 핵심 이유 |
|-----|------|-----------|
| [ADR-0001](.planning/decisions/ADR-0001-mobile-framework.md) | **Flutter** | 단일 코드로 Web·Android·iOS 동시 지원. Hot Reload로 빠른 개발 |
| [ADR-0002](.planning/decisions/ADR-0002-state-management.md) | **setState** | 소규모 앱에 외부 패키지 불필요. 실시간 갱신은 ValueNotifier 보완 |
| [ADR-0003](.planning/decisions/ADR-0003-local-database.md) | **SQLite** | 오프라인 우선. 개인 금융 데이터를 서버로 보내지 않음 |

---

## 5. 개발 환경 설정

```bash
# 1. Flutter SDK 설치
winget install Google.Flutter          # Windows
brew install --cask flutter            # macOS

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

> 전체 설치 가이드 (Windows / macOS / Linux): [docs/setup.md](docs/setup.md)

---

## 6. 빌드 & 배포

```bash
# 웹 빌드 (GitHub Pages 배포용)
flutter build web --release \
  --dart-define=GEMINI_API_KEY=<키> \
  --base-href=/chatbudget-flutter/app/

# Android APK
flutter build apk --release

# 배포: docs/app/ 폴더에 복사 후 git push → GitHub Pages 자동 서빙
cp -r build/web docs/app
git add docs/app && git push origin main
```

**배포 URL**: https://dnf98083-cmyk.github.io/chatbudget-flutter/app/

> 배포 상세: [docs/setup.md](docs/setup.md)

---

## 7. 테스트

```bash
flutter test                      # 전체 실행
flutter test --reporter=expanded  # 상세 출력
flutter analyze                   # 정적 분석
```

현재 `test/widget_test.dart`에 `TransactionParser` 단위 테스트 3개:
- 금액 파싱 (`"스타벅스 6000원"` → 6000)
- 날짜 파싱 (`"어제"` → offset 1)
- 만원 단위 (`"3만원"` → 30000)

> 테스트 작성 가이드: [docs/testing.md](docs/testing.md)

---

## 8. WBS 진행률

> 시각적 간트 차트: **[GitHub Pages에서 보기 →](https://dnf98083-cmyk.github.io/chatbudget-flutter/)**

| # | 대분류 | 세부 항목 | 상태 |
|---|--------|-----------|------|
| 1 | 프로젝트 관리 | 기획 문서 (비전·요구사항·WBS·일정) | ✅ |
| | | ADR 3건 (프레임워크·상태관리·DB) | ✅ |
| | | AUTHORING.md / AGENTS.md | ✅ |
| 2 | 개발 환경 & 아키텍처 | Flutter 프로젝트 구조·라우팅 | ✅ |
| | | SQLite 스키마 (users·transactions·savings_goals) | ✅ |
| | | GitHub Pages 웹 배포 | ✅ |
| 3 | 채팅형 입력 | 채팅 UI (버블·입력창·스크롤) | ✅ |
| | | 자연어 파서 (금액·날짜·카테고리) | ✅ |
| | | Gemini AI 파싱 + rule-based 폴백 | ✅ |
| | | 저축/적금 → 저축 목표 연동 | ✅ |
| 4 | 로그인 / 회원가입 | 계정 생성·SHA-256 해시·세션 유지 | ✅ |
| | | 계정별 데이터 분리 (user_id) | ✅ |
| 5 | 내역 조회 & 관리 | 날짜별 그룹 리스트·스와이프 삭제 | ✅ |
| | | 내역 수정 다이얼로그 | ✅ |
| | | 기록 초기화 (전체 삭제 + 2단계 확인) | ✅ |
| 6 | 통계 & 시각화 | 월별 요약 카드·도넛 차트 | ✅ |
| | | 하루 추천 예산 카드 | ✅ |
| | | 일별 막대 차트 | ✅ |
| | | 카테고리별 예산 관리 | ✅ |
| 7 | 저축 목표 | 목표 생성·진행률 프로그레스 바 | ✅ |
| | | 달성 예상일 계산 | ✅ |
| | | 목표 날짜 D-day 표시 | ✅ |
| 8 | AI & 카테고리 | AI 신규 카테고리 자동 생성 | ✅ |
| 9 | 배포 & 문서 | GitHub Pages WBS 간트차트 | ✅ |
| | | Android APK 빌드 & 릴리즈 | ⬜ |

**진행률**: 완료 29 / 전체 30 항목 (**97%**)

> WBS 상세: [.planning/02-wbs.md](.planning/02-wbs.md) | 6주 일정: [.planning/04-schedule.md](.planning/04-schedule.md)

---

## 9. AI Agent 활용 기록

이 프로젝트의 **모든 산출물**은 Claude Code (AI Agent)와 협업하여 생성·관리했습니다.

| 작업 | AI Agent 활용 내용 |
|------|-------------------|
| 기획 문서 | 비전·요구사항·WBS·일정 자동 생성 |
| 아키텍처 | 4레이어 설계 + Mermaid 다이어그램 |
| 구현 | 전체 Flutter 코드 (채팅·파서·DB·차트) |
| 테스트 | 단위 테스트 자동 작성 |
| 배포 | GitHub Pages 빌드·배포 스크립트 |
| 문서화 | README·ADR·setup·testing 자동 생성 |
| 진행 관리 | 매 기능 완료 후 WBS·git 커밋 자동 갱신 |

> AI Agent 상세 활용 기록: [AGENTS.md](AGENTS.md)  
> 본인 AI 활용 방법론: [AUTHORING.md](AUTHORING.md)

---

## 10. 위험 식별 & 대응

| # | 카테고리 | 위험 | 대응 방안 |
|---|----------|------|-----------|
| 1 | 기술 | Flutter Web에서 SQLite 미지원 | sqflite_ffi_web + OPFS로 해결 |
| 2 | 외부 의존 | Gemini API 키 노출 (웹 빌드) | `--dart-define` 컴파일 타임 삽입, rule-based 폴백 |
| 3 | 기술 | `.env` 파일이 웹 번들에 포함 안 됨 | `String.fromEnvironment()` + try-catch로 해결 |
| 4 | AI 의존 | AI가 만든 코드를 본인이 이해 못함 | 매 기능마다 코드 리뷰 후 커밋, ADR로 의사결정 기록 |
| 5 | 일정 | 기능 범위 초과로 마감 위험 | MoSCoW 우선순위로 Must 먼저 구현, Could는 후순위 |

---

## 발표 Q&A 대비

### Q. 사용한 플랫폼과 선택 이유는?
**Flutter**. 단일 Dart 코드로 Web·Android·iOS 동시 지원. 이 프로젝트는 설치 없이 웹 링크로 즉시 데모 가능해서 발표에 유리. → [ADR-0001](.planning/decisions/ADR-0001-mobile-framework.md)

### Q. 앱 구조는?
4레이어: Presentation(화면) → Domain(파서) → Data(DbHelper) → Infrastructure(SQLite). 파서 로직이 UI와 분리되어 독립 테스트 가능.

### Q. 개발 환경 설정은?
`git clone` → `flutter pub get` → `flutter run` 세 줄. → [docs/setup.md](docs/setup.md)

### Q. 빌드·배포는?
`flutter build web --release` → `docs/app/`에 복사 → `git push` → GitHub Pages 자동 서빙.

### Q. 테스트는?
`flutter test`. TransactionParser 단위 테스트 3개. → [docs/testing.md](docs/testing.md)

### Q. API 호출은 어느 레이어?
외부: `AiService` (Gemini API). 내부 DB: `DbHelper` (Data Layer). Presentation은 직접 DB를 호출하지 않음.

### Q. 새 화면 추가하면?
`lib/features/<기능>/<기능>_screen.dart` 생성 → `main.dart`의 `_screens`와 `NavigationBar`에 한 줄씩 추가.

---

## 기술 스택

| 항목 | 선택 | 이유 |
|------|------|------|
| 프레임워크 | Flutter (Dart) | 단일 코드로 멀티플랫폼 |
| 상태 관리 | setState + ValueNotifier | 소규모 앱, 외부 패키지 불필요 |
| 로컬 DB | sqflite + sqflite_ffi_web | 오프라인 우선, 관계형 쿼리 |
| AI 파싱 | Gemini 2.0 Flash Lite | 빠르고 저비용, rule-based 폴백 |
| 차트 | fl_chart | Flutter 생태계 표준 |
| 배포 | GitHub Pages | 무료, 링크 하나로 즉시 데모 |
