import 'package:expense_manager/settings/widgets/settings_tile.dart';
import 'package:expense_manager/utils/constants.dart';
import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  final String name;
  final String studentId;
  final double monthlyBudget;
  final double dailyBudget;
  final double totalExpense;
  final String defaultCategory;
  final List<Map<String, dynamic>> categories;
  final List<Map<String, dynamic>> foods;
  final bool darkMode;
  final String themeColor;
  final bool dailyReminder;
  final bool budgetAlert;

  final void Function(String name, String studentId) onProfileSaved;
  final void Function(double monthlyBudget, double dailyBudget) onBudgetSaved;
  final void Function(String defaultCategory) onPreferencesChanged;
  final Future<void> Function(String name) onCategoryAdded;
  final Future<void> Function(int id) onCategoryDeleted;
  final Future<void> Function(String name, double price) onFoodAdded;
  final Future<void> Function(int id) onFoodDeleted;
  final void Function(bool darkMode, String themeColor) onAppearanceChanged;
  final void Function(Color color)? onThemeChanged;
  final void Function(bool dailyReminder, bool budgetAlert)
  onNotificationChanged;
  final Future<void> Function() onClearAllExpenses;

  const SettingsPage({
    super.key,
    required this.name,
    required this.studentId,
    required this.monthlyBudget,
    required this.dailyBudget,
    required this.totalExpense,
    required this.defaultCategory,
    required this.categories,
    required this.foods,
    required this.darkMode,
    required this.themeColor,
    required this.dailyReminder,
    required this.budgetAlert,
    required this.onProfileSaved,
    required this.onBudgetSaved,
    required this.onPreferencesChanged,
    required this.onCategoryAdded,
    required this.onCategoryDeleted,
    required this.onFoodAdded,
    required this.onFoodDeleted,
    required this.onAppearanceChanged,
    this.onThemeChanged,
    required this.onNotificationChanged,
    required this.onClearAllExpenses,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _categoryController;
  late final TextEditingController _foodNameController;
  late final TextEditingController _foodPriceController;

  late String _defaultCategory;
  late bool _darkMode;
  late String _themeColor;
  late bool _dailyReminder;
  late bool _budgetAlert;

  Color _themeColorToColor(String theme) {
    if (theme == 'Blue') return Colors.blue;
    if (theme == 'Purple') return Colors.purple;
    return Colors.green;
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String hint,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: colorScheme.primary.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: colorScheme.primary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
    );
  }

  Widget _inputCard(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _gradientButton({
    required VoidCallback onPressed,
    required String label,
    IconData? icon,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F2196F3),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: icon == null
          ? ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(label),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(icon, size: 18),
              label: Text(label),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
    _foodNameController = TextEditingController();
    _foodPriceController = TextEditingController();
    _defaultCategory = widget.defaultCategory;
    _darkMode = widget.darkMode;
    _themeColor = widget.themeColor;
    _dailyReminder = widget.dailyReminder;
    _budgetAlert = widget.budgetAlert;
  }

  @override
  void didUpdateWidget(covariant SettingsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.defaultCategory != widget.defaultCategory) {
      _defaultCategory = widget.defaultCategory;
    }
    if (oldWidget.darkMode != widget.darkMode) {
      _darkMode = widget.darkMode;
    }
    if (oldWidget.themeColor != widget.themeColor) {
      _themeColor = widget.themeColor;
    }
    if (oldWidget.dailyReminder != widget.dailyReminder) {
      _dailyReminder = widget.dailyReminder;
    }
    if (oldWidget.budgetAlert != widget.budgetAlert) {
      _budgetAlert = widget.budgetAlert;
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _foodNameController.dispose();
    _foodPriceController.dispose();
    super.dispose();
  }

  Future<void> _showBaseModal({
    required String title,
    required String subtitle,
    required Widget child,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        final colorScheme = Theme.of(modalContext).colorScheme;
        final textTheme = Theme.of(modalContext).textTheme;

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(modalContext).size.height * 0.82,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(title, style: textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(child: child),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEditProfileModal() async {
    final nameController = TextEditingController(text: widget.name);
    final studentIdController = TextEditingController(text: widget.studentId);

    await _showBaseModal(
      title: 'Edit Profile',
      subtitle: 'Update your name and student ID',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _inputCard(
              context,
              child: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: _inputDecoration(context, hint: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: studentIdController,
                    decoration: _inputDecoration(context, hint: 'Student ID'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: _gradientButton(
                onPressed: () {
                  final name = nameController.text.trim();
                  final studentId = studentIdController.text.trim();

                  if (name.isEmpty && studentId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter name or student ID'),
                      ),
                    );
                    return;
                  }

                  widget.onProfileSaved(name, studentId);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile saved')),
                  );
                },
                label: 'Save Profile',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBudgetModal() async {
    final monthlyController = TextEditingController(
      text: widget.monthlyBudget.toStringAsFixed(2),
    );
    final dailyController = TextEditingController(
      text: widget.dailyBudget.toStringAsFixed(2),
    );

    await _showBaseModal(
      title: 'Budget Settings',
      subtitle: 'Set monthly and daily spending limits',
      child: StatefulBuilder(
        builder: (context, modalSetState) {
          final monthly = double.tryParse(monthlyController.text.trim()) ?? 0;
          final remainingBudget = monthly - widget.totalExpense;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _inputCard(
                  context,
                  child: Column(
                    children: [
                      TextField(
                        controller: monthlyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => modalSetState(() {}),
                        decoration: _inputDecoration(
                          context,
                          hint: 'Monthly Budget',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: dailyController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(
                          context,
                          hint: 'Daily Budget',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Remaining Budget: ${remainingBudget.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _gradientButton(
                    onPressed: () {
                      final monthlyBudget =
                          double.tryParse(monthlyController.text.trim()) ?? 0;
                      final dailyBudget =
                          double.tryParse(dailyController.text.trim()) ?? 0;

                      widget.onBudgetSaved(monthlyBudget, dailyBudget);
                      if (!mounted) return;
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Budget saved')),
                      );
                    },
                    label: 'Save Budget',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showPreferencesModal() async {
    final categories = widget.categories
        .map((category) => (category['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();

    var selectedCategory = categories.contains(_defaultCategory)
        ? _defaultCategory
        : '';
    var selectedTheme = _themeColor;
    var selectedDarkMode = _darkMode;

    await _showBaseModal(
      title: 'App Preferences',
      subtitle: 'Choose your default category and app appearance',
      child: StatefulBuilder(
        builder: (context, modalSetState) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      if (categories.isEmpty)
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Add a category first to set default.'),
                        )
                      else
                        DropdownButtonFormField<String>(
                          key: ValueKey(
                            'pref-category-${categories.join('|')}-$selectedCategory',
                          ),
                          initialValue: selectedCategory.isEmpty
                              ? categories.first
                              : selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Default Category',
                          ),
                          items: categories
                              .map(
                                (item) => DropdownMenuItem(
                                  value: item,
                                  child: Text(item),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            modalSetState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        key: ValueKey('pref-theme-$selectedTheme'),
                        initialValue: selectedTheme,
                        decoration: const InputDecoration(
                          labelText: 'Theme Color',
                        ),
                        items: AppConstants.themeColors
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          modalSetState(() {
                            selectedTheme = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Dark mode'),
                        value: selectedDarkMode,
                        onChanged: (value) {
                          modalSetState(() {
                            selectedDarkMode = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _gradientButton(
                    onPressed: () {
                      if (categories.isNotEmpty &&
                          selectedCategory.isNotEmpty) {
                        widget.onPreferencesChanged(selectedCategory);
                      }

                      setState(() {
                        _defaultCategory = selectedCategory;
                        _themeColor = selectedTheme;
                        _darkMode = selectedDarkMode;
                      });

                      widget.onAppearanceChanged(_darkMode, _themeColor);
                      widget.onThemeChanged?.call(
                        _themeColorToColor(_themeColor),
                      );

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Preferences updated')),
                      );
                    },
                    label: 'Apply Preferences',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showNotificationsModal() async {
    var selectedDailyReminder = _dailyReminder;
    var selectedBudgetAlert = _budgetAlert;

    await _showBaseModal(
      title: 'Notifications',
      subtitle: 'Control reminder and budget alert preferences',
      child: StatefulBuilder(
        builder: (context, modalSetState) {
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Daily reminder'),
                        value: selectedDailyReminder,
                        onChanged: (value) {
                          modalSetState(() {
                            selectedDailyReminder = value;
                          });
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Budget alert'),
                        value: selectedBudgetAlert,
                        onChanged: (value) {
                          modalSetState(() {
                            selectedBudgetAlert = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: _gradientButton(
                    onPressed: () {
                      setState(() {
                        _dailyReminder = selectedDailyReminder;
                        _budgetAlert = selectedBudgetAlert;
                      });

                      widget.onNotificationChanged(
                        _dailyReminder,
                        _budgetAlert,
                      );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notifications updated')),
                      );
                    },
                    label: 'Apply Notifications',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _addCategory() async {
    final categoryName = _categoryController.text.trim();
    if (categoryName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }

    await widget.onCategoryAdded(categoryName);
    if (!mounted) return;

    setState(() {
      _categoryController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Category saved')));
  }

  Future<void> _addFood() async {
    final foodName = _foodNameController.text.trim();
    final foodPrice = double.tryParse(_foodPriceController.text.trim()) ?? 0;

    if (foodName.isEmpty || foodPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid food name and price')),
      );
      return;
    }

    await widget.onFoodAdded(foodName, foodPrice);
    if (!mounted) return;

    setState(() {
      _foodNameController.clear();
      _foodPriceController.clear();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Food item saved')));
  }

  Future<void> _confirmDeleteFood(Map<String, dynamic> food) async {
    final foodId = food['id'] as int;
    final foodName = (food['name'] as String?)?.trim() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Food Item'),
          content: Text('Delete "$foodName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.onFoodDeleted(foodId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Food item deleted')));
    }
  }

  Future<void> _showManageFoodsModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            final colorScheme = Theme.of(modalContext).colorScheme;
            final textTheme = Theme.of(modalContext).textTheme;
            final foods = widget.foods;
            const pastelPalette = [
              Color(0xFFA8E6CF),
              Color(0xFFAED9E0),
              Color(0xFFCBAACB),
              Color(0xFFFFF1B6),
              Color(0xFFFFCAD4),
            ];

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(modalContext).size.height * 0.82,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Food Items', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Add and manage food names with prices',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _inputCard(
                      modalContext,
                      child: Column(
                        children: [
                          TextField(
                            controller: _foodNameController,
                            decoration: _inputDecoration(
                              modalContext,
                              hint: 'Food name',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _foodPriceController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: _inputDecoration(
                                    modalContext,
                                    hint: 'Price',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                height: 48,
                                child: _gradientButton(
                                  onPressed: () async {
                                    await _addFood();
                                    modalSetState(() {});
                                  },
                                  label: 'Add',
                                  icon: Icons.add,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: foods.isEmpty
                            ? Container(
                                key: const ValueKey('empty-foods'),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'No food items yet. Add your first one.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                key: ValueKey(foods.length),
                                itemCount: foods.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final food = foods[index];
                                  final foodName =
                                      (food['name'] as String?)?.trim() ?? '';
                                  final foodPrice =
                                      (food['price'] as num?)?.toDouble() ?? 0;
                                  final chipColor =
                                      pastelPalette[index %
                                          pastelPalette.length];

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: chipColor.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 2,
                                          ),
                                      leading: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: chipColor.withValues(
                                            alpha: 0.85,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.restaurant_menu_rounded,
                                          size: 16,
                                          color: Color(0xFF2E3A43),
                                        ),
                                      ),
                                      title: Text(
                                        foodName,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Price: ${foodPrice.toStringAsFixed(2)}',
                                      ),
                                      trailing: IconButton(
                                        tooltip: 'Delete food',
                                        onPressed: () async {
                                          await _confirmDeleteFood(food);
                                          modalSetState(() {});
                                        },
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showManageCategoriesModal() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (modalContext, modalSetState) {
            final colorScheme = Theme.of(modalContext).colorScheme;
            final textTheme = Theme.of(modalContext).textTheme;
            final categories = widget.categories;
            const pastelPalette = [
              Color(0xFFA8E6CF),
              Color(0xFFAED9E0),
              Color(0xFFCBAACB),
              Color(0xFFFFF1B6),
              Color(0xFFFFCAD4),
            ];

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(modalContext).size.height * 0.82,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Categories', style: textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      'Add and manage your expense categories',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _inputCard(
                      modalContext,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _categoryController,
                              decoration: _inputDecoration(
                                modalContext,
                                hint: 'Category name',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 48,
                            child: _gradientButton(
                              onPressed: () async {
                                await _addCategory();
                                modalSetState(() {});
                              },
                              label: 'Add',
                              icon: Icons.add,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: categories.isEmpty
                            ? Container(
                                key: const ValueKey('empty-categories'),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withValues(
                                    alpha: 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  'No categories yet. Add your first one.',
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                key: ValueKey(categories.length),
                                itemCount: categories.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final category = categories[index];
                                  final categoryName =
                                      (category['name'] as String?)?.trim() ??
                                      '';
                                  final chipColor =
                                      pastelPalette[index %
                                          pastelPalette.length];

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: chipColor.withValues(alpha: 0.45),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 2,
                                          ),
                                      leading: Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: chipColor.withValues(
                                            alpha: 0.85,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.label_rounded,
                                          size: 16,
                                          color: Color(0xFF2E3A43),
                                        ),
                                      ),
                                      title: Text(
                                        categoryName,
                                        style: textTheme.titleSmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        tooltip: 'Delete category',
                                        onPressed: () async {
                                          await _confirmDeleteCategory(
                                            category,
                                          );
                                          modalSetState(() {});
                                        },
                                        icon: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 20,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteCategory(Map<String, dynamic> category) async {
    final categoryId = category['id'] as int;
    final categoryName = (category['name'] as String?)?.trim() ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text('Delete "$categoryName"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await widget.onCategoryDeleted(categoryId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Category deleted')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final displayName = widget.name.trim().isEmpty ? 'Guest User' : widget.name;
    final displayStudentId = widget.studentId.trim().isEmpty
        ? 'No Student ID'
        : widget.studentId;
    final budgetSubtitle =
        'Monthly ${widget.monthlyBudget.toStringAsFixed(0)} • Daily ${widget.dailyBudget.toStringAsFixed(0)}';
    final preferenceSubtitle =
        'Default ${_defaultCategory.isEmpty ? 'None' : _defaultCategory} • Theme $_themeColor';
    final notificationSubtitle =
        'Reminder ${_dailyReminder ? 'On' : 'Off'} • Alert ${_budgetAlert ? 'On' : 'Off'}';

    return Scaffold(
      appBar: AppBar(title: const Text('Settings Page')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.person, color: colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayStudentId,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Edit profile',
                    onPressed: _showEditProfileModal,
                    icon: const Icon(Icons.edit_rounded),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.account_balance_wallet_rounded,
            title: 'Budget Settings',
            subtitle: budgetSubtitle,
            onTap: _showBudgetModal,
          ),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.tune_rounded,
            title: 'App Preferences',
            subtitle: preferenceSubtitle,
            onTap: _showPreferencesModal,
          ),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.notifications_active_rounded,
            title: 'Notifications',
            subtitle: notificationSubtitle,
            onTap: _showNotificationsModal,
          ),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.category_rounded,
            title: 'Manage Categories',
            subtitle: 'Add, edit, remove categories',
            onTap: _showManageCategoriesModal,
          ),
          const SizedBox(height: 12),
          SettingsTile(
            icon: Icons.restaurant_menu_rounded,
            title: 'Manage Food Items',
            subtitle: 'Add food names and prices',
            onTap: _showManageFoodsModal,
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1.5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Expense Manager',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Version 1.0.0',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Developer: Student Project',
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'A clean and simple expense tracker for student budgeting.',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
