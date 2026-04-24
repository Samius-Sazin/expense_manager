import 'package:expense_manager/analytics/ui/analytics_page.dart';
import 'package:expense_manager/database/db_helper.dart';
import 'package:expense_manager/home/model/expense_model.dart';
import 'package:expense_manager/home/ui/home_page.dart';
import 'package:expense_manager/settings/ui/settings_page.dart';
import 'package:expense_manager/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const Color _secondaryBlue = Color(0xFF2196F3);
const Color _backgroundColor = Color(0xFFF8FAFC);
const Color _cardColor = Color(0xFFFFFFFF);
const Color _darkBackgroundColor = Color(0xFF121212);
const Color _darkCardColor = Color(0xFF1E1E1E);
const Color _textPrimary = Color(0xFF1F2937);
const Color _textSecondary = Color(0xFF6B7280);
const Color _accentColor = Color(0xFF10B981);
const Color _errorColor = Color(0xFFEF4444);

void main() {
  runApp(const ExpenseManagerApp());
}

class ExpenseManagerApp extends StatefulWidget {
  const ExpenseManagerApp({super.key});

  @override
  State<ExpenseManagerApp> createState() => _ExpenseManagerAppState();
}

class _ExpenseManagerAppState extends State<ExpenseManagerApp> {
  int _currentIndex = 0;
  List<Expense> _expenses = [];
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _foods = [];
  Color _primaryColor = Colors.green;

