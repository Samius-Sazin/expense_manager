import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  DatabaseHelper._internal();

  static final DatabaseHelper instance = DatabaseHelper._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'expense_manager.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE expenses(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            amount REAL,
            category TEXT,
            date TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await database;
    return db.query('expenses', orderBy: 'date DESC, id DESC');
  }

  Future<double> getTotalExpense() async {
    final db = await database;
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses WHERE date >= ? AND date < ?',
      [startOfMonth, endOfMonth],
    );

    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  Future<double> getTodayExpense() async {
    final db = await database;
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
    final endOfDay = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ).toIso8601String();

    final result = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses WHERE date >= ? AND date < ?',
      [startOfDay, endOfDay],
    );

    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  Future<int> deleteAllExpenses() async {
    final db = await database;
    return db.delete('expenses');
  }

  Future<void> seedDummyExpensesIfNeeded() async {
    return;
  }
}
