# 테스트 가이드

## 테스트 구조

```
test/
└── widget_test.dart   # 파서 단위 테스트 (현재)
```

Flutter 테스트는 세 가지로 나뉩니다:

| 종류 | 설명 | 이 프로젝트 |
|------|------|-------------|
| Unit Test | 순수 Dart 함수/클래스 테스트 | `TransactionParser` 테스트 ✅ |
| Widget Test | 위젯 렌더링 & 상호작용 테스트 | 추후 추가 예정 |
| Integration Test | 실제 기기에서 전체 흐름 테스트 | 추후 추가 예정 |

---

## 테스트 실행

```bash
# 전체 테스트 실행
flutter test

# 특정 파일만
flutter test test/widget_test.dart

# 상세 출력
flutter test --reporter=expanded

# 커버리지 측정
flutter test --coverage
# 결과: coverage/lcov.info
```

---

## 현재 테스트 목록

`test/widget_test.dart` 에 파서 단위 테스트 3개가 있습니다:

```dart
// 1. 금액 파싱 + 카테고리 자동 분류
test('파서: 금액 파싱', () {
  final result = TransactionParser.parse('스타벅스 6000원');
  expect(result.amount, 6000);
  expect(result.category, '카페');
});

// 2. 상대 날짜 파싱 ("어제")
test('파서: 어제 날짜 파싱', () {
  final result = TransactionParser.parse('어제 편의점 3500');
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  expect(result.date.day, yesterday.day);
});

// 3. 만원 단위 + 수입 분류
test('파서: 만원 단위', () {
  final result = TransactionParser.parse('월급 250만원');
  expect(result.amount, 2500000);
  expect(result.type, 'income');
});
```

---

## 새 테스트 작성 방법

`test/widget_test.dart` 에 `test()` 블록을 추가합니다:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:chatbudget_flutter/core/parser/transaction_parser.dart';

void main() {
  // 단위 테스트: TransactionParser
  group('TransactionParser', () {
    test('k 단위 금액 인식', () {
      final result = TransactionParser.parse('커피 6k');
      expect(result.amount, 6000);
    });

    test('N일전 날짜 인식', () {
      final result = TransactionParser.parse('3일전 택시 12000');
      final expected = DateTime.now().subtract(const Duration(days: 3));
      expect(result.date.day, expected.day);
    });

    test('금액 없으면 null 반환', () {
      final tx = TransactionParser.toTransaction('오늘 날씨 좋다');
      expect(tx, isNull);
    });
  });
}
```

---

## 빌드 실패 시 체크리스트

```bash
# 1단계: Flutter 환경
flutter doctor

# 2단계: 의존성 문제
flutter clean
flutter pub get

# 3단계: Dart 정적 분석
flutter analyze

# 4단계: 테스트만 격리해서 실행
flutter test --no-pub
```

확인 순서:
1. `flutter doctor` — SDK/플랫폼 이슈
2. 에러 메시지 첫 줄 정확히 읽기 (보통 파일:줄번호 포함)
3. `flutter clean` 후 재빌드
4. `pubspec.yaml` 의 패키지 버전 충돌 확인
