import 'package:flutter_test/flutter_test.dart';
import 'package:chatbudget_flutter/core/parser/transaction_parser.dart';

void main() {
  test('파서: 금액 파싱', () {
    final result = TransactionParser.parse('스타벅스 6000원');
    expect(result.amount, 6000);
    expect(result.category, '카페');
  });

  test('파서: 어제 날짜 파싱', () {
    final result = TransactionParser.parse('어제 편의점 3500');
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    expect(result.date.day, yesterday.day);
  });

  test('파서: 만원 단위', () {
    final result = TransactionParser.parse('월급 250만원');
    expect(result.amount, 2500000);
    expect(result.type, 'income');
  });
}
