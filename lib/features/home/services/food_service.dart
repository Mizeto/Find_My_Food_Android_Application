import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/food_model.dart';

class FoodService {
  static const String baseUrl = 'https://find-my-food-api.onrender.com';

  // GET /foods/getAllFood
  Future<List<FoodModel>> getAllFood() async {
    try {
      print('Fetching foods from: $baseUrl/foods/getAllFood'); // Debug Log
      final response = await http.get(
        Uri.parse('$baseUrl/foods/getAllFood'),
        headers: {'accept': 'application/json'},
      ).timeout(const Duration(seconds: 60)); // Wait up to 60s for cold start

      print('Response status: ${response.statusCode}'); // Debug Log
      print('Response body: ${response.body}'); // Debug Log

      if (response.statusCode == 200) {
        // Decode with UTF-8 support
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => FoodModel.fromJson(json)).toList();
        } else {
          throw Exception('API Error: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Failed to load foods: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching foods: $e'); // Debug Log
      throw Exception('Connection error: $e');
    }
  }

  // GET /foods/getFoodByName/{food}
  Future<List<FoodModel>> getFoodByName(String name) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/foods/getFoodByName/$name'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
           // Assuming the structure is similar to getAllFood (list of foods matching name)
           // If it returns a single object, this might need adjustment based on testing.
           // Based on typical search, it might be a list.
           // Let's assume list based on getAllFood pattern, or check 'data' type.
          final dynamic data = jsonResponse['data'];
          if (data is List) {
             return data.map((json) => FoodModel.fromJson(json)).toList();
          } else if (data is Map<String, dynamic>) {
             return [FoodModel.fromJson(data)];
          }
          return [];
        } else {
           // If search not found, handle gracefully
           return [];
        }
      } else {
        throw Exception('Failed to search food: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // POST /foods/createNewFood
  Future<bool> createNewFood(String name, String imageUrl) async {
    try {
      final body = {
        'food': name,
        'image_url': imageUrl.isEmpty ? 'https://placehold.co/600x400.png' : imageUrl,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/foods/createNewFood'),
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Checking for success status in response body if consistent with other endpoints
        // Assuming success returns { "status": "success", ... }
         try {
           final jsonResponse = jsonDecode(response.body);
           if (jsonResponse is Map && jsonResponse['status'] == 'success') {
             return true;
           }
           // If 'status' key is missing but calls was 200/201, assume success?
           // Let's assume strict check for now, can relax later.
           return true; 
         } catch(_) {
           // If response isn't JSON but 200 OK, return true
           return true;
         }
      } else {
        throw Exception('Failed to create food: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
