import 'package:expense_manager/home/model/expense_model.dart';
import 'package:expense_manager/home/widgets/dashboard_card.dart';
import 'package:expense_manager/home/widgets/expense_card.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  final List<Expense> expenses;
  final String currency;
  final String defaultCategory;
  final List<Map<String, dynamic>> categories;
  final double totalMonthlyExpense;
  final double todayExpense;
  final double monthlyBudget;
  final double dailyBudget;
  final Future<void> Function(Expense expense) onExpenseAdded;
  final Future<void> Function(Expense expense) onExpenseUpdated;
  final Future<void> Function(int id) onExpenseDeleted;

  const HomePage({
    super.key,
    required this.expenses,
    required this.currency,
    required this.defaultCategory,
    required this.categories,
    required this.totalMonthlyExpense,
    required this.todayExpense,
    required this.monthlyBudget,
    required this.dailyBudget,
    required this.onExpenseAdded,
    required this.onExpenseUpdated,
    required this.onExpenseDeleted,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
    required String text,
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
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 13),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text),
      ),
    );
  }

  Future<void> _showExpenseForm({Expense? existingExpense}) async {
    final isEdit = existingExpense != null;
    final availableCategories = widget.categories
        .map((category) => (category['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toList();
    final dropdownCategories = List<String>.from(availableCategories);
    final existingCategory = existingExpense?.category.trim() ?? '';
    if (isEdit &&
        existingCategory.isNotEmpty &&
        !dropdownCategories.contains(existingCategory)) {
      dropdownCategories.insert(0, existingCategory);
    }

    final titleController = TextEditingController(
      text: existingExpense?.title ?? '',
    );
    final amountController = TextEditingController(
      text: existingExpense == null ? '' : existingExpense.amount.toString(),
    );
    String? selectedCategory = isEdit
        ? (existingCategory.isNotEmpty
              ? existingCategory
              : (dropdownCategories.isNotEmpty
                    ? dropdownCategories.first
                    : null))
        : (widget.defaultCategory.isNotEmpty &&
                  dropdownCategories.contains(widget.defaultCategory)
              ? widget.defaultCategory
              : (dropdownCategories.isNotEmpty
                    ? dropdownCategories.first
                    : null));
    DateTime selectedDate = existingExpense?.date ?? DateTime.now();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit ? 'Edit Expense' : 'Add Expense',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: 12),
                    _inputCard(
                      context,
                      child: TextField(
                        controller: titleController,
                        decoration: _inputDecoration(context, hint: 'Title'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _inputCard(
                      context,
                      child: TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: _inputDecoration(context, hint: 'Amount'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (dropdownCategories.isEmpty)
                      Card(
                        color: Theme.of(context).cardColor,
                        child: const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('Add a category in Settings first.'),
                        ),
                      )
                    else
                      _inputCard(
                        context,
                        child: DropdownButtonFormField<String>(
                          key: ValueKey(
                            'expense-category-${dropdownCategories.join('|')}-$selectedCategory',
                          ),
                          initialValue: selectedCategory,
                          decoration: _inputDecoration(
                            context,
                            hint: 'Category',
                          ),
                          items: dropdownCategories
                              .map(
                                (category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setModalState(() {
                              selectedCategory = value;
                            });
                          },
                        ),
                      ),
                    const SizedBox(height: 12),
                    ListTile(
                      tileColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      title: const Text('Date'),
                      subtitle: Text(
                        '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        setModalState(() {
                          selectedDate = picked;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: _gradientButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(context);
                          final title = titleController.text.trim();
                          final amount =
                              double.tryParse(amountController.text.trim()) ??
                              0;

                          if (title.isEmpty ||
                              amount <= 0 ||
                              selectedCategory == null ||
                              selectedCategory!.isEmpty) {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter valid title, amount and category',
                                ),
                              ),
                            );
                            return;
                          }

                          if (isEdit) {
                            await widget.onExpenseUpdated(
                              Expense(
                                id: existingExpense.id,
                                title: title,
                                amount: amount,
                                category: selectedCategory!,
                                date: selectedDate,
                              ),
                            );
                          } else {
                            await widget.onExpenseAdded(
                              Expense(
                                title: title,
                                amount: amount,
                                category: selectedCategory!,
                                date: selectedDate,
                              ),
                            );
                          }

                          if (!mounted) return;
                          navigator.pop();
                        },
                        text: isEdit ? 'Update Expense' : 'Save Expense',
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

  Future<void> _confirmAndDeleteExpense(Expense expense) async {
    if (expense.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense?'),
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
      await widget.onExpenseDeleted(expense.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final monthlyLimit = widget.monthlyBudget > 0
        ? widget.monthlyBudget
        : (widget.totalMonthlyExpense > 0 ? widget.totalMonthlyExpense : 1.0);
    final dailyLimit = widget.dailyBudget > 0
        ? widget.dailyBudget
        : (widget.todayExpense > 0 ? widget.todayExpense : 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Home Page')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TopProgressSection(
            currency: widget.currency,
            monthlySpent: widget.totalMonthlyExpense,
            monthlyLimit: monthlyLimit,
            dailySpent: widget.todayExpense,
            dailyLimit: dailyLimit,
          ),
          const SizedBox(height: 12),
          DashboardCard(
            currency: widget.currency,
            totalMonthlyExpense: widget.totalMonthlyExpense,
            todayExpense: widget.todayExpense,
          ),
          const SizedBox(height: 12),
          Text('Expense List', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          if (widget.expenses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('No expense found. Add one using + button.'),
              ),
            ),
          ...widget.expenses.map(
            (expense) => ExpenseCard(
              expense: expense,
              currency: widget.currency,
              onEdit: () => _showExpenseForm(existingExpense: expense),
              onDelete: () => _confirmAndDeleteExpense(expense),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showExpenseForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TopProgressSection extends StatelessWidget {
  final String currency;
  final double monthlySpent;
  final double monthlyLimit;
  final double dailySpent;
  final double dailyLimit;

  const _TopProgressSection({
    required this.currency,
    required this.monthlySpent,
    required this.monthlyLimit,
    required this.dailySpent,
    required this.dailyLimit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ProgressCard(
            title: 'Monthly',
            subtitle: 'Spent / Budget',
            spent: monthlySpent,
            limit: monthlyLimit,
            currency: currency,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ProgressCard(
            title: 'Daily',
            subtitle: 'Spent / Limit',
            spent: dailySpent,
            limit: dailyLimit,
            currency: currency,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final double spent;
  final double limit;
  final String currency;

  const _ProgressCard({
    required this.title,
    required this.subtitle,
    required this.spent,
    required this.limit,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final progress = (limit <= 0 ? 0.0 : (spent / limit))
        .clamp(0.0, 1.0)
        .toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, animatedProgress, _) {
              return SizedBox(
                width: 104,
                height: 104,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(104, 104),
                      painter: _GradientCircularProgressPainter(
                        progress: animatedProgress,
                        trackColor: colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$currency ${spent.toStringAsFixed(0)} / ${limit.toStringAsFixed(0)}',
                            textAlign: TextAlign.center,
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _GradientCircularProgressPainter extends CustomPainter {
  final double progress;
  final Color trackColor;

  const _GradientCircularProgressPainter({
    required this.progress,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 9.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, 2 * math.pi, false, trackPaint);

    final progressPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: math.pi * 3 / 2,
        colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweep = 2 * math.pi * progress;
    if (sweep > 0) {
      canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GradientCircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor;
  }
}
