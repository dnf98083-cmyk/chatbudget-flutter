import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/db_helper.dart';
import '../models/user_model.dart';

class AuthService {
  static const _prefUserId = 'current_user_id';

  static final ValueNotifier<UserModel?> userNotifier = ValueNotifier(null);

  // Screens listen to this to know when to reload data
  static final ValueNotifier<int> refreshNotifier = ValueNotifier(0);

  static UserModel? get currentUser => userNotifier.value;
  static int get currentUserId => userNotifier.value?.id ?? 0;
  static bool get isLoggedIn => userNotifier.value != null;

  static void notifyRefresh() {
    refreshNotifier.value++;
  }

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_prefUserId);
    if (userId != null) {
      final user = await DbHelper.instance.getUserById(userId);
      userNotifier.value = user;
    }
  }

  static Future<String?> login(String username, String password) async {
    if (username.trim().isEmpty || password.isEmpty) return '아이디와 비밀번호를 입력해주세요';
    final user = await DbHelper.instance.getUserByUsername(username.trim());
    if (user == null) return '존재하지 않는 아이디입니다';
    if (user.passwordHash != _hash(password)) return '비밀번호가 틀렸습니다';
    await _saveSession(user);
    return null;
  }

  static Future<String?> register(String username, String password) async {
    final u = username.trim();
    if (u.length < 3) return '아이디는 3자 이상이어야 합니다';
    if (password.length < 4) return '비밀번호는 4자 이상이어야 합니다';
    final existing = await DbHelper.instance.getUserByUsername(u);
    if (existing != null) return '이미 사용 중인 아이디입니다';
    final newUser = UserModel(username: u, passwordHash: _hash(password), createdAt: DateTime.now());
    final id = await DbHelper.instance.insertUser(newUser);
    await _saveSession(newUser.copyWith(id: id));
    return null;
  }

  static Future<void> logout() async {
    userNotifier.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefUserId);
  }

  static Future<void> _saveSession(UserModel user) async {
    userNotifier.value = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefUserId, user.id!);
  }

  static String _hash(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }
}
