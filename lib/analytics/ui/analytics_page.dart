import 'dart:convert';

import 'package:expense_manager/analytics/data/meal_planner_service.dart';
import 'package:expense_manager/analytics/widgets/analytics_item.dart';
import 'package:expense_manager/home/model/expense_model.dart';
import 'package:expense_manager/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnalyticsPage extends StatefulWidget {
  final List<Expense> expenses;
  final List<Map<String, dynamic>> foods;
  final String currency;

  const AnalyticsPage({
    super.key,
    required this.expenses,
    required this.foods,
    required this.currency,
  });

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

enum _BudgetType { perMeal, daily, weekly, monthly, custom }

class _AnalyticsPageState extends State<AnalyticsPage> {
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _customDurationController = TextEditingController(
    text: '7',
  );
  final GeminiService _geminiService = const GeminiService();
  final MealPlannerService _mealPlannerService = const MealPlannerService();

  _BudgetType? _budgetType;
  int _customDurationDays = 7;
  String _eatingLevel = 'Medium';
  final List<String> _selectedMealTypes = ['Breakfast', 'Lunch', 'Dinner'];
  bool _isGenerating = false;
  String? _plannerError;
  List<MealPlan> _mealPlans = const [];

  static const List<String> _mealTypeOptions = [
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Tea',
  ];

  static const List<Color> _pastelColors = [
    Color(0xFFA8E6CF),
    Color(0xFFAED9E0),
    Color(0xFFCBAACB),
    Color(0xFFFFF1B6),
    Color(0xFFFFCAD4),
  ];