  String _name = '';
  String _studentId = '';
  double _monthlyBudget = 0;
  double _dailyBudget = 0;
  String _defaultCategory = '';
  final String _currency = AppConstants.currencies.first;
  bool _darkMode = false;
  String _themeColor = AppConstants.themeColors.first;
  bool _dailyReminder = false;
  bool _budgetAlert = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await _loadProfile();
    await _loadCategories();
    await _loadFoods();
    await _loadExpenses();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final studentId = prefs.getString('student_id') ?? '';
    if (!mounted) return;
    setState(() {
      _name = name;
      _studentId = studentId;
    });
  }

  Future<void> _saveProfile(String name, String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', name);
    await prefs.setString('student_id', studentId);
  }

  Future<void> _loadExpenses() async {
    final data = await DBHelper.instance.getAllExpenseModels();
    if (!mounted) return;
    setState(() {
      _expenses = data;
    });
  }

  Future<void> _loadCategories() async {
    final data = await DBHelper.instance.getAllCategories();
    if (!mounted) return;

    final categoryNames = data
        .map((category) => (category['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    setState(() {
      _categories = data;
      if (categoryNames.isEmpty) {
        _defaultCategory = '';
      } else if (_defaultCategory.isEmpty ||
          !categoryNames.contains(_defaultCategory)) {
        _defaultCategory = categoryNames.first;
      }
    });
  }

  Future<void> _loadFoods() async {
    final data = await DBHelper.instance.getAllFoods();
    if (!mounted) return;
    setState(() {
      _foods = data;
    });
  }

  Future<void> _addExpense(Expense expense) async {
    await DBHelper.instance.insertExpenseModel(expense);
    await _loadExpenses();
  }

  Future<void> _addCategory(String name) async {
    await DBHelper.instance.insertCategory(name);
    await _loadCategories();
  }

  Future<void> _deleteCategory(int id) async {
    await DBHelper.instance.deleteCategory(id);
    await _loadCategories();
  }

  Future<void> _addFood(String name, double price) async {
    await DBHelper.instance.insertFood(name, price);
    await _loadFoods();
  }

  Future<void> _deleteFood(int id) async {
    await DBHelper.instance.deleteFood(id);
    await _loadFoods();
  }

  Future<void> _updateExpense(Expense expense) async {
    await DBHelper.instance.updateExpenseModel(expense);
    await _loadExpenses();
  }

  Future<void> _deleteExpense(int id) async {
    await DBHelper.instance.deleteExpenseModel(id);
    await _loadExpenses();
  }

  Future<void> _clearAllExpenses() async {
    await DBHelper.instance.deleteAllExpenses();
    if (!mounted) return;
    setState(() {
      _expenses = [];
    });
    await _loadExpenses();
  }

  double get _totalMonthlyExpense {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  double get _todayExpense {
    final now = DateTime.now();
    return _expenses
        .where(
          (e) =>
              e.date.year == now.year &&
              e.date.month == now.month &&
              e.date.day == now.day,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Manager',
      themeMode: _darkMode ? ThemeMode.dark : ThemeMode.light,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomePage(
              expenses: _expenses,
              currency: _currency,
              defaultCategory: _defaultCategory,
              categories: _categories,
              totalMonthlyExpense: _totalMonthlyExpense,
              todayExpense: _todayExpense,
              monthlyBudget: _monthlyBudget,
              dailyBudget: _dailyBudget,
              onExpenseAdded: _addExpense,
              onExpenseUpdated: _updateExpense,
              onExpenseDeleted: _deleteExpense,
            ),
            AnalyticsPage(
              expenses: _expenses,
              foods: _foods,
              currency: _currency,
            ),
            SettingsPage(
              name: _name,
              studentId: _studentId,
              monthlyBudget: _monthlyBudget,
              dailyBudget: _dailyBudget,
              totalExpense: _totalMonthlyExpense,
              defaultCategory: _defaultCategory,
              categories: _categories,
              foods: _foods,
              darkMode: _darkMode,
              themeColor: _themeColor,
              dailyReminder: _dailyReminder,
              budgetAlert: _budgetAlert,
              onProfileSaved: (name, studentId) {
                setState(() {
                  _name = name;
                  _studentId = studentId;
                });
                _saveProfile(name, studentId);
              },
              onBudgetSaved: (monthlyBudget, dailyBudget) {
                setState(() {
                  _monthlyBudget = monthlyBudget;
                  _dailyBudget = dailyBudget;
                });
              },
              onPreferencesChanged: (defaultCategory) {
                setState(() {
                  _defaultCategory = defaultCategory;
                });
              },
              onCategoryAdded: _addCategory,
              onCategoryDeleted: _deleteCategory,
              onFoodAdded: _addFood,
              onFoodDeleted: _deleteFood,
              onAppearanceChanged: (darkMode, themeColor) {
                setState(() {
                  _darkMode = darkMode;
                  _themeColor = themeColor;
                });
              },
              onThemeChanged: (Color newColor) {
                setState(() {
                  _primaryColor = newColor;
                });
              },
              onNotificationChanged: (dailyReminder, budgetAlert) {
                setState(() {
                  _dailyReminder = dailyReminder;
                  _budgetAlert = budgetAlert;
                });
              },
              onClearAllExpenses: _clearAllExpenses,
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.light,
        ).copyWith(
          secondary: _secondaryBlue,
          tertiary: _accentColor,
          surface: _cardColor,
          error: _errorColor,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _backgroundColor,
      cardColor: _cardColor,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: _cardColor,
        foregroundColor: _textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: _cardColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerColor: _textSecondary.withValues(alpha: 0.22),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: _textPrimary, fontWeight: FontWeight.w700),
        titleMedium: TextStyle(
          color: _textPrimary,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: _textPrimary),
        bodyMedium: TextStyle(color: _textSecondary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: colorScheme.onPrimary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _primaryColor,
        unselectedItemColor: _textSecondary,
        backgroundColor: _cardColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: _primaryColor,
          brightness: Brightness.dark,
        ).copyWith(
          secondary: _secondaryBlue,
          tertiary: _accentColor,
          surface: _darkCardColor,
          error: _errorColor,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackgroundColor,
      cardColor: _darkCardColor,
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        backgroundColor: _darkCardColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
      cardTheme: CardThemeData(
        color: _darkCardColor,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dividerColor: colorScheme.outline.withValues(alpha: 0.3),
      textTheme: TextTheme(
        titleLarge: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: colorScheme.onSurface),
        bodyMedium: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: colorScheme.onPrimary,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        selectedItemColor: _primaryColor,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        backgroundColor: _darkCardColor,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
