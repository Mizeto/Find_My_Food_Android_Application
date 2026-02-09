import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_model.dart';
import '../models/food_model.dart'; // For UnitModel if needed, though strictly not used in service return types yet

class ShoppingService {
  static const String baseUrl = 'https://find-my-food-api.onrender.com';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    final headers = {
      'accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // 1. GET /shoppingCart/getShoppingList/{shopping_type}
  Future<List<ShoppingListModel>> getShoppingList(String shoppingType) async {
    try {
      final headers = await _getHeaders();
      // Debug Token
      print('Token used: ${headers['Authorization']}');

      final getHeaders = {
        'accept': 'application/json',
        if (headers['Authorization'] != null) 'Authorization': headers['Authorization']!,
      };

      print('Fetching shopping list: $baseUrl/shoppingCart/getShoppingList/$shoppingType');
      final response = await http.get(
        Uri.parse('$baseUrl/shoppingCart/getShoppingList/$shoppingType'),
        headers: getHeaders,
      );

      print('GetList Status: ${response.statusCode}');
      print('GetList Body: ${utf8.decode(response.bodyBytes)}'); // RAW BODY LOG

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final dynamic data = jsonResponse['data'];
          if (data == null) {
              print('Data is NULL');
              return [];
          }
          if (data is List) {
            try {
              return data.map((json) => ShoppingListModel.fromJson(json)).toList();
            } catch (e) {
              print('Parsing Error: $e'); // Catch parsing error
              return [];
            }
          } else if (data is Map<String, dynamic>) {
             return [ShoppingListModel.fromJson(data)];
          }
          return [];
        } else {
          print('API Status Fail: ${jsonResponse['message']}');
          return []; 
        }
      } else {
        print('Failed to get shopping list: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error getting shopping list: $e');
      throw Exception('Connection error: $e');
    }
  }

  // Helper method to get all shopping lists (both recipe and market combined)
  Future<List<ShoppingListModel>> getAllShoppingLists() async {
    try {
      // Fetch both types in parallel
      final results = await Future.wait([
        getShoppingList('recipe'),
        getShoppingList('market'),
      ]);
      
      // Combine and return all lists
      final allLists = <ShoppingListModel>[];
      allLists.addAll(results[0]); // recipe lists
      allLists.addAll(results[1]); // market lists
      return allLists;
    } catch (e) {
      print('Error getting all shopping lists: $e');
      throw Exception('Connection error: $e');
    }
  }


  // 2. PATCH /shoppingCartupdateShoppingItemUnit/{item_id}
  Future<bool> updateShoppingItemUnit(int itemId, int unitId) async {
    try {
      final headers = await _getHeaders();
      final body = {'unit_id': unitId};
      // NOTE: Path is exactly as requested /shoppingCartupdateShoppingItemUnit/
      final response = await http.patch(
        Uri.parse('$baseUrl/shoppingCartupdateShoppingItemUnit/$itemId'),
        headers: headers,
        body: jsonEncode(body),
      );
      print('Update Unit Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // 3. PATCH /shoppingCart/updateShoppingItemQuantity/{item_id}
  Future<bool> updateShoppingItemQuantity(int itemId, double quantity) async {
    try {
      final headers = await _getHeaders();
      final body = {'quantity': quantity};
      final response = await http.patch(
        Uri.parse('$baseUrl/shoppingCart/updateShoppingItemQuantity/$itemId'),
        headers: headers,
        body: jsonEncode(body),
      );
      print('Update Quantity Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // 4. PATCH /shoppingCart/updateShoppingItemStatus/{item_id}
  Future<bool> updateShoppingItemStatus(int itemId, bool isChecked) async {
    try {
      final headers = await _getHeaders();
      final body = {'is_check': isChecked};
      final response = await http.patch(
        Uri.parse('$baseUrl/shoppingCart/updateShoppingItemStatus/$itemId'),
        headers: headers,
        body: jsonEncode(body),
      );
      print('Update Status Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // 5. POST /shoppingCart/addItemToShoppingList
  Future<bool> addItemToShoppingList({
    required String itemName,
    required double quantity,
    required int unitId,
    String note = '',
    required int shoppingListId,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'item_name': itemName,
        'quantity': quantity,
        'unit_id': unitId, // Default 0
        'note': note,
        'shopping_list_id': shoppingListId,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/shoppingCart/addItemToShoppingList'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      print('Add Item Response: ${response.statusCode} ${response.body}');
       if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // 6. POST /shoppingCart/createNewShoppingList
  Future<bool> createNewShoppingList({
    required String shoppingType,
    required String listName,
    List<Map<String, dynamic>> items = const [],
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'shopping_type': shoppingType,
        'list_name': listName,
        'items': items, // [{item_name, quantity, unit_id, note}, ...]
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/shoppingCart/createNewShoppingList'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      print('Create List Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // 7. DELETE /shoppingCart/deleteShoppingList/{list_id}
  Future<bool> deleteShoppingList(int listId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/shoppingCart/deleteShoppingList/$listId'),
        headers: headers,
      );
      
      print('Delete List Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // 8. DELETE /shoppingCart/deleteItemFromShoppingList/{item_id}
  Future<bool> deleteItemFromShoppingList(int itemId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/shoppingCart/deleteItemFromShoppingList/$itemId'),
        headers: headers,
      );
      
      print('Delete Item Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
