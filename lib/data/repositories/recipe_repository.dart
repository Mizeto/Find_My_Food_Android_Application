import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/recipe_model.dart';
import '../../features/home/services/food_service.dart';
import '../../features/home/models/food_model.dart';

class RecipeRepository {
  final FoodService _foodService = FoodService();

  Future<List<Recipe>> getRecipes({String? search}) async {
    try {
      List<FoodModel> foods;
      if (search != null && search.isNotEmpty) {
        foods = await _foodService.getFoodByName(search);
      } else {
        foods = await _foodService.getAllFood();
      }

      // Map FoodModel (External API) -> Recipe (Internal App Model)
      return foods.map((food) => Recipe(
        id: food.foodId,
        title: food.name,
        description: 'เมนูยอดนิยมจากเพื่อนคุณ', // Default description
        cookingMethod: 'ดูวิธีทำได้ที่ร้านค้าหรือวิดีโอแนะนำ', // Default method
        imageUrl: food.imageUrl,
        prepTime: 15 + (food.foodId % 30), // Randomize time 15-45 mins
      )).toList();

    } catch (e) {
      throw Exception('Error loading foods: $e');
    }
  }
}
