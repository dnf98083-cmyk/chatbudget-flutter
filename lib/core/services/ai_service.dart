import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class AiService {
  static const _baseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-lite:generateContent';

  static const _systemPrompt =
      '당신은 한국어 지출/수입 메시지를 파싱하는 어시스턴트입니다. '
      '사용자 입력에서 금융 거래 정보를 추출하여 반드시 JSON 형식으로만 응답하세요. '
      '다른 텍스트는 절대 포함하지 마세요.\n\n'
      'JSON 형식:\n'
      '{"amount": 금액(숫자, 원 단위), "type": "expense" 또는 "income", '
      '"category": "식비|카페|교통|쇼핑|편의점|의료|문화|통신|저축|수입|기타" 중 하나, '
      '"date_offset": 오늘 기준 며칠 전(오늘=0, 어제=1, 그제=2), '
      '"description": "간단한 설명"}\n\n'
      '규칙:\n'
      '- "만원", "만" → 10000배\n'
      '- "k", "K" → 1000배\n'
      '- 월급/급여/알바/용돈/입금 → income\n'
      '- 저축/적금/예금/펀드/투자 → expense, category=저축\n'
      '- 날짜: 어제=1, 그제=2, N일전=N, 오늘=0\n'
      '- 금액을 찾을 수 없으면: {"error": "no_amount"}';

  static String get _apiKey {
    const compiled = String.fromEnvironment('GEMINI_API_KEY');
    if (compiled.isNotEmpty) return compiled;
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  static Future<Map<String, dynamic>?> parseTransaction(String userInput) async {
    final apiKey = _apiKey;
    if (apiKey.isEmpty) {
      // ignore: avoid_print
      print('[AI] No API key in .env');
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl?key=$apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'system_instruction': {
                'parts': [{'text': _systemPrompt}]
              },
              'contents': [
                {
                  'role': 'user',
                  'parts': [{'text': userInput}]
                }
              ],
              'generationConfig': {
                'maxOutputTokens': 256,
                'temperature': 0.1,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      // ignore: avoid_print
      print('[AI] status=${response.statusCode}');

      if (response.statusCode != 200) {
        // ignore: avoid_print
        print('[AI] body=${response.body}');
        return null;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (((data['candidates'] as List)[0]['content']['parts']) as List)[0]['text'] as String;

      final jsonMatch = RegExp(r'\{[^}]+\}', dotAll: true).firstMatch(text.trim());
      if (jsonMatch == null) return null;

      final parsed = jsonDecode(jsonMatch.group(0)!) as Map<String, dynamic>;
      if (parsed.containsKey('error')) return null;
      return parsed;
    } catch (e) {
      // ignore: avoid_print
      print('[AI] Error: $e');
      return null;
    }
  }
}
