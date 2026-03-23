import '../../../data/models/recipe_model.dart';

class RecipeModel {
  final int recipeId;
  final String recipeName;
  final String description;
  final int cookingTimeMin;
  final String imageUrl;
  final String username;
  final String? createDate;
  final int likeCount;
  final bool isLiked;
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

  RecipeModel copyWith({
    int? recipeId,
    String? recipeName,
    String? description,
    int? cookingTimeMin,
    String? imageUrl,
    String? username,
    String? createDate,
    int? likeCount,
    bool? isLiked,
    bool? isPublic,
    bool? isActive,
    List<String>? tags,
    List<CategoryModel>? categoryDetails,
    List<TagModel>? tagDetails,
    List<RecipeIngredient>? ingredients,
    List<RecipeStep>? steps,
  }) {
    return RecipeModel(
      recipeId: recipeId ?? this.recipeId,
      recipeName: recipeName ?? this.recipeName,
      description: description ?? this.description,
      cookingTimeMin: cookingTimeMin ?? this.cookingTimeMin,
      imageUrl: imageUrl ?? this.imageUrl,
      username: username ?? this.username,
      createDate: createDate ?? this.createDate,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      isPublic: isPublic ?? this.isPublic,
      isActive: isActive ?? this.isActive,
      tags: tags ?? this.tags,
      categoryDetails: categoryDetails ?? this.categoryDetails,
      tagDetails: tagDetails ?? this.tagDetails,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
    );
  }

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    // Ultra-robust discovery
    dynamic _findValue(List<String> keys) {
      for (var k in keys) {
        if (json[k] != null) return json[k];
      }
      for (var k in json.keys) {
        for (var target in keys) {
          if (k.toLowerCase().trim() == target.toLowerCase().trim() && json[k] != null) return json[k];
        }
      }
      if (json['recipe'] is Map) {
        final r = json['recipe'] as Map;
        for (var k in keys) {
          if (r[k] != null) return r[k];
        }
      }
      return null;
    }

    final ingredientsRaw = _findValue(['ingredients', 'recipe_ingredients', 'ingredient_list', 'items', 'components', 'recipe_ingredient', 'วัตถุดิบ', 'ส่วนผสม']);
    final stepsRaw = _findValue(['steps', 'recipe_steps', 'instructions', 'method', 'directions', 'step_list', 'recipe_step', 'วิธีทำ', 'ขั้นตอน', 'ขั้นตอนการทำ']);
    final catsRaw = _findValue(['categories', 'category', 'category_details', 'dish_type', 'type', 'หมวดหมู่', 'ประเภทวอาหาร']);
    final tagsRaw = _findValue(['tags', 'tag_list', 'tag_details', 'keywords', 'แท็ก', 'ป้ายกำกับ']);

    print('DEBUG: RecipeModel.fromJson - Parsing "${json['recipe_name'] ?? json['name']}"');
    print('DEBUG: Found ingredients: ${ingredientsRaw is List ? (ingredientsRaw as List).length : (ingredientsRaw != null ? 1 : 0)}');
    print('DEBUG: Found steps: ${stepsRaw is List ? (stepsRaw as List).length : (stepsRaw != null ? 1 : 0)}');

    // Handle Categories (could be List, Map, or String)
    List<CategoryModel>? parsedCats;
    if (catsRaw is List) {
      parsedCats = (catsRaw as List).map((c) => CategoryModel.fromJson(c is String ? {'category_name': c} : c)).toList();
    } else if (catsRaw is Map) {
      parsedCats = [CategoryModel.fromJson(catsRaw as Map<String, dynamic>)];
    } else if (catsRaw is String) {
      parsedCats = [CategoryModel(categoryId: 0, categoryName: catsRaw)];
    }

    // Handle Tags (could be List, Map, or String)
    List<String> parsedTags = [];
    List<TagModel>? parsedTagDetails;
    if (tagsRaw is List) {
      for (var t in tagsRaw as List) {
        if (t is String) parsedTags.add(t);
        else if (t is Map) {
          parsedTagDetails ??= [];
          parsedTagDetails.add(TagModel.fromJson(Map<String, dynamic>.from(t)));
        }
      }
    } else if (tagsRaw is String) {
      parsedTags = [tagsRaw];
    }

    return RecipeModel(
      recipeId: json['recipe_id'] ?? json['id'] ?? 0,
      recipeName: json['recipe_name'] ?? json['name'] ?? json['title'] ?? json['label'] ?? json['ชื่อเมนู'] ?? json['ชื่ออาหาร'] ?? '',
      description: json['description']?.toString() ?? json['คำอธิบาย']?.toString() ?? json['รายละเอียด']?.toString() ?? '',
      cookingTimeMin: _parseToInt(json['cooking_time_min'] ?? json['cooking_time'] ?? json['time'] ?? json['prep_time'] ?? json['เวลาที่ใช้'] ?? json['เวลาปรุง']),
      imageUrl: json['image_url'] ?? json['image'] ?? '',
      username: json['username'] ?? '',
      createDate: json['create_date']?.toString(),
      likeCount: _parseToInt(json['like_count'] ?? json['likes']),
      isLiked: json['is_liked'] == true,
      isPublic: json['is_public'] == true,
      isActive: json['is_active'] == true,
      tags: parsedTags,
      categoryDetails: parsedCats,
      tagDetails: parsedTagDetails,
      ingredients: (ingredientsRaw is List) 
          ? ingredientsRaw.map((i) => RecipeIngredient.fromJson(i)).toList()
          : (ingredientsRaw != null ? [RecipeIngredient.fromJson(ingredientsRaw)] : null),
      steps: (stepsRaw is List) 
          ? stepsRaw.map((s) => RecipeStep.fromJson(s)).toList()
          : (stepsRaw != null ? [RecipeStep.fromJson(stepsRaw)] : null),
    );
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
  final double quantityValue;
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

