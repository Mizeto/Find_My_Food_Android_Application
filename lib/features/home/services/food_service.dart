import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeService {
  static const String baseUrl = 'https://find-my-food-api.onrender.com';

  // GET /recipe/getAllRecipe
  Future<List<RecipeModel>> getAllRecipes() async {
    try {
      print('Fetching recipes from: $baseUrl/recipe/getAllRecipe');
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getAllRecipe'),
        headers: {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => RecipeModel.fromJson(json)).toList();
        } else {
          throw Exception('API Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load recipes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      throw Exception('Connection error: $e');
    }
  }

  // GET /recipegetRecipeByName/{request}
  Future<List<RecipeModel>> getRecipeByName(String name) async {
    try {
      final encodedName = Uri.encodeComponent(name);
      print('Searching recipe: $baseUrl/recipegetRecipeByName/$encodedName');
      final response = await http.get(
        Uri.parse('$baseUrl/recipegetRecipeByName/$encodedName'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final dynamic data = jsonResponse['data'];
          if (data is List) {
             return data.map((json) => RecipeModel.fromJson(json)).toList();
          } else if (data is Map<String, dynamic>) {
             return [RecipeModel.fromJson(data)];
          }
          return [];
        } else {
           return [];
        }
      } else {
        throw Exception('Failed to search recipe: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // GET /recipe/getRecipeDetailById/{id}
  Future<RecipeModel> getRecipeDetailById(int id) async {
    try {
      print('Fetching recipe detail: $baseUrl/recipe/getRecipeDetailById/$id');
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getRecipeDetailById/$id'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
         final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
         if (jsonResponse['status'] == 'success') {
           return RecipeModel.fromJson(jsonResponse['data']);
         } else {
           throw Exception('API Error: ${jsonResponse['message']}');
         }
      } else {
        throw Exception('Failed to load recipe detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Helper to get token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders({bool isMultipart = false}) async {
    final token = await _getToken();
    final headers = {
      'accept': 'application/json',
    };
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json';
    }
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // POST /recipe/createNewRecipe
  Future<bool> createNewRecipe(Map<String, dynamic> recipeData) async {
    try {
      print('Creating recipe: $baseUrl/recipe/createNewRecipe');
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/recipe/createNewRecipe'), 
        headers: headers,
        body: jsonEncode(recipeData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
         return true;
      } else {
        throw Exception('Failed to create recipe: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // POST /recipe/uploadNewRecipeImage
  Future<String?> uploadNewRecipeImage(String filePath) async {
    try {
      print('Uploading image: $baseUrl/recipe/uploadNewRecipeImage');
      final token = await _getToken();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/recipe/uploadNewRecipeImage'),
      );
      
      // Add headers manually for MultipartRequest
      request.headers['accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        filePath,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']; 
        } 
        return null;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Connection error during upload: $e');
    }
  }

  // PUT /recipe/updateRecipeHeaderById/{recipe_id}
  Future<bool> updateRecipeHeaderById(int recipeId, Map<String, dynamic> headerData) async {
    try {
      print('Updating recipe header: $baseUrl/recipe/updateRecipeHeaderById/$recipeId');
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/recipe/updateRecipeHeaderById/$recipeId'),
        headers: headers,
        body: jsonEncode(headerData),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // PUT /recipe/updateRecipeIngredientById/{recipe_id}
  Future<bool> updateRecipeIngredientById(int recipeId, List<Map<String, dynamic>> ingredients) async {
    try {
      print('Updating recipe ingredients: $baseUrl/recipe/updateRecipeIngredientById/$recipeId');
      final headers = await _getHeaders();
      final body = {'ingredients': ingredients};
      final response = await http.put(
        Uri.parse('$baseUrl/recipe/updateRecipeIngredientById/$recipeId'),
        headers: headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // PUT /recipe/updateRecipeStepById/{recipe_id}
  Future<bool> updateRecipeStepById(int recipeId, List<Map<String, dynamic>> steps) async {
    try {
      print('Updating recipe steps: $baseUrl/recipe/updateRecipeStepById/$recipeId');
      final headers = await _getHeaders();
      final body = {'steps': steps};
      final response = await http.put(
        Uri.parse('$baseUrl/recipe/updateRecipeStepById/$recipeId'),
        headers: headers,
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
  // GET /unit/
  Future<List<UnitModel>> getAllUnits() async {
    try {
      print('Fetching units: $baseUrl/unit/');
      final response = await http.get(
        Uri.parse('$baseUrl/unit/'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => UnitModel.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load units: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // GET /recipe/getIngredientByName/{ingredient_name}
  Future<List<IngredientModel>> getIngredientByNameSearch(String name) async {
    try {
      final encodedName = Uri.encodeComponent(name);
      print('Searching ingredients: $baseUrl/recipe/getIngredientByName/$encodedName');
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getIngredientByName/$encodedName'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final dynamic data = jsonResponse['data'];
          if (data is List) {
            return data.map((json) => IngredientModel.fromJson(json)).toList();
          } else if (data is Map<String, dynamic>) {
            return [IngredientModel.fromJson(data)];
          }
          return [];
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to search ingredients: ${response.statusCode}');
      }
    } catch (e) {
      return []; // Return empty instead of error for smooth autocomplete
    }
  }

  // POST /recipeAI/ - Predict Dish Name
  Future<DishAIResponse?> predictDishAI(String filePath) async {
    try {
      print('Predicting dish with AI: $baseUrl/recipeAI/');
      final token = await _getToken();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/recipeAI/'),
      );
      
      request.headers['accept'] = 'application/json';
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        'file', 
        filePath,
      ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          return DishAIResponse.fromJson(jsonResponse['data']);
        } else {
          throw Exception(jsonResponse['message'] ?? 'AI Prediction failed');
        }
      } else {
        throw Exception('Failed to predict: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during Dish AI: $e');
      return null;
    }
  }
}
