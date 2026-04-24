import 'dart:convert';

import 'package:http/http.dart' as http;

class MealPlannerService {
  const MealPlannerService();

  static const String _defaultEndpoint =
      'https://api.openai.com/v1/chat/completions';

  Future<List<MealPlan>> generatePlans({
    required List<Map<String, dynamic>> foods,
    required Map<String, String> foodTypes,
    required double budget,
    required int durationDays,
    required List<String> mealTypes,
    required String eatingLevel,
  }) async {
    final apiKey = const String.fromEnvironment('OPENAI_API_KEY');
    final endpoint = const String.fromEnvironment(
      'OPENAI_ENDPOINT',
      defaultValue: _defaultEndpoint,
    );
    final model = const String.fromEnvironment(
      'OPENAI_MODEL',
      defaultValue: 'gpt-4o-mini',
    );

    if (apiKey.isEmpty) {
      return _fallbackPlans(
        foods: foods,
        foodTypes: foodTypes,
        budget: budget,
        durationDays: durationDays,
        mealTypes: mealTypes,
        eatingLevel: eatingLevel,
      );
    }

    final prompt = _buildPrompt(
      foods: foods,
      foodTypes: foodTypes,
      budget: budget,
      durationDays: durationDays,
      mealTypes: mealTypes,
      eatingLevel: eatingLevel,
    );

    final response = await http.post(
      Uri.parse(endpoint),
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'temperature': 0.3,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a smart budget meal planner and always return valid JSON only.',
          },
          {'role': 'user', 'content': prompt},
        ],
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      return _fallbackPlans(
        foods: foods,
        foodTypes: foodTypes,
        budget: budget,
        durationDays: durationDays,
        mealTypes: mealTypes,
        eatingLevel: eatingLevel,
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = payload['choices'] as List<dynamic>?;
    final content =
        choices?.firstWhere(
              (item) => item is Map<String, dynamic>,
              orElse: () => <String, dynamic>{},
            )
            as Map<String, dynamic>?;
    final message = content?['message'] as Map<String, dynamic>?;
    final jsonText = (message?['content'] as String?)?.trim() ?? '';

    final decoded = _extractJson(jsonText);
    if (decoded == null) {
      return _fallbackPlans(
        foods: foods,
        foodTypes: foodTypes,
        budget: budget,
        durationDays: durationDays,
        mealTypes: mealTypes,
        eatingLevel: eatingLevel,
      );
    }

    return _parsePlans(decoded);
  }

