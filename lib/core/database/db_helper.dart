import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../models/user_model.dart';

class DbHelper {
  static final DbHelper instance = DbHelper._();
  static Database? _db;

  DbHelper._();

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'chatbudget.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 0,
        amount INTEGER NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        date TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE savings_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 0,
        title TEXT NOT NULL,
        target_amount INTEGER NOT NULL,
        current_amount INTEGER DEFAULT 0,
        deadline TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS users (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          username TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      try {
        await db.execute('ALTER TABLE transactions ADD COLUMN user_id INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE savings_goals ADD COLUMN user_id INTEGER NOT NULL DEFAULT 0');
      } catch (_) {}
    }
  }

  // ── Users ──────────────────────────────────────────────────

  Future<int> insertUser(UserModel u) async {
    final database = await db;
    return database.insert('users', u.toMap()..remove('id'));
  }

  Future<UserModel?> getUserByUsername(String username) async {
    final database = await db;
    final rows = await database.query('users', where: 'username = ?', whereArgs: [username]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<UserModel?> getUserById(int id) async {
    final database = await db;
    final rows = await database.query('users', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  // ── Transactions ──────────────────────────────────────────

  Future<int> insertTransaction(TransactionModel t) async {
    final database = await db;
    return database.insert('transactions', t.toMap()..remove('id'));
  }

  Future<List<TransactionModel>> getTransactions({required int userId}) async {
    final database = await db;
    final rows = await database.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(int year, int month, {required int userId}) async {
    final database = await db;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final rows = await database.query(
      'transactions',
      where: 'user_id = ? AND date >= ? AND date < ?',
      whereArgs: [userId, start, end],
      orderBy: 'date DESC',
    );
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<void> deleteTransaction(int id) async {
    final database = await db;
    await database.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateTransaction(TransactionModel t) async {
    final database = await db;
    await database.update('transactions', t.toMap(), where: 'id = ?', whereArgs: [t.id]);
  }

  // ── Savings Goals ─────────────────────────────────────────

  Future<int> insertSavingsGoal(SavingsGoalModel g) async {
    final database = await db;
    return database.insert('savings_goals', g.toMap()..remove('id'));
  }

  Future<List<SavingsGoalModel>> getSavingsGoals({required int userId}) async {
    final database = await db;
    final rows = await database.query(
      'savings_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
    return rows.map(SavingsGoalModel.fromMap).toList();
  }

  Future<void> updateSavingsGoal(SavingsGoalModel g) async {
    final database = await db;
    await database.update('savings_goals', g.toMap(), where: 'id = ?', whereArgs: [g.id]);
  }

  Future<void> deleteSavingsGoal(int id) async {
    final database = await db;
    await database.delete('savings_goals', where: 'id = ?', whereArgs: [id]);
  }
}
