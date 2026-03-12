import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/food_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RecipeService {
  static const String baseUrl = 'https://find-my-food-api.onrender.com';

  // GET /recipe/getAllRecipe
  Future<List<RecipeModel>> getAllRecipes() async {
    try {
      print('Fetching recipes from: $baseUrl/recipe/getAllRecipe');
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getAllRecipe'),
        headers: headers,
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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/recipegetRecipeByName/$encodedName'),
        headers: headers,
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
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getRecipeDetailById/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
         final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
         if (jsonResponse['status'] == 'success') {
           final data = jsonResponse['data'];
           // API returns nested structure: {recipe: {...}, ingredients: [...], steps: [...], is_liked: bool}
           // We need to merge them into a single object for RecipeModel.fromJson
           final recipeData = data['recipe'] as Map<String, dynamic>;
           recipeData['ingredients'] = data['ingredients'];
           recipeData['steps'] = data['steps'];
           recipeData['is_liked'] = data['is_liked'];
           return RecipeModel.fromJson(recipeData);
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
    print('DEBUG: RecipeService retrieved token: ${token != null ? "${token.substring(0, 10)}..." : "NULL"}');
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

  // GET /recipe/getRecipeCategory
  Future<List<CategoryModel>> getRecipeCategory() async {
    try {
      print('Fetching categories from: $baseUrl/recipe/getRecipeCategory');
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getRecipeCategory'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => CategoryModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Connection error fetching categories: $e');
    }
  }

  // GET /recipe/getRecipeTag
  Future<List<TagModel>> getRecipeTag() async {
    try {
      print('Fetching tags from: $baseUrl/recipe/getRecipeTag');
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getRecipeTag'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => TagModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      throw Exception('Connection error fetching tags: $e');
    }
  }

  // GET /recipe/getRecipeFilterOption
  Future<Map<String, dynamic>> getRecipeFilterOption() async {
    try {
      print('Fetching filter options from: $baseUrl/recipe/getRecipeFilterOption');
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getRecipeFilterOption'),
        headers: {'accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];
          final categories = (data['categories'] as List?)
              ?.map((c) => CategoryModel.fromJson(c))
              .toList() ?? [];
          final tags = (data['tags'] as List?)
              ?.map((t) => TagModel.fromJson(t))
              .toList() ?? [];
          return {'categories': categories, 'tags': tags};
        }
      }
      return {'categories': <CategoryModel>[], 'tags': <TagModel>[]};
    } catch (e) {
      throw Exception('Connection error fetching filter options: $e');
    }
  }

  // GET /recipe/getSearchRecipeFilterOption
  Future<List<RecipeModel>> getSearchRecipeFilterOption({
    List<int>? categoryIds,
    List<int>? tagIds,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (categoryIds != null && categoryIds.isNotEmpty) {
        queryParams['categories'] = categoryIds.join(',');
      }
      if (tagIds != null && tagIds.isNotEmpty) {
        queryParams['tags'] = tagIds.join(',');
      }

      final uri = Uri.parse('$baseUrl/recipe/getSearchRecipeFilterOption')
          .replace(queryParameters: queryParams);
      print('Searching with filter: $uri');

      final headers = await _getHeaders();
      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => RecipeModel.fromJson(json)).toList();
        }
        return [];
      } else {
        throw Exception('Failed to search with filter: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
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

  // POST /recipeAI/analyzeFoodImage - Predict Dish Name
  Future<DishAIResponse?> predictDishAI(String filePath) async {
    try {
      print('Predicting dish with AI: $baseUrl/recipeAI/analyzeFoodImage');
      final token = await _getToken();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/recipeAI/analyzeFoodImage'),
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
        final decodedBody = utf8.decode(response.bodyBytes);
        print('Dish AI Raw Response: $decodedBody');
        
        final dynamic jsonResponse = jsonDecode(decodedBody);
        
        // Handle both {status: "success", data: ...} and raw data formats
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('status')) {
          if (jsonResponse['status'] == 'success') {
             final data = jsonResponse['data'];
             // Handle empty data
             if (data == null || (data is List && data.isEmpty)) {
               // Returning an empty DishAIResponse will trigger the NO_FOOD_DATA in Cubit
               return DishAIResponse(top3: [], ingredients: [], recipes: []);
             }
             return DishAIResponse.fromJson(data);
          } else {
             final msg = jsonResponse['message'] ?? 'อัปโหลดรูปภาพไม่สำเร็จ กรุณาลองใหม่';
             throw Exception(msg);
          }
        } else {
          // Assume raw data directly
          return DishAIResponse.fromJson(jsonResponse);
        }
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        print('Dish AI Failed Response: $errorBody');
        String? extractedMsg;
        try {
          final errJson = jsonDecode(errorBody);
          if (errJson is Map<String, dynamic> && errJson.containsKey('message')) {
            extractedMsg = errJson['message'];
          }
        } catch (_) {}
        
        if (extractedMsg != null) {
          throw Exception(extractedMsg);
        }
        // Fallback
        throw Exception(errorBody.isNotEmpty ? errorBody : 'Failed to predict: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during Dish AI: $e');
      rethrow;
    }
  }

  // POST /recipeAI/analyzeIngredientImage - Identify Ingredients/Recommend Recipes from Image
  Future<DishAIResponse?> analyzeIngredientImage(String filePath) async {
    try {
      print('Analyzing ingredients with AI: $baseUrl/recipeAI/analyzeIngredientImage');
      final token = await _getToken();
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/recipeAI/analyzeIngredientImage'),
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
        final decodedBody = utf8.decode(response.bodyBytes);
        print('Ingredient AI Raw Response: $decodedBody');
        
        final dynamic jsonResponse = jsonDecode(decodedBody);
        
        if (jsonResponse is Map<String, dynamic> && jsonResponse.containsKey('status')) {
          if (jsonResponse['status'] == 'success') {
            final data = jsonResponse['data'];
            // Handle empty data
            if (data == null || (data is List && data.isEmpty)) {
              return DishAIResponse(top3: [], ingredients: [], recipes: []);
            }
            // Since backend is returning recipes, we parse it as DishAIResponse
            return DishAIResponse.fromJson(data);
          } else {
            throw Exception(jsonResponse['message'] ?? 'Ingredient analysis failed');
          }
        } else {
           return DishAIResponse.fromJson(jsonResponse);
        }
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        print('Ingredient AI Failed Response: $errorBody');
        String? extractedMsg;
        try {
          final errJson = jsonDecode(errorBody);
          if (errJson is Map<String, dynamic> && errJson.containsKey('message')) {
            extractedMsg = errJson['message'];
          }
        } catch (_) {}
        
        if (extractedMsg != null) {
          throw Exception(extractedMsg);
        }
        // Fallback
        throw Exception(errorBody.isNotEmpty ? errorBody : 'Failed to analyze: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('Error during Ingredient AI: $e');
      return null;
    }
  }
  
  // GET /recipe/getMyCreateRecipe - Get recipes created by current user
  // (Redundant method removed, using getMyCreateRecipes below)

  // POST /recipe/likeRecipe/{recipe_id} - Like a recipe
  Future<Map<String, dynamic>?> likeRecipe(int recipeId) async {
    try {
      final headers = await _getHeaders();
      print('Liking recipe: $baseUrl/recipe/likeRecipe/$recipeId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/recipe/likeRecipe/$recipeId'),
        headers: headers,
      );

      print('Like Recipe Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']; // Contains like_count and is_liked
        }
      }
      return null;
    } catch (e) {
      print('Error liking recipe: $e');
      throw Exception('Connection error: $e');
    }
  }

  // DELETE /recipe/unlikeRecipe/{recipe_id} - Unlike a recipe
  Future<Map<String, dynamic>?> unlikeRecipe(int recipeId) async {
    try {
      final headers = await _getHeaders();
      print('Unliking recipe: $baseUrl/recipe/unlikeRecipe/$recipeId');
      
      final response = await http.delete(
        Uri.parse('$baseUrl/recipe/unlikeRecipe/$recipeId'),
        headers: headers,
      );

      print('Unlike Recipe Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          return jsonResponse['data']; // Contains like_count and is_liked
        }
      }
      return null;
    } catch (e) {
      print('Error unliking recipe: $e');
      throw Exception('Connection error: $e');
    }
  }

  // GET /users/getUserLikeRecipe - Get recipes liked by current user
  Future<List<RecipeModel>> getUserLikeRecipes() async {
    try {
      final headers = await _getHeaders();
      print('Fetching user liked recipes: $baseUrl/users/getUserLikeRecipe');
      final response = await http.get(
        Uri.parse('$baseUrl/users/getUserLikeRecipe'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'] ?? [];
          return data.map((json) => RecipeModel.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load liked recipes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching liked recipes: $e');
      throw Exception('Connection error: $e');
    }
  }

  Future<bool> addUserStock(UserStockRequest request) async {
    try {
      final headers = await _getHeaders();
      print('Adding user stock: $baseUrl/userStock/addUserStock');
      final response = await http.post(
        Uri.parse('$baseUrl/userStock/addUserStock'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('Add User Stock Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error adding user stock: $e');
      throw Exception('Connection error: $e');
    }
  }

  // PATCH /userStock/updateItemInUserStock/{stock_id}
  Future<bool> updateUserStockItem(int stockId, UserStockUpdateRequest request) async {
    try {
      final headers = await _getHeaders();
      print('Updating user stock: $baseUrl/userStock/updateItemInUserStock/$stockId');
      final response = await http.patch(
        Uri.parse('$baseUrl/userStock/updateItemInUserStock/$stockId'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      print('Update User Stock Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error updating user stock: $e');
      throw Exception('Connection error: $e');
    }
  }

  // GET /userStock/getItemExpireDate/{storage_location}/{item_id}
  Future<String?> getItemExpireDate(String storageLocation, int itemId) async {
    try {
      final headers = await _getHeaders();
      print('Fetching item expire date: $baseUrl/userStock/getItemExpireDate/$storageLocation/$itemId');
      final response = await http.get(
        Uri.parse('$baseUrl/userStock/getItemExpireDate/$storageLocation/$itemId'),
        headers: headers,
      );

      print('Get Item Expire Date Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];
          if (data is Map && data.containsKey('expire_date')) {
            return data['expire_date']?.toString();
          }
          return data?.toString();
        }
      }
      return null;
    } catch (e) {
      print('Error fetching item expire date: $e');
      return null;
    }
  }

  // DELETE /userStock/deleteItemInUserStock/{stock_id}
  Future<bool> deleteUserStockItem(int stockId) async {
    try {
      final headers = await _getHeaders();
      print('Deleting user stock: $baseUrl/userStock/deleteItemInUserStock/$stockId');
      final response = await http.delete(
        Uri.parse('$baseUrl/userStock/deleteItemInUserStock/$stockId'),
        headers: headers,
      );

      print('Delete User Stock Response: ${response.statusCode} ${response.body}');
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return jsonResponse['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Error deleting user stock: $e');
      throw Exception('Connection error: $e');
    }
  }

  // GET /userStock/getUserStockFromStorage/{storage_location}
  Future<List<UserStockModel>> getUserStockFromStorage(String storageLocation) async {
    try {
      final headers = await _getHeaders();
      print('Fetching user stock from $storageLocation: $baseUrl/userStock/getUserStockFromStorage/$storageLocation');
      final response = await http.get(
        Uri.parse('$baseUrl/userStock/getUserStockFromStorage/$storageLocation'),
        headers: headers,
      );

      print('Get User Stock Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'] ?? [];
          return data.map((json) => UserStockModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching user stock from storage: $e');
      return [];
    }
  }

  // GET /recipe/getRecommendRecipeFromStock
  Future<List<RecipeModel>> getRecommendRecipeFromStock() async {
    try {
      final headers = await _getHeaders();
      print('Fetching recommend recipes from stock: $baseUrl/recipe/getRecommendRecipeFromStock');
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getRecommendRecipeFromStock'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => RecipeModel.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load recommend recipes from stock: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recommend recipes from stock: $e');
      throw Exception('Connection error: $e');
    }
  }

  // GET /recipe/getRecommendRecipeForYou
  Future<List<RecipeModel>> getRecommendRecipeForYou() async {
    try {
      final headers = await _getHeaders();
      print('Fetching recommend recipes for you: $baseUrl/recipe/getRecommendRecipeForYou');
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getRecommendRecipeForYou'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => RecipeModel.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load recommend recipes for you: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching recommend recipes for you: $e');
      throw Exception('Connection error: $e');
    }
  }

  // GET /recipe/getMyCreateRecipe
  Future<List<RecipeModel>> getMyCreateRecipes() async {
    try {
      final headers = await _getHeaders();
      print('Fetching my create recipes: $baseUrl/recipe/getMyCreateRecipe');
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getMyCreateRecipe'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'] ?? [];
          return data.map((json) => RecipeModel.fromJson(json)).toList();
        } else {
          return [];
        }
      } else {
        throw Exception('Failed to load my created recipes: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching my created recipes: $e');
      throw Exception('Connection error: $e');
    }
  }

  // POST /recipeAI/generateRecipeImage
  Future<String?> generateRecipeImage(String recipeName, List<String> ingredients) async {
    try {
      print('Generating recipe image with AI: $baseUrl/recipeAI/generateRecipeImage');
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/recipeAI/generateRecipeImage'),
        headers: headers,
        body: jsonEncode({
          'recipe_name': recipeName,
          'ingredients': ingredients,
        }),
      ).timeout(const Duration(seconds: 90));

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        print('Image Gen Response Body: $decodedBody');
        final jsonResponse = jsonDecode(decodedBody);
        
        if (jsonResponse['status'] == 'success') {
          final data = jsonResponse['data'];
          print('Extracted data field: $data (Type: ${data.runtimeType})');
          
          String? base64Data;
          
          if (data is String) {
            if (data.startsWith('http')) {
              print('Data is a URL: $data');
              return data;
            }
            print('Data is a string, assuming base64');
            base64Data = data;
          } else if (data is Map) {
            print('Data is a Map. Keys: ${data.keys}');
            if (data.containsKey('image_base64')) {
              base64Data = data['image_base64'];
              print('Found image_base64 in Map');
            } else if (data.containsKey('base64')) {
              base64Data = data['base64'];
              print('Found base64 in Map');
            } else {
              final url = data['image_url'] ?? data['url'] ?? data['data'];
              if (url != null) {
                print('Found URL in Map: $url');
                return url.toString();
              }
            }
          }

          if (base64Data != null && base64Data is String) {
            try {
              print('Attempting to decode base64 data (length: ${base64Data.length})');
              // Remove data URI prefix if present
              if (base64Data.contains(',')) {
                base64Data = base64Data.split(',').last;
              }
              
              final bytes = base64Decode(base64Data.trim());
              final tempDir = await getTemporaryDirectory();
              final fileName = 'ai_gen_${DateTime.now().millisecondsSinceEpoch}.jpg';
              final file = File('${tempDir.path}/$fileName');
              await file.writeAsBytes(bytes);
              print('SUCCESS: Saved AI image to temp file: ${file.path}');
              return file.path;
            } catch (e) {
              print('ERROR decoding/saving base64: $e');
            }
          } else {
            print('No base64 data or URL found in response data');
          }
        }
      }
      print('Image Gen Error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Error generating image (Exception): $e');
      return null;
    }
  }

  // GET /recipe/getRecipeCategory
  Future<List<Map<String, dynamic>>> getRecipeCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getRecipeCategory'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.cast<Map<String, dynamic>>();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // GET /recipe/getRecipeByCategory/{category_id}
  Future<List<RecipeModel>> getRecipeByCategory(int categoryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/recipe/getRecipeByCategory/$categoryId'),
        headers: headers,
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
        if (jsonResponse['status'] == 'success') {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((json) => RecipeModel.fromJson(json)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error fetching recipes by category: $e');
      return [];
    }
  }
}
