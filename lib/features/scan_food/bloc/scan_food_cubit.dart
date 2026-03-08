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

  Future<void> analyzeImage(XFile image, {required bool isDishPrediction}) async {
    emit(ScanFoodLoading());

    try {
      if (isDishPrediction) {
        // 1. Predict Dish (via Backend API)
        final dishResult = await _recipeService.predictDishAI(image.path);
        
        if (dishResult == null || dishResult.top3.isEmpty) {
          emit(const ScanFoodError('ไม่สามารถวิเคราะห์เมนูอาหารได้'));
          return;
        }
        
        emit(ScanFoodSuccess(
          ingredients: dishResult.ingredients,
          dishResponse: dishResult,
        ));
      } else {
        // 2. Identify Ingredients/Recommend Recipes (via Backend API)
        final result = await _recipeService.analyzeIngredientImage(image.path);

        if (result == null || (result.top3.isEmpty && (result.recipes == null || result.recipes!.isEmpty))) {
          emit(const ScanFoodError('ไม่พบข้อมูลจากการวิเคราะห์'));
          return;
        }
        
        emit(ScanFoodSuccess(
          ingredients: result.ingredients,
          dishResponse: result,
        ));
      }

    } catch (e) {
      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      emit(ScanFoodError(errorMsg));
    }
  }
}
