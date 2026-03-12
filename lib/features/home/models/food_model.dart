import '../../../data/models/recipe_model.dart';

class RecipeModel {
  final int recipeId;
  final String recipeName;
  final String description;
  final int cookingTimeMin;
  final String imageUrl;
  final String username;
  final String? createDate;
  final int likeCount; // Add this
  final bool isLiked; // Add this
  final bool isPublic;
  final bool isActive;
  final List<String>? tags;
  final List<CategoryModel>? categoryDetails;
  final List<TagModel>? tagDetails;

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
    this.likeCount = 0,
    this.isLiked = false,
    this.isPublic = true,
    this.isActive = true,
    this.tags,
    this.categoryDetails,
    this.tagDetails,
    this.ingredients,
    this.steps,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    var ingredientsList = json['ingredients'] as List?;
    var stepsList = json['steps'] as List?;

    // Safe tags parsing
    List<String> parsedTags = [];
    try {
      if (json['tags'] != null && json['tags'] is List) {
        parsedTags = (json['tags'] as List).map((t) => t.toString()).toList();
      }
    } catch (_) {
      parsedTags = [];
    }

    return RecipeModel(
      recipeId: json['recipe_id'] ?? 0,
      recipeName: json['recipe_name'] ?? '',
      description: json['description']?.toString() ?? '',
      cookingTimeMin: (json['cooking_time_min'] as num?)?.toInt() ?? 0,
      imageUrl: json['image_url'] ?? '',
      username: json['username'] ?? '',
      createDate: json['create_date']?.toString(),
      likeCount: (json['like_count'] as num?)?.toInt() ?? 0,
      isLiked: json['is_liked'] == true,
      isPublic: json['is_public'] == true,
      isActive: json['is_active'] == true,
      tags: parsedTags,
      categoryDetails: json['category_details'] == null 
          ? null 
          : (json['category_details'] as List).map((c) => CategoryModel.fromJson(c)).toList(),
      tagDetails: json['tag_details'] == null 
          ? null 
          : (json['tag_details'] as List).map((t) => TagModel.fromJson(t)).toList(),
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
      'like_count': likeCount,
      'is_liked': isLiked,
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
  final bool isMainIngredient;

  RecipeIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityValue,
    required this.unitId,
    required this.unitName,
    this.isMainIngredient = false,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientId: json['ingredient_id'] ?? 0,
      ingredientName: json['ingredient_name'] ?? '',
      quantityValue: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitId: json['unit_id'] ?? 0,
      unitName: json['unit_name'] ?? '',
      isMainIngredient: json['is_main_ingredient'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'ingredient_name': ingredientName,
      'quantity': quantityValue,
      'unit_id': unitId,
      'unit_name': unitName,
      'is_main_ingredient': isMainIngredient,
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
      stepNo: json['step_no'] ?? 0,
      instruction: json['instruction'] ?? '',
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
      unitId: json['unit_id'] ?? 0,
      unitName: json['unit_name'] ?? '',
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
      ingredientId: json['ingredient_id'] ?? 0,
      ingredientName: json['ingredient_name'] ?? '',
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
    // Robust parsing for various backend formats
    final name = json['class_name'] ?? json['recipe_name'] ?? json['label'] ?? json['prediction'] ?? 'ไม่ทราบข้อมูล';
    
    // Safety against Null is not a subtype of num
    double conf = 0.0;
    final rawConf = json['confidence'] ?? json['score'] ?? json['probability'];
    if (rawConf is num) {
      conf = rawConf.toDouble();
    } else if (rawConf is String) {
      conf = double.tryParse(rawConf) ?? 0.0;
    } else if (name != 'ไม่ทราบข้อมูล' && rawConf == null) {
      // If we have a name but no confidence, default to 1.0 (100%) or something visible
      conf = 1.0; 
    }

    return DishPrediction(
      className: name.toString(),
      confidence: conf,
    );
  }
}

class DishAIResponse {
  final List<DishPrediction> top3;
  final List<Recipe>? recipes;
  final List<String> ingredients;

