import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import '../../home/services/food_service.dart';
import '../../home/models/food_model.dart';
import '../services/ai_service.dart';
import 'dart:convert';

part 'scan_food_state.dart';

class ScanFoodCubit extends Cubit<ScanFoodState> {
  final RecipeService _recipeService;
  final AiService _aiService;

  ScanFoodCubit({RecipeService? recipeService, AiService? aiService}) 
      : _recipeService = recipeService ?? RecipeService(),
        _aiService = aiService ?? AiService(),
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
        
        emit(ScanFoodSuccess(dishResponse: dishResult));
      } else {
        // 2. Identify Ingredients (via Local Gemini)
        final bytes = await image.readAsBytes();
        final jsonString = await _aiService.identifyIngredients(bytes);
        final cleanJson = jsonString.replaceAll('```json', '').replaceAll('```', '').trim();
        
        List<String> ingredients = [];
        try {
          ingredients = List<String>.from(jsonDecode(cleanJson));
        } catch (e) {
          ingredients = cleanJson.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',');
        }

        if (ingredients.isEmpty) {
          emit(const ScanFoodError('ไม่พบวัตถุดิบในภาพ'));
          return;
        }
        
        emit(ScanFoodSuccess(ingredients: ingredients));
      }

    } catch (e) {
      emit(ScanFoodError('ผิดพลาด: ${e.toString()}'));
    }
  }
}
