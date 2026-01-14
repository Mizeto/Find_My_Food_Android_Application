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

       return Recipe(
          id: apiRecipe.recipeId,
          title: apiRecipe.recipeName,
          description: apiRecipe.description,
          cookingMethod: method,
          imageUrl: apiRecipe.imageUrl,
          prepTime: apiRecipe.cookingTimeMin,
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
}