  factory RecipeIngredient.fromJson(dynamic json) {
    if (json is String) {
      return RecipeIngredient(
        ingredientId: 0,
        ingredientName: json,
        quantityValue: 0.0,
        unitId: 0,
        unitName: '',
        isMainIngredient: true,
      );
    }
    
    if (json is! Map) {
       return RecipeIngredient(ingredientId: 0, ingredientName: '', quantityValue: 0.0, unitId: 0, unitName: '');
    }

    return RecipeIngredient(
      ingredientId: json['ingredient_id'] ?? 0,
      ingredientName: json['ingredient_name'] ?? json['name'] ?? json['item'] ?? json['ingredient'] ?? json['item_name'] ?? '',
      quantityValue: _parseToDouble(json['quantity'] ?? json['qty'] ?? json['amount']),
      unitId: json['unit_id'] ?? 0,
      unitName: json['unit_name'] ?? json['unit'] ?? '',
      isMainIngredient: json['is_main_ingredient'] == true || json['main'] == true || json['is_main'] == true,
    );
  }

  static double _parseToDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
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

  factory RecipeStep.fromJson(dynamic json) {
    if (json is String) {
      return RecipeStep(
        stepNo: 0,
        instruction: json,
      );
    }

    if (json is! Map) {
      return RecipeStep(stepNo: 0, instruction: '');
    }

    return RecipeStep(
      stepNo: _parseToInt(json['step_no'] ?? json['no'] ?? json['order']),
      instruction: json['instruction'] ?? json['description'] ?? json['text'] ?? json['step'] ?? json['detail'] ?? '',
    );
  }

  static int _parseToInt(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
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
    final name = json['class_name'] ?? json['recipe_name'] ?? json['label'] ?? json['prediction'] ?? 'ไม่ทราบข้อมูล';
    
    double conf = 0.0;
    final rawConf = json['confidence'] ?? json['score'] ?? json['probability'];
    if (rawConf is num) {
      conf = rawConf.toDouble();
    } else if (rawConf is String) {
      conf = double.tryParse(rawConf) ?? 0.0;
    } else if (name != 'ไม่ทราบข้อมูล' && rawConf == null) {
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
  final List<TagModel>? tags;
  final List<String>? predictedNames;

  DishAIResponse({
    required this.top3, 
    this.recipes, 
    this.ingredients = const [],
    this.tags,
    this.predictedNames,
  });

  factory DishAIResponse.fromJson(dynamic json) {
    try {
      if (json == null) {
        return DishAIResponse(top3: [], ingredients: [], recipes: [], tags: [], predictedNames: []);
      }

      if (json is List) {
        final recipes = json.whereType<Map<String, dynamic>>()
            .map((e) => Recipe.fromJson(e)).toList();
        final predictions = recipes.map((r) => DishPrediction(className: r.title, confidence: 1.0)).toList();
        return DishAIResponse(top3: predictions, recipes: recipes, ingredients: const [], tags: [], predictedNames: []);
      }

      if (json is! Map<String, dynamic>) {
        return DishAIResponse(top3: [], ingredients: [], recipes: [], tags: [], predictedNames: []);
      }

      Map<String, dynamic> target = json;
      if (json.containsKey('data')) {
        final data = json['data'];
        if (data is Map<String, dynamic>) {
          target = data;
        } else if (data is List) {
          final recipes = data.whereType<Map<String, dynamic>>()
              .map((e) => Recipe.fromJson(e)).toList();
          final predictions = recipes.map((r) => DishPrediction(className: r.title, confidence: 1.0)).toList();
          return DishAIResponse(top3: predictions, recipes: recipes, ingredients: [], tags: [], predictedNames: []);
        }
      }

      final predictionsList = target['top_3'] ?? target['results'] ?? target['predictions'];
      List<DishPrediction> predictions = [];
      if (predictionsList != null && predictionsList is List) {
        predictions = predictionsList.whereType<Map<String, dynamic>>()
            .map((e) => DishPrediction.fromJson(e)).toList();
      }
      
      final ingredientsList = (target['ingredients'] ?? target['items']) as List?;
      List<String> ingredients = [];
      if (ingredientsList != null && ingredientsList is List) {
        ingredients = ingredientsList.map((e) => e.toString()).toList();
      }
      
      final recipesList = (target['recipes'] ?? target['data']) as List?;
      List<Recipe>? recipes;
      if (recipesList != null && recipesList is List) {
        recipes = recipesList.whereType<Map<String, dynamic>>()
            .map((e) => Recipe.fromJson(e)).toList();
      }

      final tagsList = target['tags'] as List?;
      List<TagModel>? tags;
      if (tagsList != null && tagsList is List) {
        tags = tagsList.whereType<Map<String, dynamic>>()
            .map((e) => TagModel.fromJson(e)).toList();
      }

      final predictedNamesList = target['predicted_name'] as List?;
      List<String>? predictedNames;
      if (predictedNamesList != null) {
        predictedNames = predictedNamesList.map((e) => e.toString()).toList();
      }

      return DishAIResponse(
        top3: predictions,
        recipes: recipes,
        ingredients: ingredients,
        tags: tags,
        predictedNames: predictedNames,
      );
    } catch (e) {
      return DishAIResponse(top3: [], ingredients: [], recipes: [], tags: [], predictedNames: []);
    }
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
      categoryId: json['category_id'] ?? json['tag_id'] ?? 0,
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
