import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../home/services/food_service.dart';
import '../../home/models/food_model.dart';

part 'scan_food_state.dart';

class ScanFoodCubit extends Cubit<ScanFoodState> {
  final RecipeService _recipeService;

  ScanFoodCubit({RecipeService? recipeService}) 
      : _recipeService = recipeService ?? RecipeService(),
        super(ScanFoodInitial());

  Future<void> analyzeImage(XFile image, {required bool isDishPrediction, bool forceSearch = true}) async {
    emit(ScanFoodLoading());

    try {
      if (isDishPrediction) {
        // 1. Predict Dish (via Backend API)
        final dishResult = await _recipeService.predictDishAI(image.path, forceSearch: forceSearch);
        
        if (dishResult == null) {
          emit(const ScanFoodError('ไม่พบวัตถุในรูปภาพ'));
          return;
        }
        
        if (dishResult.top3.isEmpty && 
            dishResult.ingredients.isEmpty && 
            (dishResult.recipes == null || dishResult.recipes!.isEmpty) &&
            (dishResult.predictedNames == null || dishResult.predictedNames!.isEmpty)) {
          emit(const ScanFoodError('NO_FOOD_DATA'));
          return;
        }
        
        emit(ScanFoodSuccess(
          ingredients: dishResult.ingredients,
          predictedNames: dishResult.predictedNames ?? [],
          dishResponse: dishResult,
        ));
      } else {
        // 2. Identify Ingredients/Recommend Recipes (via Backend API)
        final result = await _recipeService.analyzeIngredientImage(image.path);

        if (result == null) {
          emit(const ScanFoodError('ไม่พบวัตถุในรูปภาพ'));
          return;
        }

        if (result.top3.isEmpty && 
            result.ingredients.isEmpty && 
            (result.recipes == null || result.recipes!.isEmpty) &&
            (result.predictedNames == null || result.predictedNames!.isEmpty)) {
          emit(const ScanFoodError('NO_FOOD_DATA'));
          return;
        }
        
        emit(ScanFoodSuccess(
          ingredients: result.ingredients,
          predictedNames: result.predictedNames ?? [],
          dishResponse: result,
        ));
      }

    } catch (e) {
      emit(const ScanFoodError('ไม่พบวัตถุในรูปภาพ'));
    }
  }

  Future<void> generateAIRecipe(String recipeName) async {
    emit(ScanFoodLoading());
    try {
      var recipes = await _recipeService.generateNewRecipeByAI(recipeName);
      RecipeModel? recipeModel;

      if (recipes.isNotEmpty) {
        recipeModel = recipes.first;
      } else {
        // FALLBACK: If AI returned success but null/empty data, try to find the new stub manually
        print('DEBUG: AI returned no data. Searching user created recipes for "$recipeName"...');
        try {
          final myRecipes = await _recipeService.getMyCreateRecipes();
          // Find the newest recipe that matches the name
          final matching = myRecipes.where((r) => r.recipeName.toLowerCase().trim() == recipeName.toLowerCase().trim()).toList();
          if (matching.isNotEmpty) {
             // getMyCreateRecipes is usually sorted by ID desc, so first is newest
             recipeModel = matching.first;
             print('DEBUG: Found matching stub! ID: ${recipeModel.recipeId}');
          }
        } catch (e) {
          print('DEBUG: Fallback search failed: $e');
        }
      }

      if (recipeModel != null) {
        // Fallback: If AI returns an existing recipe ID but no ingredients/steps, fetch them!
        if (recipeModel.recipeId > 0 && 
           (recipeModel.ingredients == null || recipeModel.ingredients!.isEmpty)) {
          print('DEBUG: Recipe (ID: ${recipeModel.recipeId}) has no ingredients. Fetching full details...');
          try {
            final fullRecipe = await _recipeService.getRecipeDetailById(recipeModel.recipeId);
            recipeModel = fullRecipe;
          } catch (e) {
            print('DEBUG: Failed to fetch full details: $e. Proceeding with partial data.');
          }
        }

        // IMPORTANT: We MUST leave the recipeId as is so AddFoodScreen can update the stub record
        
        emit(ScanFoodSuccess(
          ingredients: recipeModel?.ingredients?.map((e) => e.ingredientName).toList() ?? [],
          recipeModel: recipeModel,
          dishResponse: DishAIResponse(
            top3: [DishPrediction(className: recipeName, confidence: 1.0)],
            recipes: [], 
            ingredients: recipeModel?.ingredients?.map((e) => e.ingredientName).toList() ?? [],
            tags: recipeModel?.tagDetails ?? [],
          ),
        ));
      } else {
        emit(const ScanFoodError('ไม่สามารถสร้างสูตรอาหารได้ (หาข้อมูลไม่พบ)'));
      }
    } catch (e) {
      emit(ScanFoodError('Error: ${e.toString()}'));
    }
  }
}
