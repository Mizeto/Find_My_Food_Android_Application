class RecipeModel {
  final int recipeId;
  final String recipeName;
  final String description;
  final int cookingTimeMin;
  final String imageUrl;
  final String username;
  final String? createDate;
  final bool isPublic;
  final bool isActive;

  final List<RecipeIngredient>? ingredients;
  final List<RecipeStep>? steps;

  RecipeModel({
    required this.recipeId,
    required this.recipeName,
    required this.description,
    required this.cookingTimeMin,
    required this.imageUrl,
    required this.username,
    this.createDate,
    this.isPublic = true,
    this.isActive = true,
    this.ingredients,
    this.steps,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    var ingredientsList = json['ingredients'] as List?;
    var stepsList = json['steps'] as List?;

    return RecipeModel(
      recipeId: json['recipe_id'] as int,
      recipeName: json['recipe_name'] as String,
      description: json['description'] as String? ?? '',
      cookingTimeMin: json['cooking_time_min'] as int? ?? 0,
      imageUrl: json['image_url'] as String,
      username: json['username'] as String? ?? '',
      createDate: json['create_date'] as String?,
      isPublic: json['is_public'] as bool? ?? true,
      isActive: json['is_active'] as bool? ?? true,
      ingredients: ingredientsList?.map((i) => RecipeIngredient.fromJson(i)).toList(),
      steps: stepsList?.map((s) => RecipeStep.fromJson(s)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'recipe_id': recipeId,
      'recipe_name': recipeName,
      'description': description,
      'cooking_time_min': cookingTimeMin,
      'image_url': imageUrl,
      'username': username,
      'create_date': createDate,
      'is_public': isPublic,
      'is_active': isActive,
      'ingredients': ingredients?.map((i) => i.toJson()).toList(),
      'steps': steps?.map((s) => s.toJson()).toList(),
    };
  }
}

class RecipeIngredient {
  final int ingredientId;
  final String ingredientName;
  // final IconData? quantity; // Removed erroneous field
  final double quantityValue; // JSON says "quantity": 1
  final int unitId;
  final String unitName;

  RecipeIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityValue,
    required this.unitId,
    required this.unitName,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientId: json['ingredient_id'] as int,
      ingredientName: json['ingredient_name'] as String,
      quantityValue: (json['quantity'] as num).toDouble(),
      unitId: json['unit_id'] as int,
      unitName: json['unit_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
      'quantity': quantityValue,
      'unit_id': unitId,
      'unit_name': unitName,
    };
  }
}

class RecipeStep {
  final int stepNo;
  final String instruction;

  RecipeStep({
    required this.stepNo,
    required this.instruction,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNo: json['step_no'] as int,
      instruction: json['instruction'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step_no': stepNo,
      'instruction': instruction,
    };
  }
}

class UnitModel {
  final int unitId;
  final String unitName;

  UnitModel({
    required this.unitId,
    required this.unitName,
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) {
    return UnitModel(
      unitId: json['unit_id'] as int,
      unitName: json['unit_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'unit_id': unitId,
      'unit_name': unitName,
    };
  }
}

class IngredientModel {
  final int ingredientId;
  final String ingredientName;

  IngredientModel({
    required this.ingredientId,
    required this.ingredientName,
  });

  factory IngredientModel.fromJson(Map<String, dynamic> json) {
    return IngredientModel(
      ingredientId: json['ingredient_id'] as int,
      ingredientName: json['ingredient_name'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
    };
  }
}

class DishPrediction {
  final String className;
  final double confidence;

  DishPrediction({
    required this.className,
    required this.confidence,
  });

  factory DishPrediction.fromJson(Map<String, dynamic> json) {
    return DishPrediction(
      className: json['class_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}

class DishAIResponse {
  final List<DishPrediction> top3;

  DishAIResponse({required this.top3});

  factory DishAIResponse.fromJson(Map<String, dynamic> json) {
    final list = json['top_3'] as List;
    return DishAIResponse(
      top3: list.map((e) => DishPrediction.fromJson(e)).toList(),
    );
  }
}
