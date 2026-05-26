import '../models/transaction_model.dart';

class ParseResult {
  final int? amount;
  final String? type;
  final String category;
  final String description;
  final DateTime date;

  ParseResult({
    required this.amount,
    required this.type,
    required this.category,
    required this.description,
    required this.date,
  });
}

class TransactionParser {
  static const Map<String, List<String>> _categoryKeywords = {
    '식비': ['밥', '점심', '저녁', '아침', '식사', '밥집', '한식', '중식', '일식', '분식', '치킨', '피자', '햄버거', '패스트푸드'],
    '카페': ['커피', '아메리카노', '라떼', '카페', '스타벅스', '투썸', '이디야', '빽다방', '음료'],
    '교통': ['버스', '지하철', '택시', '카카오택시', '우버', 'ktx', 'kx', '기차', '교통'],
    '쇼핑': ['쇼핑', '옷', '신발', '의류', '아마존', '쿠팡', '11번가', '지마켓'],
    '편의점': ['편의점', 'cu', 'gs25', '세븐일레븐', '미니스톱', '편의'],
    '의료': ['병원', '약국', '약', '의원', '치과', '한의원'],
    '문화': ['영화', '공연', '넷플릭스', '유튜브', '게임', '책', '도서'],
    '통신': ['통신', '핸드폰', '요금', 'kt', 'skt', 'lg', '인터넷'],
    '저축': ['저축', '적금', '예금', '펀드', '투자', '주식'],
    '수입': ['월급', '급여', '알바', '용돈', '수입', '입금', '환급'],
  };

  static ParseResult parse(String input) {
    final lower = input.toLowerCase().trim();

    final date = _parseDate(lower);
    final amount = _parseAmount(lower);
    final type = _parseType(lower, amount);
    final category = _parseCategory(lower, type);
    final description = _cleanDescription(input);

    return ParseResult(
      amount: amount,
      type: type,
      category: category,
      description: description,
      date: date,
    );
  }

  static DateTime _parseDate(String input) {
    // 특정 날짜: "2025-05-10" 또는 "05-10" 또는 "5/10"
    final fullDateRegex = RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})');
    final shortDateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})');

    final now = DateTime.now();

    final fullMatch = fullDateRegex.firstMatch(input);
    if (fullMatch != null) {
      return DateTime(int.parse(fullMatch.group(1)!), int.parse(fullMatch.group(2)!), int.parse(fullMatch.group(3)!));
    }

    // "N일전", "N일 전"
    final daysAgoRegex = RegExp(r'(\d+)일\s*전');
    final daysAgoMatch = daysAgoRegex.firstMatch(input);
    if (daysAgoMatch != null) {
      return now.subtract(Duration(days: int.parse(daysAgoMatch.group(1)!)));
    }

    if (input.contains('어제')) return now.subtract(const Duration(days: 1));
    if (input.contains('그제') || input.contains('그저께')) return now.subtract(const Duration(days: 2));

    final shortMatch = shortDateRegex.firstMatch(input);
    if (shortMatch != null) {
      return DateTime(now.year, int.parse(shortMatch.group(1)!), int.parse(shortMatch.group(2)!));
    }

    return now;
  }

  static int? _parseAmount(String input) {
    // "6만원", "6만", "60000원", "6000", "6k", "6.5만"
    final manRegex = RegExp(r'(\d+(?:\.\d+)?)\s*만');
    final wonRegex = RegExp(r'(\d{3,})\s*원?');
    final kRegex = RegExp(r'(\d+(?:\.\d+)?)\s*k');

    final manMatch = manRegex.firstMatch(input);
    if (manMatch != null) {
      return (double.parse(manMatch.group(1)!) * 10000).toInt();
    }

    final kMatch = kRegex.firstMatch(input);
    if (kMatch != null) {
      return (double.parse(kMatch.group(1)!) * 1000).toInt();
    }

    final wonMatch = wonRegex.firstMatch(input);
    if (wonMatch != null) {
      return int.parse(wonMatch.group(1)!);
    }

    return null;
  }

  static String _parseType(String input, int? amount) {
    for (final keyword in _categoryKeywords['수입']!) {
      if (input.contains(keyword)) return 'income';
    }
    if (input.contains('수입') || input.contains('받았') || input.contains('입금')) return 'income';
    return 'expense';
  }

  static String _parseCategory(String input, String? type) {
    if (type == 'income') return '수입';

    for (final entry in _categoryKeywords.entries) {
      if (entry.key == '수입') continue;
      for (final keyword in entry.value) {
        if (input.contains(keyword)) return entry.key;
      }
    }
    return '기타';
  }

  static String _cleanDescription(String input) {
    // 날짜/금액 패턴 제거 후 남은 텍스트를 설명으로
    var desc = input
        .replaceAll(RegExp(r'\d{4}[/-]\d{1,2}[/-]\d{1,2}'), '')
        .replaceAll(RegExp(r'\d{1,2}[/-]\d{1,2}'), '')
        .replaceAll(RegExp(r'\d+(?:\.\d+)?만원?'), '')
        .replaceAll(RegExp(r'\d+(?:\.\d+)?k'), '')
        .replaceAll(RegExp(r'\d{3,}원?'), '')
        .replaceAll(RegExp(r'어제|그제|그저께|\d+일\s*전'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    return desc.isEmpty ? input.trim() : desc;
  }

  static TransactionModel? toTransaction(String input) {
    final result = parse(input);
    if (result.amount == null) return null;

    return TransactionModel(
      amount: result.amount!,
      type: result.type ?? 'expense',
      category: result.category,
      description: result.description.isEmpty ? input.trim() : result.description,
      date: result.date,
    );
  }
}
