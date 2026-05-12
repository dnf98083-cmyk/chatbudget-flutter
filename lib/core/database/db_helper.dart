import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/transaction_model.dart';
import '../models/savings_goal_model.dart';

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
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        title TEXT NOT NULL,
        target_amount INTEGER NOT NULL,
        current_amount INTEGER DEFAULT 0,
        deadline TEXT
      )
    ''');
  }

  // ── Transactions ──────────────────────────────────────────

  Future<int> insertTransaction(TransactionModel t) async {
    final database = await db;
    return database.insert('transactions', t.toMap()..remove('id'));
  }

  Future<List<TransactionModel>> getTransactions() async {
    final database = await db;
    final rows = await database.query('transactions', orderBy: 'date DESC');
    return rows.map(TransactionModel.fromMap).toList();
  }

  Future<List<TransactionModel>> getTransactionsByMonth(int year, int month) async {
    final database = await db;
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final rows = await database.query(
      'transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
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

  Future<List<SavingsGoalModel>> getSavingsGoals() async {
    final database = await db;
    final rows = await database.query('savings_goals', orderBy: 'id DESC');
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
