# ADR-0001 — 모바일 프레임워크 선택

- **날짜**: 2026-05-12
- **상태**: 확정

## 배경

개인 금융 앱을 Android / iOS 양쪽에서 동작하도록 만들어야 한다.
프레임워크 선택지: Flutter, React Native, Android Native (Kotlin), iOS Native (Swift)

## 결정

**Flutter** 를 선택한다.

## 대안 검토

| 대안 | 장점 | 단점 | 제외 이유 |
|---|---|---|---|
| React Native | JS 생태계 친숙 | 성능 이슈, 브릿지 복잡도 | Dart 학습이 더 취업 차별화 |
| Android Native | 성능 최적 | iOS 별도 개발 필요 | 6주 안에 양 플랫폼 불가 |
| iOS Native | 성능 최적 | Android 별도 개발 필요 | 동일 |

## 결정 이유

1. **단일 코드베이스**로 Android/iOS 동시 지원 가능
2. **fl_chart, sqflite** 등 필요한 패키지 생태계 충분
3. 국내 취업 시장에서 **Flutter 수요 증가** 추세
4. Hot Reload로 빠른 UI 이터레이션 가능

## 결과

- Dart 언어 학습 필요 (1~2일 예상)
- `pubspec.yaml` 기반 패키지 관리
- Android Studio 또는 VS Code + Flutter 플러그인 사용
