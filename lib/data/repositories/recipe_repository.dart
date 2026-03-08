import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import '../../features/home/services/food_service.dart';
import '../../features/home/models/food_model.dart';

class RecipeRepository {
  final RecipeService _recipeService = RecipeService();

  Future<List<Recipe>> getRecipes({String? search}) async {
    try {
      List<RecipeModel> apiRecipes;
      if (search != null && search.isNotEmpty) {
        apiRecipes = await _recipeService.getRecipeByName(search);
      } else {
        apiRecipes = await _recipeService.getAllRecipes();
      }

      // Map API RecipeModel -> Internal Recipe
      return apiRecipes.map((apiRecipe) {
        // Convert steps to string for cookingMethod if available, else default
        String method = 'ดูวิธีทำได้ที่ร้านค้าหรือวิดีโอแนะนำ';
        if (apiRecipe.steps != null && apiRecipe.steps!.isNotEmpty) {
          method = apiRecipe.steps!.map((s) => '${s.stepNo}. ${s.instruction}').join('\n');
        }

        return Recipe(
          id: apiRecipe.recipeId,
          title: apiRecipe.recipeName,
          description: apiRecipe.description.isNotEmpty ? apiRecipe.description : 'ไม่มีคำอธิบาย',
          cookingMethod: method,
          imageUrl: apiRecipe.imageUrl,
          prepTime: apiRecipe.cookingTimeMin, // Use actual time from API
          likeCount: apiRecipe.likeCount, // Add this
        );
      }).toList();

    } catch (e) {
      throw Exception('Error loading recipes: $e');
    }
  }

  Future<Recipe> getRecipeDetail(int id) async {
    try {
       final apiRecipe = await _recipeService.getRecipeDetailById(id);
       
       String method = 'ดูวิธีทำได้ที่ร้านค้าหรือวิดีโอแนะนำ';
       if (apiRecipe.steps != null && apiRecipe.steps!.isNotEmpty) {
          method = apiRecipe.steps!.map((s) => '${s.stepNo}. ${s.instruction}').join('\n');
       }

       // Convert ingredients from RecipeIngredient to RecipeIngredientItem
       List<RecipeIngredientItem>? ingredientItems;
       if (apiRecipe.ingredients != null && apiRecipe.ingredients!.isNotEmpty) {
          ingredientItems = apiRecipe.ingredients!.map((ing) => RecipeIngredientItem(
            ingredientId: ing.ingredientId,
            ingredientName: ing.ingredientName,
            quantity: ing.quantityValue,
            unitId: ing.unitId,
            unitName: ing.unitName,
            isMainIngredient: ing.isMainIngredient,
          )).toList();
       }

       return Recipe(
          id: apiRecipe.recipeId,
          title: apiRecipe.recipeName,
          description: apiRecipe.description,
          cookingMethod: method,
          imageUrl: apiRecipe.imageUrl,
          prepTime: apiRecipe.cookingTimeMin,
          likeCount: apiRecipe.likeCount, // Add this
          ingredients: ingredientItems,
       );
    } catch (e) {
      throw Exception('Error loading recipe detail: $e');
    }
  }
  Future<bool> createRecipe(Map<String, dynamic> data) async {
    return _recipeService.createNewRecipe(data);
  }

  Future<String?> uploadImage(String filePath) async {
    return _recipeService.uploadNewRecipeImage(filePath);
  }

  Future<bool> updateRecipeHeader(int id, Map<String, dynamic> data) async {
    return _recipeService.updateRecipeHeaderById(id, data);
  }

  Future<bool> updateRecipeIngredients(int id, List<Map<String, dynamic>> ingredients) async {
    return _recipeService.updateRecipeIngredientById(id, ingredients);
  }

  Future<bool> updateRecipeSteps(int id, List<Map<String, dynamic>> steps) async {
    return _recipeService.updateRecipeStepById(id, steps);
  }
  Future<List<UnitModel>> getUnits() async {
    return _recipeService.getAllUnits();
  }

  Future<List<IngredientModel>> getIngredientByName(String name) async {
    return _recipeService.getIngredientByNameSearch(name);
  }

  Future<bool> addUserStock(UserStockRequest request) async {
    return _recipeService.addUserStock(request);
  }

  Future<bool> updateUserStock(int stockId, UserStockUpdateRequest request) async {
    return _recipeService.updateUserStockItem(stockId, request);
  }

  Future<bool> deleteUserStock(int stockId) async {
    return _recipeService.deleteUserStockItem(stockId);
  }

  Future<List<UserStockModel>> getUserStockByStorage(String storageLocation) async {
    return _recipeService.getUserStockFromStorage(storageLocation);
  }

  Future<String?> getItemExpireDate(String storageLocation, int itemId) async {
    return _recipeService.getItemExpireDate(storageLocation, itemId);
  }

  Future<List<Recipe>> getRecommendFromStock() async {
    try {
      final apiRecipes = await _recipeService.getRecommendRecipeFromStock();
      return _mapRecipes(apiRecipes);
    } catch (e) {
      throw Exception('Error loading recommendations from stock: $e');
    }
  }

  Future<List<Recipe>> getRecommendForYou() async {
    try {
      final apiRecipes = await _recipeService.getRecommendRecipeForYou();
      return _mapRecipes(apiRecipes);
    } catch (e) {
      throw Exception('Error loading recommendations for you: $e');
    }
  }

  Future<List<Recipe>> getMyRecipes() async {
    try {
      final apiRecipes = await _recipeService.getMyCreateRecipes();
      return _mapRecipes(apiRecipes);
    } catch (e) {
      throw Exception('Error loading my recipes: $e');
    }
  }

  List<Recipe> _mapRecipes(List<RecipeModel> apiRecipes) {
    return apiRecipes.map((apiRecipe) {
      String method = 'ดูวิธีทำได้ที่ร้านค้าหรือวิดีโอแนะนำ';
      if (apiRecipe.steps != null && apiRecipe.steps!.isNotEmpty) {
        method = apiRecipe.steps!.map((s) => '${s.stepNo}. ${s.instruction}').join('\n');
      }

      return Recipe(
        id: apiRecipe.recipeId,
        title: apiRecipe.recipeName,
        description: apiRecipe.description.isNotEmpty ? apiRecipe.description : 'ไม่มีคำอธิบาย',
        cookingMethod: method,
        imageUrl: apiRecipe.imageUrl,
        prepTime: apiRecipe.cookingTimeMin,
        likeCount: apiRecipe.likeCount, // Add this
      );
    }).toList();
  }
}
