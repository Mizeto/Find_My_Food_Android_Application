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
      final recipes = await _recipeService.generateNewRecipeByAI(recipeName);
      if (recipes.isNotEmpty) {
        var recipeModel = recipes.first;
        
        // Fallback: If AI returns an existing recipe ID but no ingredients/steps, fetch them!
        if (recipeModel.recipeId > 0 && 
           (recipeModel.ingredients == null || recipeModel.ingredients!.isEmpty)) {
          print('DEBUG: AI returned truncated recipe (ID: ${recipeModel.recipeId}). Fetching full details...');
          try {
            final fullRecipe = await _recipeService.getRecipeDetailById(recipeModel.recipeId);
            recipeModel = fullRecipe;
          } catch (e) {
            print('DEBUG: Failed to fetch full details: $e. Proceeding with partial data.');
          }
        }

        // IMPORTANT: Reset ID to 0 so AddFoodScreen treats this as a NEW recipe creation
        recipeModel = recipeModel.copyWith(recipeId: 0);

        emit(ScanFoodSuccess(
          ingredients: recipeModel.ingredients?.map((e) => e.ingredientName).toList() ?? [],
          recipeModel: recipeModel,
          dishResponse: DishAIResponse(
            top3: [DishPrediction(className: recipeName, confidence: 1.0)],
            recipes: [], 
            ingredients: recipeModel.ingredients?.map((e) => e.ingredientName).toList() ?? [],
            tags: recipeModel.tagDetails ?? [],
          ),
        ));
      } else {
        emit(const ScanFoodError('ไม่สามารถสร้างสูตรอาหารได้'));
      }
    } catch (e) {
      emit(ScanFoodError('Error: ${e.toString()}'));
    }
  }
}
