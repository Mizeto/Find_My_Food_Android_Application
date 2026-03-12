import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/models/food_model.dart';
import '../../../data/repositories/recipe_repository.dart';

class CreateRecipeState {
  final bool isLoading;
  final String? error;
  final bool isSuccess;

  // Form fields
  final String title;
  final String description;
  final int cookingTime;
  final String? imagePath;
  final bool isPublic;

  // Selected lists
  final List<CategoryModel> selectedCategories;
  final List<TagModel> selectedTags;
  
  // Ingredients and Steps
  final List<Map<String, dynamic>> ingredients;
  final List<String> steps;

  // Options
  final List<CategoryModel> availableCategories;
  final List<TagModel> availableTags;
  final List<UnitModel> availableUnits;

  CreateRecipeState({
    this.isLoading = false,
    this.error,
    this.isSuccess = false,
    this.title = '',
    this.description = '',
    this.cookingTime = 0,
    this.imagePath,
    this.isPublic = true,
    this.selectedCategories = const [],
    this.selectedTags = const [],
    this.ingredients = const [],
    this.steps = const [],
    this.availableCategories = const [],
    this.availableTags = const [],
    this.availableUnits = const [],
  });

  CreateRecipeState copyWith({
    bool? isLoading,
    String? error,
    bool? isSuccess,
    String? title,
    String? description,
    int? cookingTime,
    String? imagePath,
    bool? isPublic,
    List<CategoryModel>? selectedCategories,
    List<TagModel>? selectedTags,
    List<Map<String, dynamic>>? ingredients,
    List<String>? steps,
    List<CategoryModel>? availableCategories,
    List<TagModel>? availableTags,
    List<UnitModel>? availableUnits,
  }) {
    return CreateRecipeState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // overwrite explicitly
      isSuccess: isSuccess ?? this.isSuccess,
      title: title ?? this.title,
      description: description ?? this.description,
      cookingTime: cookingTime ?? this.cookingTime,
      imagePath: imagePath ?? this.imagePath,
      isPublic: isPublic ?? this.isPublic,
      selectedCategories: selectedCategories ?? this.selectedCategories,
      selectedTags: selectedTags ?? this.selectedTags,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      availableCategories: availableCategories ?? this.availableCategories,
      availableTags: availableTags ?? this.availableTags,
      availableUnits: availableUnits ?? this.availableUnits,
    );
  }
}

class CreateRecipeCubit extends Cubit<CreateRecipeState> {
  final RecipeRepository repository;

  CreateRecipeCubit(this.repository) : super(CreateRecipeState());

  Future<void> fetchOptions() async {
    emit(state.copyWith(isLoading: true));
    try {
      final categories = await repository.getCategoryModels();
      final tags = await repository.getTags();
      final units = await repository.getUnits();
      emit(state.copyWith(
        isLoading: false,
        availableCategories: categories,
        availableTags: tags,
        availableUnits: units,
      ));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'ไม่สามารถโหลดข้อมูลตัวเลือกได้: $e'));
    }
  }

  void updateBasicInfo({
    String? title,
    String? description,
    int? cookingTime,
    bool? isPublic,
  }) {
    emit(state.copyWith(
      title: title,
      description: description,
      cookingTime: cookingTime,
      isPublic: isPublic,
      error: null,
    ));
  }

  void setImagePath(String path) {
    emit(state.copyWith(imagePath: path));
  }

  void toggleCategory(CategoryModel category) {
    final list = List<CategoryModel>.from(state.selectedCategories);
    if (list.any((c) => c.categoryId == category.categoryId)) {
      list.removeWhere((c) => c.categoryId == category.categoryId);
    } else {
      list.add(category);
    }
    emit(state.copyWith(selectedCategories: list));
  }

  void toggleTag(TagModel tag) {
    final list = List<TagModel>.from(state.selectedTags);
    if (list.any((t) => t.tagId == tag.tagId)) {
      list.removeWhere((t) => t.tagId == tag.tagId);
    } else {
      list.add(tag);
    }
    emit(state.copyWith(selectedTags: list));
  }

  // Ingredient: { ingredientId: int, quantity: double, unitId: int, isMainIngredient: bool, name: String (for UI only) }
  void addIngredient(Map<String, dynamic> ingredient) {
    final list = List<Map<String, dynamic>>.from(state.ingredients);
    list.add(ingredient);
    emit(state.copyWith(ingredients: list));
  }

  void removeIngredient(int index) {
    final list = List<Map<String, dynamic>>.from(state.ingredients);
    list.removeAt(index);
    emit(state.copyWith(ingredients: list));
  }

  void addStep(String stepInstruction) {
    final list = List<String>.from(state.steps);
    list.add(stepInstruction);
    emit(state.copyWith(steps: list));
  }

  void removeStep(int index) {
    final list = List<String>.from(state.steps);
    list.removeAt(index);
    emit(state.copyWith(steps: list));
  }

  Future<void> submit() async {
    if (state.title.isEmpty || state.description.isEmpty) {
      emit(state.copyWith(error: 'กรุณากรอกชื่อและคำอธิบายสูตร'));
      return;
    }
    if (state.ingredients.isEmpty) {
      emit(state.copyWith(error: 'กรุณาเพิ่มวัตถุดิบอย่างน้อย 1 รายการ'));
      return;
    }
    if (state.steps.isEmpty) {
      emit(state.copyWith(error: 'กรุณาเพิ่มขั้นตอนการทำอย่างน้อย 1 ขั้นตอน'));
      return;
    }

    emit(state.copyWith(isLoading: true, error: null));
    try {
      String? uploadedImageUrl;
      if (state.imagePath != null && state.imagePath!.isNotEmpty) {
        uploadedImageUrl = await repository.uploadImage(state.imagePath!);
      }

      // Prepare payload mapping
      final payload = {
        "recipe_name": state.title,
        "description": state.description,
        "cooking_time_min": state.cookingTime,
        "image_url": uploadedImageUrl ?? "https://placehold.co/600x400.png",
        "is_public": state.isPublic,
        "categories": state.selectedCategories.map((c) => c.categoryId).toList(),
        "tags": state.selectedTags.map((t) => t.tagId).toList(),
        "ingredients": state.ingredients.map((ing) {
          return {
            "ingredient_id": ing['ingredientId'],
            "quantity": ing['quantity'],
            "unit_id": ing['unitId'],
            "is_main_ingredient": ing['isMainIngredient'] ?? false
          };
        }).toList(),
        "steps": state.steps.asMap().entries.map((entry) {
          return {
            "step_no": entry.key + 1,
            "instruction": entry.value
          };
        }).toList(),
      };

      final success = await repository.createRecipe(payload);
      if (success) {
        emit(state.copyWith(isLoading: false, isSuccess: true));
      } else {
        emit(state.copyWith(isLoading: false, error: 'บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง'));
      }
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: 'ข้อผิดพลาด: $e'));
    }
  }
}
