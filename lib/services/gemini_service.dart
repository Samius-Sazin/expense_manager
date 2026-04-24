import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  const GeminiService();

  static const String _apiKey = 'AIzaSyBrnF2GTkXRJXVSRdRgpIDRDNl9FTyZkik';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent';

  Future<String> generateMealPlan(String prompt) async {
    try {
      final uri = Uri.parse('$_endpoint?key=$_apiKey');
      final response = await http.post(
        uri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return 'Failed to generate plan. Try again.';
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      final firstCandidate = candidates?.isNotEmpty == true
          ? candidates!.first as Map<String, dynamic>
          : null;
      final content = firstCandidate?['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final firstPart = parts?.isNotEmpty == true
          ? parts!.first as Map<String, dynamic>
          : null;
      final text = (firstPart?['text'] as String?)?.trim() ?? '';

      if (text.isEmpty) {
        return 'Failed to generate plan. Try again.';
      }

      return text;
    } catch (_) {
      return 'Failed to generate plan. Try again.';
    }
  }

  Future<Map<String, String>> classifyFoods(List<String> foodNames) async {
    if (foodNames.isEmpty) return const {};

    final uniqueNames = foodNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();

    if (uniqueNames.isEmpty) return const {};

    final foodListText = uniqueNames.map((name) => '- $name').join('\n');

    final prompt =
        '''
Classify each food into one category: staple, protein, vegetable, drink, or snack.

Food list:
$foodListText

Return ONLY in this format:
Food Name - category
''';

    final responseText = await generateMealPlan(prompt);
    if (responseText == 'Failed to generate plan. Try again.') {
      return const {};
    }

    final parsed = <String, String>{};
    const allowed = {'staple', 'protein', 'vegetable', 'drink', 'snack'};

    for (final line in responseText.split('\n')) {
      final clean = line.trim();
      if (clean.isEmpty || !clean.contains('-')) continue;

      final parts = clean.split('-');
      if (parts.length < 2) continue;

      final name = parts.first.trim();
      final category = parts.last.trim().toLowerCase();

      if (name.isEmpty || !allowed.contains(category)) continue;
      parsed[name.toLowerCase()] = category;
    }

    return parsed;
  }
}