  @override
  void dispose() {
    _budgetController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  int _mealsPerDayFromSelection() => _selectedMealTypes.length;

  int _resolvedDurationDays() {
    switch (_budgetType) {
      case _BudgetType.perMeal:
        return 1;
      case _BudgetType.daily:
        return 1;
      case _BudgetType.weekly:
        return 7;
      case _BudgetType.monthly:
        return 30;
      case _BudgetType.custom:
        return _customDurationDays;
      case null:
        return 0;
    }
  }

  double _resolvedTotalBudget(double enteredBudget) {
    final durationDays = _resolvedDurationDays();
    if (durationDays <= 0 || enteredBudget <= 0) return 0;

    if (_budgetType == _BudgetType.perMeal) {
      final mealsPerDay = _mealsPerDayFromSelection();
      return enteredBudget * mealsPerDay * durationDays;
    }

    return enteredBudget;
  }

  double _resolvedBudgetPerDay(double enteredBudget) {
    final durationDays = _resolvedDurationDays();
    final totalBudget = _resolvedTotalBudget(enteredBudget);
    if (durationDays <= 0 || totalBudget <= 0) return 0;
    return totalBudget / durationDays;
  }

  String _budgetTypeLabel(_BudgetType? type) {
    switch (type) {
      case _BudgetType.perMeal:
        return 'Per Meal Budget';
      case _BudgetType.daily:
        return 'Daily Budget';
      case _BudgetType.weekly:
        return 'Weekly Budget (7 days)';
      case _BudgetType.monthly:
        return 'Monthly Budget (30 days)';
      case _BudgetType.custom:
        return 'Custom Duration Budget';
      case null:
        return 'Select budget type';
    }
  }

  String _budgetHelperText(_BudgetType? type) {
    switch (type) {
      case _BudgetType.perMeal:
        return 'Budget applies to each meal slot';
      case _BudgetType.daily:
        return 'Budget applies to 1 day';
      case _BudgetType.weekly:
        return 'Budget is distributed across 7 days';
      case _BudgetType.monthly:
        return 'Budget is distributed across 30 days';
      case _BudgetType.custom:
        return 'Budget is distributed across the selected duration';
      case null:
        return 'Choose how the budget should be applied';
    }
  }

  String _budgetInputHint(_BudgetType? type) {
    switch (type) {
      case _BudgetType.perMeal:
        return 'Enter budget for each meal (e.g. 50 per meal)';
      case _BudgetType.daily:
        return 'Enter total budget for 1 day (e.g. 300 per day)';
      case _BudgetType.weekly:
        return 'Enter total budget for 7 days (e.g. 2000 for a week)';
      case _BudgetType.monthly:
        return 'Enter total budget for 30 days (e.g. 8000 for a month)';
      case _BudgetType.custom:
        return 'Enter total budget for selected duration';
      case null:
        return 'Select budget type first';
    }
  }

  bool _containsAny(String value, List<String> keywords) {
    return keywords.any(value.contains);
  }

  String _fallbackFoodType(String foodName) {
    final name = foodName.toLowerCase();
    if (_containsAny(name, ['juice', 'mojo', 'tea', 'coffee'])) {
      return 'drink';
    }
    if (_containsAny(name, ['chips', 'biscuit'])) {
      return 'snack';
    }
    if (_containsAny(name, ['rice', 'roti'])) {
      return 'staple';
    }
    if (_containsAny(name, ['egg', 'chicken', 'fish', 'meat', 'dal'])) {
      return 'protein';
    }
    return 'vegetable';
  }

  String _normalizeFoodType(String? type, String foodName) {
    final normalized = type?.trim().toLowerCase();
    const valid = {'staple', 'protein', 'vegetable', 'drink', 'snack'};
    if (normalized != null && valid.contains(normalized)) {
      return normalized;
    }
    return _fallbackFoodType(foodName);
  }

  Future<Map<String, String>> _classifyFoods(
    List<Map<String, dynamic>> foods,
  ) async {
    final names = foods
        .map((food) => (food['name'] as String?)?.trim() ?? '')
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    final aiTypes = await _geminiService.classifyFoods(names);
    final resolved = <String, String>{};
    for (final name in names) {
      final key = name.toLowerCase();
      resolved[key] = _normalizeFoodType(aiTypes[key], name);
    }
    return resolved;
  }

  List<Map<String, dynamic>> _filterFoodsForMealTypes({
    required List<Map<String, dynamic>> foods,
    required List<String> mealTypes,
    required Map<String, String> foodTypes,
  }) {
    final normalizedMeals = mealTypes.map((type) => type.toLowerCase()).toSet();
    final needsMainMeals =
        normalizedMeals.contains('lunch') || normalizedMeals.contains('dinner');
    final needsBreakfast = normalizedMeals.contains('breakfast');
    final needsSnackTea =
        normalizedMeals.contains('snacks') || normalizedMeals.contains('tea');

    final allowedTypes = <String>{};
    if (needsMainMeals) {
      allowedTypes.addAll({'staple', 'protein', 'vegetable'});
    }
    if (needsBreakfast) {
      allowedTypes.addAll({'staple', 'protein', 'drink', 'snack'});
    }
    if (needsSnackTea) {
      allowedTypes.addAll({'drink', 'snack'});
    }

    if (allowedTypes.isEmpty) {
      allowedTypes.addAll({'staple', 'protein', 'vegetable', 'drink', 'snack'});
    }

    final filtered = foods.where((food) {
      final name = ((food['name'] as String?) ?? '').trim();
      if (name.isEmpty) return false;
      final type = _normalizeFoodType(foodTypes[name.toLowerCase()], name);
      return allowedTypes.contains(type);
    }).toList();

    return filtered.isEmpty ? foods : filtered;
  }

  Future<void> _generatePlans() async {
    final budgetText = _budgetController.text.trim();
    final enteredBudget = double.tryParse(budgetText) ?? 0;
    final durationDays = _resolvedDurationDays();
    final totalBudget = _resolvedTotalBudget(enteredBudget);
    final budgetPerDay = _resolvedBudgetPerDay(enteredBudget);

    if (_budgetType == null) {
      setState(() {
        _plannerError = 'Please select a budget type';
      });
      return;
    }

    if (budgetText.isEmpty) {
      setState(() {
        _plannerError = 'Please enter a budget value';
      });
      return;
    }

    if (double.tryParse(budgetText) == null) {
      setState(() {
        _plannerError = 'Budget must be numeric only';
      });
      return;
    }

    if (enteredBudget <= 0) {
      setState(() {
        _plannerError = 'Please enter a budget greater than 0';
      });
      return;
    }

    if (_selectedMealTypes.isEmpty) {
      setState(() {
        _plannerError = 'Please select at least one meal type';
      });
      return;
    }

    if (durationDays <= 0) {
      setState(() {
        _plannerError = 'Please select a valid duration';
      });
      return;
    }

    if (_budgetType == _BudgetType.custom && _customDurationDays <= 0) {
      setState(() {
        _plannerError = 'Please enter a custom duration greater than 0';
      });
      return;
    }

    if (widget.foods.isEmpty) {
      setState(() {
        _plannerError = 'Please add food items in Settings first';
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _plannerError = null;
      _mealPlans = const [];
    });

    try {
      final foodTypes = await _classifyFoods(widget.foods);
      final filteredFoods = _filterFoodsForMealTypes(
        foods: widget.foods,
        mealTypes: _selectedMealTypes,
        foodTypes: foodTypes,
      );

      if (filteredFoods.isEmpty) {
        setState(() {
          _plannerError = 'No valid foods found for selected meal types';
        });
        return;
      }

      final prompt = _buildPrompt(
        foods: filteredFoods,
        foodTypes: foodTypes,
        budget: totalBudget,
        durationDays: durationDays,
        budgetPerDay: budgetPerDay,
        mealTypes: _selectedMealTypes,
        eatingLevel: _eatingLevel,
        budgetType: _budgetType!,
      );

      final resultText = await _geminiService.generateMealPlan(prompt);

      if (!mounted) return;
      final parsedPlans = _parsePlansFromText(resultText);

      if (parsedPlans.isNotEmpty) {
        setState(() {
          _mealPlans = parsedPlans;
          _plannerError = null;
        });
        return;
      }

      final fallbackPlans = await _mealPlannerService.generatePlans(
        foods: filteredFoods,
        foodTypes: foodTypes,
        budget: totalBudget,
        durationDays: durationDays,
        mealTypes: _selectedMealTypes,
        eatingLevel: _eatingLevel,
      );

      setState(() {
        _mealPlans = fallbackPlans;
        _plannerError = fallbackPlans.isEmpty
            ? 'Unable to generate plans right now. Try again.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _plannerError = 'Failed to generate plan. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  String _buildPrompt({
    required List<Map<String, dynamic>> foods,
    required Map<String, String> foodTypes,
    required double budget,
    required int durationDays,
    required double budgetPerDay,
    required List<String> mealTypes,
    required String eatingLevel,
    required _BudgetType budgetType,
  }) {
    final foodLines = foods
        .map((food) {
          final name = (food['name'] as String?)?.trim() ?? 'Unknown';
          final price = (food['price'] as num?)?.toDouble() ?? 0;
          final category = _normalizeFoodType(
            foodTypes[name.toLowerCase()],
            name,
          );
          return '- $name (${category}): ${price.toStringAsFixed(2)}';
        })
        .join('\n');

    return '''
You are a smart budget meal planner.
You are also strict and practical: generate only realistic, complete meals that people actually eat.

Your goal is to fully utilize the budget. Do NOT try to save money. Maximize food quantity and variety while staying within budget.

Available foods with prices:
$foodLines

User constraints:
- Budget: ${budget.toStringAsFixed(2)}
- Budget type: ${_budgetTypeLabel(budgetType)}
- Duration: $durationDays days
- Budget per day: ${budgetPerDay.toStringAsFixed(2)}
- Meal types per day: [${mealTypes.join(', ')}]
- Eating level: $eatingLevel

Rules:
- COMPLETE MEAL STRUCTURE (MANDATORY):
- Every Lunch or Dinner option MUST include:
  - 1 staple/filling item (rice or roti or similar)
  - 1 protein/main dish (egg/chicken/fish/dal/meat)
  - Optional side (vegetable/salad)
- Do NOT generate drink-only meals, vegetable-only main meals, or random unrelated combinations.
- Drinks (juice/mojo/tea) are allowed only in Snacks/Tea.
- Drinks must NEVER appear as Lunch or Dinner options.
- Snacks must NEVER replace Lunch or Dinner.
- Validation rule: if an option is only vegetables or only drinks, remove it.
- MEAL TYPE RULES:
  - Breakfast should be light but filling.
  - Lunch and Dinner must be full proper meals.
  - Snacks/Tea must be light items and must NEVER replace main meals.
- FOOD COMPATIBILITY: only combine foods that are normally eaten together.
- LOCAL CONTEXT: prefer common South Asian/Bangladeshi-style practical meals.
- Fully utilize budget as closely as possible
- Maximize meals and variety
- Prioritize filling all meal slots
- MUST NOT exceed budget
- Do not intentionally leave unused budget
- Adjust based on eating level
- Use only given foods
- Each selected meal type must appear exactly once per day in the plan.
- If a meal option looks unrealistic or incomplete, exclude it.
- If a valid option cannot be created from available foods, skip that combination.

For each meal (breakfast, lunch, dinner, snacks, tea), generate at least 2-3 different realistic food combination options.
Structure the response strictly by Day -> Meal -> Options.

Return valid JSON only in this exact structure:
{
  "plans": [
    {
      "title": "Plan name",
      "dailyCost": 0,
      "totalCost": 0,
      "days": [
        {
          "day": "Day 1",
          "meals": [
            {
              "mealType": "Lunch",
              "options": [
                {
                  "label": "Option 1",
                  "items": ["Food A", "Food B"],
                  "cost": 0
                }
              ]
            }
          ]
        }
      ]
    }
  ]
}

Return exactly 2 or 3 plans.
''';
  }

  List<MealPlan> _parsePlansFromText(String text) {
    final decoded = _extractJson(text);
    if (decoded == null) return const [];
    return _parsePlans(decoded);
  }

  Map<String, dynamic>? _extractJson(String text) {
    try {
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) return null;
      try {
        return jsonDecode(text.substring(start, end + 1))
            as Map<String, dynamic>;
      } catch (_) {
        return null;
      }
    }
  }

  List<MealPlan> _parsePlans(Map<String, dynamic> map) {
    final plansRaw = map['plans'];
    if (plansRaw is! List) return const [];

    final plans = <MealPlan>[];
    for (final item in plansRaw) {
      if (item is! Map<String, dynamic>) continue;
      plans.add(MealPlan.fromMap(item));
    }

    return plans.where((plan) => plan.days.isNotEmpty).toList();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final total = widget.expenses.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );

    final Map<String, double> categorySummary = {};

    for (final expense in widget.expenses) {
      final categoryName = expense.category.trim();
      if (categoryName.isEmpty) continue;

      categorySummary[categoryName] =
          (categorySummary[categoryName] ?? 0) + expense.amount;
    }

    final categoryEntries = categorySummary.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return Scaffold(
      appBar: AppBar(title: const Text('Analytics Page')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.14),
                  colorScheme.secondary.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.10),
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.shadow.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.insights_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expense',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.currency} ${total.toStringAsFixed(2)}',
                          style: textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'A quick view of your spending this month',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('Category Summary', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          if (categoryEntries.isEmpty)
            Container(
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
              child: const ListTile(
                leading: Icon(Icons.pie_chart_outline_rounded),
                title: Text('No category data yet'),
                subtitle: Text('Add expenses to see category analytics.'),
              ),
            )
          else
            ...categoryEntries.asMap().entries.map((entry) {
              final index = entry.key;
              final categoryEntry = entry.value;
              final share = total <= 0 ? 0.0 : categoryEntry.value / total;
              final accentColor = _pastelColors[index % _pastelColors.length];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnalyticsItem(
                  title: categoryEntry.key,
                  value:
                      '${widget.currency} ${categoryEntry.value.toStringAsFixed(2)}',
                  shareLabel: '${(share * 100).toStringAsFixed(0)}%',
                  accentColor: accentColor,
                  progress: share,
                  icon: _categoryIcon(index),
                ),
              );
            }),
          const SizedBox(height: 14),
          _buildMealPlannerPanel(context),
        ],
      ),
    );
  }

  Widget _buildMealPlannerPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final enteredBudget = double.tryParse(_budgetController.text.trim()) ?? 0;
    final mealsPerDay = _mealsPerDayFromSelection();
    final totalBudget = _resolvedTotalBudget(enteredBudget);
    final budgetPerDay = _resolvedBudgetPerDay(enteredBudget);

    Widget buildInputCard({
      required IconData icon,
      required String label,
      required Widget child,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  child,
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildPlannerChip(String label, bool selected, VoidCallback onTap) {
      return FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: colorScheme.primary.withValues(alpha: 0.16),
        checkmarkColor: colorScheme.primary,
        backgroundColor: colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.65,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      );
    }

    void selectBudgetType(_BudgetType type) {
      setState(() {
        _budgetType = type;
        if (type == _BudgetType.daily) {
          _customDurationDays = 1;
          _customDurationController.text = '1';
        } else if (type == _BudgetType.weekly) {
          _customDurationDays = 7;
          _customDurationController.text = '7';
        } else if (type == _BudgetType.monthly) {
          _customDurationDays = 30;
          _customDurationController.text = '30';
        } else if (type == _BudgetType.perMeal) {
          _customDurationDays = 1;
          _customDurationController.text = '1';
        }
      });
    }

    final budgetOptions =
        <({_BudgetType type, IconData icon, String title, String subtitle})>[
          (
            type: _BudgetType.perMeal,
            icon: Icons.restaurant_menu_rounded,
            title: 'Per Meal',
            subtitle: 'Cost per single meal',
          ),
          (
            type: _BudgetType.daily,
            icon: Icons.today_rounded,
            title: 'Daily',
            subtitle: '1 day total budget',
          ),
          (
            type: _BudgetType.weekly,
            icon: Icons.stacked_line_chart_rounded,
            title: 'Weekly',
            subtitle: '7 days budget',
          ),
          (
            type: _BudgetType.monthly,
            icon: Icons.savings_rounded,
            title: 'Monthly',
            subtitle: '30 days budget',
          ),
          (
            type: _BudgetType.custom,
            icon: Icons.tune_rounded,
            title: 'Custom',
            subtitle: 'User-defined duration',
          ),
        ];

    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Meal Planner', style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              'Generate smart meal plans based on your budget',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Budget Type',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: budgetOptions.map((option) {
                final selected = _budgetType == option.type;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => selectBudgetType(option.type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 156,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? LinearGradient(
                              colors: [
                                colorScheme.primary.withValues(alpha: 0.24),
                                colorScheme.secondary.withValues(alpha: 0.20),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: selected
                          ? null
                          : colorScheme.surfaceContainerHighest.withValues(
                              alpha: 0.35,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: selected
                            ? colorScheme.primary.withValues(alpha: 0.45)
                            : colorScheme.outlineVariant.withValues(alpha: 0.5),
                        width: selected ? 1.5 : 1,
                      ),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.16,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: selected
                                    ? colorScheme.primary.withValues(
                                        alpha: 0.18,
                                      )
                                    : colorScheme.primary.withValues(
                                        alpha: 0.10,
                                      ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                option.icon,
                                size: 16,
                                color: colorScheme.primary,
                              ),
                            ),
                            const Spacer(),
                            if (selected)
                              Icon(
                                Icons.check_circle_rounded,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          option.title,
                          style: textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              _budgetHelperText(_budgetType),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            buildInputCard(
              icon: Icons.payments_rounded,
              label: 'Budget',
              child: TextField(
                controller: _budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                ],
                decoration: InputDecoration(
                  hintText: _budgetInputHint(_budgetType),
                  filled: true,
                  fillColor: colorScheme.primary.withValues(alpha: 0.05),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _budgetType == _BudgetType.perMeal
                  ? 'Per Day Budget: ${widget.currency} ${(enteredBudget * mealsPerDay).toStringAsFixed(2)} / day'
                  : 'Per Day Budget: ${widget.currency} ${budgetPerDay.toStringAsFixed(2)} / day',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (_budgetType == _BudgetType.custom) ...[
              buildInputCard(
                icon: Icons.date_range_rounded,
                label: 'Custom duration (days)',
                child: TextField(
                  controller: _customDurationController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Enter duration in days',
                    filled: true,
                    fillColor: colorScheme.primary.withValues(alpha: 0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
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
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value.trim()) ?? 0;
                    setState(() {
                      _customDurationDays = parsed;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              'Meal types',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mealTypeOptions.map((mealType) {
                final selected = _selectedMealTypes.contains(mealType);
                return FilterChip(
                  label: Text(mealType),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _selectedMealTypes.add(mealType);
                      } else {
                        _selectedMealTypes.remove(mealType);
                      }
                    });
                  },
                  selectedColor: colorScheme.primary.withValues(alpha: 0.16),
                  checkmarkColor: colorScheme.primary,
                  backgroundColor: colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.65),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedMealTypes.isEmpty
                  ? 'Meals per day: 0'
                  : 'Meals per day: ${_selectedMealTypes.length} (${_selectedMealTypes.join(', ')})',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Eating level',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['Light', 'Medium', 'Heavy'].map((level) {
                final selected = _eatingLevel == level;
                return buildPlannerChip(level, selected, () {
                  setState(() {
                    _eatingLevel = level;
                  });
                });
              }).toList(),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Budget Breakdown',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Entered Budget: ${widget.currency} ${enteredBudget.toStringAsFixed(2)}',
                  ),
                  Text('Duration: ${_resolvedDurationDays()} days'),
                  Text(
                    'Planning Budget: ${widget.currency} ${totalBudget.toStringAsFixed(2)}',
                  ),
                  Text(
                    'Per Day Budget: ${widget.currency} ${budgetPerDay.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF2196F3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1F2196F3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isGenerating ? null : _generatePlans,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: colorScheme.onPrimary,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isGenerating
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    _isGenerating ? 'Generating...' : 'Generate Plan',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The planner uses the budget exactly against the selected duration. It does not intentionally save leftover money.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (_plannerError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _plannerError!,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ),
            if (_plannerError != null) const SizedBox(height: 12),
            if (_isGenerating)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Text(
                    'Generating smart plan...',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            if (!_isGenerating && _plannerError == null && _mealPlans.isEmpty)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'Generate a plan to see results',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            if (_mealPlans.isNotEmpty) ...[
              const SizedBox(height: 8),
              ..._mealPlans.asMap().entries.map((entry) {
                final index = entry.key;
                final plan = entry.value;
                final cardColor = _pastelColors[index % _pastelColors.length];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardColor.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Cost / day: ${widget.currency} ${plan.dailyCost.toStringAsFixed(2)}',
                              style: textTheme.bodyMedium,
                            ),
                          ),
                          Text(
                            'Total: ${widget.currency} ${plan.totalCost.toStringAsFixed(2)}',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...plan.days.asMap().entries.map((dayEntry) {
                        final dayIndex = dayEntry.key;
                        final day = dayEntry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.66),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 2,
                            ),
                            childrenPadding: const EdgeInsets.only(
                              left: 8,
                              right: 8,
                              bottom: 8,
                            ),
                            title: Text(
                              day.day,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${day.meals.length} meal slots',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            children: day.meals.map((meal) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color:
                                      _pastelColors[(dayIndex + 1) %
                                              _pastelColors.length]
                                          .withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ExpansionTile(
                                  initiallyExpanded: false,
                                  tilePadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  childrenPadding: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                    bottom: 10,
                                  ),
                                  title: Text(
                                    meal.mealType,
                                    style: textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  children: meal.options.asMap().entries.map((
                                    optionEntry,
                                  ) {
                                    final optionIndex = optionEntry.key;
                                    final option = optionEntry.value;
                                    final isRecommended = optionIndex == 0;

                                    return Container(
                                      width: double.infinity,
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isRecommended
                                            ? colorScheme.primary.withValues(
                                                alpha: 0.10,
                                              )
                                            : colorScheme.surface,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isRecommended
                                              ? colorScheme.primary.withValues(
                                                  alpha: 0.35,
                                                )
                                              : colorScheme.outlineVariant,
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  option.label,
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                              ),
                                              if (isRecommended)
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          999,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Recommended',
                                                    style: textTheme.labelSmall
                                                        ?.copyWith(
                                                          color: colorScheme
                                                              .onPrimary,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            option.items.join(' + '),
                                            style: textTheme.bodySmall,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Cost: ${widget.currency} ${option.cost.toStringAsFixed(2)}',
                                            style: textTheme.bodySmall
                                                ?.copyWith(
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(int index) {
    switch (index % 5) {
      case 0:
        return Icons.receipt_long_rounded;
      case 1:
        return Icons.directions_bus_rounded;
      case 2:
        return Icons.school_rounded;
      case 3:
        return Icons.shopping_bag_rounded;
      default:
        return Icons.label_rounded;
    }
  }
}