  DishAIResponse({required this.top3, this.recipes, this.ingredients = const []});

  factory DishAIResponse.fromJson(dynamic json) {
    List<Recipe>? recipes;
    List<DishPrediction> predictions = [];

    if (json is List) {
      recipes = json.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();
      predictions = recipes.map((r) => DishPrediction(className: r.title, confidence: 1.0)).toList();
      
      return DishAIResponse(
        top3: predictions,
        recipes: recipes,
        ingredients: const [],
      );
    }
    
    final list = (json['top_3'] ?? json['results'] ?? json['predictions']) as List?;
    predictions = list?.map((e) => DishPrediction.fromJson(e as Map<String, dynamic>)).toList() ?? [];
    
    final ingredientsList = (json['ingredients'] ?? json['items']) as List?;
    final ingredients = ingredientsList?.map((e) => e.toString()).toList() ?? [];
    
    final recipesList = (json['recipes'] ?? json['data']) as List?;
    recipes = recipesList?.map((e) => Recipe.fromJson(e as Map<String, dynamic>)).toList();

    return DishAIResponse(
      top3: predictions,
      recipes: recipes,
      ingredients: ingredients,
    );
  }
}

class UserStockRequest {
  final int? ingredientId;
  final String itemName;
  final double quantity;
  final int unitId;
  final String? expireDate;
  final String storageLocation;

  UserStockRequest({
    this.ingredientId,
    required this.itemName,
    required this.quantity,
    required this.unitId,
    this.expireDate,
    required this.storageLocation,
  });

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'item_name': itemName,
      'quantity': quantity,
      'unit_id': unitId,
      'expire_date': expireDate,
      'storage_location': storageLocation,
    };
  }
}

class UserStockModel {
  final int stockId;
  final int? ingredientId;
  final String itemName;
  final double quantity;
  final int unitId;
  final String unitName;
  final String? expireDate;
  final String storageLocation;

  UserStockModel({
    required this.stockId,
    this.ingredientId,
    required this.itemName,
    required this.quantity,
    required this.unitId,
    required this.unitName,
    this.expireDate,
    required this.storageLocation,
  });

  factory UserStockModel.fromJson(Map<String, dynamic> json) {
    return UserStockModel(
      stockId: json['stock_id'] ?? 0,
      ingredientId: json['ingredient_id'],
      itemName: json['item_name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitId: json['unit_id'] ?? 0,
      unitName: json['unit_name'] ?? '',
      expireDate: json['expire_date'] as String?,
      storageLocation: json['storage_location'] ?? '',
    );
  }
}

class UserStockUpdateRequest {
  final double quantity;
  final int unitId;
  final String? expireDate;
  final String storageLocation;

  UserStockUpdateRequest({
    required this.quantity,
    required this.unitId,
    this.expireDate,
    required this.storageLocation,
  });

  Map<String, dynamic> toJson() {
    return {
      'quantity': quantity,
      'unit_id': unitId,
      'expire_date': expireDate,
      'storage_location': storageLocation,
    };
  }
}

class CategoryModel {
  final int categoryId;
  final String categoryName;

  CategoryModel({
    required this.categoryId,
    required this.categoryName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      categoryId: json['category_id'] ?? json['tag_id'] ?? 0, // In case of overlap format
      categoryName: json['category_name'] ?? json['tag_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'category_name': categoryName,
    };
  }
}

class TagModel {
  final int tagId;
  final String tagName;

  TagModel({
    required this.tagId,
    required this.tagName,
  });

  factory TagModel.fromJson(Map<String, dynamic> json) {
    return TagModel(
      tagId: json['tag_id'] ?? 0,
      tagName: json['tag_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag_id': tagId,
      'tag_name': tagName,
    };
  }
}
