# ADR-0003 — 로컬 데이터베이스 선택

- **날짜**: 2026-05-12
- **상태**: 확정

## 배경

지출/수입 내역과 저축 목표를 로컬에 영구 저장해야 한다.
서버 없이 오프라인에서도 동작해야 한다.
선택지: sqflite (SQLite), Hive, Isar, SharedPreferences

## 결정

**sqflite (SQLite)** 를 선택한다.

## 대안 검토

| 대안 | 장점 | 단점 | 제외 이유 |
|---|---|---|---|
| Hive | 빠름, NoSQL, 쉬운 API | 복잡한 쿼리 어려움 | 날짜 범위 조회, 카테고리 집계 쿼리 필요 |
| Isar | 빠름, 타입 안전 | 학습 곡선, 상대적으로 신규 | 레퍼런스 부족 |
| SharedPreferences | 매우 간단 | Key-Value만 가능, 대용량 부적합 | 구조화된 내역 저장 불가 |

## 결정 이유

1. **SQL 쿼리** 로 날짜 범위, 카테고리별 집계 등 복잡한 통계 쿼리 가능
2. 업계 표준 SQLite — 면접에서 **DB 설계 질문에 답하기 용이**
3. `sqflite` 패키지 성숙도 높고 레퍼런스 풍부
4. 향후 서버 연동 시 **동일한 스키마**로 마이그레이션 용이

## 스키마 요약

```sql
-- 지출/수입 내역
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount INTEGER NOT NULL,
  type TEXT NOT NULL,          -- 'expense' | 'income'
  category TEXT NOT NULL,
  description TEXT,
  date TEXT NOT NULL,          -- ISO8601: '2026-05-12T14:30:00'
  created_at TEXT NOT NULL
);

-- 저축 목표
CREATE TABLE savings_goals (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  target_amount INTEGER NOT NULL,
  current_amount INTEGER DEFAULT 0,
  deadline TEXT,
  created_at TEXT NOT NULL
);
```

## 결과

- `sqflite`, `path` 패키지 추가
- `lib/core/database/db_helper.dart` 에 DB 초기화 및 CRUD 메서드 구현
