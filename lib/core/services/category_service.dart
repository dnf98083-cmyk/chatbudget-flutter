import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  static const _key = 'custom_categories';

  static const baseCategories = [
    '식비', '카페', '교통', '쇼핑', '편의점', '의료', '문화', '통신', '저축', '수입', '기타',
  ];

  static const _emojiMap = {
    '식비': '🍚', '카페': '☕', '교통': '🚌', '쇼핑': '🛍️',
    '편의점': '🏪', '의료': '💊', '문화': '🎬', '통신': '📱',
    '저축': '🏦', '수입': '💰', '기타': '💳',
  };

  static String emoji(String category) => _emojiMap[category] ?? '🏷️';

  static Future<List<String>> getAll() async {
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList(_key) ?? [];
    return [...baseCategories, ...custom.where((c) => !baseCategories.contains(c))];
  }

  static Future<List<String>> getCustom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  /// Returns true if the category was genuinely new and added.
  static Future<bool> addIfNew(String category) async {
    if (category.isEmpty || baseCategories.contains(category)) return false;
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList(_key) ?? [];
    if (custom.contains(category)) return false;
    custom.add(category);
    await prefs.setStringList(_key, custom);
    return true;
  }

  static Future<void> remove(String category) async {
    if (baseCategories.contains(category)) return;
    final prefs = await SharedPreferences.getInstance();
    final custom = prefs.getStringList(_key) ?? [];
    custom.remove(category);
    await prefs.setStringList(_key, custom);
  }
}