  String _buildPrompt({
    required List<Map<String, dynamic>> foods,
    required Map<String, String> foodTypes,
    required double budget,
    required int durationDays,
    required List<String> mealTypes,
    required String eatingLevel,
  }) {
    final foodLines = foods
        .map((food) {
          final name = (food['name'] as String?)?.trim() ?? 'Unknown';
          final price = (food['price'] as num?)?.toDouble() ?? 0;
          final category = _resolveFoodType(name, foodTypes);
          return '- $name (${category}): ${price.toStringAsFixed(2)}';
        })
        .join('\n');

    final budgetPerDay = durationDays <= 0 ? 0.0 : budget / durationDays;

    return '''
You are a smart budget meal planner.
You are also strict and practical: generate only realistic, complete meals that people actually eat.

Your goal is to fully utilize the budget. Do NOT try to save money. Maximize food quantity and variety while staying within budget.

Available foods with prices:
$foodLines

User constraints:
- Budget: ${budget.toStringAsFixed(2)}
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

  List<MealPlan> _fallbackPlans({
    required List<Map<String, dynamic>> foods,
    required Map<String, String> foodTypes,
    required double budget,
    required int durationDays,
    required List<String> mealTypes,
    required String eatingLevel,
  }) {
    if (foods.isEmpty || durationDays <= 0 || mealTypes.isEmpty) {
      return const [];
    }

    final sortedFoods = List<Map<String, dynamic>>.from(foods)
      ..sort((a, b) {
        final priceA = (a['price'] as num?)?.toDouble() ?? 0;
        final priceB = (b['price'] as num?)?.toDouble() ?? 0;
        return priceA.compareTo(priceB);
      });

    final forward = _buildFallbackPlan(
      title: 'Balanced Usage Plan',
      orderedFoods: sortedFoods,
      foodTypes: foodTypes,
      budget: budget,
      durationDays: durationDays,
      mealTypes: mealTypes,
      eatingLevel: eatingLevel,
    );

    final reverse = _buildFallbackPlan(
      title: 'Variety Usage Plan',
      orderedFoods: sortedFoods.reversed.toList(),
      foodTypes: foodTypes,
      budget: budget,
      durationDays: durationDays,
      mealTypes: mealTypes,
      eatingLevel: eatingLevel,
    );

    return [forward, reverse];
  }

  MealPlan _buildFallbackPlan({
    required String title,
    required List<Map<String, dynamic>> orderedFoods,
    required Map<String, String> foodTypes,
    required double budget,
    required int durationDays,
    required List<String> mealTypes,
    required String eatingLevel,
  }) {
    final budgetPerDay = budget / durationDays;
    final effectiveMealTypes = mealTypes.isEmpty ? <String>['Meal'] : mealTypes;

    final levelMultiplier = eatingLevel == 'Heavy'
        ? 1.2
        : eatingLevel == 'Light'
        ? 0.85
        : 1.0;

    final perMealBudget =
        (budgetPerDay / effectiveMealTypes.length) * levelMultiplier;

    final days = <MealDay>[];
    var rollingIndex = 0;

    for (var day = 1; day <= durationDays; day++) {
      final meals = <MealSlot>[];

      for (final mealType in effectiveMealTypes) {
        final options = <MealOption>[];

        for (var optionIndex = 0; optionIndex < 3; optionIndex++) {
          final option = _buildFallbackMealOption(
            mealType: mealType,
            orderedFoods: orderedFoods,
            foodTypes: foodTypes,
            rollingIndex: rollingIndex,
            perMealBudget: perMealBudget,
            optionIndex: optionIndex,
          );

          if (option == null) {
            rollingIndex++;
            continue;
          }

          options.add(
            MealOption(
              label: 'Option ${optionIndex + 1}',
              items: option.$1,
              cost: option.$2,
            ),
          );
          rollingIndex++;
        }

        if (options.isNotEmpty) {
          meals.add(MealSlot(mealType: mealType, options: options));
        }
      }

      days.add(MealDay(day: 'Day $day', meals: meals));
    }

    final dailyCost = days.isEmpty
        ? 0.0
        : days.first.meals.fold<double>(
            0,
            (sum, meal) =>
                sum + (meal.options.isEmpty ? 0.0 : meal.options.first.cost),
          );

    final cappedDaily = dailyCost > budgetPerDay ? budgetPerDay : dailyCost;

    return MealPlan(
      title: title,
      days: days,
      dailyCost: cappedDaily,
      totalCost: cappedDaily * durationDays,
    );
  }

  (List<String>, double)? _buildFallbackMealOption({
    required String mealType,
    required List<Map<String, dynamic>> orderedFoods,
    required Map<String, String> foodTypes,
    required int rollingIndex,
    required double perMealBudget,
    required int optionIndex,
  }) {
    if (orderedFoods.isEmpty) return null;

    final type = mealType.toLowerCase();
    final isMainMeal = type == 'lunch' || type == 'dinner';
    final isSnackOrTea = type == 'snacks' || type == 'tea';

    final candidateFoods = orderedFoods.where((food) {
      final name = ((food['name'] as String?) ?? '').trim();
      final category = _resolveFoodType(name, foodTypes);
      if (isMainMeal && (category == 'drink' || category == 'snack')) {
        return false;
      }
      if (isSnackOrTea && (category == 'staple' || category == 'protein')) {
        return false;
      }
      return true;
    }).toList();

    if (candidateFoods.isEmpty) return null;

    final comboItems = <String>[];
    var comboCost = 0.0;
    final maxItems = (optionIndex % 2 == 0) ? 2 : 3;

    for (var pick = 0; pick < maxItems; pick++) {
      final food =
          candidateFoods[(rollingIndex + pick) % candidateFoods.length];
      final name = (food['name'] as String?)?.trim() ?? 'Food';
      final price = (food['price'] as num?)?.toDouble() ?? 0;
      if (comboItems.isEmpty || comboCost + price <= perMealBudget) {
        comboItems.add(name);
        comboCost += price;
      }
    }

    if (comboItems.isEmpty) return null;

    if (isMainMeal) {
      final hasStaple = comboItems.any(
        (item) => _resolveFoodType(item, foodTypes) == 'staple',
      );
      final hasMain = comboItems.any(
        (item) => _resolveFoodType(item, foodTypes) == 'protein',
      );
      final allVeg = comboItems.every(
        (item) => _resolveFoodType(item, foodTypes) == 'vegetable',
      );
      final allDrink = comboItems.every(
        (item) => _resolveFoodType(item, foodTypes) == 'drink',
      );
      if (!hasStaple || !hasMain || allVeg || allDrink) {
        return null;
      }
    }

    if (isSnackOrTea) {
      final allHeavy = comboItems.every((item) {
        final type = _resolveFoodType(item, foodTypes);
        return type == 'staple' || type == 'protein';
      });
      if (allHeavy) return null;
    }

    return (comboItems, comboCost);
  }

  bool _containsAny(String name, List<String> keywords) {
    return keywords.any(name.contains);
  }

  String _resolveFoodType(String name, Map<String, String> foodTypes) {
    final key = name.trim().toLowerCase();
    final aiType = foodTypes[key]?.trim().toLowerCase();
    if (aiType != null && _isSupportedType(aiType)) {
      return aiType;
    }
    return _fallbackFoodType(key);
  }

  bool _isSupportedType(String type) {
    return type == 'staple' ||
        type == 'protein' ||
        type == 'vegetable' ||
        type == 'drink' ||
        type == 'snack';
  }

  String _fallbackFoodType(String name) {
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
}

class MealPlan {
  final String title;
  final List<MealDay> days;
  final double dailyCost;
  final double totalCost;

  const MealPlan({
    required this.title,
    required this.days,
    required this.dailyCost,
    required this.totalCost,
  });

  factory MealPlan.fromMap(Map<String, dynamic> map) {
    final rawDays = map['days'];
    final parsedDays = rawDays is List
        ? rawDays
              .whereType<Map<String, dynamic>>()
              .map(MealDay.fromMap)
              .where((day) => day.meals.isNotEmpty)
              .toList()
        : <MealDay>[];

    if (parsedDays.isEmpty) {
      final legacy = _legacyDays(map['dailyBreakdown']);
      return MealPlan(
        title: (map['title'] as String?)?.trim().isNotEmpty == true
            ? (map['title'] as String)
            : 'Meal Plan',
        days: legacy,
        dailyCost: (map['dailyCost'] as num?)?.toDouble() ?? 0,
        totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0,
      );
    }

    return MealPlan(
      title: (map['title'] as String?)?.trim().isNotEmpty == true
          ? (map['title'] as String)
          : 'Meal Plan',
      days: parsedDays,
      dailyCost: (map['dailyCost'] as num?)?.toDouble() ?? 0,
      totalCost: (map['totalCost'] as num?)?.toDouble() ?? 0,
    );
  }

  static List<MealDay> _legacyDays(dynamic rawBreakdown) {
    if (rawBreakdown is! List) return const [];

    final days = <MealDay>[];
    for (final line in rawBreakdown) {
      final text = line.toString().trim();
      if (text.isEmpty) continue;
      final parts = text.split(':');
      if (parts.length < 2) continue;

      final dayLabel = parts.first.trim();
      final rest = parts.sublist(1).join(':').trim();
      final items = rest
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();

      days.add(
        MealDay(
          day: dayLabel,
          meals: [
            MealSlot(
              mealType: 'Meals',
              options: [MealOption(label: 'Option 1', items: items, cost: 0)],
            ),
          ],
        ),
      );
    }

    return days;
  }
}

class MealDay {
  final String day;
  final List<MealSlot> meals;

  const MealDay({required this.day, required this.meals});

  factory MealDay.fromMap(Map<String, dynamic> map) {
    final rawMeals = map['meals'];
    final parsedMeals = rawMeals is List
        ? rawMeals
              .whereType<Map<String, dynamic>>()
              .map(MealSlot.fromMap)
              .where((meal) => meal.options.isNotEmpty)
              .toList()
        : <MealSlot>[];

    return MealDay(
      day: (map['day'] as String?)?.trim().isNotEmpty == true
          ? (map['day'] as String)
          : 'Day',
      meals: parsedMeals,
    );
  }
}

class MealSlot {
  final String mealType;
  final List<MealOption> options;

  const MealSlot({required this.mealType, required this.options});

  factory MealSlot.fromMap(Map<String, dynamic> map) {
    final rawOptions = map['options'];
    final parsedOptions = rawOptions is List
        ? rawOptions
              .whereType<Map<String, dynamic>>()
              .map(MealOption.fromMap)
              .where((option) => option.items.isNotEmpty)
              .toList()
        : <MealOption>[];

    return MealSlot(
      mealType: (map['mealType'] as String?)?.trim().isNotEmpty == true
          ? (map['mealType'] as String)
          : 'Meal',
      options: parsedOptions,
    );
  }
}

class MealOption {
  final String label;
  final List<String> items;
  final double cost;

  const MealOption({
    required this.label,
    required this.items,
    required this.cost,
  });

  factory MealOption.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];
    final parsedItems = rawItems is List
        ? rawItems
              .map((item) => item.toString().trim())
              .where((item) => item.isNotEmpty)
              .toList()
        : <String>[];

    return MealOption(
      label: (map['label'] as String?)?.trim().isNotEmpty == true
          ? (map['label'] as String)
          : 'Option',
      items: parsedItems,
      cost: (map['cost'] as num?)?.toDouble() ?? 0,
    );
  }
}
