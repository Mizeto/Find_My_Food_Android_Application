import 'dart:typed_data';
import 'package:google_generative_ai/google_generative_ai.dart';

class AiService {
  // TODO: Replace with your actual API Key or use --dart-define
  static const String _apiKey = 'YOUR_GEMINI_API_KEY'; 

  late final GenerativeModel _model;

  AiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash', // fast and cost-effective
      apiKey: _apiKey,
    );
  }

  Future<String> identifyIngredients(Uint8List imageBytes) async {
    try {
      final prompt = TextPart(
        "Look at this food image. Identify the ingredients visible. "
        "Return the result as a JSON list of strings. "
        "Example: ['egg', 'tomato', 'onion']. "
        "Only return the JSON, no markdown formatting."
      );
      
      final imageParts = [
        DataPart('image/jpeg', imageBytes),
      ];

      final response = await _model.generateContent([
        Content.multi([prompt, ...imageParts])
      ]);

      print('AI Response: ${response.text}');
      return response.text ?? "[]";
    } catch (e) {
      print('AI Error: $e');
      throw Exception('Failed to identify ingredients: $e');
    }
  }

  Future<String> suggestRecipes(String ingredients) async {
    try {
       final prompt = Content.text(
        "Suggest 3 Thai recipes that can be made with these ingredients: $ingredients. "
        "Return only the recipe names as a comma-separated string."
      );
      
      final response = await _model.generateContent([prompt]);
      return response.text ?? "";
    } catch (e) {
      throw Exception('Failed to suggest recipes');
    }
  }
}
