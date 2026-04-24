import 'package:expense_manager/home/model/expense_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  DBHelper._();

  static final DBHelper instance = DBHelper._();
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'expense_manager.db');

    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createCategoryTable(db);
          await _seedCategoriesFromExpenses(db);
        }
        if (oldVersion < 3) {
          await _createFoodTable(db);
        }
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        amount REAL,
        category TEXT,
        date TEXT
      )
    ''');

    await _createCategoryTable(db);
    await _createFoodTable(db);
  }

  Future<void> _createCategoryTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT
      )
    ''');
  }

  Future<void> _createFoodTable(Database db) async {
    await db.execute('''
      CREATE TABLE foods(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        price REAL
      )
    ''');
  }

  Future<void> _seedCategoriesFromExpenses(Database db) async {
    final categories = await db.rawQuery('''
      SELECT DISTINCT category
      FROM expenses
      WHERE category IS NOT NULL AND TRIM(category) <> ''
      ORDER BY category ASC
    ''');

    for (final row in categories) {
      final categoryName = (row['category'] as String?)?.trim();
      if (categoryName == null || categoryName.isEmpty) continue;

      await db.insert('categories', {'name': categoryName});
    }
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('expenses', expense);
  }

  Future<int> insertCategory(String name) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 0;

    final db = await database;
    final existing = await db.query(
      'categories',
      columns: ['id'],
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [trimmedName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await db.insert('categories', {'name': trimmedName});
  }

  Future<List<Map<String, dynamic>>> getAllCategories() async {
    final db = await database;
    return await db.query('categories', orderBy: 'name ASC, id ASC');
  }

  Future<int> insertFood(String name, double price) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty || price <= 0) return 0;

    final db = await database;
    final existing = await db.query(
      'foods',
      columns: ['id'],
      where: 'LOWER(name) = LOWER(?)',
      whereArgs: [trimmedName],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      return existing.first['id'] as int;
    }

    return await db.insert('foods', {'name': trimmedName, 'price': price});
  }

  Future<List<Map<String, dynamic>>> getAllFoods() async {
    final db = await database;
    return await db.query('foods', orderBy: 'name ASC, id ASC');
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await database;
    return await db.query('expenses', orderBy: 'id DESC');
  }

  Future<double> getTotalExpense() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses',
    );

    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  Future<double> getTodayExpense() async {
    final db = await database;
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    final result = await db.rawQuery(
      'SELECT SUM(amount) AS total FROM expenses WHERE substr(date, 1, 10) = ?',
      [today],
    );

    final total = result.first['total'];
    return total == null ? 0.0 : (total as num).toDouble();
  }

  Future<int> deleteAllExpenses() async {
    final db = await database;
    return await db.delete('expenses');
  }

  Future<int> updateExpense(int id, Map<String, dynamic> updatedData) async {
    final db = await database;
    return await db.update(
      'expenses',
      updatedData,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteFood(int id) async {
    final db = await database;
    return await db.delete('foods', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> insertExpenseModel(Expense expense) async {
    final map = expense.toMap();
    map.remove('id');
    return insertExpense(map);
  }

  Future<List<Expense>> getAllExpenseModels() async {
    final result = await getAllExpenses();
    return result.map(Expense.fromMap).toList();
  }

  Future<int> updateExpenseModel(Expense expense) async {
    if (expense.id == null) return 0;
    final map = expense.toMap();
    map.remove('id');
    return updateExpense(expense.id!, map);
  }

  Future<int> deleteExpenseModel(int id) async {
    return deleteExpense(id);
  }

  Future<void> seedDummyExpensesIfNeeded() async {
    return;
  }
}
