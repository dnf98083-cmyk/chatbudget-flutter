# AGENTS.md — AI Agent 활용 기록

> ChatBudget 프로젝트에서 Claude Code (AI Agent) 를 어떻게 활용했는지 기록합니다.
> 가산점 항목: AI Agent / 스킬 / 워크플로우 적극 활용 (+1점)

---

## 사용 도구

| 도구 | 용도 |
|------|------|
| **Claude Code** (Anthropic) | 기획 문서, 코드 구현, 아키텍처 설계, 문서화 전반 |

---

## 세션별 활용 내역

### 세션 1 — 기획 & 문서화 (2026-05-12)

**목표**: 프로젝트 기획 문서 세트 완성

**Claude Code에게 시킨 것:**
```
채팅형 가계부 앱을 만들고 싶다.
.planning/ 폴더 아래에 다음을 만들어줘:
- 00-vision.md (비전, 목표, 사용자 시나리오 3개)
- 01-requirements.md (MoSCoW 기능 분류)
- 02-wbs.md (3단계 WBS, 명사형 산출물)
- 04-schedule.md (6주 일정, 위험 5개 이상)
- ADR 3개 (플랫폼/상태관리/DB 선택)
```

**결과물:**
- `.planning/00-vision.md` — 비전/목표/시나리오
- `.planning/01-requirements.md` — MoSCoW 분류표
- `.planning/02-wbs.md` — WBS 8개 항목
- `.planning/04-schedule.md` — 6주 일정 + 위험 5개
- `.planning/decisions/ADR-0001~0003` — 3개 ADR

**소요 시간**: 약 20분 (수동 작업 대비 ~90% 절감)

---

### 세션 2 — Flutter 앱 초기 구현 (2026-05-12)

**목표**: 작동하는 프로토타입 구축

**Claude Code에게 시킨 것:**
```
Flutter로 채팅형 가계부 앱을 만들어줘.
- feature-based 폴더 구조 (lib/features/, lib/core/)
- SQLite로 로컬 저장
- 자연어 파서 ("스타벅스 6000원" → 카테고리/금액/날짜 자동 추출)
- 4개 화면: 채팅, 내역, 통계(차트), 저축목표
```

**결과물:**
- `lib/core/parser/transaction_parser.dart` — 자연어 파서 (금액/날짜/카테고리 추출)
- `lib/core/database/db_helper.dart` — SQLite CRUD
- `lib/features/chat/chat_screen.dart` — 채팅 UI
- `lib/features/history/history_screen.dart` — 내역 목록
- `lib/features/stats/stats_screen.dart` — 파이 차트 통계
- `lib/features/savings/savings_screen.dart` — 저축 목표 관리
- `test/widget_test.dart` — 파서 단위 테스트 3개

**소요 시간**: 약 2시간 (수동 구현 대비 ~80% 절감)

---

### 세션 3 — 문서화 & GitHub 정리 (2026-05-19)

**목표**: 제출 서류 완비 + GitHub 설명 추가

**Claude Code에게 시킨 것:**
```
세션 3 필수 제출물을 만들어줘:
- docs/architecture.md (Mermaid 다이어그램)
- docs/setup.md (Windows/Mac/Linux zero→run, FAQ 5개)
- docs/testing.md (테스트 가이드)
- AGENTS.md (AI 활용 기록)
- README.md 전면 개편 (발표 Q&A 포함)
- GitHub 저장소 description/topics 업데이트
```

**결과물:**
- 이 파일 포함 문서 5개 일괄 생성
- GitHub 저장소 메타 정보 업데이트

---

## 활용 패턴 — 내가 개발한 방법론

자세한 내용은 [AUTHORING.md](./AUTHORING.md) 참조.

핵심 원칙:
1. **내가 What/Why, AI가 How** — 기술 선택은 내가 하고 구현은 AI에게
2. **코드 받으면 즉시 이해 질문** — AI가 만든 코드는 반드시 설명 듣고 다음 진행
3. **결정은 ADR로 문서화** — AI 제안 중 선택한 이유를 남겨야 발표 때 설명 가능
4. **문서 먼저, 코드 나중** — `.planning/` 문서가 있으면 AI가 방향을 잃지 않음

---

## 수치로 본 효율

| 작업 | 예상 수동 시간 | AI 활용 시 | 절감 |
|------|--------------|-----------|------|
| 기획 문서 5개 | 4~6시간 | 20분 | ~90% |
| Flutter 앱 초기 구현 | 2~3일 | 2시간 | ~85% |
| 문서화 (arch/setup/testing) | 3~4시간 | 30분 | ~87% |

---

## 한계와 교훈

- **파서 정확도**: AI가 만든 키워드 목록이 완벽하지 않음 → 직접 테스트하며 키워드 추가
- **ADR vs 실제 구현 불일치**: ADR-0002에 Riverpod을 계획했으나 규모상 setState로 충분하다 판단 → 계획과 실제의 차이를 문서에 명시하는 것이 중요
- **이해 없이 복사하면 발표 때 막힘** → 코드 받은 직후 "이게 뭐야?" 질문 습관화가 필수
